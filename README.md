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

- **WordPress** - CMS/Blog
- **Nextcloud** - File sharing
- **HedgeDoc** - Collaborative markdown
- **Jitsi** - Video conferencing
- **PrestaShop** - E-commerce

## 🧹 Cleanup

```bash
make clean           # Clean local artifacts
make destroy-cloud   # Destroy Hetzner infrastructure
```
