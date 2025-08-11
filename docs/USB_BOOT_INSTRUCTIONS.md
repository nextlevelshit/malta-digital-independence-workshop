# 🍪 CODE CRISPIES Workshop
## USB Boot Instructions

### 📋 Quick Reference Card

**Your assigned server:** `__________.codecrispi.es`
**Workshop WiFi:** `CODE_CRISPIES_GUEST` / Password: `workshop2024`

---

## 💻 How to Boot from USB Drive

### Step 1: Insert USB Drive
- Insert the CODE CRISPIES workshop USB drive
- Do NOT remove it until workshop ends

### Step 2: Boot from USB

#### 🖥️ **Desktop PC / Most Laptops**
1. **Restart** your computer
2. **Press and HOLD** one of these keys immediately as it starts:
   - `F12` (most common)
   - `F11` 
   - `F9`
   - `ESC`
3. Select **USB Drive** or **UEFI: USB Drive** from boot menu
4. Press `Enter`

#### 🍎 **Mac (Intel)**
1. **Restart** your Mac
2. **Press and HOLD** `Option` (⌥) key immediately
3. Select the **USB drive** (may show as "EFI Boot")
4. Press `Enter`

#### 🍎 **Mac (Apple Silicon M1/M2)**
1. **Shut down** completely
2. **Press and HOLD** the power button until you see startup options
3. Select the **USB drive** option
4. Click **Continue**

#### 🔧 **If Boot Menu Doesn't Appear**

**Windows PC:**
1. Boot into Windows
2. Hold `Shift` + click **Restart**
3. Choose **Troubleshoot** → **Advanced** → **UEFI Firmware**
4. Find **Boot Order** settings
5. Move **USB Drive** to top of list
6. Save and exit

**Popular Manufacturer Keys:**
- **Dell:** `F12`
- **HP:** `F9` or `ESC` then `F9`
- **Lenovo:** `F12` or `Fn + F12`
- **ASUS:** `F8` or `ESC`
- **Acer:** `F12`
- **MSI:** `F11`
- **Samsung:** `F2` then navigate to Boot tab
- **Toshiba:** `F12`

---

## ✅ What You Should See

1. **NixOS Boot Screen** appears
2. System loads (takes 30-60 seconds)
3. **Desktop environment** starts automatically
4. **Terminal opens** with CODE CRISPIES welcome message
5. You see available servers and commands

---

## 🚀 Getting Started Commands

```bash
# Connect to your assigned server
connect hopper

# See available app recipes  
recipes

# Get help
help
```

---

## 📱 Mobile Hotspot Instructions
**If WiFi isn't working:**

**iPhone:**
Settings → Personal Hotspot → Turn On
Name: iPhone, Password: (ask facilitator)

**Android:**
Settings → Network → Hotspot & Tethering → Mobile Hotspot
Name: Android, Password: (ask facilitator)

---

## 🆘 Troubleshooting

❌ **"No bootable device"**
→ Try different F-key (F11, F9, ESC)
→ USB drive may not be properly inserted

❌ **Mac won't boot USB**  
→ USB drive might need to be reformatted for Mac
→ Ask facilitator for Mac-compatible USB

❌ **Boots to Windows/Mac instead**
→ You didn't press the boot key fast enough
→ Restart and try again immediately

❌ **Terminal doesn't open**
→ Click terminal icon in taskbar
→ Or press `Ctrl + Alt + T`

