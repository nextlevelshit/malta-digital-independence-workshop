# 🚀 DIGITAL INDEPENDENCE DAY Workshop Infrastructure

Single-participant learning environments with local practice and cloud deployment capabilities.

## 🚀 Quick Start

```bash
# 1. Start local VM for development/testing
make vm

# 2. Build USB drives for participants
make build-usb
make flash-usb USB_DEVICE=/dev/sdX

# 3. Deploy cloud infrastructure
export HCLOUD_TOKEN="your_token"
make deploy-cloud
```

## 🎯 Learning Flow

### Local Practice (USB/VM)
```bash
setup                      # REQUIRED: Setup local proxy first!
recipes                    # Show available apps
deploy wordpress           # Deploy locally
browser wordpress          # Open directly in Firefox
```

### Cloud Deployment
```bash
connect hopper             # SSH to cloud server
# Same abra commands work here
abra app new wordpress -S --domain=blog.hopper.codecrispi.es
abra app deploy blog.hopper.codecrispi.es
```

## 🗃️ Architecture

**Single Participant Model**: Each environment (USB/VM) is complete and self-contained.

- **USB Boot**: Bootable NixOS with Docker + abra for hands-on learning
- **Local VM**: Identical environment for development/testing  
- **Cloud Servers**: 15 production servers (hopper, curie, lovelace, etc.)
- **Wildcard DNS**: `*.workshop.local` resolves to `127.0.0.1` via dnsmasq

## 💾 USB Environment

Pre-configured with:
- Docker Swarm + abra installation
- SSH client for cloud access
- Wildcard DNS resolution (dnsmasq)
- Terminal-first interface (`desktop` command for GUI)
- Helper commands: `recipes`, `deploy`, `connect`, `browser`, `help`
- Tab completion for all commands

Build and flash:
```bash
make build-usb
make flash-usb USB_DEVICE=/dev/sdb
```

## 🌐 Cloud Deployment

Creates 15 Hetzner VMs at `{name}.codecrispi.es`:

```bash
export HCLOUD_TOKEN="your_token"
make deploy-cloud
make status-cloud  # Check health
```

## 🖥️ Local Development

```bash
make vm             # Start VM (simulates USB environment)
make build-usb      # Verify build (builds ISO)
```

The VM simulates the USB experience with identical configuration and commands.

## 📚 Complete Recipe Catalog

Based on Co-op Cloud with quality scoring:

### ⭐ Tier 1 - Production Ready (Score 5)
- **gitea** - Self-hosted Git service
- **nextcloud** - Personal cloud storage & collaboration  
- **mealie** - Recipe manager and meal planner

### 🔧 Tier 2 - Stable (Score 4)
- **gotosocial** - Lightweight Fediverse server
- **wordpress** - Website & blog platform

### 🧪 Tier 3 - Community (Score 3)
- **collabora** - Online office suite
- **croc** - File transfer tool
- **custom-php** - Custom PHP applications
- **dokuwiki** - Simple wiki software
- **engelsystem** - Event coordination
- **fab-manager** - FabLab management
- **ghost** - Professional publishing platform
- **karrot** - Grassroots initiatives platform
- **lauti** - Calendar software for events
- **loomio** - Collaborative decision-making
- **mattermost** / **mattermost-lts** - Team collaboration
- **mrbs** - Meeting room booking system
- **onlyoffice** - Document editing suite
- **open-inventory** - Inventory management
- **outline** - Team knowledge base
- **owncast** - Self-hosted live streaming
- **rallly** - Group meeting scheduler

### 🌐 Extended Catalog
- **Content**: hedgedoc, mediawiki, seafile
- **Communication**: jitsi-meet, matrix-synapse, rocketchat  
- **Business**: prestashop, invoiceninja, kimai, pretix
- **Development**: drone, n8n, gitlab, jupyter-lab
- **Analytics**: plausible, matomo, uptime-kuma, grafana
- **Media & Social**: peertube, funkwhale, mastodon, pixelfed, jellyfin

## 📚 Enhanced Commands

**In USB/VM environments**:
- `setup` - **REQUIRED FIRST**: Setup local DNS proxy
- `recipes` - Show complete Co-op Cloud catalog
- `deploy <app>` - Deploy locally with tab completion
- `browser [app]` - Launch Firefox [to specific app]
- `connect <server>` - SSH to cloud server with tab completion
- `desktop` - Start GUI session
- `help` - Show all commands and debug info

**Examples**:
```bash
# Deploy and open WordPress
deploy wordpress
browser wordpress           # Opens http://wordpress.workshop.local in Firefox

# Just open browser
browser                     # Opens Firefox with blank page

# Use tab completion
deploy <TAB>               # Shows all available recipes
connect <TAB>              # Shows all available servers
```

## 🔧 Prerequisites

- Nix with flakes enabled
- SSH key at `~/.ssh/id_ed25519.pub`
- HCLOUD_TOKEN for cloud deployment
- 2GB+ RAM for VM testing

## 🛠️ Development Tools

```bash
# Format Nix files
make format         # Format Nix files

# Start development environment
make opencode       # Start opencode in dev shell
```

## 🧹 Cleanup

```bash
make clean         # Local artifacts
make destroy-cloud # Cloud infrastructure
```

## 🔍 Troubleshooting

```bash
# Check DNS resolution
dig @127.0.0.1 test.workshop.local

# Check running services  
docker service ls

# Check DNS service
systemctl status dnsmasq

# Restart if needed
sudo systemctl restart dnsmasq
```
