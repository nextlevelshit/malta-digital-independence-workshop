# 🍪 CODE CRISPIES Workshop Infrastructure

This repository contains the infrastructure for the Co-op Cloud workshop, providing three distinct deployment environments.

---
## 🚀 Quick Start

```bash
# 1. Start the local development virtual machine
make local-vm-run

# 2. Build & flash USB drives for participants
make build-usb
make flash-usb USB_DEVICE=/dev/sdX

# 3. Deploy the production cloud infrastructure
export HCLOUD_TOKEN="your_token_here"
make deploy-cloud
````

-----

## 📁 Project Structure

```
├── flake.nix              # All Nix configurations (USB, VM)
├── terraform/             # Hetzner Cloud infrastructure
├── scripts/deploy.sh      # Cloud setup automation
├── docs/USB_BOOT_INSTRUCTIONS.md
└── Makefile              # Build & deploy commands
```

-----

## 🌍 Three Environments

### 1\. Cloud (Production)

  - [cite\_start]**What:** Hetzner VMs named `hopper.codecrispi.es`, `curie.codecrispi.es`, etc. [cite: 52]
  - **Purpose:** The live environment for workshop participants.

### 2\. USB Boot (Workshop)

  - [cite\_start]**What:** A bootable NixOS live environment. [cite: 4]
  - **Purpose:** Used by participants to connect to their cloud servers. [cite\_start]It includes helper functions like `connect hopper`. [cite: 12]

### 3\. Local (Development)

  - **What:** A self-contained Virtual Machine (VM) that runs on your local computer.
  - **Purpose:** The VM hosts simulated participant containers (e.g., `hopper.local`) and includes a lightweight desktop with a web browser, providing a perfect, isolated environment to test the entire workshop flow without needing cloud servers.

-----

## 🔧 Local Development Workflow

1.  **Start the VM**
    Run the following command. A new window will open and automatically boot into a lightweight desktop.

    ```bash
    make local-vm-run
    ```

2.  **Work Inside the VM**
    All testing is now done inside the VM's graphical desktop.

      * Open the **Terminal** to run commands.
      * Open **Firefox** to view the deployed web applications.

3.  **Example: Deploying WordPress**

      * **In the VM's Terminal**, get a root shell and SSH into the first participant's container:
        ```bash
        # Become root (no password needed)
        sudo -i

        # Connect to participant 1 (hopper.local)
        ssh root@192.168.100.11
        ```
      * **Inside the container**, deploy a WordPress site with `abra`:
        ```bash
        abra app new wordpress -S --domain=blog.hopper.local
        abra app deploy blog.hopper.local
        ```
      * **In the VM's Firefox**, navigate to the address `http://blog.hopper.local`. You will see the WordPress installation screen.

-----

## 🧹 Cleanup

```bash
# Clean local build artifacts
make clean

# Destroy Hetzner cloud infrastructure
make destroy-cloud

# To stop the local VM, simply close its window.
```
