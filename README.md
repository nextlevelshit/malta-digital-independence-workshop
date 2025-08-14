# 🍪 CODE CRISPIES Workshop Infrastructure

This repository contains the infrastructure for the Co-op Cloud workshop, providing three distinct deployment environments.

---
## 🚀 Quick Start

```bash
# 1. Start the local development virtual machine (15 containers)
make local-vm-run

# 2. Build & flash USB drives for participants
make build-usb
make flash-usb USB_DEVICE=/dev/sdX

# 3. Deploy the production cloud infrastructure
export HCLOUD_TOKEN="your_token_here"
make deploy-cloud
```

---

## 📁 Project Structure

```
├── flake.nix              # All Nix configurations (USB, VM)
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

- **What:** A self-contained Virtual Machine (VM) that runs on your local computer with all 15 containers.
- **Purpose:** Complete local testing environment that mirrors production setup without needing cloud servers.
- **Resources:** Creates 15 containers (heavy resource usage - ensure adequate RAM/CPU)

---

## 🔧 Local Development Workflow

1. **Start the VM**
   Run the following command. A new window will open and automatically boot into a lightweight desktop.

   ```bash
   make local-vm-run
   ```

2. **Work Inside the VM**
   All testing is now done inside the VM's graphical desktop.

   * Open the **Terminal** to run commands.
   * Open **Firefox** to view the deployed web applications.

3. **Example: Deploying WordPress**

   * **In the VM's Terminal**, get a root shell and SSH into a participant's container:
     ```bash
     # Become root (no password needed)
     sudo -i

     # Connect to participant 1 (hopper)
     connect hopper

     # Or direct SSH
     ssh root@192.168.100.11
     ```
   * **Inside the container**, deploy a WordPress site with `abra`:
     ```bash
     abra app new wordpress -S --domain=blog.hopper.local
     abra app deploy blog.hopper.local
     ```
   * **In the VM's Firefox**, navigate to `http://blog.hopper.local`. You will see the WordPress installation screen.

4. **Available Helper Commands**
   ```bash
   sudo containers    # List all 15 containers with IPs
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

## 🧹 Cleanup

```bash
# Clean local build artifacts
make clean

# Destroy Hetzner cloud infrastructure  
make destroy-cloud

# To stop the local VM, simply close its window
```

---

## 🔑 Prerequisites

- **SSH Key:** Ed25519 key at `~/.ssh/id_ed25519.pub`
  ```bash
  ssh-keygen -t ed25519
  ```
- **Nix:** NixOS or Nix package manager with flakes enabled
- **Cloud Tokens:** Hetzner Cloud API token for deployment
- **Resources:** For local VM: 8GB+ RAM recommended (runs 15 containers)

---

## 🎯 Workshop Flow

1. **Preparation:** Deploy cloud infrastructure with `make deploy-cloud`
2. **Distribution:** Flash USB drives for participants with `make build-usb && make flash-usb`  
3. **Workshop:** Participants boot from USB and connect to their assigned cloud servers
4. **Development:** Use local VM (`make local-vm-run`) for testing and development

The architecture ensures participants get identical environments whether connecting from USB boot drives to cloud servers, or testing locally in the development VM.
