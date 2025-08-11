# Load .env file if it exists
-include .env
export

.PHONY: help cloud-deploy cloud-status cloud-destroy usb-build usb-flash local-dev-shell local-deploy local-ssh local-clean clean

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := /dev/sdX

help:
	@echo "🍪 CODE CRISPIES Workshop"
	@echo ""
	@echo "Usage: make <command>"
	@echo ""
	@echo "Cloud Commands:"
	@echo "  cloud-deploy    - Deploy VMs to Hetzner and run health checks"
	@echo "  cloud-status    - Check the status of cloud servers"
	@echo "  cloud-destroy   - Destroy all cloud infrastructure"
	@echo ""
	@echo "USB Drive Commands:"
	@echo "  usb-build       - Build the NixOS ISO for the workshop"
	@echo "  usb-flash       - Flash the ISO to a USB drive (set USB_DEVICE)"
	@echo ""
	@echo "Local Development Commands:"
	@echo "  local-dev-shell - Enter the development shell with all tools"
	@echo "  local-deploy    - Deploy local NixOS containers for testing"
	@echo "  local-ssh       - SSH into a local participant container"
	@echo "  local-clean     - Stop and destroy all local containers"

# --- Cloud Infrastructure ---
cloud-deploy:
	@echo "🚀 Deploying to Hetzner Cloud..."
	./scripts/deploy.sh

cloud-status:
	@echo "📊 Checking server status..."
	@for name in hopper curie lovelace noether hamilton franklin johnson clarke goldberg liskov wing rosen shaw karp rich; do \
		echo -n "$$name.${DOMAIN}: "; \
		if curl -s -f https://traefik.$$name.${DOMAIN}/ping >/dev/null 2>&1; then \
			echo "✅ Ready"; \
		else \
			echo "❌ Not ready"; \
		fi; \
	done

cloud-destroy:
	cd cloud && terraform destroy -auto-approve

# --- USB Boot Drive ---
usb-build:
	@echo "🔨 Building NixOS workshop ISO..."
	nix build .#packages.x86_64-linux.live-iso
	@echo "✅ ISO built: result/iso/nixos.iso"

usb-flash: usb-build
	@echo "⚠️ Flashing to ${USB_DEVICE} - THIS WILL ERASE THE DEVICE!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=${USB_DEVICE} bs=4M status=progress oflag=sync
	@echo "✅ USB drive ready!"

# --- Local Development ---
local-dev-shell:
	nix develop

local-deploy:
	@echo "🏠 Deploying local workshop environment..."
	sudo nixos-rebuild switch --flake .#workshop-local
	@echo "✅ Local containers running!"

local-ssh:
	@read -p "Connect to participant number [1-15]: " num; \
	ssh root@192.168.100.$$((10 + $$num))

local-clean:
	sudo nixos-container stop participant{1..15} || true
	sudo nixos-container destroy participant{1..15} || true

clean:
	rm -rf result .direnv
