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
					
					# CORRECTED GUI setup
					services.xserver = {
						enable = true;
						desktopManager.xfce.enable = true;
						displayManager = {
							lightdm.enable = true;
							autoLogin.enable = true;
							autoLogin.user = "workshop";
							sessionCommands = ''
								${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal --title="Workshop Terminal" \
									--command="bash -c 'echo \"🍪 Workshop VM Ready!\"; echo \"\"; echo \"SSH into containers:\"; echo \"  ssh root@192.168.100.11  # hopper\"; echo \"  ssh root@192.168.100.12  # curie\"; echo \"\"; bash'" &
							'';
						};
					};
					
					environment.systemPackages = with pkgs; [ 
						firefox curl git jq nano tree nixos-container
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
					
					programs.bash.shellAliases = {
						containers = "nixos-container list";
						hopper = "ssh root@192.168.100.11";
						curie = "ssh root@192.168.100.12";
					};

					# Container configs (same as before)
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
										docker curl git wget jq
									];
									
									systemd.services.workshop-setup = {
										wantedBy = [ "multi-user.target" ];
										after = [ "network-online.target" "docker.service" ];
										wants = [ "network-online.target" ];
										script = ''
											echo "🍪 Setting up ${name} container..."
											
											for i in {1..10}; do
												if curl -s --max-time 5 google.com >/dev/null 2>&1; then
													echo "✅ Network ready"
													break
												fi
												echo "⏳ Waiting for network... ($i/10)"
												sleep 2
											done
											
											${pkgs.docker}/bin/docker swarm init --advertise-addr ${ip} || true
											
											echo "✅ ${name} container ready!"
											echo "SSH: ssh root@${ip} (password: root)"
										'';
										serviceConfig = {
											Type = "oneshot";
											RemainAfterExit = true;
										};
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
