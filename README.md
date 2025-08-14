# 🍪 CODE CRISPIES Workshop Infrastructure

This repository contains the infrastructure for the Co-op Cloud workshop, providing three distinct deployment environments with dynamic scaling support.

---
## 🚀 Quick Start

```bash
# 1. Start the local development virtual machine (default: 3 containers)
make local-vm-run

# 2. Test with different container counts
PARTICIPANTS=2 make local-vm-test    # Lightweight testing
PARTICIPANTS=15 make local-vm-full   # Full workshop simulation

# 3. Build & flash USB drives for participants
make build-usb
make flash-usb USB_DEVICE=/dev/sdX

# 4. Deploy the production cloud infrastructure
export HCLOUD_TOKEN="your_token_here"
make deploy-cloud
```

---

## 📁 Project Structure

```
├── flake.nix              # All Nix configurations (USB, VM, containers)
├── terraform/             # Hetzner Cloud infrastructure
├── scripts/deploy.sh      # Cloud setup automation
├── docs/USB_BOOT_INSTRUCTIONS.md
└── Makefile              # Build & deploy commands
```

---

## 🌍 Three Environments

### 1. Cloud (Production)

- **What:** 15 Hetzner VMs named `hopper.codecrispi.es`, `curie.codecrispi.es`, etc.
- **Purpose:** The live environment for workshop participants.
- **Participants:** hopper, curie, lovelace, noether, hamilton, franklin, johnson, clarke, goldberg, liskov, wing, rosen, shaw, karp, rich

### 2. USB Boot (Workshop)

- **What:** A bootable NixOS live environment with SSH client tools.
- **Purpose:** Used by participants to connect to their cloud servers.
- **Features:** Pre-configured with helper functions like `connect hopper`, `recipes` command, and workshop-specific tooling.

### 3. Local (Development)

- **What:** A self-contained Virtual Machine (VM) that runs on your local computer with configurable container count.
- **Purpose:** Complete local testing environment that mirrors production setup without needing cloud servers.
- **Scalability:** Supports 1-15 containers via `PARTICIPANTS` environment variable.

---

## 🔧 Local Development Workflow

1. **Choose Your Scale**
   ```bash
   # Lightweight development (2 containers)
   PARTICIPANTS=2 make local-vm-run

   # Production simulation (15 containers) - requires 8GB+ RAM
   PARTICIPANTS=15 make local-vm-run

   # Use default (3 containers) - good balance
   make local-vm-run
   ```

2. **Work Inside the VM**
   All testing is now done inside the VM's graphical desktop:
   * Open the **Terminal** to run commands.
   * Open **Firefox** to view the deployed web applications.

3. **Example: Deploying WordPress**
   
   **In the VM's Terminal**, get a root shell and SSH into a participant's container:
   ```bash
   # Become root (no password needed)
   sudo -i

   # Connect to participant 1 (hopper)
   connect hopper

   # Or direct SSH (password: root)
   ssh root@192.168.100.11
   ```
   
   **Inside the container**, deploy a WordPress site with `abra`:
   ```bash
   abra app new wordpress -S --domain=blog.hopper.local
   abra app deploy blog.hopper.local
   ```
   
   **In the VM's Firefox**, navigate to `http://blog.hopper.local`. You will see the WordPress installation screen.

4. **Available Helper Commands**
   ```bash
   sudo containers    # List all containers with IPs
   sudo logs          # Show setup logs for all containers  
   sudo recipes       # Display available Co-op Cloud recipes
   sudo help          # Show all available commands
   ```

---

## 🌐 Cloud Deployment

The cloud environment creates 15 production servers:

```bash
# Set required environment variables
export HCLOUD_TOKEN="your_hetzner_token"
export HETZNER_DNS_TOKEN="your_dns_token"  
export DNS_ZONE_ID="your_zone_id"

# Deploy all 15 servers
make deploy-cloud

# Check server status
make status-cloud
```

Each server is accessible at:
- `hopper.codecrispi.es`
- `curie.codecrispi.es`
- `lovelace.codecrispi.es`
- ... (15 total)

---

## 💾 USB Workshop Environment

Build bootable USB drives for participants:

```bash
# Build the ISO
make build-usb

# Flash to USB drive (replace /dev/sdX with your device)
make flash-usb USB_DEVICE=/dev/sdb
```

The USB environment includes:
- Pre-configured SSH client
- `connect <name>` command to SSH into assigned servers
- `recipes` command showing available Co-op Cloud applications
- Workshop-specific networking and WiFi helpers

---

## ⚙️ Environment Variables

Control workshop behavior with environment variables:

```bash
# Number of containers (1-15, default: 3)
export PARTICIPANTS=5
make local-vm-run

# Workshop domain for cloud deployment
export WORKSHOP_DOMAIN=myworkshop.com

# USB device for flashing
export USB_DEVICE=/dev/sdb
```

---

## 🧹 Cleanup & Management

```bash
# Clean local build artifacts
make clean

# Destroy Hetzner cloud infrastructure  
make destroy-cloud

# Verify VM builds correctly
make check-vm

# Run development tools
make opencode    # Start development environment
make lint        # Code quality checks
```

---

## 🔑 Prerequisites

- **SSH Key:** Ed25519 key at `~/.ssh/id_ed25519.pub`
  ```bash
  ssh-keygen -t ed25519
  ```
- **Nix:** NixOS or Nix package manager with flakes enabled
- **Cloud Tokens:** Hetzner Cloud API token for deployment
- **Resources:** 
  - 2-3 containers: 4GB+ RAM
  - 5-10 containers: 8GB+ RAM  
  - 15 containers: 16GB+ RAM

---

## 🎯 Workshop Flow

1. **Preparation:** Deploy cloud infrastructure with `make deploy-cloud`
2. **Distribution:** Flash USB drives for participants with `make build-usb && make flash-usb`  
3. **Workshop:** Participants boot from USB and connect to their assigned cloud servers
4. **Development:** Use local VM with `make local-vm-run` for testing and development

The architecture ensures participants get identical environments whether connecting from USB boot drives to cloud servers, or testing locally in the development VM.

---

## 🐛 Troubleshooting

### VM Won't Start
```bash
# Check if build works
make check-vm

# Try with fewer containers
PARTICIPANTS=2 make local-vm-run
```

### Containers Not Accessible
```bash
# Check container status inside VM
sudo containers

# View setup logs  
sudo logs

# Manual SSH test
ssh root@192.168.100.11  # Password: root
```

### Abra Not Working in Container
```bash
# Inside container, check installation
ls -la /root/.local/bin/abra
export PATH="/root/.local/bin:$PATH"
abra --version
```
