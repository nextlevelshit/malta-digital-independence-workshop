{
	description = "Workshop VM with Participant Containers + USB ISO";
	
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		nixos-generators = {
			url = "github:nix-community/nixos-generators";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, nixos-generators }:
		let
			system = "x86_64-linux";
			pkgs = nixpkgs.legacyPackages.${system};
			
			# All possible participant names for the workshop
			allParticipantNames = [
				"hopper" "curie" "lovelace" "noether" "hamilton"
				"franklin" "johnson" "clarke" "goldberg" "liskov"
				"wing" "rosen" "shaw" "karp" "rich"
			];
			
			# Dynamic participant count (default 3, max 15)
			participantsEnv = builtins.getEnv "PARTICIPANTS";
			numParticipants = 
				if participantsEnv != "" && builtins.match "^[0-9]+$" participantsEnv != null
				then 
					let num = builtins.fromJSON participantsEnv;
					in if num >= 1 && num <= 15 then num else 3
				else 3;
			
			# Selected participant names based on count
			participantNames = builtins.genList 
				(i: builtins.elemAt allParticipantNames i) 
				numParticipants;
		in
		{
			packages.${system} = {
				local-vm = self.nixosConfigurations.workshop-vm.config.system.build.vm;

				live-iso = nixos-generators.nixosGenerate {
					inherit system;
					format = "iso";

					modules = [
						({ pkgs, ... }: {
							system.stateVersion = "25.05";

							isoImage.makeEfiBootable = true;
							isoImage.makeUsbBootable = true;

							networking.wireless.enable = true;
							networking.networkmanager.enable = true;
							networking.hostName = "workshop-live";

							# Enable Docker for local development
							virtualisation.docker.enable = true;

							services.getty.autologinUser = "workshop";
							users.users.workshop = {
								isNormalUser = true;
								shell = pkgs.zsh;
								extraGroups = [ "networkmanager" "wheel" "docker" ];
								password = "";
							};

							security.sudo.wheelNeedsPassword = false;

							environment.systemPackages = with pkgs; [
								openssh curl git networkmanager firefox xterm
								docker docker-compose
								# For local abra installation
								bash wget jq tree nano
							];

							# Auto-install abra on boot
							systemd.services.workshop-abra-setup = {
								wantedBy = [ "multi-user.target" ];
								after = [ "network-online.target" "docker.service" ];
								wants = [ "network-online.target" ];
								script = ''
									export HOME=/home/workshop
									
									# Wait for network
									for i in {1..10}; do
										if ${pkgs.curl}/bin/curl -s --max-time 5 google.com >/dev/null 2>&1; then
											break
										fi
										sleep 3
									done
									
									# Install abra for workshop user (DO NOT change installation method)
									if [ ! -f /home/workshop/.local/bin/abra ]; then
										sudo -u workshop mkdir -p /home/workshop/.local/bin
										cd /home/workshop
										sudo -u workshop ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | sudo -u workshop ${pkgs.bash}/bin/bash
									fi
									
									# Initialize local Docker Swarm
									${pkgs.docker}/bin/docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || true
									
									# Add workshop user to docker group
									usermod -aG docker workshop
								'';
								serviceConfig = {
									Type = "oneshot";
									RemainAfterExit = true;
									User = "root";
								};
							};

							programs.zsh = {
								enable = true;
								interactiveShellInit = ''
									echo "CODE CRISPIES Workshop Environment"
									echo "Mode: Local Development + Cloud Access"
									echo ""
									echo "🏠 Local Development:"
									echo "  recipes          - Show available app recipes"
									echo "  deploy <recipe>  - Deploy app locally (e.g., deploy wordpress)"
									echo "  browser          - Launch Firefox"
									echo "  desktop          - Start GUI session"
									echo ""
									echo "☁️  Cloud Access:"
									echo "  Available servers:"
									${builtins.concatStringsSep "\n" (map (name: 
										"echo \"    - ${name}.codecrispi.es\""
									) allParticipantNames)}
									echo "  connect <name>   - SSH to cloud server"
									echo ""
									echo "📚 Commands: recipes | deploy | connect | browser | desktop | help"
									
									# Ensure abra is in PATH
									export PATH="$HOME/.local/bin:$PATH"
									
									deploy() {
										if [ -z "$1" ]; then
											echo "Usage: deploy <recipe>"
											echo "Example: deploy wordpress"
											echo "Run 'recipes' to see available options"
											return 1
										fi
										
										local recipe="$1"
										local domain="$recipe.workshop.local"
										
										echo "🚀 Deploying $recipe locally..."
										echo "Domain: $domain"
										
										# Check if abra is available
										if ! command -v abra &> /dev/null; then
											echo "❌ Abra not found. Run 'sudo systemctl restart workshop-abra-setup'"
											return 1
										fi
										
										# Deploy with abra
										abra app new "$recipe" -S --domain="$domain"
										abra app deploy "$domain"
										
										echo "✅ Deployed! Access at: http://$domain"
										echo "🌐 Open browser with: browser"
									}
									
									connect() {
										[ -z "$1" ] && { echo "Usage: connect <name>"; return 1; }
										echo "Connecting to $1.codecrispi.es..."
										ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
									}
									
									recipes() {
										echo "Available Co-op Cloud Recipes:"
										echo ""
										echo "📝 Content Management:"
										echo "  wordpress ghost hedgedoc dokuwiki mediawiki"
										echo ""
										echo "📁 File & Collaboration:" 
										echo "  nextcloud seafile collabora onlyoffice"
										echo ""
										echo "💬 Communication:"
										echo "  jitsi-meet matrix-synapse rocketchat mattermost"
										echo ""
										echo "🛒 E-commerce & Business:"
										echo "  prestashop invoiceninja kimai pretix"
										echo ""
										echo "⚙️  Development & Tools:"
										echo "  gitea drone n8n gitlab jupyter-lab"
										echo ""
										echo "📊 Analytics & Monitoring:"
										echo "  plausible matomo uptime-kuma grafana"
										echo ""
										echo "🎵 Media & Social:"
										echo "  peertube funkwhale mastodon pixelfed jellyfin"
										echo ""
										echo "🚀 Local Deploy: deploy <recipe>"
										echo "☁️  Cloud Deploy: connect <server> then use abra commands"
										echo "📖 Browse all: https://recipes.coopcloud.tech"
									}
									
									browser() {
										echo "🌐 Starting Firefox..."
										if [ -n "$DISPLAY" ]; then
											firefox &
										else
											echo "❌ No GUI session. Run 'desktop' first"
										fi
									}
									
									desktop() {
										echo "🖥️  Starting GUI session..."
										if [ -z "$DISPLAY" ]; then
											startx &
											export DISPLAY=:0
											sleep 3
											echo "✅ GUI started. Run 'browser' to open Firefox"
										else
											echo "ℹ️  GUI already running"
										fi
									}
									
									help() {
										echo "CODE CRISPIES Workshop Commands:"
										echo ""
										echo "🏠 Local Development:"
										echo "  recipes         - Show all available app recipes"
										echo "  deploy <recipe> - Deploy app locally (e.g., deploy wordpress)"
										echo "  browser         - Launch Firefox browser"
										echo "  desktop         - Start GUI desktop session"
										echo ""
										echo "☁️  Cloud Access:"
										echo "  connect <name>  - SSH to cloud server (e.g., connect hopper)"
										echo ""
										echo "🔧 System:"
										echo "  sudo nmcli dev wifi connect SSID password PASSWORD"
										echo "  sudo systemctl restart workshop-abra-setup  # Reinstall abra"
										echo ""
										echo "📚 Learning Flow:"
										echo "  1. Try local: recipes → deploy wordpress → browser"
										echo "  2. Try cloud: connect hopper → same abra commands"
										echo ""
										echo "Available servers: ${builtins.concatStringsSep " " allParticipantNames}"
									}
									
									export -f deploy connect recipes browser desktop help
								'';
							};

							services.xserver = {
								enable = true;
								desktopManager.xfce.enable = true;
								displayManager = {
									lightdm.enable = true;
									autoLogin.enable = false;  # Manual desktop start
								};
							};

							# Don't auto-start GUI, let user choose
							systemd.user.services.workshop-welcome = {
								wantedBy = [ "default.target" ];
								script = ''
									echo "Welcome! Run 'desktop' to start GUI session"
								'';
								serviceConfig.Type = "oneshot";
							};
						})
					];
				};
			};

			devShells.${system}.default = pkgs.mkShell {
				packages = with pkgs; [
					markdownlint-cli
					jq
					nixpkgs-fmt
				];
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
							password = "workshop";
							shell = pkgs.bash;
						};

						security.sudo.wheelNeedsPassword = false;

						services.xserver = {
							enable = true;
							desktopManager.xfce.enable = true;
							displayManager.lightdm.enable = true;
						};

						services.displayManager = {
							autoLogin.enable = true;
							autoLogin.user = "workshop";
						};

						services.xserver.displayManager.sessionCommands = ''
							${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal --title="Workshop Terminal" \
								--command="bash -c '
									echo \"Workshop VM Ready!\";
									echo \"\";
									echo \"SSH into containers:\";
									${builtins.concatStringsSep "\n" (builtins.genList (i:
										let 
											name = builtins.elemAt participantNames i;
											ip = "192.168.100.${toString (11 + i)}";
										in "echo \"  sudo connect ${name}       # Container login to ${name} (${ip})\""
									) (builtins.length participantNames))}
									echo \"  (Total: ${toString numParticipants} containers)\";
									echo \"\";
									echo \"Container management:\";
									echo \"  sudo containers           # List all containers\";
									echo \"  sudo logs                 # Show setup logs\";
									echo \"  sudo recipes              # Show available recipes\";
									echo \"\";
									echo \"Abra is pre-installed in containers!\";
									echo \"\";
									bash
								'" &
						'';

						environment.systemPackages = with pkgs; [
							firefox curl git jq nano tree nixos-container
							
							(pkgs.writeScriptBin "connect" ''
								#!/bin/bash
								if [ -z "$1" ]; then
									echo "Usage: connect <container-name>"
									echo "Available: ${builtins.concatStringsSep " " participantNames}"
									exit 1
								fi
								exec nixos-container root-login "$1"
							'')
							
							(pkgs.writeScriptBin "containers" ''
								#!/bin/bash
								echo "Active containers:"
								nixos-container list
								echo ""
								echo "Container IPs:"
								${builtins.concatStringsSep "\n" (builtins.genList (i:
									let 
										name = builtins.elemAt participantNames i;
										ip = "192.168.100.${toString (11 + i)}";
									in "echo \"  ${name}: ${ip}\""
								) (builtins.length participantNames))}
							'')
							
							(pkgs.writeScriptBin "logs" ''
								#!/bin/bash
								echo "Showing logs for all containers (Ctrl+C to exit)"
								exec journalctl -u container@* -f
							'')
							
							(pkgs.writeScriptBin "recipes" ''
								#!/bin/bash
								echo "Available Co-op Cloud Recipes:"
								echo ""
								echo "Content Management:"
								echo "  wordpress ghost hedgedoc dokuwiki mediawiki"
								echo ""
								echo "File & Collaboration:"
								echo "  nextcloud seafile collabora onlyoffice"
								echo ""
								echo "Communication:"
								echo "  jitsi-meet matrix-synapse rocketchat mattermost"
								echo ""
								echo "E-commerce & Business:"
								echo "  prestashop invoiceninja kimai pretix"
								echo ""
								echo "Development & Tools:"
								echo "  gitea drone n8n gitlab jupyter-lab"
								echo ""
								echo "Analytics & Monitoring:"
								echo "  plausible matomo uptime-kuma grafana"
								echo ""
								echo "Media & Social:"
								echo "  peertube funkwhale mastodon pixelfed jellyfin"
								echo ""
								echo "Usage in container:"
								echo "  abra app new <recipe> -S --domain=myapp.<container-name>.local"
								echo "  abra app new wordpress -S --domain=blog.hopper.local"
								echo "  abra app deploy myapp.<container-name>.local"
								echo ""
								echo "Browse all: https://recipes.coopcloud.tech"
							'')
							
							(pkgs.writeScriptBin "help" ''
								#!/bin/bash
								echo "CODE CRISPIES Workshop VM Commands:"
								echo ""
								echo "Container Management:"
								echo "  connect <name>  - SSH into specific container"
								echo "  containers      - List all containers with IPs"
								echo "  logs            - Show container setup logs"
								echo ""
								echo "Workshop Tools:"
								echo "  recipes         - Show available Co-op Cloud recipes"
								echo "  help            - Show this help"
								echo ""
								echo "Examples:"
								echo "  sudo connect hopper"
								echo "  ssh root@192.168.100.11"
								echo ""
								echo "Available containers (${toString numParticipants}): ${builtins.concatStringsSep " " participantNames}"
							'')    
						];

						# Local DNS resolution for .local domains
						networking = {
							hostName = "workshop-vm";
							firewall.enable = false;
							nat = {
								enable = true;
								internalInterfaces = [ "ve-+" ];
								externalInterface = "eth0";
							};
							extraHosts = builtins.concatStringsSep "\n" (builtins.genList (i: 
								let 
									name = builtins.elemAt participantNames i;
									ip = "192.168.100.${toString (11 + i)}";
								in "${ip} ${name}.local"
							) (builtins.length participantNames));
						};

						# Dynamic container generation with improved stability
						containers = builtins.listToAttrs (builtins.genList
							(i:
								let
									name = builtins.elemAt participantNames i;
									ip = "192.168.100.${toString (11 + i)}";
								in
								{
									inherit name;
									value = {
										autoStart = true;
										privateNetwork = true;
										hostAddress = "192.168.100.1";
										localAddress = ip;
										
										# Add restart policy for container itself
										restartIfChanged = true;

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
												nameservers = [ "8.8.8.8" "1.1.1.1" ];
												firewall.enable = false;
											};

											security.sudo.wheelNeedsPassword = false;
											virtualisation.docker.enable = true;

											environment.systemPackages = with pkgs; [
												docker curl git wget jq bash nano tree
											];

											# Improved workshop setup with retry logic
											systemd.services.workshop-setup = {
												wantedBy = [ "multi-user.target" ];
												after = [ "network-online.target" "docker.service" ];
												wants = [ "network-online.target" ];
												
												# Add restart capability for failed setups
												serviceConfig = {
													Type = "oneshot";
													RemainAfterExit = true;
													StandardOutput = "journal";
													StandardError = "journal";
													TimeoutStartSec = "300";
													Restart = "on-failure";
													RestartSec = "30s";
													StartLimitBurst = 3;
													StartLimitIntervalSec = "10min";
												};
												
												script = ''
													set -e
													echo "Setting up ${name} container (attempt started)..."
													
													# Wait for network connectivity with timeout
													network_ready=false
													for i in {1..20}; do
														if ${pkgs.curl}/bin/curl -s --max-time 5 google.com >/dev/null 2>&1; then
															echo "Network ready after $i attempts"
															network_ready=true
															break
														fi
														echo "Waiting for network... ($i/20)"
														sleep 5
													done
													
													if [ "$network_ready" != "true" ]; then
														echo "❌ Network failed after 20 attempts"
														exit 1
													fi
													
													# Initialize Docker Swarm (idempotent)
													if ! ${pkgs.docker}/bin/docker info | grep -q "Swarm: active"; then
														echo "Initializing Docker Swarm..."
														${pkgs.docker}/bin/docker swarm init --advertise-addr ${ip} || {
															echo "Swarm init failed, but continuing..."
														}
													else
														echo "Docker Swarm already active"
													fi
													
													# Install abra (DO NOT change installation method - keep curl approach)
													export HOME=/root
													if [ ! -f /root/.local/bin/abra ]; then
														echo "Installing abra..."
														${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
														echo "Abra installed to /root/.local/bin/abra"
													else
														echo "Abra already installed"
													fi
													
													# Setup PATH in .bashrc (idempotent)
													if ! grep -q "/.local/bin" /root/.bashrc 2>/dev/null; then
														echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
													fi
													
													# Create system symlink for abra (idempotent)
													if [ -f /root/.local/bin/abra ]; then
														ln -sf /root/.local/bin/abra /usr/local/bin/abra 2>/dev/null || true
													fi
													
													# Add abra server config (idempotent)
													if [ -f /root/.local/bin/abra ]; then
														export PATH="/root/.local/bin:$PATH"
														/root/.local/bin/abra server add ${name}.local 2>/dev/null || echo "Server config handled"
													fi
													
													echo "✅ ${name} container setup completed successfully!"
													echo "SSH: ssh root@${ip} (password: root)"
													echo "Workshop user: ssh workshop@${ip} (password: workshop)"
													echo "Abra: Available via 'abra' command"
												'';
											};

											# Add container health monitoring
											systemd.services.workshop-health = {
												wantedBy = [ "multi-user.target" ];
												after = [ "workshop-setup.service" ];
												serviceConfig = {
													Type = "simple";
													Restart = "always";
													RestartSec = "60s";
													ExecStart = "${pkgs.writeScript "health-check" ''
														#!/bin/bash
														while true; do
															# Check if abra is accessible
															if [ -f /root/.local/bin/abra ]; then
																export PATH="/root/.local/bin:$PATH"
																/root/.local/bin/abra --version >/dev/null 2>&1 || {
																	echo "⚠️ Abra health check failed, triggering restart"
																	systemctl restart workshop-setup.service
																}
															fi
															sleep 300  # Check every 5 minutes
														done
													''}";
												};
											};

											environment.sessionVariables = {
												PATH = [ "/root/.local/bin" ];
											};
										};
									};
								}
							)
							(builtins.length participantNames));
					})
				];
			};
		};
}
