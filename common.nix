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
    "gitea"
    "mealie"
    "nextcloud"

    # Tier 2 - Stable (Score 4)
    "gotosocial"
    "wordpress"

    # Tier 3 - Community (Score 3)
    "collabora"
    "croc"
    "custom-php"
    "dokuwiki"
    "engelsystem"
    "fab-manager"
    "ghost"
    "karrot"
    "lauti"
    "loomio"
    "mattermost"
    "mattermost-lts"
    "mrbs"
    "onlyoffice"
    "open-inventory"
    "outline"
    "owncast"
    "rallly"

    # Additional recipes from Co-op Cloud catalog
    "hedgedoc"
    "mediawiki"
    "seafile"
    "jitsi-meet"
    "matrix-synapse"
    "rocketchat"
    "prestashop"
    "invoiceninja"
    "kimai"
    "pretix"
    "drone"
    "n8n"
    "gitlab"
    "jupyter-lab"
    "plausible"
    "matomo"
    "uptime-kuma"
    "grafana"
    "peertube"
    "funkwhale"
    "mastodon"
    "pixelfed"
    "jellyfin"
  ];
in

isoConfig // {
  system.stateVersion = "25.05";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
    ports = [ 22 ];
  };

  networking = {
    wireless.enable = false;
    networkmanager = {
      enable = true;
      dns = "none";
    };
    hostName = if isLiveIso then "workshop-live" else "workshop-vm";
    hosts = {
      "127.0.0.1" = [ "workshop.local" "localhost" ];
    };
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
  users.users.root.password = "root";
  users.users.workshop = {
    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    password = "workshop";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    openssh
    curl
    git
    networkmanager
    firefox
    docker
    docker-compose
    bash
    wget
    jq
    tree
    nano
    dnsutils
    dig # For DNS debugging
  ];

  # Auto-install abra and setup Docker Swarm
  systemd.services.workshop-abra-setup = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "docker.service" "dnsmasq.service" ];
    wants = [ "network-online.target" ];
    script = ''
      export HOME=/home/workshop
      export PATH="/run/current-system/sw/bin:/usr/bin:/bin"
      # Wait for network and services with better testing
      echo "Waiting for services to start..."
      for i in {1..30}; do
        # Test external connectivity
        if /run/current-system/sw/bin/curl -s --max-time 3 google.com >/dev/null 2>&1; then
          echo "✅ External network ready"
          break
        fi
        sleep 2
      done
      # Test DNS resolution specifically
      for i in {1..20}; do
        if /run/current-system/sw/bin/nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ Wildcard DNS ready"
          break
        fi
        echo "🔄 Waiting for DNS... (attempt $i)"
        sleep 2
      done
      # Test Docker
      for i in {1..10}; do
        if /run/current-system/sw/bin/docker info >/dev/null 2>&1; then
          echo "✅ Docker ready"
          break
        fi
        sleep 2
      done
      # Install abra for workshop user
      if [ ! -f /home/workshop/.local/bin/abra ]; then
        echo "🚀 Installing abra for user workshop..."
        /usr/bin/su - workshop -c "mkdir -p /home/workshop/.local/bin"
        # Run installer and log output
        install_log="/tmp/abra-install.log"
        /usr/bin/su - workshop -c "bash -c \"cd /home/workshop && /run/current-system/sw/bin/curl -fsSL https://install.abra.coopcloud.tech | bash\"" &> "$install_log"
        if [ -f /home/workshop/.local/bin/abra ]; then
          echo "✅ abra installed successfully."
        else
          echo "❌ abra installation failed. See logs: cat $install_log"
        fi
      else
        echo "✅ abra already installed."
      fi
      # Initialize Docker Swarm
      echo "🔄 Checking Docker Swarm status..."
      if ! /run/current-system/sw/bin/docker info | grep -q "Swarm: active"; then
        echo "🔥 Initializing Docker Swarm..."
        /run/current-system/sw/bin/docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || true
        if /run/current-system/sw/bin/docker info | grep -q "Swarm: active"; then
          echo "✅ Docker Swarm initialized."
        else
          echo "❌ Docker Swarm initialization failed."
        fi
      else
        echo "✅ Docker Swarm already active."
      fi
      # Ensure workshop user is in docker group
      echo "🔄 Ensuring workshop user is in docker group..."
      /usr/bin/usermod -aG docker workshop
      if id -nG workshop | grep -q "docker"; then
        echo "✅ workshop user is in docker group."
      else
        echo "❌ Failed to add workshop user to docker group."
      fi
      # Create proper abra server configuration
      if [ ! -f /home/workshop/.abra/servers/workshop.local.env ]; then
        /usr/bin/su - workshop -c "mkdir -p /home/workshop/.abra/servers/"
      fi
      # Set up autocomplete
      if command -v abra &> /dev/null; then
        /usr/bin/su - workshop -c "source <(/home/workshop/.local/bin/abra autocomplete bash)"
      fi
      # Test final DNS resolution
      if /run/current-system/sw/bin/nslookup test.workshop.local 127.0.0.1; then
        echo "🎉 All services ready!"
      else
        echo "⚠️ DNS may need manual restart: sudo systemctl restart dnsmasq"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Environment = [
        "PATH=/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
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

           # Ensure we can SSH to workshop.local first (tutorial requirement)
         if ! ssh -o ConnectTimeout=3 -o BatchMode=yes workshop@workshop.local echo "SSH OK" 2>/dev/null; then
           echo "⚠️  SSH to workshop.local not working, but continuing with local setup..."
         fi

           # DNS check
         if ! nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
           echo "❌ DNS not resolving *.workshop.local"
           sudo systemctl restart dnsmasq
           sleep 3
         fi

           # Docker Swarm + proxy network
         if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
           echo "🔥 Initializing Docker Swarm..."
           docker swarm init --advertise-addr 127.0.0.1
         fi

         if ! docker network ls | grep -q "proxy"; then
           echo "📡 Creating proxy overlay network..."
           docker network create -d overlay proxy
         fi

           # Add server (tutorial step)
         if ! abra server ls 2>/dev/null | grep -q "workshop.local"; then
           echo "🏗 Adding workshop.local server..."
           # Try to add as proper domain first, fallback to --local
           abra server add workshop.local 2>/dev/null || abra server add --local
         fi

           # Create Traefik app (tutorial step 1)
         if ! abra app ls 2>/dev/null | grep -q "traefik"; then
           echo "🚀 Creating Traefik app..."
           abra app new traefik --domain=traefik.workshop.local
         fi

           # Configure Traefik (tutorial step 2)
         echo "⚙️ Configuring Traefik..."
         abra app config traefik.workshop.local

           # Deploy Traefik (tutorial step 3)
         echo "📦 Deploying Traefik..."
         abra app deploy traefik.workshop.local

           # Wait and verify
         echo "⏳ Waiting for Traefik..."
         for i in {1..30}; do
           if curl -s http://traefik.workshop.local >/dev/null 2>&1; then
             echo "✅ Traefik ready! Dashboard: http://traefik.workshop.local"
             return 0
           fi
           sleep 2
         done

         echo "⚠️ Traefik may still be starting. Check: abra app logs traefik.workshop.local"
       }

      deploy() {
        if [ -z "$1" ]; then
          echo "Usage: deploy <recipe>"
          echo "Available recipes: $ALL_RECIPES"
          return 1
        fi
        local recipe="$1"
        local domain="$recipe.workshop.local"
        echo "🚀 Deploying $recipe locally..."
        echo "Domain: $domain"
          # Ensure Traefik is running first
        if ! curl -s --max-time 3 http://traefik.workshop.local/ping >/dev/null 2>&1; then
          echo "⚠️ Traefik not responding. Setting up..."
          setup-traefik || return 1
        fi
        echo "📦 Creating app: $recipe"
          # Use correct server name
        abra app new "$recipe" --domain="$domain" --server=default -S 2>/dev/null || \
        abra app new "$recipe" --domain="$domain" --server=default
        echo "🚀 Deploying app: $domain"
        abra app deploy "$domain"
        echo "⏳ Waiting for deployment..."
        for i in {1..60}; do
          if curl -s --max-time 3 http://$domain >/dev/null 2>&1; then
            echo "✅ Deployed! Access at: http://$domain"
            return 0
          fi
          sleep 3
        done

        echo "⚠️ Deployment may still be starting..."
        echo "🔍 Debug: abra app ps $domain"
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

      abra-status() {
        echo "🔍 Checking workshop-abra-setup service status..."
        systemctl status workshop-abra-setup
        echo ""
        if [ -f /tmp/abra-install.log ]; then
          echo "📚 Last abra installation log (/tmp/abra-install.log):"
          cat /tmp/abra-install.log
        else
          echo "ℹ️ No abra installation log found at /tmp/abra-install.log"
        fi
        echo ""
        echo "💡 To check if abra is in your PATH: which abra"
        echo "💡 To check abra version: abra --version"
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
        echo "  abra-status        - Check the status of the abra setup service"
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
