# AGENTS.md

This file provides guidelines for AI coding agents operating within this repository.

## Build, Lint, and Test Commands

- **Build**: `make usb-build` (Builds the NixOS workshop ISO)
- **Local VM**: `make vm` (Starts local VM that simulates USB environment)
- **Test**: `make status-cloud` (Health checks for cloud infrastructure)
- **Deploy**: `make deploy-cloud` (Deploys 15 VMs to Hetzner Cloud)
- **Format**: `make format` (Format Nix files)

## Code Style Guidelines

- **Imports**: Organize imports alphabetically. Avoid unused imports.
- **Formatting**: Adhere to Nixpkgs formatting conventions. Use `nixpkgs-fmt` for consistency.
- **Types**: Use Nix's type system rigorously. Define types explicitly where possible.
- **Naming Conventions**:
    - Variables and functions: `camelCase` for Nix expressions
    - Container/server names: `lowercase` (hopper, curie, lovelace, etc.)
    - Script names: `kebab-case` for executables
- **SSH Keys**: Always use Ed25519 keys (`~/.ssh/id_ed25519.pub`)
- **Domain**: Use `codecrispi.es` consistently across all environments
- **Password Policy**: Minimize password usage; prefer key-based authentication
- **Error Handling**: Handle errors explicitly. Use Nix's error reporting mechanisms.
- **Commit Messages**: Use conventional commit style (`type: subject`). Avoid scopes like `(makefile)`. The subject should be in lowercase.

## Container Architecture

- **Local VM**: Provides infrastructure to deploy up to 15 containers on demand (matching production count)
- **Container Names**: hopper, curie, lovelace, noether, hamilton, franklin, johnson, clarke, goldberg, liskov, wing, rosen, shaw, karp, rich
- **Networking**: Private networking with NAT for local development
- **DNS**: Local `.local` domain resolution for testing

## Available Scripts

- `connect <name>` - SSH into specific container
- `containers` - List all containers with IPs  
- `logs` - Show container setup logs
- `recipes` - Display available Co-op Cloud recipes
- `help` - Show command help

## Development Workflow

1. Use `make vm-run` for local development
2. Test with all 15 containers to match production
3. Use `make usb-build` for workshop USB drives (outputs to ./build/iso/)
4. Deploy to cloud with `make deploy-cloud`

## General Guidelines

- Keep code concise and readable
- Prefer declarative over imperative approaches
- Document complex logic with comments
- Test locally before cloud deployment
- Maintain feature parity between USB/VM environments where possible
- **ALWAYS check package existence on search.nixos.org before adding new packages**

## Build Locations

- **USB ISOs**: `./build/iso/result/iso/*.iso` (custom build directory)
- **VM builds**: `./result/` (Nix default symlink)
- **Clean command**: Removes both `./build/` and `./result/` directories

## ⚠️ Critical Warnings

- **NEVER RUN `nix-env`** - This can break your Nix environment. Use `nix-shell`, `nix develop`, or declarative approaches instead.

## ⚠️ Critical Warnings

- **NEVER RUN `nix-env`** - This can break your Nix environment. Use `nix-shell`, `nix develop`, or declarative approaches instead.
