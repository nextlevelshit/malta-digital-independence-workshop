-include .env
export

.PHONY: help deploy-cloud usb-build usb-flash usb-test vm-run vm-build clean status destroy-cloud opencode format

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := $(or $(USB_DEVICE),/dev/sdX)
BUILD_DIR := ./build
ISO_FILE = $(shell ls $(BUILD_DIR)/iso/iso/*.iso 2>/dev/null | head -1)

help:
	@echo "CODE CRISPIES Workshop Infrastructure"
	@echo ""
	@echo "🌐 Cloud Infrastructure (Hetzner):"
	@echo "  make deploy-cloud    - Deploy 15 VMs to Hetzner Cloud"
	@echo "  make status-cloud    - Check server health"
	@echo "  make destroy-cloud   - Destroy cloud infrastructure"
	@echo ""
	@echo "💾 USB Boot Drive (Single Participant Environment):"
	@echo "  make usb-build       - Build NixOS workshop ISO"
	@echo "  make usb-flash       - Flash ISO to USB drive"
	@echo "  make usb-test        - Test USB environment in QEMU"
	@echo ""
	@echo "🖥️ Local Development:"
	@echo "  make vm-run          - Start local VM (simulates USB environment)"
	@echo "  make vm              - Alias for vm-run"
	@echo "  make vm-build        - Test VM without GUI"
	@echo "  make clean           - Clean build artifacts"
	@echo ""
	@echo "⚙️ Development:"
	@echo "  make opencode        - Start opencode in dev shell"
	@echo "  make format          - Format Nix files"
	@echo ""
	@echo "Current Config:"
	@echo "  Domain: $(DOMAIN)"
	@echo "  USB Device: $(USB_DEVICE)"
	@echo ""
	@echo "Required: HCLOUD_TOKEN, SSH key at ~/.ssh/id_ed25519.pub"

usb-build:
	@echo "🔨 Building NixOS workshop ISO..."
	@if [ ! -f ~/.ssh/id_ed25519.pub ]; then \
		echo "❌ SSH key not found at ~/.ssh/id_ed25519.pub"; \
		echo "Generate with: ssh-keygen -t ed25519"; \
		exit 1; \
	fi
	@mkdir -p $(BUILD_DIR)
	nix build .#live-iso --out-link $(BUILD_DIR)/iso --show-trace
	@echo "✅ ISO built: $(ISO_FILE)"
	@echo "📦 Size: $$(du -h $(ISO_FILE) | cut -f1)"

usb-flash: usb-build
	@if [ "$(USB_DEVICE)" = "/dev/sdX" ]; then \
		echo "❌ Set USB_DEVICE=/dev/sdX (find with 'lsblk')"; \
		exit 1; \
	fi
	@echo "⚠️ About to flash $(USB_DEVICE) - THIS WILL ERASE ALL DATA!"
	@echo "Device info: $$(lsblk $(USB_DEVICE) 2>/dev/null || echo 'DEVICE NOT FOUND')"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=$(ISO_FILE) of=$(USB_DEVICE) bs=4M status=progress oflag=sync
	sync
	@echo "✅ USB drive ready!"

usb-test: usb-build
	@echo "🧪 Testing USB environment in QEMU..."
	nix develop --command qemu-system-x86_64 \
		-cdrom $(ISO_FILE) \
		-m 4096 \
		-enable-kvm \
		-netdev user,id=net0 \
		-device virtio-net,netdev=net0 \
		-display gtk

vm: vm-run

vm-run:
	@echo "🖥️ Starting workshop VM as root..."
	nix run .#local-vm --impure

vm-build:
	@echo "🧪 Testing VM build as root..."
	nix build .#local-vm --impure
	@echo "✅ VM builds successfully"

deploy-cloud:
	@if [ -z "$(HCLOUD_TOKEN)" ]; then \
		echo "❌ HCLOUD_TOKEN not set"; \
		exit 1; \
	fi
	@echo "🚀 Deploying 15 workshop servers..."
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve \
		-var="hcloud_token=$(HCLOUD_TOKEN)" \
		-var="domain=$(DOMAIN)"

status-cloud:
	@echo "📊 Checking server health..."
	@for name in hopper curie lovelace noether hamilton franklin johnson clarke goldberg liskov wing rosen shaw karp rich; do \
		printf "%-10s " "$$name:"; \
		if timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no workshop@$$name.$(DOMAIN) "echo ok" >/dev/null 2>&1; then \
			echo "✅ Ready"; \
		else \
			echo "❌ Not ready"; \
		fi; \
	done

destroy-cloud:
	@echo "⚠️ This will destroy ALL workshop servers!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform && terraform destroy -auto-approve

clean:
	rm -rf result $(BUILD_DIR) .direnv terraform/.terraform terraform/terraform.tfstate* workshop-vm.*
	@echo "🧹 Cleaned up build artifacts"

opencode:
	nix develop --command opencode

format:
	@echo "🔍 Formatting Nix files..."
	@nix run nixpkgs#nixfmt-rfc-style *.nix
