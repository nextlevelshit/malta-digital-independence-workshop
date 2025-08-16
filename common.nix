{ pkgs, lib ? pkgs.lib, cloudServerNames, isLiveIso ? false, ... }: 

let
  # Only include isoImage config when building ISO
  isoConfig = lib.optionalAttrs isLiveIso {
    isoImage = {
      makeEfiBootable = true;
      makeUsbBootable = true;
    };
  };
  
  # Complete Co-op Cloud recipe list (based on your ABRA_RECIPES.md and more)
  allRecipes = [
    # Tier 1 - Production Ready (Score 5)
    "gitea" "mealie" "nextcloud"
    
    # Tier 2 - Stable (Score 4)
    "gotosocial" "wordpress"
    
    # Tier 3 - Community (Score 3)
    "collabora" "croc" "custom-php" "dokuwiki" "engelsystem" "fab-manager"
    "ghost" "karrot" "lauti" "loomio" "mattermost" "mattermost-lts" "mrbs"
    "onlyoffice" "open-inventory" "outline" "owncast" "rallly"
    
    # Additional recipes from Co-op Cloud catalog
    "hedgedoc" "mediawiki" "seafile" "jitsi-meet" "matrix-synapse" 
    "rocketchat" "prestashop" "invoiceninja" "kimai" "pretix"
    "drone" "n8n" "gitlab" "jupyter-lab" "plausible" "matomo"
    "uptime-kuma" "grafana" "peertube" "funkwhale" "mastodon"
    "pixelfed" "jellyfin"
  ];
in

