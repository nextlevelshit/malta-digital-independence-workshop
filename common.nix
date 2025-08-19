{ pkgs, lib ? pkgs.lib, cloudServerNames, isLiveIso ? false, ... }:

let
  # Only include isoImage config when building ISO
  isoConfig = lib.optionalAttrs isLiveIso {
    isoImage = {
      makeEfiBootable = true;
      makeUsbBootable = true;
    };
  };

  # Complete Co-op Cloud recipe list
  allRecipes = [
    # Tier 1 - Production Ready (Score 5)
    "gitea"
    "mealie"
    "nextcloud"

    # Tier 2 - Stable (Score 4)
    "gotosocial"
    "wordpress"

    # Tier 3 - Community (Score 3)
    "adapt_authoring"
    "agora"
    "alerta"
    "amusewiki"
    "authentik"
    "babybuddy"
    "backup-bot"
    "backup-bot-two"
    "base-row"
    "baserow"
    "bonfire"
    "botamusique"
    "caddy"
    "cal"
    "calibre-web"
    "capsul"
    "civicrm-backdrop"
    "civicrm-wordpress"
    "collabora"
    "compy"
    "container"
    "croc"
    "cryptpad"
    "custom-html"
    "custom-html-tiny"
    "custom-php"
    "dashy"
    "discourse"
    "distribution"
    "docker-hub-rss"
    "dokuwiki"
    "drone"
    "drone-docker-runner"
    "drutopia"
    "element-web"
    "engelsystem"
    "etherpad"
    "fab-manager"
    "farmos"
    "federatedwiki"
    "filerun"
    "filestash"
    "firefly-iii"
    "firefly-iii-importer"
    "fluffychat"
    "focalboard"
    "foodsoft"
    "forgejo-runner"
    "funkwhale"
    "gancio"
    "garage"
    "ghost"
    "gitlab"
    "go-neb"
    "go-ssb-room"
    "grafana"
    "grist"
    "h5ai"
    "hedgedoc"
    "hometown"
    "hugo"
    "icecast"
    "immich"
    "indentificator"
    "invidious"
    "invoiceninja"
    "jellyfin"
    "jellyseerr"
    "jitsi"
    "jupyter-lab"
    "kanboard"
    "karrot"
    "keycloak"
    "keycloak-collective-portal"
    "keyoxide"
    "kimai"
    "kutt"
    "laplace"
    "lasuite-docs"
    "lauti"
    "lemmy"
    "levelfly"
    "liberaforms"
    "limesurvey"
    "listmonk"
    "loomio"
    "mailman3"
    "mailu"
    "mastodon"
    "matomo"
    "mattermost"
    "mattermost-lts"
    "maubot"
    "mediawiki"
    "minecraft"
    "minetest"
    "miniflux"
    "minio"
    "mobilizon"
    "monica"
    "monitoring"
    "monitoring-lite"
    "monitoring-ng"
    "mrbs"
    "mumble"
    "mycorrhiza"
    "n8n"
    "navidrome"
    "netdata"
    "nitter"
    "nocodb"
    "notea"
    "ntfy"
    "oasis"
    "ohmyform"
    "onlyoffice"
    "open-dispatch"
    "open-inventory"
    "osticket"
    "outline"
    "owncast"
    "parasol-static-site"
    "peertube"
    "pelican"
    "penpot"
    "photoprism"
    "phpservermon"
    "pixelfed"
    "plausible"
    "portainer"
    "postfix-relay"
    "pretix"
    "privatebin"
    "projectsend"
    "prowlarr"
    "qbit"
    "radarr"
    "radicale"
    "rallly"
    "rauthy"
    "redmine"
    "renovate"
    "restic-rest-server"
    "rocketchat"
    "rsshub"
    "rstudio"
    "rustdesk-server"
    "screensy"
    "seafile"
    "selfoss"
    "sextant"
    "shlink"
    "singlelink"
    "snikket"
    "snowflake"
    "sonarr"
    "statping"
    "statuspal"
    "strapi"
    "stream-share"
    "swarm-cronjob"
    "swarmpit"
    "synapse-admin"
    "traefik"
    "traefik-cert-dumper"
    "traefik-forward-auth"
    "uptime-kuma"
    "vaultwarden"
    "vikunja"
    "voila"
    "vroom"
    "wallabag"
    "weblate"
    "wekan"
    "woodpecker"
    "wordpress-bedrock"
    "workadventure"
    "writefreely"
    "xwiki"
    "zammad"
    "znc"
    "zulip"
  ];

