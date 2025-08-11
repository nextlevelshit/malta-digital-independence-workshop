# Load .env file if it exists
-include .env
export

.PHONY: help cloud-deploy cloud-status cloud-destroy usb-build usb-flash local-vm-run local-shell clean

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := /dev/sdX

help:
	@echo "🍪 CODE CRISPIES Workshop"
	@echo ""
	@echo "Usage: make <command>"
	@echo ""
	@echo "--- Local VM Development ---"
	@echo "  make local-vm-run    - Start the complete workshop environment in a VM"
	@echo ""
	@echo "--- Cloud Infrastructure ---"
	@echo "  make cloud-deploy    - Deploy VMs to Hetzner"
	@echo "  make cloud-status    - Check the status of cloud servers"
	@echo "  make cloud-destroy   - Destroy all cloud infrastructure"
	@echo ""
	@echo "--- USB Drive Creation ---"
	@echo "  make usb-build       - Build the NixOS ISO for the workshop"
	@echo "  make usb-flash       - Flash the ISO to a USB drive (set USB_DEVICE)"
	@echo ""
	@echo "--- Host Development Shell ---"
	@echo "  make local-shell     - Enter a dev shell with terraform, etc., on your main machine"


# --- Local Development ---
local-vm-run:
	@echo "🚀 Starting local workshop environment inside a VM..."
	@echo "    (Close the VM window or press Ctrl+A, X to exit)"
	nix run --impure .#local-vm

# --- Cloud Infrastructure ---
cloud-deploy:
	./scripts/deploy.sh

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

# --- USB Boot Drive ---
usb-build:
	nix build .#live-iso

flash-usb: usb-build
	@echo "⚠️  Flashing to ${USB_DEVICE} - THIS WILL ERASE THE DEVICE!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=${USB_DEVICE} bs=4M status=progress oflag=sync
	@echo "✅ USB drive ready!"

# --- Host Development ---
local-shell:
	nix develop

clean:
	rm -rf result .direnv
