# AGENTS.md

This file provides guidelines for AI coding agents operating within this repository.

## Build, Lint, and Test Commands

- **Build**: `make build-usb` (Builds the NixOS workshop ISO)
- **Lint**: No specific linting command found. Follow general code style guidelines.
- **Test**: No specific testing command found. Use `make status-cloud` for health checks.
- **Single Test**: No specific command for running a single test.

## Code Style Guidelines

- **Imports**: Organize imports alphabetically. Avoid unused imports.
- **Formatting**: Adhere to Nixpkgs formatting conventions. Use `nixpkgs-fmt` if available.
- **Types**: Use Nix's type system rigorously. Define types explicitly where possible.
- **Naming Conventions**:
    - Variables and functions: `camelCase` or `snake_case` (be consistent).
    - Package names: `lowercase-with-hyphens`.
- **Error Handling**: Handle errors explicitly. Use Nix's error reporting mechanisms.
- **General**:
    - Keep code concise and readable.
    - Prefer declarative over imperative approaches.
    - Document complex logic.