in
isoConfig // {
  system.stateVersion = "25.05";

  # SSH Configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
    ports = [ 22 ];
  };

  # Network Configuration  
  networking = {
    wireless.enable = false;
    networkmanager = {
      enable = true;
      dns = "none"; # We use dnsmasq
    };
    hostName = if isLiveIso then "workshop-live" else "workshop-vm";
    hosts."127.0.0.1" = [ "workshop.local" "localhost" ];
    nameservers = lib.mkForce [ "127.0.0.1" ];
    firewall.enable = false; # Workshop environment
  };

  # DNS Configuration - Wildcard *.workshop.local -> 127.0.0.1
  services.dnsmasq = {
    enable = true;
    settings = {
      address = "/.workshop.local/127.0.0.1";
      server = [ "8.8.8.8" "1.1.1.1" ];
      listen-address = [ "127.0.0.1" ];
      bind-interfaces = true;
      cache-size = 1000;
      local = "/workshop.local/";
      domain-needed = true;
      bogus-priv = true;
    };
  };

  # Disable systemd-resolved (conflicts with dnsmasq)
  services.resolved.enable = false;

  # Container Runtime
  virtualisation.docker.enable = true;

  # User Configuration
  users = {
    users.root.password = "root";
    users.workshop = {
      isNormalUser = true;
      shell = pkgs.bash;
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      password = "workshop";
    };
  };

  services.getty.autologinUser = "workshop";
  security.sudo.wheelNeedsPassword = false;

  # System Packages
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
    dig
  ];

  # Workshop Setup Service - REFACTORED
  systemd.services.workshop-abra-setup = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "docker.service" "dnsmasq.service" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ bash curl dnsutils docker gnugrep shadow coreutils wget ];
    script = ''
      # Wait for network and services
      echo "Waiting for services to start..."
      for i in {1..30}; do
        if curl -s --max-time 3 google.com >/dev/null 2>&1; then
          echo "✅ External network ready"
          break
        fi
        sleep 2
      done

      # Test DNS resolution
      for i in {1..20}; do
        if nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ Wildcard DNS ready"
          break
        fi
        echo "🔄 Waiting for DNS... (attempt $i)"
        sleep 2
      done

      # Test Docker
      for i in {1..10}; do
        if docker info >/dev/null 2>&1; then
          echo "✅ Docker ready"
          break
        fi
        sleep 2
      done

      # Install abra for workshop user - as root, to /usr/local/bin
      if [ ! -f /usr/local/bin/abra ]; then
        echo "🚀 Installing abra for root user..."
        
        # Download and install abra directly to /usr/local/bin
        curl -fsSL https://install.abra.coopcloud.tech | bash
        
        if [ -f /usr/local/bin/abra ] && [ -x /usr/local/bin/abra ]; then
          echo "✅ abra installed successfully to /usr/local/bin/abra"
        else
          echo "❌ abra installation failed."
          echo "🔍 Debug: Contents of /usr/local/bin:"
          ls -la /usr/local/bin/abra 2>/dev/null || echo "File not found"
        fi
      else
        echo "✅ abra already installed at /usr/local/bin/abra"
      fi

      # Initialize Docker Swarm
      echo "🔄 Checking Docker Swarm status..."
      if ! docker info | grep -q "Swarm: active"; then
        echo "🔥 Initializing Docker Swarm..."
        docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || true
        if docker info | grep -q "Swarm: active"; then
          echo "✅ Docker Swarm initialized."
        else
          echo "❌ Docker Swarm initialization failed."
        fi
      else
        echo "✅ Docker Swarm already active."
      fi

      # Ensure workshop user is in docker group (we are root, can use usermod directly)
      echo "🔄 Ensuring workshop user is in docker group..."
      usermod -aG docker workshop
      if id -nG workshop | grep -q "docker"; then
        echo "✅ workshop user is in docker group."
      else
        echo "❌ Failed to add workshop user to docker group."
      fi

      # Set up autocomplete (skip this for now since we can't run as user easily)
      # The bash init script will handle abra autocomplete on login

      # Test final DNS resolution
      if nslookup test.workshop.local 127.0.0.1; then
        echo "🎉 All services ready!"
      else
        echo "⚠️ DNS may need manual restart: systemctl restart dnsmasq"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };

  # Enhanced Bash Configuration with All Features
  programs.bash.interactiveShellInit =
    let
      recipeList = builtins.concatStringsSep " " allRecipes;
      serverList = builtins.concatStringsSep " " cloudServerNames;
    in
    ''
      # Workshop Environment Welcome
      echo "🚀 CODE CRISPIES Workshop Environment"
      echo "Mode: Local Development + Cloud Access"
      echo ""
    
      # DNS Health Check
      if command -v nslookup >/dev/null 2>&1; then
        if nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ DNS wildcard ready: *.workshop.local → 127.0.0.1"
        else
          echo "⚠️ DNS not working! Run: sudo systemctl restart dnsmasq"
        fi
      fi
    
      # Ensure abra is in PATH
      export PATH="$HOME/.local/bin:$PATH"
    
      # Bash Completion Configuration
      _workshop_completion() {
        local cur prev
        COMPREPLY=()
        cur="''${COMP_WORDS[COMP_CWORD]}"
        prev="''${COMP_WORDS[COMP_CWORD-1]}"
      
        case "$prev" in
          deploy|browser)
            COMPREPLY=($(compgen -W "${recipeList}" -- "$cur"))
            return 0
            ;;
          connect)
            COMPREPLY=($(compgen -W "${serverList}" -- "$cur"))
            return 0
            ;;
        esac
      }
      complete -F _workshop_completion deploy browser connect
    
      # Core Workshop Functions
      setup-traefik() {
        echo "🔧 Setting up local Traefik proxy..."
      
        # Test SSH capability (tutorial requirement)
        if ! timeout 3 ssh -o BatchMode=yes workshop@workshop.local echo "SSH OK" 2>/dev/null; then
          echo "⚠️ SSH to workshop.local not working, continuing with local setup..."
        fi
      
        # Verify DNS
        if ! nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "🔄 Restarting DNS..."
          sudo systemctl restart dnsmasq
          sleep 3
        fi
      
        # Ensure Docker Swarm + proxy network
        if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
          echo "🔥 Initializing Docker Swarm..."
          docker swarm init --advertise-addr 127.0.0.1
        fi
      
        if ! docker network ls | grep -q "proxy"; then
          echo "🌐 Creating proxy network..."
          docker network create -d overlay proxy
        fi
      
        # Add server
        if ! abra server ls 2>/dev/null | grep -q "workshop.local"; then
          echo "🏗️ Adding workshop.local server..."
          abra server add workshop.local 2>/dev/null || abra server add --local
        fi
      
        # Create, configure, and deploy Traefik
        if ! abra app ls 2>/dev/null | grep -q "traefik"; then
          echo "🚀 Creating Traefik app..."
          abra app new traefik --domain=traefik.workshop.local
        
          echo "⚙️ Configuring Traefik..."  
          abra app config traefik.workshop.local
        
          echo "📦 Deploying Traefik..."
          abra app deploy traefik.workshop.local
        
          echo "⏳ Waiting for Traefik..."
          for i in {1..30}; do
            if curl -s http://traefik.workshop.local >/dev/null 2>&1; then
              echo "✅ Traefik ready! Dashboard: http://traefik.workshop.local"
              return 0
            fi
            sleep 2
          done
        
          echo "⚠️ Traefik may still be starting. Check: abra app logs traefik.workshop.local"
        else
          echo "✅ Traefik already exists"
        fi
      }
    
      deploy() {
        if [[ -z "$1" ]]; then
          echo "Usage: deploy <recipe>"
          echo "Available: ${recipeList}"
          return 1
        fi
      
        local recipe="$1"
        local domain="$recipe.workshop.local"
      
        echo "🚀 Deploying $recipe locally..."
        echo "Domain: $domain"
      
        # Ensure Traefik is running
        if ! curl -s --max-time 3 http://traefik.workshop.local/ping >/dev/null 2>&1; then
          echo "⚠️ Traefik not responding. Setting up..."
          setup-traefik || return 1
        fi
      
        # Create and deploy app
        echo "📦 Creating app: $recipe"
        abra app new "$recipe" --domain="$domain" --server=default 2>/dev/null || \
        abra app new "$recipe" --domain="$domain"
      
        echo "🚀 Deploying: $domain"
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
        if [[ -z "$1" ]]; then
          echo "Usage: connect <name>"
          echo "Available: ${serverList}"
          return 1
        fi
        echo "🔌 Connecting to $1.codecrispi.es..."
        ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
      }
    
      browser() {
        local target_url="about:blank"
      
        if [[ -n "$1" ]]; then
          target_url="http://$1.workshop.local"
          echo "🌐 Opening $1 at $target_url"
        else
          echo "🌐 Opening Firefox browser"  
        fi
      
        if [[ -n "$DISPLAY" ]]; then
          firefox "$target_url" &
        else
          echo "❌ No GUI session. Run 'desktop' first"
          echo "🌐 Target was: $target_url"
        fi
      }
    
      recipes() {
        echo "📚 Complete Co-op Cloud Recipe Catalog:"
        echo ""
        echo "⭐ Tier 1 - Production Ready: gitea mealie nextcloud"
        echo "🔧 Tier 2 - Stable: gotosocial wordpress" 
        echo "🧪 Tier 3 - Community: collabora croc dokuwiki ghost loomio..."
        echo "🌐 Extended: matrix-synapse rocketchat gitlab n8n mastodon..."
        echo ""
        echo "🚀 Usage:"
        echo "  deploy <recipe>     - Deploy locally"
        echo "  browser <recipe>    - Open in browser" 
        echo "  📖 Full catalog: https://recipes.coopcloud.tech"
        echo ""
        echo "💡 Tab completion: deploy <TAB> or browser <TAB>"
      }
    
      desktop() {
        echo "🖥️ Starting GUI session..."
        if command -v startx >/dev/null 2>&1; then
          if [[ -z "$DISPLAY" ]]; then
            startx &
            export DISPLAY=:0
            sleep 3
            echo "✅ GUI started"
          else
            echo "ℹ️ GUI already running"
          fi
        else
          echo "💡 GUI available in QEMU window"
        fi
      }
    
      abra-status() {
        systemctl status workshop-abra-setup
      }

      abra-logs() {
        journalctl -u workshop-abra-setup -f
      }

    
      help() {
        echo "🚀 CODE CRISPIES Workshop Commands:"
        echo ""
        echo "🏠 Local Development:"
        echo "  setup-traefik      - Setup local proxy (REQUIRED FIRST!)"
        echo "  recipes            - Show all available apps"
        echo "  deploy <recipe>    - Deploy app locally"
        echo "  browser [recipe]   - Launch Firefox [to app]"
        echo "  desktop            - Start GUI session"
        echo ""
        echo "☁️ Cloud Access:"
        echo "  connect <name>     - SSH to cloud server"
        echo "  Available: ${serverList}"
        echo ""
        echo "🔍 Debug:"
        echo "  abra-status        - Check setup service"
        echo "  docker service ls  - List running services"
        echo "  systemctl status dnsmasq - Check DNS"
        echo ""
        echo "📚 Learning Flow:"
        echo "  1. setup-traefik"
        echo "  2. deploy wordpress"  
        echo "  3. browser wordpress"
        echo "  4. connect hopper"
      }
    '';

  # GUI Configuration
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };
}
