.PHONY: help vm-run clean

help:
	@echo "🍪 Workshop VM with Containers"
	@echo ""
	@echo "Commands:"
	@echo "  make vm-run    - Start VM with participant containers"
	@echo "  make clean     - Clean build artifacts"
	@echo ""
	@echo "Inside the VM:"
	@echo "  ssh root@192.168.100.11  # Connect to hopper container"
	@echo "  ssh root@192.168.100.12  # Connect to curie container"

vm-run:
	@echo "🚀 Starting workshop VM with containers..."
	@echo "VM will open with desktop. Terminal shows SSH commands."
	nix run --impure .#local-vm

clean:
	rm -rf result .direnv
