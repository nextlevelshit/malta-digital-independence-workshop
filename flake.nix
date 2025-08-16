{
  description = "Workshop VM with Participant Containers + USB ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Server names for cloud connections
      cloudServerNames = [
        "hopper"
        "curie"
        "lovelace"
        "noether"
        "hamilton"
        "franklin"
        "johnson"
        "clarke"
        "goldberg"
        "liskov"
        "wing"
        "rosen"
        "shaw"
        "karp"
        "rich"
      ];

      # Common configuration
      commonConfig = { isLiveIso ? false }:
        import ./common.nix {
          inherit pkgs cloudServerNames isLiveIso;
        };
    in
    {
      packages.${system} = {
        local-vm = self.nixosConfigurations.workshop-vm.config.system.build.vm;

        live-iso = nixos-generators.nixosGenerate {
          inherit system;
          format = "iso";
          modules = [
            (commonConfig { isLiveIso = true; })
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          markdownlint-cli
          jq
          nixpkgs-fmt
        ];
      };

      nixosConfigurations.workshop-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"

          (commonConfig { isLiveIso = false; })

          ({ config, pkgs, lib, ... }: {
            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;

            # Enable networking for VM
            networking.hostName = "workshop-vm";
            networking.networkmanager.enable = true;
            networking.firewall.enable = false;

            # Hybrid console configuration - serial primary, GUI available
            boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];

            # VM specific settings
            virtualisation.memorySize = 4096;
            virtualisation.diskSize = 40000;

            # Hybrid mode: GUI available but serial console primary
            virtualisation.qemu.options = [
              "-display"
              "gtk"
              "-monitor"
              "stdio"
            ];
            # Fix the auto-login conflict with mkForce
            services.displayManager.autoLogin = lib.mkForce {
              enable = true;
              user = "workshop";
            };
            # Keep GUI session commands for when GUI is used
            services.xserver.displayManager.sessionCommands = ''
              ${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal --fullscreen --title="Workshop Terminal" &
            '';
          })
        ];
      };
    };
}