isoConfig // {
  system.stateVersion = "25.05";

  networking = {
    wireless.enable = false;  # Disable to avoid conflicts
    networkmanager = {
      enable = true;
      dns = "none";  # Critical: Don't let NetworkManager manage DNS
    };
    hostName = if isLiveIso then "workshop-live" else "workshop-vm";
  };

  # Configure dnsmasq properly for wildcard DNS
  services.dnsmasq = {
    enable = true;
    settings = {
      # Wildcard: *.workshop.local -> 127.0.0.1
      address = "/.workshop.local/127.0.0.1";
      
      # Use upstream DNS for everything else
      server = [ "8.8.8.8" "1.1.1.1" ];
      
      # Listen on all interfaces (important for VM/container access)
      listen-address = [ "127.0.0.1" ];
      
      # Bind to interfaces
      bind-interfaces = true;
      
      # Don't read /etc/hosts for our custom domains
      no-hosts = false;
      
      # Cache settings
      cache-size = 1000;
      log-queries = true;
      log-dhcp = true;
      
      # Local domain handling
      local = "/workshop.local/";
      domain-needed = true;
      bogus-priv = true;
    };
  };

  # Force system to use our dnsmasq
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];

  # Disable systemd-resolved to avoid conflicts
  services.resolved.enable = false;

  # Enable Docker for local development
  virtualisation.docker.enable = true;

  services.getty.autologinUser = "workshop";
  users.users.workshop = {
    isNormalUser = true;
    shell = pkgs.bash;
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
    bash
    wget
    jq
    tree
    nano
    dnsutils
    dig  # For DNS debugging
  ];

  # Auto-install abra and setup Docker Swarm
  systemd.services.workshop-abra-setup = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "docker.service" "dnsmasq.service" ];
    wants = [ "network-online.target" ];
    script = ''
      export HOME=/home/workshop
      
      # Wait for network and services with better testing
      echo "Waiting for services to start..."
      for i in {1..30}; do
        # Test external connectivity
        if ${pkgs.curl}/bin/curl -s --max-time 3 google.com >/dev/null 2>&1; then
          echo "✅ External network ready"
          break
        fi
        sleep 2
      done
      
      # Test DNS resolution specifically
      for i in {1..20}; do
        if ${pkgs.dnsutils}/bin/nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ Wildcard DNS ready"
          break
        fi
        echo "🔄 Waiting for DNS... (attempt $i)"
        sleep 2
      done
      
      # Test Docker
      for i in {1..10}; do
        if ${pkgs.docker}/bin/docker info >/dev/null 2>&1; then
          echo "✅ Docker ready"
          break
        fi
        sleep 2
      done
      
      # Install abra for workshop user
      if [ ! -f /home/workshop/.local/bin/abra ]; then
        sudo -u workshop mkdir -p /home/workshop/.local/bin
        cd /home/workshop
        sudo -u workshop ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | sudo -u workshop ${pkgs.bash}/bin/bash
      fi
      
      # Initialize Docker Swarm
      if ! ${pkgs.docker}/bin/docker info | grep -q "Swarm: active"; then
        ${pkgs.docker}/bin/docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || true
      fi
      
      # Ensure workshop user is in docker group
      usermod -aG docker workshop
      
      # Test final DNS resolution
      if ${pkgs.dnsutils}/bin/nslookup test.workshop.local 127.0.0.1; then
        echo "🎉 All services ready!"
      else
        echo "⚠️  DNS may need manual restart: sudo systemctl restart dnsmasq"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };

  # Enhanced bash configuration with complete recipe support
  programs.bash = {
    interactiveShellInit = ''
      # Workshop welcome and command definitions
      echo "🚀 CODE CRISPIES Workshop Environment"
      echo "Mode: Local Development + Cloud Access"
      echo ""
      
      # Test DNS immediately on login
      if command -v nslookup &> /dev/null; then
        if nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ DNS wildcard ready: *.workshop.local → 127.0.0.1"
        else
          echo "❌ DNS not working! Run: sudo systemctl restart dnsmasq"
          echo "🔧 Debug: nslookup test.workshop.local 127.0.0.1"
        fi
      fi

      # Ensure abra is in PATH
      export PATH="$HOME/.local/bin:$PATH"

      # Complete recipe list for bash completion
      ALL_RECIPES="${builtins.concatStringsSep " " allRecipes}"

      # Enable tab completion for deploy and browser commands
      _workshop_completion() {
        local cur prev opts
        COMPREPLY=()
        cur="''${COMP_WORDS[COMP_CWORD]}"
        prev="''${COMP_WORDS[COMP_CWORD-1]}"
        
        case "''${prev}" in
          deploy|browser)
            opts="$ALL_RECIPES"
            COMPREPLY=( $(compgen -W "''${opts}" -- ''${cur}) )
            return 0
            ;;
          connect)
            opts="${builtins.concatStringsSep " " cloudServerNames}"
            COMPREPLY=( $(compgen -W "''${opts}" -- ''${cur}) )
            return 0
            ;;
        esac
      }
      complete -F _workshop_completion deploy browser connect

      setup-traefik() {
        echo "🔧 Setting up local Traefik proxy..."
        
        # Test DNS first
        if ! nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "❌ DNS not resolving *.workshop.local"
          echo "🔄 Restarting dnsmasq..."
          sudo systemctl restart dnsmasq
          sleep 3
          
          if ! nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
            echo "❌ DNS still not working!"
            echo "🔍 Debug info:"
            echo "  systemctl status dnsmasq"
            echo "  nslookup traefik.workshop.local 127.0.0.1"
            return 1
          fi
        fi
        
        echo "✅ DNS resolution working"
        
        # Rest of your existing setup-traefik function...
        if ! command -v abra &> /dev/null; then
          echo "❌ Abra not found. Installing..."
          sudo systemctl restart workshop-abra-setup
          sleep 5
          export PATH="$HOME/.local/bin:$PATH"
        fi
        # Ensure Docker Swarm is ready
        if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
          echo "🔥 Initializing Docker Swarm..."
          docker swarm init --advertise-addr 127.0.0.1 || true
        fi
        # Create abra context if not exists
        if ! abra server ls 2>/dev/null | grep -q "workshop-local"; then
          echo "🏗 Creating local abra context..."
          abra server add --local
        fi
				#echo "🚀 Deploying Traefik..."
				#abra app new traefik -S --domain=traefik.workshop.local --server=workshop-local
				#abra app deploy traefik.workshop.local
        
        # Wait for Traefik to be ready
        echo "⏳ Waiting for Traefik to start..."
        for i in {1..30}; do
          if curl -s http://traefik.workshop.local >/dev/null 2>&1; then
            echo "✅ Traefik deployed! Dashboard: http://traefik.workshop.local"
            echo "🚀 Now you can deploy apps with 'deploy <recipe>'"
            return 0
          fi
          sleep 2
        done
        
        echo "⚠️  Traefik deployed but may still be starting..."
        echo "🔍 Debug: docker service ls | curl -I http://traefik.workshop.local"
      }

      deploy() {
        if [ -z "$1" ]; then
          echo "Usage: deploy <recipe>"
          echo "Example: deploy wordpress"
          echo "Available recipes: $ALL_RECIPES"
          echo ""
          echo "🔍 Use tab completion or run 'recipes' for categorized list"
          return 1
        fi
  
        local recipe="$1"
        local domain="$recipe.workshop.local"
  
        echo "🚀 Deploying $recipe locally..."
        echo "Domain: $domain"
  
        if ! command -v abra &> /dev/null; then
          echo "❌ Abra not found. Run 'sudo systemctl restart workshop-abra-setup'"
          return 1
        fi

        # Check if Traefik is running
        if ! curl -s http://traefik.workshop.local >/dev/null 2>&1; then
          echo "⚠️  Traefik not detected. Running setup first..."
          setup-traefik
        fi
  
        echo "📦 Creating app: $recipe"
        abra app new "$recipe" -S --domain="$domain" --server=workshop-local
        
        echo "🚀 Deploying app: $domain"
        abra app deploy "$domain"
  
        echo "⏳ Waiting for deployment..."
        for i in {1..60}; do
          if curl -s http://$domain >/dev/null 2>&1; then
            echo "✅ Deployed! Access at: http://$domain"
            echo "🌐 Quick launch: browser $recipe"
            return 0
          fi
          sleep 3
        done
        
        echo "⚠️  Deployment completed but app may still be starting..."
        echo "🔍 Debug: docker service ls | dig @127.0.0.1 $domain +short"
        echo "🌐 Try: browser $recipe (in a few moments)"
      }

      connect() {
        [ -z "$1" ] && { echo "Usage: connect <name>"; echo "Available: ${builtins.concatStringsSep " " cloudServerNames}"; return 1; }
        echo "🔌 Connecting to $1.codecrispi.es..."
        ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
      }

      browser() {
        local target_url="about:blank"
        
        if [ -n "$1" ]; then
          # Specific app requested
          target_url="http://$1.workshop.local"
          echo "🌐 Opening $1 at $target_url"
        else
          echo "🌐 Opening Firefox browser"
        fi
        
        if [ -n "$DISPLAY" ]; then
          firefox "$target_url" &
        else
          echo "❌ No GUI session. Run 'desktop' first"
          echo "🌐 Target was: $target_url"
        fi
      }

      recipes() {
        echo "📚 Complete Co-op Cloud Recipe Catalog:"
        echo ""
        echo "⭐ Tier 1 - Production Ready (Score 5):"
        echo "  gitea mealie nextcloud"
        echo ""
        echo "🔧 Tier 2 - Stable (Score 4):" 
        echo "  gotosocial wordpress"
        echo ""
        echo "🧪 Tier 3 - Community (Score 3):"
        echo "  collabora croc custom-php dokuwiki engelsystem"
        echo "  fab-manager ghost karrot lauti loomio mattermost"
        echo "  mattermost-lts mrbs onlyoffice open-inventory outline"
        echo "  owncast rallly"
        echo ""
        echo "🌐 Extended Catalog:"
        echo "  Content: hedgedoc mediawiki seafile"
        echo "  Chat: jitsi-meet matrix-synapse rocketchat"
        echo "  Business: prestashop invoiceninja kimai pretix"
        echo "  Dev Tools: drone n8n gitlab jupyter-lab"
        echo "  Analytics: plausible matomo uptime-kuma grafana"
        echo "  Media: peertube funkwhale mastodon pixelfed jellyfin"
        echo ""
        echo "🚀 Usage:"
        echo "  deploy <recipe>     - Deploy locally"
        echo "  browser <recipe>    - Open app in browser"
        echo "  📖 Full catalog: https://recipes.coopcloud.tech"
        echo ""
        echo "💡 Use tab completion: type 'deploy <TAB>' or 'browser <TAB>'"
      }

      desktop() {
        echo "🖥️ Starting GUI session..."
        if command -v startx &> /dev/null; then
          if [ -z "$DISPLAY" ]; then
            startx &
            export DISPLAY=:0
            sleep 3
            echo "✅ GUI started. Check QEMU window or run 'browser'"
          else
            echo "ℹ️  GUI already running"
          fi
        else
          echo "💡 GUI available in QEMU window (Alt+Tab to switch)"
          echo "🖱️  Click on QEMU graphics window to use desktop"
        fi
      }

      help() {
        echo "🚀 CODE CRISPIES Workshop Commands:"
        echo ""
        echo "🏠 Local Development:"
        echo "  setup-traefik      - Setup local Traefik proxy (REQUIRED FIRST!)"
        echo "  recipes            - Show all available app recipes"
        echo "  deploy <recipe>    - Deploy app locally (e.g., deploy wordpress)"
        echo "  browser [recipe]   - Launch Firefox [to specific app]"
        echo "  desktop            - Start GUI desktop session"
        echo ""
        echo "☁️ Cloud Access:"
        echo "  connect <name>     - SSH to cloud server (e.g., connect hopper)"
        echo ""
        echo "Available servers: ${builtins.concatStringsSep " " cloudServerNames}"
        echo ""
        echo "📚 Learning Flow:"
        echo "  1. First time: setup-traefik"
        echo "  2. Try local: recipes → deploy wordpress → browser wordpress"
        echo "  3. Try cloud: connect hopper → same abra commands"
        echo ""
        echo "🔍 Debug Commands:"
        echo "  docker service ls                    - Check running services"
        echo "  dig @127.0.0.1 app.workshop.local   - Test DNS resolution"
        echo "  systemctl status dnsmasq             - Check DNS service"
        echo ""
        echo "💡 Tab completion available for deploy, browser, connect commands"
      }


    '';
  };

  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
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
