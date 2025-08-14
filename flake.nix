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
      allParticipantNames = [
        "hopper"
        "curie"
        "lovelace"
        "noether"
        "hamilton"
        "franklin"
        "johnson"
        "clarke"
        "goldberg"
        "liskov"
        "wing"
        "rosen"
        "shaw"
        "karp"
        "rich"
      ];
      numLookup = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "10" = 10; "11" = 11; "12" = 12; "13" = 13; "14" = 14; "15" = 15;
      };
      participantsEnv = builtins.getEnv "PARTICIPANTS";
      numParticipants = if builtins.hasAttr participantsEnv numLookup
                        then builtins.getAttr participantsEnv numLookup
                        else 3;
      participantNames = builtins.genList (i: builtins.elemAt allParticipantNames i) numParticipants;
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

              services.getty.autologinUser = "workshop";
              users.users.workshop = {
                isNormalUser = true;
                shell = pkgs.zsh;
                extraGroups = [ "networkmanager" "wheel" ];
                password = "";
              };

              security.sudo.wheelNeedsPassword = false;

              environment.systemPackages = with pkgs; [
                openssh
                curl
                git
                networkmanager
                firefox
                xterm
              ];

              programs.zsh = {
                enable = true;
                interactiveShellInit = ''
                  echo "CODE CRISPIES Workshop Environment"
                  echo "Available servers:"
                  ${builtins.concatStringsSep "\n" (map (name: 
                    "echo \"  - ${name}.codecrispi.es\""
                  ) allParticipantNames)}
                  echo ""
                  echo "Commands: connect <name> | recipes | help"
                  
                  connect() {
                    [ -z "$1" ] && { echo "Usage: connect <name>"; return 1; }
                    echo "Connecting to $1.codecrispi.es..."
                    ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
                  }
                  
                  recipes() {
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
                    echo "Deploy: abra app new <recipe> -S --domain=myapp.<name>.codecrispi.es"
                    echo "Browse all: https://recipes.coopcloud.tech"
                  }
                  
                  help() {
                    echo "CODE CRISPIES Workshop Commands:"
                    echo ""
                    echo "connect <name> - SSH to your assigned server"
                    echo "recipes        - Show available app recipes"
                    echo "sudo nmcli dev wifi connect SSID password PASSWORD"
                    echo ""
                    echo "Examples:"
                    echo "  connect hopper"
                    echo "  sudo nmcli dev wifi connect CODE_CRISPIES_GUEST password workshop2024"
                  }
                  
                  export -f connect recipes help
                '';
              };

              services.xserver = {
                enable = true;
                desktopManager.xfce.enable = true;
                displayManager = {
                  lightdm.enable = true;
                  autoLogin.enable = true;
                  autoLogin.user = "workshop";
                };
              };

              systemd.user.services.workshop-welcome = {
                wantedBy = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];
                script = "${pkgs.xterm}/bin/xterm -title 'CODE CRISPIES Workshop' -e 'zsh' &";
                serviceConfig.Type = "forking";
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
              password = "";
              shell = pkgs.bash;
            };

            security.pam.services.login.allowNullPassword = true;
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
                   echo "Workshop VM Ready!";
                   echo "";
                   echo "SSH into containers:";
                   ${builtins.concatStringsSep "
" (map (name:
                     let ip = "192.168.100.${toString (11 + (builtins.elemAt (builtins.genList (x: x) (builtins.length participantNames))
                       (builtins.elemAt
                         (builtins.filter (i: builtins.elemAt participantNames i == name)
                           (builtins.genList (x: x) (builtins.length participantNames))) 0)))}";
                     in "echo \"  sudo connect ${name}       # Container login to ${name}\""
                   ) participantNames)}
                   echo "  (Total: ${toString numParticipants} containers)";
                   echo "";
                   echo "Container management:";
                   echo "  sudo containers           # List all containers";
                   echo "  sudo logs                 # Show setup logs";
                   echo "  sudo recipes              # Show available recipes";
                   echo "";
                   echo "Abra is pre-installed in containers!";
                   echo "";
                   bash
                 '" &
             '';
            environment.systemPackages = with pkgs; [
              firefox
              curl
              git
              jq
              nano
              tree
              nixos-container
              
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
              '')
              
              (pkgs.writeScriptBin "logs" ''
                #!/bin/bash
                echo "Showing logs for all containers (Ctrl+C to exit)"
                exec journalctl -u container@* -f
              '')
              
              (pkgs.writeScriptBin "recipes" ''
                #!/bin/bash
                echo "Available Co-op Cloud Recipes"
                echo "Content Management:"
                echo "  wordpress ghost hedgedoc dokuwiki mediawiki"
                echo "File & Collaboration:"
                echo "  nextcloud seafile collabora onlyoffice"
                echo "Communication:"
                echo "  jitsi-meet matrix-synapse rocketchat mattermost"
                echo "E-commerce & Business:"
                echo "  prestashop invoiceninja kimai pretix"
                echo "Development & Tools:"
                echo "  gitea drone n8n gitlab jupyter-lab"
                echo "Analytics & Monitoring:"
                echo "  plausible matomo uptime-kuma grafana"
                echo "Media & Social:"
                echo "  peertube funkwhale mastodon pixelfed jellyfin"
                echo "Usage in container:"
                echo "  abra app new <recipe> -S --domain=myapp.<container-name>.local"
                echo "  abra app deploy myapp.<container-name>.local"
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
                echo "Available containers: ${builtins.concatStringsSep " " participantNames}"
              '')    
            ];
            # Add local DNS resolution for .local domains
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

                    config = {
                      system.stateVersion = "25.05";

                      users.users.root.password = "";
                      users.users.workshop = {
                        isNormalUser = true;
                        password = "";
                        extraGroups = [ "wheel" "docker" ];
                      };

                      services.openssh = {
                        enable = true;
                        settings = {
                          PasswordAuthentication = true;
                          PermitRootLogin = "yes";
                          PermitEmptyPasswords = true;
                        };
                      };

                      networking = {
                        hostName = name;
                        nameservers = [ "8.8.8.8" ];
                        firewall.enable = false;
                      };

                      security.sudo.wheelNeedsPassword = false;
                      security.pam.services.login.allowNullPassword = true;
                      virtualisation.docker.enable = true;

                      environment.systemPackages = with pkgs; [
                        docker
                        curl
                        git
                        wget
                        jq
                        bash
                      ];

                      systemd.services.workshop-setup = {
                        wantedBy = [ "multi-user.target" ];
                        after = [ "network-online.target" "docker.service" ];
                        wants = [ "network-online.target" ];
                        script = ''
                          echo "Setting up ${name} container..."
                          
                          for i in {1..10}; do
                            if ${pkgs.curl}/bin/curl -s --max-time 5 google.com >/dev/null 2>&1; then
                              echo "Network ready"
                              break
                            fi
                            echo "Waiting for network... ($i/10)"
                            sleep 2
                          done
                          
                          ${pkgs.docker}/bin/docker swarm init --advertise-addr ${ip} || true
                          
                          export HOME=/root
                          if [ ! -f /root/.local/bin/abra ]; then
                            echo "Installing abra..."
                            ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
                            echo "Abra installed"
                          fi
                          
                          if ! grep -q "/.local/bin" /root/.bashrc 2>/dev/null; then
                            echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
                          fi
                          
                          if [ -f /root/.local/bin/abra ]; then
                            ln -sf /root/.local/bin/abra /usr/local/bin/abra 2>/dev/null || true
                          fi
                          
                          if [ -f /root/.local/bin/abra ]; then
                            export PATH="/root/.local/bin:$PATH"
                            /root/.local/bin/abra server add ${name}.local 2>/dev/null || true
                          fi
                          
                          echo "${name} container ready!"
                          echo "SSH: ssh root@${ip} (no password)"
                          echo "Abra: Available via 'abra' command"
                        '';
                        serviceConfig = {
                          Type = "oneshot";
                          RemainAfterExit = true;
                          StandardOutput = "journal";
                          StandardError = "journal";
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
