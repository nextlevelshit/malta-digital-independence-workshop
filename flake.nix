{
	description = "Workshop VM with Participant Containers";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
	};

	outputs = { self, nixpkgs }:
	let
		system = "x86_64-linux";
		pkgs = nixpkgs.legacyPackages.${system};
		participantNames = [ "hopper" "curie" ];
	in
	{
		packages.${system} = {
			local-vm = self.nixosConfigurations.workshop-vm.config.system.build.vm;
		};

		nixosConfigurations.workshop-vm = nixpkgs.lib.nixosSystem {
			inherit system;
			modules = [
				({ config, pkgs, ... }: {
					system.stateVersion = "25.05";
					
					boot.loader.grub.enable = false;
					boot.loader.generic-extlinux-compatible.enable = true;
					boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
					
					users.users.workshop = {
						isNormalUser = true;
						extraGroups = [ "wheel" ];
						password = "";
						shell = pkgs.bash;
					};
					
					security.pam.services.login.allowNullPassword = true;
					security.sudo.wheelNeedsPassword = false;
					
					# GUI setup
					services.xserver = {
						enable = true;
						desktopManager.xfce.enable = true;
						displayManager.lightdm.enable = true;
					};
					
					services.displayManager = {
						autoLogin.enable = true;
						autoLogin.user = "workshop";
					};
					
					# Auto-open terminal with helper commands
					services.xserver.displayManager.sessionCommands = ''
						${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal --title="🍪 Workshop Terminal" \
							--command="bash -c '
								echo \"🍪 Workshop VM Ready!\"; 
								echo \"\";
								echo \"🔌 SSH into containers:\";
								echo \"  sudo connect hopper       # Container login\";
								echo \"  sudo connect curie        # Container login\";
								echo \"  ssh root@192.168.100.11   # Direct SSH to hopper\";
								echo \"  ssh root@192.168.100.12   # Direct SSH to curie\";
								echo \"\";
								echo \"📦 Container management:\";
								echo \"  sudo containers           # List all containers\";
								echo \"  sudo logs                 # Show setup logs\";
								echo \"\";
								echo \"✨ Abra is pre-installed in containers!\";
								echo \"\";
								bash
							'" &
					'';
					
					# System packages including helper scripts
					environment.systemPackages = with pkgs; [ 
						firefox curl git jq nano tree nixos-container
						# Custom helper scripts that work with sudo
						(pkgs.writeScriptBin "connect" ''
							#!/bin/bash
							if [ -z "$1" ]; then
								echo "Usage: connect <container-name>"
								echo "Available: hopper curie"
								exit 1
							fi
							exec nixos-container root-login "$1"
						'')
						(pkgs.writeScriptBin "containers" ''
							#!/bin/bash
							exec nixos-container list
						'')
						(pkgs.writeScriptBin "logs" ''
							#!/bin/bash
							exec journalctl -u container@hopper -u container@curie -f
						'')
					];
					
					networking = {
						hostName = "workshop-vm";
						firewall.enable = false;
						nat = {
							enable = true;
							internalInterfaces = ["ve-+"];
							externalInterface = "eth0";
						};
					};

					# Container configurations with automated abra installation
					containers = builtins.listToAttrs (builtins.genList (i:
						let 
							name = builtins.elemAt participantNames i;
							ip = "192.168.100.${toString (11 + i)}";
						in {
							inherit name;
							value = {
								autoStart = true;
								privateNetwork = true;
								hostAddress = "192.168.100.1";
								localAddress = ip;
								
								config = {
									system.stateVersion = "25.05";
									
									users.users.root.password = "root";
									users.users.workshop = {
										isNormalUser = true;
										password = "workshop";
										extraGroups = [ "wheel" "docker" ];
									};
									
									services.openssh = {
										enable = true;
										settings = {
											PasswordAuthentication = true;
											PermitRootLogin = "yes";
										};
									};
									
									networking = {
										hostName = name;
										nameservers = [ "8.8.8.8" ];
										firewall.enable = false;
									};
									
									security.sudo.wheelNeedsPassword = false;
									virtualisation.docker.enable = true;
									
									environment.systemPackages = with pkgs; [ 
										docker curl git wget jq bash
									];
									
									# Automated abra installation service
									systemd.services.workshop-setup = {
										wantedBy = [ "multi-user.target" ];
										after = [ "network-online.target" "docker.service" ];
										wants = [ "network-online.target" ];
										script = ''
											echo "🍪 Setting up ${name} container..."
											
											# Wait for network
											for i in {1..10}; do
												if ${pkgs.curl}/bin/curl -s --max-time 5 google.com >/dev/null 2>&1; then
													echo "✅ Network ready"
													break
												fi
												echo "⏳ Waiting for network... ($i/10)"
												sleep 2
											done
											
											# Initialize Docker Swarm
											${pkgs.docker}/bin/docker swarm init --advertise-addr ${ip} || true
											
											# Install abra for root user
											export HOME=/root
											if [ ! -f /root/.local/bin/abra ]; then
												echo "📦 Installing abra..."
												${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
												echo "✅ Abra installed"
											fi
											
											# Make abra available globally
											if ! grep -q "/.local/bin" /root/.bashrc 2>/dev/null; then
												echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
											fi
											
											# Create symlink for immediate availability
											if [ -f /root/.local/bin/abra ]; then
												ln -sf /root/.local/bin/abra /usr/local/bin/abra 2>/dev/null || true
											fi
											
											# Add server
											if [ -f /root/.local/bin/abra ]; then
												export PATH="/root/.local/bin:$PATH"
												/root/.local/bin/abra server add ${name}.local 2>/dev/null || true
											fi
											
											echo "✅ ${name} container ready!"
											echo "SSH: ssh root@${ip} (password: root)"
											echo "Abra: Available via 'abra' command"
										'';
										serviceConfig = {
											Type = "oneshot";
											RemainAfterExit = true;
											StandardOutput = "journal";
											StandardError = "journal";
										};
									};
									
									# Ensure abra is in PATH for all sessions
									environment.sessionVariables = {
										PATH = [ "/root/.local/bin" ];
									};
								};
							};
						}
					) (builtins.length participantNames));
				})
			];
		};
	};
}
