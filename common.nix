{
  pkgs,
  lib ? pkgs.lib,
  cloudServerNames,
  isLiveIso ? false,
  ...
}:

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
isoConfig
// {
  system.stateVersion = "25.05";

  # Timezone Configuration
  time.timeZone = "Europe/Berlin";

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
    networkmanager = {
      enable = true;
      #wifi.enable = true;
      dns = "none"; # We use dnsmasq
      ensureProfiles = {
        environmentFiles = [ "/etc/NetworkManager/workshop-wifi.env" ];
        profiles = {
          "workshop-hotspot" = {
            connection = {
              id = "workshop-hotspot";
              type = "wifi";
              autoconnect = true;
              autoconnect-priority = 10;
            };
            wifi = {
              ssid = "$WORKSHOP_SSID";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WORKSHOP_PSK";
            };
          };
        };
      };
    };
    hostName = if isLiveIso then "workshop-live" else "workshop-vm";
    hosts."127.0.0.1" = [
      "workshop.local"
      "localhost"
    ];
    nameservers = lib.mkForce [ "127.0.0.1" ];
    firewall.enable = false; # Workshop environment
  };

  # WiFi credentials file
  environment.etc."NetworkManager/workshop-wifi.env" = {
    text = ''
      WORKSHOP_SSID="ziegel"
      WORKSHOP_PSK="1234567890"
    '';
    mode = "0600";
  };

  # DNS Configuration - Wildcard *.workshop.local -> 127.0.0.1
  services.dnsmasq = {
    enable = true;
    settings = {
      address = "/.workshop.local/127.0.0.1";
      server = [
        "8.8.8.8"
        "1.1.1.1"
      ];
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
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
      ];
      password = "workshop";
    };
  };

  # SSH key generation for workshop user
  systemd.services.workshop-ssh-keygen = {
    description = "Generate SSH key for workshop user for passwordless localhost access";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = with pkgs; [
      openssh
      coreutils
      gnugrep
    ];
    script = ''
      USER_HOME=/home/workshop
      SSH_DIR=$USER_HOME/.ssh
      KEY_FILE=$SSH_DIR/id_ed25519
      AUTH_KEYS_FILE=$SSH_DIR/authorized_keys
      mkdir -p $SSH_DIR
      chown workshop:workshop $SSH_DIR
      chmod 700 $SSH_DIR
      if [ ! -f "$KEY_FILE" ]; then
        echo "Generating SSH key for workshop user..."
        ssh-keygen -t ed25519 -f $KEY_FILE -N "" -C "workshop@workshop-vm"
        chown workshop:workshop $KEY_FILE $KEY_FILE.pub
        chmod 600 $KEY_FILE
        chmod 644 $KEY_FILE.pub
      fi
      PUB_KEY=$(cat $KEY_FILE.pub)
      if ! grep -qF -- "$PUB_KEY" "$AUTH_KEYS_FILE" 2>/dev/null; then
        echo "Adding public key to authorized_keys..."
        echo "$PUB_KEY" >> $AUTH_KEYS_FILE
      fi

      chown workshop:workshop $AUTH_KEYS_FILE
      chmod 600 $AUTH_KEYS_FILE
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = true;
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
    docker
    docker-compose
    gnome-terminal
    bash
    wget
    jq
    tree
    nano
    dnsutils
    dig
    gnutar
    openssl # Add this for certificate generation
    # Additional font packages for QEMU
    chromium # Add Chromium browser
    firefox
    dejavu_fonts
    liberation_ttf
    fontconfig
  ];

  # System Setup Service (Root Tasks)
  systemd.services.workshop-system-setup = {
    description = "System-level checks for network, DNS, and Docker";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "docker.service"
      "dnsmasq.service"
    ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      bash
      curl
      dnsutils
      docker
      gnugrep
      shadow
      coreutils
    ];
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
      # Ensure workshop user is in docker group
      echo "🔄 Ensuring workshop user is in docker group..."
      usermod -aG docker workshop
      if id -nG workshop | grep -q "docker"; then
        echo "✅ workshop user is in docker group."
      else
        echo "❌ Failed to add workshop user to docker group."
      fi
      # Final DNS resolution test
      if nslookup test.workshop.local 127.0.0.1; then
        echo "🎉 System services ready!"
      else
        echo "⚠️ DNS may need manual restart: systemctl restart dnsmasq"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Environment = [
        "TERM=xterm-256color"
        "HOME=/root"
      ];
    };
  };

  # Abra Installation Service (System-wide)
  systemd.services.workshop-abra-install = {
    description = "Install abra CLI system-wide";
    wantedBy = [ "multi-user.target" ];
    after = [ "workshop-system-setup.service" ];
    wants = [ "workshop-system-setup.service" ];
    path = with pkgs; [
      bash
      wget
      curl
      coreutils
      gnutar
      ncurses
      gzip
      file
      gnugrep
      docker
    ];

    script = ''
      # Set proper environment
      export TERM=xterm-256color
      export HOME=/root

      # Check if abra is already installed
      if [ -x "/root/.local/bin/abra" ]; then
        echo "✅ abra already installed"
        /root/.local/bin/abra --version
        exit 0
      fi

      echo "🚀 Installing abra system-wide..."

      # Install to /usr/local/bin (default behavior)
      curl -fsSL https://install.abra.coopcloud.tech | bash

      # Add to bashrc only once
      if ! grep -q "/root/.local/bin" /root/.bashrc 2>/dev/null; then
        echo 'export PATH="$PATH:/root/.local/bin"' >> /root/.bashrc
        echo "✅ Added /root/.local/bin to PATH in /root/.bashrc"
      fi

      # Verify
      if [ -x "/root/.local/bin/abra" ]; then
        echo "✅ abra installed to /root/.local/bin/abra"
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Environment = [
        "TERM=xterm-256color"
        "HOME=/root"
      ];
    };
  };

  # Set Firefox as default browser
  systemd.services.workshop-set-default-browser = {
    description = "Set Firefox as the default browser for workshop user";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = with pkgs; [
      xdg-utils
      coreutils
      su
    ];
    script = ''
      # Set Firefox as default browser for workshop user
      su - workshop -c "xdg-settings set default-web-browser firefox.desktop"
      # Also set MIME types for HTML files
      su - workshop -c "xdg-mime default firefox.desktop text/html"
      su - workshop -c "xdg-mime default firefox.desktop x-scheme-handler/http"
      su - workshop -c "xdg-mime default firefox.desktop x-scheme-handler/https"
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
    echo "Mode: Local Development (Offline Co-op Cloud)"
    echo ""
  
    # DNS Health Check
    if command -v nslookup >/dev/null 2>&1; then
      if nslookup test.workshop.local 127.0.0.1 >/dev/null 2>&1; then
        echo "✅ DNS wildcard ready: *.workshop.local → 127.0.0.1"
      else
        echo "⚠️ DNS not working! Run: sudo systemctl restart dnsmasq"
      fi
    fi

    # Ensure /root/.local/bin is in PATH (safety net)
    if [[ ":$PATH:" != *":/root/.local/bin:"* ]]; then
      echo "✅ adding abra to PATH"
      export PATH="$PATH:/root/.local/bin"
    fi

    # Check abra installation  
    if sudo abra >/dev/null 2>&1; then
      echo "✅ abra ready: $(sudo which abra)"
      source <(sudo abra autocomplete bash) 2>/dev/null || true
      echo "✅ abra autocomplete enabled"
    else
      echo "⚠️ abra not found! Check: systemctl status workshop-abra-install"
    fi

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
    complete -F _workshop_completion deploy browser connect abra

    # Core Workshop Functions
     setup() {
       echo "🔧 Setting up LOCAL Co-op Cloud environment..."

       # Run permission checks first
       setup_permissions || return 1

       # Run setup steps individually
       setup_dns || return 1
       setup_docker || return 1
       setup_abra_server || return 1
       setup_certificates || return 1
       setup_traefik || return 1

       echo "🎉 Setup complete!"
     }

     setup_permissions() {
       echo "🔐 Checking system permissions and prerequisites..."

       # Check if running as workshop user
       if [[ "$(whoami)" != "workshop" ]]; then
         echo "⚠️ Not running as workshop user (current: $(whoami))"
         echo "   This may cause permission issues. Consider running as workshop user."
       else
         echo "✅ Running as workshop user"
       fi

       # Check sudo access
       if sudo -n true 2>/dev/null; then
         echo "✅ Sudo access available (no password required)"
       else
         echo "⚠️ Sudo may require password - this could interrupt automated setup"
       fi

       # Check Docker group membership
       if id -nG | grep -q "docker"; then
         echo "✅ User is in docker group"
       else
         echo "⚠️ User not in docker group - Docker commands may fail"
         echo "   Current groups: $(id -nG)"
       fi

       # Check if abra is available via sudo
       if sudo abra --version >/dev/null 2>&1; then
         echo "✅ abra available via sudo: $(sudo which abra)"
       else
         echo "❌ abra not available via sudo"
         echo "   Check: systemctl status workshop-abra-install"
         return 1
       fi

       # Check abra server configuration
       if sudo abra server ls 2>/dev/null | grep -q "default"; then
         echo "✅ Abra default server configured"
       else
         echo "⚠️ Abra default server not configured - will be set up"
       fi

       # Check /tmp permissions
       if [[ -w "/tmp" ]]; then
         echo "✅ /tmp directory is writable"
       else
         echo "❌ /tmp directory is not writable"
         ls -ld /tmp
         return 1
       fi

       # Check openssl availability
       if command -v openssl >/dev/null 2>&1; then
         echo "✅ OpenSSL available: $(openssl version | head -1)"
       else
         echo "❌ OpenSSL not found - certificate generation will fail"
         return 1
       fi

       # Check curl availability
       if command -v curl >/dev/null 2>&1; then
         echo "✅ curl available for health checks"
       else
         echo "⚠️ curl not found - health checks may not work properly"
       fi

       echo "🎯 Permission checks complete!"
     }

    setup_dns() {
      echo "🌐 Step 1: Verifying DNS configuration..."

      if ! nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
        echo "🔄 DNS not working, restarting dnsmasq..."
        sudo systemctl restart dnsmasq
        sleep 3

        # Test again
        if nslookup traefik.workshop.local 127.0.0.1 >/dev/null 2>&1; then
          echo "✅ DNS restarted successfully"
        else
          echo "❌ DNS restart failed"
          return 1
        fi
      else
        echo "✅ DNS working correctly"
      fi
    }

    setup_docker() {
      echo "🐳 Step 2: Setting up Docker Swarm and networks..."

      # Check Docker status
      if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "🔥 Initializing Docker Swarm..."
        if docker swarm init --advertise-addr 127.0.0.1; then
          echo "✅ Docker Swarm initialized"
        else
          echo "❌ Docker Swarm initialization failed"
          return 1
        fi
      else
        echo "✅ Docker Swarm already active"
      fi

      # Check proxy network
      if ! docker network ls | grep -q "proxy"; then
        echo "🌐 Creating proxy network..."
        if docker network create -d overlay proxy; then
          echo "✅ Proxy network created"
        else
          echo "❌ Proxy network creation failed"
          return 1
        fi
      else
        echo "✅ Proxy network exists"
      fi
    }

    setup_abra_server() {
      echo "🗄️ Step 3: Setting up Abra server..."

      if ! sudo abra server ls 2>/dev/null | grep -q "default"; then
        echo "🗄️ Adding LOCAL server to abra..."
        if sudo abra server add --local; then
          echo "✅ Local server registered"
        else
          echo "❌ Failed to add local server"
          return 1
        fi
      else
        echo "✅ Abra server already configured"
      fi
    }

     setup_certificates() {
       echo "🔐 Step 4: Generating self-signed certificates..."

       setup_certificates_dir || return 1
       setup_certificates_generate || return 1
       setup_certificates_verify || return 1

       # Export CERT_DIR for use in setup_traefik
       export CERT_DIR
     }

     setup_certificates_dir() {
       echo "📁 Creating certificate directory..."

       CERT_DIR="/tmp/workshop-certs"
       echo "   Target directory: $CERT_DIR"

       # Check if directory already exists and clean it up
       if [[ -d "$CERT_DIR" ]]; then
         echo "   🧹 Cleaning up existing certificate directory..."
         rm -rf "$CERT_DIR" || {
           echo "❌ Failed to remove existing directory"
           return 1
         }
       fi

       # Create fresh directory
       if mkdir -p "$CERT_DIR"; then
         echo "✅ Certificate directory created"
       else
         echo "❌ Failed to create certificate directory"
         echo "   Current user: $(whoami)"
         echo "   User ID: $(id)"
         echo "   /tmp permissions: $(ls -ld /tmp)"
         return 1
       fi

       # Verify directory permissions
       echo "🔍 Verifying directory permissions..."
       ls -la /tmp/ | grep workshop-certs || {
         echo "❌ Directory not found in /tmp listing"
         return 1
       }

       local dir_perms=$(stat -c "%a" "$CERT_DIR" 2>/dev/null || echo "unknown")
       echo "   Directory permissions: $dir_perms"
       echo "   Directory owner: $(stat -c "%U:%G" "$CERT_DIR" 2>/dev/null || echo "unknown")"
     }

     setup_certificates_generate() {
       echo "🔑 Generating self-signed certificate..."

       CERT_FILE="$CERT_DIR/workshop.crt"
       KEY_FILE="$CERT_DIR/workshop.key"

       echo "   Certificate file: $CERT_FILE"
       echo "   Key file: $KEY_FILE"

       # Check if openssl is available
       if ! command -v openssl >/dev/null 2>&1; then
         echo "❌ OpenSSL not found in PATH"
         which openssl || echo "   openssl command not found"
         return 1
       fi

       echo "   OpenSSL version: $(openssl version)"

       # Check if certificate already exists
       if [[ -f "$CERT_FILE" ]]; then
         echo "   ⚠️ Certificate file already exists, removing..."
         rm -f "$CERT_FILE" "$KEY_FILE" || {
           echo "❌ Failed to remove existing certificate files"
           return 1
         }
       fi

        # Generate certificate following abra guidelines
        echo "   Generating RSA key and certificate (abra-compatible)..."
        if openssl req -x509 -out "$CERT_FILE" -keyout "$KEY_FILE" \
          -newkey rsa:2048 -nodes -sha256 -days 365 \
          -subj "/CN=*.workshop.local" -extensions EXT -config <( \
           printf "[dn]\nCN=*.workshop.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:*.workshop.local,DNS:workshop.local,DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth"); then

          echo "✅ Certificate generation completed successfully (abra-compatible)"
        else
          echo "❌ Certificate generation failed"
          echo "   OpenSSL exit code: $?"
          return 1
        fi
     }

     setup_certificates_verify() {
       echo "🔍 Verifying certificate files..."

       CERT_FILE="$CERT_DIR/workshop.crt"
       KEY_FILE="$CERT_DIR/workshop.key"

       # Check if files exist
       if [[ ! -f "$CERT_FILE" ]]; then
         echo "❌ Certificate file not found: $CERT_FILE"
         ls -la "$CERT_DIR" || echo "   Directory listing failed"
         return 1
       fi

       if [[ ! -f "$KEY_FILE" ]]; then
         echo "❌ Key file not found: $KEY_FILE"
         ls -la "$CERT_DIR" || echo "   Directory listing failed"
         return 1
       fi

       echo "✅ Certificate files created successfully"

       # Show file details
       echo "   Certificate file details:"
       ls -la "$CERT_FILE"
       echo "   Key file details:"
       ls -la "$KEY_FILE"

        # Verify certificate content
        echo "   Verifying certificate content..."
        if openssl x509 -in "$CERT_FILE" -text -noout >/dev/null 2>&1; then
          echo "✅ Certificate is valid X.509 format"

          # Show certificate details
          echo "   Certificate subject:"
          openssl x509 -in "$CERT_FILE" -subject -noout 2>/dev/null || echo "   Could not read certificate subject"

          echo "   Certificate issuer:"
          openssl x509 -in "$CERT_FILE" -issuer -noout 2>/dev/null || echo "   Could not read certificate issuer"

          echo "   Certificate validity:"
          openssl x509 -in "$CERT_FILE" -dates -noout 2>/dev/null || echo "   Could not read certificate dates"

          echo "   Certificate extensions:"
          openssl x509 -in "$CERT_FILE" -text -noout 2>/dev/null | grep -A 5 "Subject Alternative Name" || echo "   No SAN extension found"

        else
          echo "❌ Certificate file is not valid"
          return 1
        fi

        # Verify key content
        if openssl rsa -in "$KEY_FILE" -check -noout >/dev/null 2>&1; then
          echo "✅ Private key is valid"
        else
          echo "❌ Private key is invalid"
          return 1
        fi

        # Verify certificate matches key
        if openssl x509 -in "$CERT_FILE" -noout -modulus 2>/dev/null | openssl md5 >/dev/null 2>&1 && \
           openssl rsa -in "$KEY_FILE" -noout -modulus 2>/dev/null | openssl md5 >/dev/null 2>&1; then
          echo "✅ Certificate and key match"
        else
          echo "⚠️ Could not verify certificate/key match (non-critical)"
        fi

       echo "🎉 Certificate generation and verification complete!"
     }

     setup_traefik() {
       echo "🚀 Step 5: Setting up Traefik..."

       setup_traefik_app || return 1
       setup_traefik_config || return 1
       setup_traefik_secrets || return 1
       setup_traefik_deploy || return 1
       setup_traefik_wait || return 1
     }

     setup_traefik_app() {
       echo "📦 Checking Traefik app..."

       if ! sudo abra app ls 2>/dev/null | grep -q "traefik"; then
         echo "🚀 Creating Traefik app for OFFLINE use..."
         echo "   Command: sudo abra app new traefik --domain=traefik.workshop.local --server=default"

         if sudo abra app new traefik --domain=traefik.workshop.local --server=default; then
           echo "✅ Traefik app created successfully"
         else
           echo "❌ Failed to create Traefik app"
           echo "   abra exit code: $?"
           sudo abra app ls 2>&1 || echo "   Could not list apps"
           return 1
         fi
       else
         echo "✅ Traefik app already exists"
       fi
     }

     setup_traefik_config() {
       echo "⚙️ Configuring Traefik for offline mode..."

       TRAEFIK_ENV="/root/.abra/servers/default/traefik.workshop.local.env"
       echo "   Config file: $TRAEFIK_ENV"

       # Check if config file exists
       if [[ -f "$TRAEFIK_ENV" ]]; then
         echo "   ⚠️ Config file already exists, backing up..."
         cp "$TRAEFIK_ENV" "$TRAEFIK_ENV.backup" || echo "   Backup failed, continuing..."
       fi

       # Create offline-friendly traefik configuration
       echo "   Writing offline configuration..."
       if sudo tee -a "$TRAEFIK_ENV" >/dev/null <<EOF

# OFFLINE/LOCAL DEVELOPMENT CONFIGURATION
LETS_ENCRYPT_ENV=staging
WILDCARDS_ENABLED=1
SECRET_WILDCARD_CERT_VERSION=v1
SECRET_WILDCARD_KEY_VERSION=v1
COMPOSE_FILE="\$COMPOSE_FILE:compose.wildcard.yml"

# Disable Let's Encrypt for local development
TRAEFIK_ACME_CASERVER=
TRAEFIK_ACME_EMAIL=
EOF
       then
         echo "✅ Traefik configuration written successfully"
         echo "   Config file contents:"
         sudo cat "$TRAEFIK_ENV" | head -20
       else
         echo "❌ Failed to write Traefik configuration"
         echo "   Target file: $TRAEFIK_ENV"
         ls -la "$(dirname "$TRAEFIK_ENV")" 2>/dev/null || echo "   Parent directory not accessible"
         return 1
       fi
     }

     setup_traefik_secrets() {
       echo "📋 Installing self-signed certificates as Docker secrets..."

       # Verify certificate files exist
       if [[ ! -f "$CERT_DIR/workshop.crt" ]]; then
         echo "❌ Certificate file not found: $CERT_DIR/workshop.crt"
         ls -la "$CERT_DIR" 2>/dev/null || echo "   Certificate directory not accessible"
         return 1
       fi

       if [[ ! -f "$CERT_DIR/workshop.key" ]]; then
         echo "❌ Key file not found: $CERT_DIR/workshop.key"
         ls -la "$CERT_DIR" 2>/dev/null || echo "   Certificate directory not accessible"
         return 1
       fi

       echo "   Certificate files verified:"
       ls -la "$CERT_DIR/workshop.crt" "$CERT_DIR/workshop.key"

       # Insert SSL certificate secret
       echo "   🔐 Inserting SSL certificate secret..."
       echo "   Command: sudo abra app secret insert traefik.workshop.local ssl_cert v1"

       if sudo abra app secret insert traefik.workshop.local ssl_cert v1 -f "$CERT_DIR/workshop.crt"; then
         echo "✅ SSL certificate secret inserted successfully"
       else
         echo "❌ Failed to insert SSL certificate secret"
         echo "   abra exit code: $?"
         echo "   Checking abra app status..."
         sudo abra app ls 2>&1 || echo "   Could not list apps"
         echo "   Checking certificate file..."
         file "$CERT_DIR/workshop.crt" 2>/dev/null || echo "   Could not check certificate file type"
         return 1
       fi

       # Insert SSL key secret
       echo "   🔑 Inserting SSL key secret..."
       echo "   Command: sudo abra app secret insert traefik.workshop.local ssl_key v1"

       if sudo abra app secret insert traefik.workshop.local ssl_key v1 -f "$CERT_DIR/workshop.key"; then
         echo "✅ SSL key secret inserted successfully"
       else
         echo "❌ Failed to insert SSL key secret"
         echo "   abra exit code: $?"
         echo "   Checking abra app status..."
         sudo abra app ls 2>&1 || echo "   Could not list apps"
         echo "   Checking key file..."
         file "$CERT_DIR/workshop.key" 2>/dev/null || echo "   Could not check key file type"
         return 1
       fi

       echo "🎉 All secrets inserted successfully!"
     }

     setup_traefik_deploy() {
       echo "🚀 Deploying Traefik..."

       echo "   Command: sudo abra app deploy traefik.workshop.local"

       if sudo abra app deploy traefik.workshop.local; then
         echo "✅ Traefik deployment initiated successfully"
       else
         echo "❌ Traefik deployment failed"
         echo "   abra exit code: $?"
         echo "   Checking deployment status..."
         sudo abra app ps traefik.workshop.local 2>&1 || echo "   Could not check app status"
         return 1
       fi
     }

     setup_traefik_wait() {
       echo "⏳ Waiting for Traefik to be ready..."

       for i in {1..30}; do
         echo "   Checking Traefik status (attempt $i/30)..."

         # Try HTTPS first
         if curl -s -k --max-time 5 https://traefik.workshop.local/ping >/dev/null 2>&1; then
           echo "✅ Traefik ready via HTTPS!"
           echo "   Dashboard: https://traefik.workshop.local (accept self-signed cert)"
           echo "   💡 For HTTP: http://traefik.workshop.local"
           break
         fi

         # Try HTTP as fallback
         if curl -s --max-time 5 http://traefik.workshop.local/ping >/dev/null 2>&1; then
           echo "✅ Traefik ready via HTTP!"
           echo "   Dashboard: http://traefik.workshop.local"
           echo "   💡 For HTTPS: https://traefik.workshop.local (may require accepting cert)"
           break
         fi

         if [[ $i -eq 30 ]]; then
           echo "❌ Traefik failed to respond after 30 attempts"
           echo "   🔍 Debug commands:"
           echo "     sudo abra app logs traefik.workshop.local"
           echo "     sudo abra app ps traefik.workshop.local"
           echo "     docker service ls | grep traefik"
           return 1
         fi

         sleep 2
       done

       # Cleanup temporary certs
       echo "🧹 Cleaning up temporary certificate files..."
       if rm -rf "$CERT_DIR" 2>/dev/null; then
         echo "✅ Certificate cleanup completed"
       else
         echo "⚠️ Certificate cleanup failed (non-critical)"
       fi

       echo "🎉 Traefik setup complete!"
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
      if ! curl -s -k --max-time 3 https://traefik.workshop.local/ping >/dev/null 2>&1 && \
         ! curl -s --max-time 3 http://traefik.workshop.local/ping >/dev/null 2>&1; then
        echo "⚠️ Traefik not responding. Setting up..."
        setup || return 1
      fi
    
      # Create and deploy app
      echo "📦 Creating app: $recipe"
      sudo abra app new "$recipe" --domain="$domain" --server=default
    
      echo "🚀 Deploying: $domain"
      sudo abra app deploy "$domain"
    
      echo "⏳ Waiting for deployment..."
      for i in {1..60}; do
        if curl -s -k --max-time 3 https://$domain >/dev/null 2>&1 || \
           curl -s --max-time 3 http://$domain >/dev/null 2>&1; then
          echo "✅ Deployed! Access at: https://$domain (accept self-signed cert)"
          echo "💡 Or HTTP: http://$domain"
          return 0
        fi
        sleep 3
      done
    
      echo "⚠️ Deployment may still be starting..."
      echo "🔍 Debug: sudo abra app ps $domain"
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
          echo "🌐 Opening $1 at $target_url in Firefox"
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
      echo "  browser  [recipe] - Open in browser"
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
  
    help() {
      echo "🚀 CODE CRISPIES Workshop Commands:"
      echo ""
      echo "🏠 Local Development:"
      echo "  setup              - Setup local proxy (REQUIRED FIRST!)"
      echo "  recipes            - Show all available apps"
      echo "  deploy <recipe>    - Deploy app locally"
      echo "  browser [recipe] - Launch browser [to app]"
      echo "  desktop            - Start GUI session"
      echo "  sudo abra          - Run abra CLI directly as root"
      echo ""
      echo "☁️ Cloud Access:"
      echo "  connect <name>     - SSH to cloud server"
      echo "  Available: ${serverList}"
      echo ""
      echo "🔍 Debug:"
      echo "  docker service ls  - List running services"
      echo "  systemctl status dnsmasq - Check DNS"
      echo "  systemctl status workshop-abra-install - Check abra installation"
      echo ""
      echo "📚 Learning Flow:"
      echo "  1. setup"
      echo "  2. deploy wordpress"  
      echo "  3. browser wordpress"
      echo "  4. connect hopper"
    }
    '';

  programs.firefox = {
    enable = true;
    preferences = {
      "browser.fixup.fallback-to-https" = false;
      "browser.urlbar.autoFill" = false;
      # Disable telemetry and data collection
      "datareporting.healthreport.uploadEnabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.newProfilePing.enabled" = false;
      "toolkit.telemetry.shutdownPingSender.enabled" = false;
      "toolkit.telemetry.updatePing.enabled" = false;
      "toolkit.telemetry.bhrPing.enabled" = false;
      "toolkit.telemetry.firstShutdownPing.enabled" = false;
      "toolkit.telemetry.coverage.opt-out" = true;
      "toolkit.coverage.opt-out" = true;
      "toolkit.coverage.endpoint.base" = "";
      # Disable Mozilla experiments
      "experiments.supported" = false;
      "experiments.enabled" = false;
      "experiments.manifest.uri" = "";
      # Disable crash reporting
      "breakpad.reportURL" = "";
      "browser.tabs.crashReporting.sendReport" = false;
      "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
      # Disable default browser check
      "browser.shell.checkDefaultBrowser" = false;
      # Disable welcome tour and onboarding
      "browser.aboutwelcome.enabled" = false;
      "browser.onboarding.enabled" = false;
      "browser.onboarding.tour-type" = "new";
      "browser.onboarding.seen-tourset-version" = "999";
      "browser.onboarding.hidden" = true;
      # Disable pocket
      "extensions.pocket.enabled" = false;
      # Disable Firefox accounts
      "identity.fxaccounts.enabled" = false;
      # Disable sponsored content
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      # Disable search suggestions
      "browser.search.suggest.enabled" = false;
      "browser.urlbar.suggest.searches" = false;
      # Disable geolocation
      "geo.enabled" = false;
      # Disable webRTC
      "media.peerconnection.enabled" = false;
    };
  };

  # Font packages for GUI rendering (QEMU GTK display)
  fonts.packages = with pkgs; [
    dejavu_fonts # DejaVu fonts including Sans Mono
    liberation_ttf
    noto-fonts
    cantarell-fonts # GNOME default font
    ubuntu-classic # Additional font for compatibility
    freefont_ttf # Additional fonts
    fontconfig # Enhanced font configuration for QEMU
  ];

  # GUI Configuration
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };

  # Exclude unnecessary GNOME packages
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    gnome-music
    gnome-maps
    cheese
    epiphany
    geary
    evince
    totem
    simple-scan
    yelp
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-terminal
  ];

  # Auto-start console and set GNOME settings
  environment.etc."xdg/autostart/gnome-console.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Workshop Console
    Exec=sh -c "gsettings set org.gnome.shell favorite-apps \"['org.gnome.TextEditor.desktop', 'org.gnome.Console.desktop', 'firefox.desktop']\" && gsettings set org.gnome.shell welcome-dialog-last-shown-version \"999999\" && gnome-console --maximize --hide-menubar --title=\"Workshop Console\""
    NoDisplay=false
  '';

  # Auto-login configuration (renamed in newer NixOS)
  services.displayManager.autoLogin = {
    enable = true;
    user = "workshop";
  };

  # Configure GNOME favorite apps and disable welcome dialog
  services.xserver.desktopManager.gnome = {
    extraGSettingsOverrides = ''
      [org.gnome.shell]
      favorite-apps=['org.gnome.TextEditor.desktop', 'org.gnome.Console.desktop', 'firefox.desktop']
      welcome-dialog-last-shown-version='999999'
    '';
  };
}
