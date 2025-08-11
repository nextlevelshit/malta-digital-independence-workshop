{
  description = "Local Co-op Cloud Testing";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          containers = builtins.listToAttrs (map (i: 
            let participant = builtins.elemAt [
              "hopper" "curie" "lovelace" "noether" "hamilton"
              "franklin" "johnson" "clarke" "goldberg" "liskov" 
              "wing" "rosen" "shaw" "karp" "rich"
            ] (i - 1);
            in {
              name = "participant${toString i}";
              value = {
                autoStart = true;
                privateNetwork = true;
                hostAddress = "192.168.100.1";
                localAddress = "192.168.100.${toString (10 + i)}";
                
                config = { pkgs, ... }: {
                  virtualisation.docker = {
                    enable = true;
                    extraOptions = "--experimental";
                  };
                  
                  environment.systemPackages = with pkgs; [
                    docker git curl wget tar jq
                  ];
                  
                  # Helper script for workshop commands
                  environment.etc."workshop-helpers.sh" = {
                    text = ''
                      #!/bin/bash
                      
                      connect() {
                        case "$1" in
                          hopper|curie|lovelace|noether|hamilton|franklin|johnson|clarke|goldberg|liskov|wing|rosen|shaw|karp|rich)
                            echo "🔗 Connecting to $1.codecrispi.es..."
                            ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
                            ;;
                          *)
                            echo "Available servers:"
                            echo "  hopper curie lovelace noether hamilton franklin johnson"
                            echo "  clarke goldberg liskov wing rosen shaw karp rich"
                            ;;
                        esac
                      }
                      
                      recipes() {
                        echo "🍪 Available Co-op Cloud Recipes:"
                        echo ""
                        echo "📝 Content Management:"
                        echo "  wordpress     - Blog/CMS platform"
                        echo "  ghost         - Publishing platform" 
                        echo "  hedgedoc      - Collaborative markdown editor"
                        echo "  dokuwiki      - Simple textfile based wiki"
                        echo "  mediawiki     - The wiki software that runs Wikipedia"
                        echo ""
                        echo "☁️  File & Collaboration:"
                        echo "  nextcloud     - File sync & collaboration"
                        echo "  seafile       - File hosting platform"
                        echo "  collabora     - Online Office suite"
                        echo "  onlyoffice    - Online office suite"
                        echo ""
                        echo "💬 Communication:"
                        echo "  jitsi-meet    - Video conferencing"
                        echo "  matrix-synapse - Chat server"
                        echo "  rocketchat    - Team communication"
                        echo "  mattermost    - Team collaboration platform"
                        echo ""
                        echo "🛒 E-commerce & Business:"
                        echo "  prestashop    - E-commerce platform"
                        echo "  invoiceninja  - Invoice & billing"
                        echo "  kimai         - Time tracking"
                        echo "  pretix        - Event ticketing"
                        echo ""
                        echo "🔧 Development & Tools:"
                        echo "  gitea         - Git repository hosting"
                        echo "  drone         - CI/CD platform"
                        echo "  n8n           - Workflow automation"
                        echo "  gitlab        - DevOps platform"
                        echo "  jupyter-lab   - Interactive computing"
                        echo ""
                        echo "📊 Analytics & Monitoring:"
                        echo "  plausible     - Privacy-friendly analytics"
                        echo "  matomo        - Web analytics"
                        echo "  uptime-kuma   - Status monitoring"
                        echo "  grafana       - Observability platform"
                        echo ""
                        echo "🎵 Media & Social:"
                        echo "  peertube      - Video platform"
                        echo "  funkwhale     - Music platform"
                        echo "  mastodon      - Social networking"
                        echo "  pixelfed      - Photo sharing"
                        echo "  jellyfin      - Media system"
                        echo ""
                        echo "Usage: abra app new <recipe> -S --domain=myapp.${participant}.local"
                        echo "Browse all 100+ recipes: https://recipes.coopcloud.tech"
                      }
                      
                      help() {
                        echo "🍪 CODE CRISPIES Workshop Commands:"
                        echo ""
                        echo "connect <name> - SSH to cloud server"
                        echo "recipes       - Show available app recipes"
                        echo "abra app new <recipe> -S --domain=<name>.${participant}.local"
                        echo "abra app deploy <domain>"
                        echo "abra app ls   - List your apps"
                        echo ""
                        echo "Examples:"
                        echo "  connect hopper"
                        echo "  abra app new wordpress -S --domain=blog.${participant}.local"
                        echo "  abra app deploy blog.${participant}.local"
                        echo ""
                        echo "Server: ${participant}.local"
                        echo "Your apps will be available at: https://<name>.${participant}.local"
                      }
                      
                      export -f connect recipes help
                    '';
                    mode = "0755";
                  };
                  
                  systemd.services.workshop-setup = {
                    wantedBy = [ "multi-user.target" ];
                    after = [ "docker.service" "network-online.target" ];
                    wants = [ "network-online.target" ];
                    script = ''
                      # Wait for network interface
                      until ip addr show | grep -q "192.168.100.${toString (10 + i)}"; do
                        sleep 1
                      done
                      
                      # Install abra
                      export HOME=/root
                      ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
                      
                      # Docker swarm setup  
                      ${pkgs.docker}/bin/docker swarm init --advertise-addr 192.168.100.${toString (10 + i)} || true
                      ${pkgs.docker}/bin/docker network create -d overlay proxy || true
                      
                      # Abra server setup
                      mkdir -p /root/.abra/servers
                      /root/.local/bin/abra server add ${participant}.local
                      
                      # Setup helper commands in bash profile
                      echo "source /etc/workshop-helpers.sh" >> /root/.bashrc
                    '';
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                    };
                  };
                  
                  services.openssh.enable = true;
                  networking = {
                    firewall.allowedTCPPorts = [ 22 80 443 ];
                    hostName = "${participant}.local";
                  };
                };
              };
            }
          ) (nixpkgs.lib.range 1 15));
          
          # Wildcard DNS for all participant subdomains
          services.dnsmasq = {
            enable = true;
            settings.address = builtins.concatMap (i: 
              let participant = builtins.elemAt [
                "hopper" "curie" "lovelace" "noether" "hamilton"
                "franklin" "johnson" "clarke" "goldberg" "liskov" 
                "wing" "rosen" "shaw" "karp" "rich"
              ] (i - 1);
              in [
                "/${participant}.local/192.168.100.${toString (10 + i)}"
                "/.${participant}.local/192.168.100.${toString (10 + i)}"
              ]
            ) (nixpkgs.lib.range 1 15);
          };
        }
      ];
    };
  };
}
