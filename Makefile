-include .env
export

.PHONY: help deploy-cloud build-usb flash-usb local-vm-run clean status destroy-cloud opencode lint

DOMAIN := $(or $(WORKSHOP_DOMAIN),codecrispi.es)
PARTICIPANTS := $(or $(WORKSHOP_PARTICIPANTS),3)
USB_DEVICE := $(or $(USB_DEVICE),/dev/sdX)

help:
	@echo "CODE CRISPIES Workshop"
	@echo ""
	@echo "Cloud Infrastructure (Hetzner):"
	@echo "  make deploy-cloud    - Deploy 15 VMs to Hetzner Cloud"
	@echo "  make status-cloud    - Check server health"
	@echo "  make destroy-cloud   - Destroy cloud infrastructure"
	@echo ""
	@echo "USB Boot Drive:"
	@echo "  make build-usb       - Build NixOS workshop ISO"
	@echo "  make flash-usb       - Flash ISO to USB drive"
	@echo ""
	@echo "Local Development:"
	@echo "  make local-vm-run    - Start local VM with 15 containers"
	@echo "  make clean           - Clean build artifacts"
	@echo ""
	@echo "Development:"
	@echo "  make opencode        - Start opencode in dev shell"
	@echo "  make lint            - Run linting checks"
	@echo ""
	@echo "Config: Domain=$(DOMAIN), USB=$(USB_DEVICE)"
	@echo "Required: HCLOUD_TOKEN, SSH key at ~/.ssh/id_ed25519.pub"

build-usb:
	@echo "Building NixOS workshop ISO for $(DOMAIN)..."
	@if [ ! -f ~/.ssh/id_ed25519.pub ]; then \
		echo "SSH key not found at ~/.ssh/id_ed25519.pub"; \
		echo "Generate with: ssh-keygen -t ed25519"; \
		exit 1; \
	fi
	nix build .#live-iso --show-trace
	@echo "ISO built: result/iso/nixos.iso"
	@echo "Size: $$(du -h result/iso/nixos.iso | cut -f1)"

flash-usb: build-usb
	@if [ "$(USB_DEVICE)" = "/dev/sdX" ]; then \
		echo "Set USB_DEVICE=/dev/sdX (find with 'lsblk')"; \
		exit 1; \
	fi
	@echo "About to flash $(USB_DEVICE) - THIS WILL ERASE ALL DATA!"
	@echo "Verify device: $$(lsblk $(USB_DEVICE) 2>/dev/null || echo 'DEVICE NOT FOUND')"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	sudo dd if=result/iso/nixos.iso of=$(USB_DEVICE) bs=4M status=progress oflag=sync
	sync
	@echo "USB drive ready for workshop!"

deploy-cloud:
	@if [ -z "$(HCLOUD_TOKEN)" ]; then \
		echo "HCLOUD_TOKEN not set"; \
		echo "Get token from: https://console.hetzner.cloud/"; \
		exit 1; \
	fi
	@if [ ! -f ~/.ssh/id_ed25519.pub ]; then \
		echo "SSH key not found at ~/.ssh/id_ed25519.pub"; \
		echo "Generate with: ssh-keygen -t ed25519"; \
		exit 1; \
	fi
	@echo "Deploying 15 workshop servers to Hetzner Cloud..."
	@echo "Domain: $(DOMAIN)"
	cd terraform && terraform init
	cd terraform && terraform apply -auto-approve \
		-var="hcloud_token=$(HCLOUD_TOKEN)" \
		-var="hetzner_dns_token=$(HETZNER_DNS_TOKEN)" \
		-var="dns_zone_id=$(DNS_ZONE_ID)" \
		-var="domain=$(DOMAIN)" \
		-var="ssh_public_key=$$(cat ~/.ssh/id_ed25519.pub)"
	@echo "Running health checks..."
	@sleep 60
	$(MAKE) status-cloud
	@echo "Cloud deployment complete!"

status-cloud:
	@echo "Checking server health..."
	@for name in hopper curie lovelace noether hamilton franklin johnson clarke goldberg liskov wing rosen shaw karp rich; do \
		printf "%-10s " "$$name:"; \
		if timeout 10 curl -s -f https://traefik.$$name.$(DOMAIN)/ping >/dev/null 2>&1; then \
			echo "Ready"; \
		elif timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no workshop@$$name.$(DOMAIN) "echo ok" >/dev/null 2>&1; then \
			echo "SSH OK, Traefik starting..."; \
		else \
			echo "Not ready"; \
		fi; \
	done

destroy-cloud:
	@echo "This will destroy ALL workshop servers!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform && terraform destroy -auto-approve

local-vm-run:
	@echo "Starting local workshop VM with $(PARTICIPANTS) containers..."
	@echo "VM will open with desktop showing all participant containers"
	nix run --impure .#local-vm

clean:
	rm -rf result .direnv terraform/.terraform terraform/terraform.tfstate*
	@echo "Cleaned up build artifacts"

opencode:
	@echo "Starting opencode in Nix dev shell..."
	nix develop --command opencode

lint:
	@echo "Linting Markdown files..."
	@markdownlint-cli . || true
	@echo "Linting JSON files..."
	@find . -type f -name "*.json" -print0 | xargs -0 -I {} bash -c 'jq . "{}" >/dev/null || (echo "JSON lint error in {}" && exit 1)'
	@echo "Linting Nix files..."
	@nixpkgs-fmt . || true
	@echo "Linting complete."
