# 🪐 CODE CRISPIES Workshop Infrastructure

Single-participant learning environments with local practice and cloud deployment capabilities.

## 🚀 Quick Start

```bash
# 1. Start local VM for development/testing
make local-vm

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
recipes                    # Show available apps
deploy wordpress           # Deploy locally  
browser                    # View at wordpress.workshop.local
```

### Cloud Deployment
```bash
connect hopper             # SSH to cloud server
# Same abra commands work here
abra app new wordpress -S --domain=blog.hopper.codecrispi.es
abra app deploy blog.hopper.codecrispi.es
```

## 🏗️ Architecture

**Single Participant Model**: Each environment (USB/VM) is complete and self-contained.

- **USB Boot**: Bootable NixOS with Docker + abra for hands-on learning
- **Local VM**: Identical environment for development/testing  
- **Cloud Servers**: 15 production servers (hopper, curie, lovelace, etc.)

## 💾 USB Environment

Pre-configured with:
- Docker Swarm + abra installation
- SSH client for cloud access
- Terminal-first interface (`desktop` command for GUI)
- Helper commands: `recipes`, `deploy`, `connect`, `help`

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
make local-vm      # Start VM
make test-vm       # Verify build
```

The VM simulates the USB experience with identical configuration and commands.

## 📚 Available Commands

**In USB/VM environments**:
- `recipes` - Show Co-op Cloud catalog
- `deploy <app>` - Deploy locally (e.g., `deploy wordpress`)
- `apps` - List deployed applications  
- `connect <server>` - SSH to cloud server
- `cloud-deploy <app> <server>` - Direct cloud deployment
- `desktop` - Start GUI session
- `browser` - Launch Firefox

## 🔧 Prerequisites

- Nix with flakes enabled
- SSH key at `~/.ssh/id_ed25519.pub`
- HCLOUD_TOKEN for cloud deployment
- 2GB+ RAM for VM testing

## 🧹 Cleanup

```bash
make clean         # Local artifacts
make destroy-cloud # Cloud infrastructure
```
