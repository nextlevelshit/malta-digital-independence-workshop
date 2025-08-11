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
	@echo "  make deploy-cloud    - Deploy VMs to Hetzner"
	@echo "  make status-cloud    - Check the status of cloud servers"
	@echo "  make destroy-cloud   - Destroy all cloud infrastructure"
	@echo ""
	@echo "--- USB Drive Creation ---"
	@echo "  make build-usb       - Build the NixOS ISO for the workshop"
	@echo "  make flash-usb       - Flash the ISO to a USB drive (set USB_DEVICE)"
	@echo ""
	@echo "--- Host Development Shell ---"
	@echo "  make local-shell     - Enter a dev shell with terraform, etc., on your main machine"


# --- Local Development ---
local-vm-run:
	@echo "🚀 Starting local workshop environment inside a VM..."
	@echo "    (A new window with a desktop will open. Close it to stop the VM.)"
	nix run --impure .#local-vm

# --- Cloud Infrastructure ---
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

# --- USB Boot Drive ---
build-usb:
	@echo "🔨 Building NixOS workshop ISO..."
	nix build .#live-iso
	@echo "✅ ISO built: result/iso/nixos.iso"

flash-usb: build-usb
	@echo "⚠️  Flashing to ${USB_DEVICE} - THIS WILL ERASE THE DEVICE!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=${USB_DEVICE} bs=4M status=progress oflag=sync
	@echo "✅ USB drive ready!"

# --- Host Development ---
local-shell:
	nix develop

clean:
	rm -rf result .direnv
