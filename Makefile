-include .env
export

.PHONY: help deploy-cloud build-usb flash-usb vm-run vm-build clean status destroy-cloud opencode lint

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := $(or $(USB_DEVICE),/dev/sdX)

help:
	@echo "CODE CRISPIES Workshop Infrastructure"
	@echo ""
	@echo "🌐 Cloud Infrastructure (Hetzner):"
	@echo "  make deploy-cloud    - Deploy 15 VMs to Hetzner Cloud"
	@echo "  make status-cloud    - Check server health"
	@echo "  make destroy-cloud   - Destroy cloud infrastructure"
	@echo ""
	@echo "💾 USB Boot Drive (Single Participant Environment):"
	@echo "  make build-usb       - Build NixOS workshop ISO"
	@echo "  make flash-usb       - Flash ISO to USB drive"
	@echo "  make test-usb        - Test USB environment in QEMU"
	@echo ""
	@echo "🖥️ Local Development:"
	@echo "  make vm-run          - Start local VM (simulates USB environment)"
	@echo "  make vm              - Alias for vm-run"
	@echo "  make vm-build        - Test VM without GUI"
	@echo "  make clean           - Clean build artifacts"
	@echo ""
	@echo "⚙️ Development:"
	@echo "  make opencode        - Start opencode in dev shell"
	@echo "  make lint            - Run linting checks"
	@echo ""
	@echo "Current Config:"
	@echo "  Domain: $(DOMAIN)"
	@echo "  USB Device: $(USB_DEVICE)"
	@echo ""
	@echo "Required: HCLOUD_TOKEN, SSH key at ~/.ssh/id_ed25519.pub"

build-usb:
	@echo "🔨 Building NixOS workshop ISO..."
	@if [ ! -f ~/.ssh/id_ed25519.pub ]; then \
		echo "❌ SSH key not found at ~/.ssh/id_ed25519.pub"; \
		echo "Generate with: ssh-keygen -t ed25519"; \
		exit 1; \
	fi
	nix build .#live-iso --show-trace
	@echo "✅ ISO built: result/iso/nixos.iso"
	@echo "📦 Size: $$(du -h result/iso/nixos.iso | cut -f1)"

flash-usb: build-usb
	@if [ "$(USB_DEVICE)" = "/dev/sdX" ]; then \
		echo "❌ Set USB_DEVICE=/dev/sdX (find with 'lsblk')"; \
		exit 1; \
	fi
	@echo "⚠️ About to flash $(USB_DEVICE) - THIS WILL ERASE ALL DATA!"
	@echo "Device info: $$(lsblk $(USB_DEVICE) 2>/dev/null || echo 'DEVICE NOT FOUND')"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=$(USB_DEVICE) bs=4M status=progress oflag=sync
	sync
	@echo "✅ USB drive ready!"

test-usb: build-usb
	@echo "🧪 Testing USB environment in QEMU..."
	qemu-system-x86_64 \
		-cdrom result/iso/nixos.iso \
		-m 2048 \
		-enable-kvm \
		-netdev user,id=net0 \
		-device virtio-net,netdev=net0 \
		-display gtk

vm-run:
	@echo "🖥️ Starting workshop VM..."
	nix run .#local-vm

vm: vm-run

vm-build:
	@echo "🧪 Testing VM build..."
	nix build .#local-vm
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
	rm -rf result .direnv terraform/.terraform terraform/terraform.tfstate*
	@echo "🧹 Cleaned up build artifacts"

opencode:
	nix develop --command opencode

lint:
	@echo "🔍 Linting project files..."
	@markdownlint-cli . || true
	@nixpkgs-fmt --check . || true

lint-fix:
	@echo "🎨 Formatting Nix files..."
	@nixpkgs-fmt .
