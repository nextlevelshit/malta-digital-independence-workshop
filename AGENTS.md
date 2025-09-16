# AGENTS.md

This file provides guidelines for AI coding agents operating within this repository.

## Build, Lint, and Test Commands

- **Build**: `make usb-build` (Builds the NixOS workshop ISO)
- **Local VM**: `make vm` (Starts local VM that simulates USB environment)
- **Test**: `make usb-test` (Test USB environment in QEMU)
- **Deploy**: `make usb-build` (Build workshop USB ISO)
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

- **Local VM**: Provides self-contained workshop environment
- **Container Names**: workshop-local (single container environment)
- **Networking**: Local networking with DNS resolution
- **DNS**: `*.workshop.local` domain resolution for testing

## Available Scripts

- `setup` - Initialize local workshop environment
- `deploy <recipe>` - Deploy Co-op Cloud applications
- `browser [app]` - Open applications in Firefox
- `recipes` - Display available Co-op Cloud recipes
- `help` - Show command help

## Development Workflow

1. Use `make vm` for local development testing
2. Test workshop environment with `make usb-test`
3. Use `make usb-build` for workshop USB drives (outputs to ./build/iso/)
4. Focus on local deployment and learning

## General Guidelines

- Keep code concise and readable
- Prefer declarative over imperative approaches
- Document complex logic with comments
- Test locally in VM before USB deployment
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
