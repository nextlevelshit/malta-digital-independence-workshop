{ pkgs, allParticipantNames, ... }: {
  system.stateVersion = "25.05";

  # Conditional ISO image settings
  ${pkgs.lib.mkIf isLiveIso {
    isoImage.makeEfiBootable = true;
    isoImage.makeUsbBootable = true;
  }}

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
    openssh
    curl
    git
    networkmanager
    firefox
    xterm
    docker
    docker-compose
    # For local abra installation
    bash
    wget
    jq
    tree
    nano
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
            echo "  setup-traefik    - Setup local Traefik (required first!)"
            echo "  browser          - Launch Firefox"
            echo "  desktop          - Start GUI session"
            echo ""
            echo "☁️ Cloud Access:"
            echo "  Available servers:"
            ${builtins.concatStringsSep "\n" (map (name: 
              "echo \"    - ${name}.codecrispi.es\""
            ) cloudServerNames)}
            echo "  connect <name>   - SSH to cloud server"
            echo ""
            echo "📚 Commands: setup-traefik | recipes | deploy | connect | browser | desktop | help"

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
              echo "  setup-traefik   - Setup local Traefik proxy (required first!)"
              echo "  recipes         - Show all available app recipes"
              echo "  deploy <recipe> - Deploy app locally (e.g., deploy wordpress)"
              echo "  browser         - Launch Firefox browser"
              echo "  desktop         - Start GUI desktop session"
              echo ""
              echo "☁️ Cloud Access:"
              echo "  connect <name>  - SSH to cloud server (e.g., connect hopper)"
              echo ""
              echo "Available servers: ${builtins.concatStringsSep " " cloudServerNames}"
              echo ""
              echo "📚 Learning Flow:"
              echo "  1. First time: setup-traefik"
              echo "  2. Try local: recipes → deploy wordpress → browser"
              echo "  3. Try cloud: connect hopper → same abra commands"
            }
      
            export -f setup-traefik deploy connect recipes browser desktop help
      		'';
  };

  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager = {
      lightdm.enable = true;
      autoLogin.enable = false; # Manual desktop start
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
}