❌ **Can't connect to internet**
→ Try different WiFi network
→ Use mobile hotspot as backup
```

## flake.nix
```nix
{
  description = "CODE CRISPIES Workshop Live Environment";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
  };

  outputs = { self, nixpkgs, nixos-generators }: 
  let
    system = "x86_64-linux";
    participantNames = [ 
      "hopper" "curie" "lovelace" "noether" "hamilton" 
      "franklin" "johnson" "clarke" "goldberg" "liskov" 
      "wing" "rosen" "shaw" "karp" "rich" 
    ];
  in {
    packages.${system}.live-iso = nixos-generators.nixosGenerate {
      inherit system;
      format = "iso";
      
      modules = [
        ({ pkgs, ... }: {
          # WiFi support
          networking.wireless.enable = true;
          networking.networkmanager.enable = true;
          networking.wireless.networks = {
            "CODE_CRISPIES_GUEST" = {
              psk = "workshop2024";
            };
          };
          
          # Auto-connect to workshop WiFi
          systemd.services.workshop-wifi = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
            '';
          };
          
          # Auto-login workshop user
          services.getty.autologinUser = "workshop";
          users.users.workshop = {
            isNormalUser = true;
            shell = pkgs.zsh;
          };
          
          # Workshop shell environment
          programs.zsh = {
            enable = true;
            interactiveShellInit = ''
              echo "🍪 CODE CRISPIES Workshop Environment"
              echo "📶 WiFi: CODE_CRISPIES_GUEST (auto-connecting...)"
              echo "📡 Available servers:"
              ${builtins.concatStringsSep "\n" (map (name: 
                "echo \"  - ${name}.codecrispi.es\""
              ) participantNames)}
              echo ""
              echo "💡 Commands: connect <name> | recipes | help"
              
              connect() {
                [ -z "$1" ] && { echo "Usage: connect <name>"; return 1; }
                echo "🔗 Connecting to $1.codecrispi.es..."
                ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
              }
              
              recipes() {
                echo "🍪 Featured Co-op Cloud Recipes:"
                echo ""
                echo "📝 Content Management:"
                echo "  wordpress ghost hedgedoc dokuwiki mediawiki"
                echo ""
                echo "☁️  File & Collaboration:" 
                echo "  nextcloud seafile collabora onlyoffice"
                echo ""
                echo "💬 Communication:"
                echo "  jitsi-meet matrix-synapse rocketchat mattermost"
                echo ""
                echo "🛒 E-commerce & Business:"
                echo "  prestashop invoiceninja kimai pretix"
                echo ""
                echo "🔧 Development & Tools:"
                echo "  gitea drone n8n gitlab jupyter-lab"
                echo ""
                echo "📊 Analytics & Monitoring:"
                echo "  plausible matomo uptime-kuma grafana"
                echo ""
                echo "🎵 Media & Social:"
                echo "  peertube funkwhale mastodon pixelfed jellyfin"
                echo ""
                echo "Deploy: abra app new <recipe> -S --domain=myapp.<name>.codecrispi.es"
                echo "Browse all 100+ recipes: https://recipes.coopcloud.tech"
              }
              
              help() {
                echo "🍪 CODE CRISPIES Workshop Commands:"
                echo ""
                echo "connect <name> - SSH to your assigned server"
                echo "recipes        - Show available app recipes"
                echo "abra app new <recipe> -S --domain=<name>.<server>.codecrispi.es"
                echo "abra app deploy <domain>"
                echo "abra app ls    - List your apps"
                echo ""
                echo "Examples:"
                echo "  connect hopper"
                echo "  abra app new wordpress -S --domain=blog.hopper.codecrispi.es"
                echo "  abra app deploy blog.hopper.codecrispi.es"
              }
            '';
          };
          
          environment.systemPackages = with pkgs; [ openssh curl git networkmanager ];
          
          # Auto-start terminal
          services.xserver = {
            enable = true;
            displayManager = {
              autoLogin.enable = true;
              autoLogin.user = "workshop";
              sessionCommands = "${pkgs.xterm}/bin/xterm &";
            };
          };
        })
      ];
    };
    
    # Dev shell for local testing
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
      buildInputs = with nixpkgs.legacyPackages.${system}; [
        terraform
        nixos-rebuild
        docker
        openssh
      ];
    };
  };
}
```

## local/flake.nix
```nix
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
```

## Makefile
```make
# Load .env file if it exists
-include .env
export

.PHONY: help deploy-cloud build-usb flash-usb local-shell local-deploy local-ssh clean status

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := /dev/sdX

help:
	@echo "🍪 CODE CRISPIES Workshop"
	@echo ""
	@echo "Config: WiFi=$(or $(WORKSHOP_WIFI_SSID),CODE_CRISPIES_GUEST), Domain=$(DOMAIN)"
	@echo ""
	@echo "Cloud Infrastructure:"
	@echo "  make deploy-cloud    - Deploy VMs to Hetzner (with health checks)"
	@echo "  make status-cloud    - Check cloud server status"
	@echo "  make destroy-cloud   - Destroy cloud infrastructure"
	@echo ""
	@echo "USB Boot Drive:"
	@echo "  make build-usb       - Build NixOS ISO"
	@echo "  make flash-usb       - Flash ISO to USB (set USB_DEVICE=/dev/sdX)"
	@echo ""
	@echo "Local Development:"
	@echo "  make local-shell     - Enter dev shell"
	@echo "  make local-deploy    - Deploy local NixOS containers"
	@echo "  make local-ssh       - SSH into local participant container"
	@echo "  make local-clean     - Stop local containers"

build-usb:
	@echo "🔨 Building NixOS workshop ISO..."
	@echo "📝 Config: WiFi=$(or $(WORKSHOP_WIFI_SSID),CODE_CRISPIES_GUEST), Domain=$(DOMAIN)"
	nix build .#live-iso
	@echo "✅ ISO built: result/iso/nixos.iso"

