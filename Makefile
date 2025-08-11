# Load .env file if it exists
-include .env
export

.PHONY: help deploy-cloud build-usb flash-usb local-shell local-deploy local-ssh clean status

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
USB_DEVICE := /dev/sdX

help:
	@echo "🍪 CODE CRISPIES Workshop"
	@echo ""
	@echo "Config: WiFi=$(or $(WORKSHOP_WIFI_SSID),CODE_CRISPIES_GUEST), Domain=$(DOMAIN)"
	@echo ""
	@echo "Cloud Infrastructure:"
	@echo "  make deploy-cloud    - Deploy VMs to Hetzner (with health checks)"
	@echo "  make status-cloud    - Check cloud server status"
	@echo "  make destroy-cloud   - Destroy cloud infrastructure"
	@echo ""
	@echo "USB Boot Drive:"
	@echo "  make build-usb       - Build NixOS ISO"
	@echo "  make flash-usb       - Flash ISO to USB (set USB_DEVICE=/dev/sdX)"
	@echo ""
	@echo "Local Development:"
	@echo "  make local-shell     - Enter dev shell"

build-usb:
	@echo "🔨 Building NixOS workshop ISO..."
	@echo "📝 Config: WiFi=$(or $(WORKSHOP_WIFI_SSID),CODE_CRISPIES_GUEST), Domain=$(DOMAIN)"
	nix build .#live-iso
	@echo "✅ ISO built: result/iso/nixos.iso"

flash-usb: build-usb
	@echo "⚠️  Flashing to ${USB_DEVICE} - THIS WILL ERASE THE DEVICE!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=${USB_DEVICE} bs=4M status=progress oflag=sync
	@echo "✅ USB drive ready!"

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

local-shell:
	nix develop

clean:
	rm -rf result .direnv
