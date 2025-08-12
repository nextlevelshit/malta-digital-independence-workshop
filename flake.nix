{
	description = "CODE CRISPIES Workshop Infrastructure";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		nixos-generators.url = "github:nix-community/nixos-generators";
	};

	outputs = { self, nixpkgs, nixos-generators }:
	let
		system = "x86_64-linux";
		pkgs = nixpkgs.legacyPackages.${system};
		participantRange = nixpkgs.lib.range 1 2;
		fullParticipantNames = [
			"hopper" "curie" "lovelace" "noether" "hamilton"
			"franklin" "johnson" "clarke" "goldberg" "liskov"
			"wing" "rosen" "shaw" "karp" "rich"
		];
	in
	{
		packages.${system} = {
			live-iso = nixos-generators.nixosGenerate {
				inherit system;
				format = "iso";
				modules = [
					({ pkgs, ... }: {
						system.stateVersion = "25.05";
						networking.networkmanager.enable = true;
						users.users.workshop = { 
							isNormalUser = true;
							shell = pkgs.zsh;
							extraGroups = [ "wheel" ];
							password = "workshop";
						};
						services.getty.autologinUser = "workshop";
						programs.zsh.enable = true;
						environment.systemPackages = with pkgs; [ openssh curl git ];
						services.xserver = {
							enable = true;
							displayManager.lightdm.enable = true;
							desktopManager.xfce.enable = true;
						};
						services.displayManager.autoLogin.enable = true;
						services.displayManager.autoLogin.user = "workshop";
					})
				];
			};
			local-vm = self.nixosConfigurations.workshop-local.config.system.build.vm;
		};

		nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				({ config, pkgs, ... }: {
					system.stateVersion = "25.05";
					boot.loader.grub.enable = false;
					boot.loader.generic-extlinux-compatible.enable = true;
					
					# Enable IP forwarding for NAT
					boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
					
					# Host VM user setup
					users.users.workshop = {
						isNormalUser = true;
						extraGroups = [ "wheel" ];
						password = "";
						shell = pkgs.bash;
					};
					
					# GUI setup
					services.xserver = {
						enable = true;
						desktopManager.xfce.enable = true;
						displayManager.lightdm.enable = true;
					};
					services.displayManager.autoLogin.enable = true;
					services.displayManager.autoLogin.user = "workshop";
					
					# Auto-open root terminal
					services.xserver.displayManager.sessionCommands = ''
						${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal -T "Workshop Root Shell" -e "sudo -i" &
					'';

					# Workshop user convenience
					programs.bash = {
						shellAliases = {
							connect = "sudo nixos-container login";
							containers = "sudo nixos-container list";
							root = "sudo -i";
						};
					};

					environment.systemPackages = with pkgs; [ 
						gnumake nano nixos-container firefox git curl jq
					];
					security.pam.services.login.allowNullPassword = true;
					security.sudo.wheelNeedsPassword = false;
					networking.hostName = "workshop-vm";

					# FIXED: Proper NAT configuration
					networking = {
						nat = {
							enable = true;
							internalInterfaces = ["ve-+"];
							externalInterface = "eth0";
							# Ensure we have masquerading
							extraCommands = ''
								iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
							'';
						};
						firewall = {
							enable = true;
							trustedInterfaces = [ "ve-+" ];
							# Allow forwarding from containers
							extraCommands = ''
								iptables -A FORWARD -i ve-+ -j ACCEPT
								iptables -A FORWARD -o ve-+ -j ACCEPT
							'';
						};
					};

					# Container configurations
					containers = builtins.listToAttrs (map (i:
						let participant = builtins.elemAt fullParticipantNames (i - 1);
						in {
							name = participant;
							value = {
								autoStart = true;
								privateNetwork = true;
								hostAddress = "192.168.100.1";
								localAddress = "192.168.100.${toString (10 + i)}";
								config = {
									system.stateVersion = "25.05";
									
									users.users.root = {
										password = "root";
										openssh.authorizedKeys.keys = [];
									};
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
									
									# FIXED: Proper network configuration
									networking = {
										hostName = participant;
										nameservers = [ "8.8.8.8" "1.1.1.1" ];
										defaultGateway = {
											address = "192.168.100.1";
											interface = "eth0";
										};
										firewall.enable = false;
										useHostResolvConf = false;
										# Ensure eth0 is configured properly
										interfaces.eth0.ipv4.addresses = [{
											address = "192.168.100.${toString (10 + i)}";
											prefixLength = 24;
										}];
									};
									
									console.enable = true;
									security.sudo.wheelNeedsPassword = false;
									
									virtualisation.docker.enable = true;
									environment.systemPackages = with pkgs; [ 
										docker git curl jq wget gnutar gzip util-linux
									];
									
									# FIXED: Better network initialization
									systemd.services.container-network-setup = {
										wantedBy = [ "network.target" ];
										before = [ "network-online.target" ];
										script = ''
											# Ensure proper routing
											${pkgs.iproute2}/bin/ip route add default via 192.168.100.1 dev eth0 || true
											# Set up DNS
											echo "nameserver 8.8.8.8" > /etc/resolv.conf
											echo "nameserver 1.1.1.1" >> /etc/resolv.conf
										'';
										serviceConfig = {
											Type = "oneshot";
											RemainAfterExit = true;
										};
									};
									
									systemd.services.workshop-setup = {
										wantedBy = [ "multi-user.target" ];
										after = [ "network-online.target" "docker.service" "container-network-setup.service" ];
										wants = [ "network-online.target" ];
										script = ''
											export HOME=/root
											export PATH=/run/current-system/sw/bin:$PATH
											
											# Wait for network with better test
											echo "Testing network connectivity..."
											for attempt in {1..30}; do
												if ${pkgs.curl}/bin/curl -s --max-time 10 --connect-timeout 5 https://install.abra.coopcloud.tech >/dev/null 2>&1; then
													echo "Network is up!"
													break
												fi
												echo "Attempt $attempt: Waiting for network..."
												sleep 2
											done
											
											# Docker swarm init
											${pkgs.docker}/bin/docker swarm init --advertise-addr 192.168.100.${toString (10 + i)} || true
											
											# Install abra
											if [ ! -f /root/.local/bin/abra ]; then
												echo "Installing abra..."
												${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
											fi
											
											# Make abra globally available
											if [ -f /root/.local/bin/abra ]; then
												ln -sf /root/.local/bin/abra /usr/local/bin/abra || true
											fi
											
											# Add server
											if command -v abra >/dev/null 2>&1; then
												abra server add ${participant}.local || true
											fi
										'';
										serviceConfig = { 
											Type = "oneshot"; 
											RemainAfterExit = true;
											StandardOutput = "journal";
											StandardError = "journal";
										};
									};

									environment.sessionVariables = {
										PATH = [ "/root/.local/bin" "$PATH" ];
									};
								};
							};
						}
					) participantRange);
					
					# DNS for .local domains
					services.dnsmasq = {
						enable = true;
						settings = {
							address = builtins.concatMap (i:
								let participant = builtins.elemAt fullParticipantNames (i - 1);
								in [ "/${participant}.local/192.168.100.${toString (10 + i)}" ]
							) participantRange;
							server = [ "8.8.8.8" "1.1.1.1" ];
						};
					};
				})
			];
		};
		
		devShells.${system}.default = pkgs.mkShell {
			buildInputs = with pkgs; [
				terraform
				nixos-rebuild
				docker
				openssh
			];
		};
	};
}