flash-usb: build-usb
	@echo "⚠️  Flashing to ${USB_DEVICE} - THIS WILL ERASE THE DEVICE!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=${USB_DEVICE} bs=4M status=progress oflag=sync
	@echo "✅ USB drive ready!"

deploy-cloud:
	@echo "🚀 Deploying to Hetzner Cloud..."
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve \
		-var="hcloud_token=${HCLOUD_TOKEN}" \
		-var="domain=${DOMAIN}" \
		-var="ssh_public_key=$$(cat ~/.ssh/id_rsa.pub)"
	@echo "🔍 Running health checks..."
	./scripts/deploy.sh
	@echo "✅ Cloud deployment complete and verified!"

status-cloud:
	@echo "📊 Checking server status..."
	@for name in hopper curie lovelace noether hamilton franklin johnson clarke goldberg liskov wing rosen shaw karp rich; do \
		echo -n "$$name.${DOMAIN}: "; \
		if curl -s -f https://traefik.$$name.${DOMAIN}/ping >/dev/null 2>&1; then \
			echo "✅ Ready"; \
		else \
			echo "❌ Not ready"; \
		fi; \
	done

destroy-cloud:
	cd terraform && terraform destroy -auto-approve

local-shell:
	nix develop

local-deploy:
	@echo "🏠 Deploying local workshop environment..."
	sudo nixos-rebuild switch --flake ./local#workshop-local
	@echo "✅ Local containers running!"
	@echo "Available: participant1.local through participant15.local"

local-ssh:
	@echo "Available local participants:"
	@echo "  participant1.local (192.168.100.11)"
	@echo "  participant2.local (192.168.100.12)"
	@echo "  ... through participant15.local"
	@read -p "Connect to participant number [1-15]: " num; \
	ssh root@192.168.100.$$((10 + $$num))

local-clean:
	sudo nixos-container stop participant{1..15} || true
	sudo nixos-container destroy participant{1..15} || true

clean:
	rm -rf result .direnv
```

## README.md
```markdown
# 🍪 CODE CRISPIES Workshop Infrastructure

Three deployment environments for Co-op Cloud workshop:

## 🚀 Quick Start

```bash
# 1. Build & flash USB drives
make build-usb
make flash-usb USB_DEVICE=/dev/sdX

# 2. Deploy cloud infrastructure  
export HCLOUD_TOKEN=your_token
make deploy-cloud

# 3. Local development
make local-shell
make local-deploy
make local-ssh
```

## 📁 Project Structure

```
├── flake.nix              # USB boot environment
├── local/flake.nix        # Local NixOS containers
├── terraform/             # Hetzner Cloud infrastructure
├── scripts/deploy.sh      # Cloud setup automation
├── docs/USB_BOOT_INSTRUCTIONS.md
└── Makefile              # Build & deploy commands
```

## 🌍 Three Environments

### 1. Cloud (Production)
- Hetzner VMs: `hopper.codecrispi.es`, `curie.codecrispi.es`, etc.
- Pre-configured with Docker Swarm + abra
- SSL certificates via Let's Encrypt

### 2. USB Boot (Workshop)
- NixOS live environment 
- Auto-connects to workshop WiFi
- Helper functions: `connect hopper`, `recipes`, `help`
- SSH into cloud VMs

### 3. Local (Development)
- NixOS containers: `participant1.local` through `participant15.local`
- Test abra deployments locally
- Isolated Docker Swarm per container

## 🔧 Development Workflow

```bash
# Enter development environment
make local-shell

# Deploy local testing environment
make local-deploy

# SSH into local participant container
make local-ssh  # Select participant 1-15

# Test app deployment inside container
abra app new wordpress -S --domain=test.participant1.local
abra app deploy test.participant1.local
```

## 📦 Workshop Flow

1. **Participant boots USB** → NixOS live environment
2. **Connects to WiFi** → `CODE_CRISPIES_GUEST` 
3. **SSH to cloud VM** → `connect hopper`
4. **Deploy apps** → `abra app new wordpress -S --domain=mysite.hopper.codecrispi.es`
5. **Access via browser** → `https://mysite.hopper.codecrispi.es`

## 🎯 Available Apps

### Featured Recipes
- **WordPress** - Blog/CMS platform
- **Nextcloud** - File sync & collaboration  
- **HedgeDoc** - Collaborative markdown editor
- **Jitsi** - Video conferencing
- **PrestaShop** - E-commerce platform
- **Gitea** - Git repository hosting
- **Matrix Synapse** - Chat server
- **Plausible** - Privacy-friendly analytics
- **PeerTube** - Video platform
- **Mastodon** - Social networking

Browse all 100+ recipes at: https://recipes.coopcloud.tech

## 🧹 Cleanup

```bash
make clean           # Clean local artifacts
make destroy-cloud   # Destroy Hetzner infrastructure
```
