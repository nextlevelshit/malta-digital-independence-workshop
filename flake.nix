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

      # All possible participant names for the workshop
      allParticipantNames = [
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

      # Dynamic participant count (default 3, max 15)
      participantsEnv = builtins.getEnv "PARTICIPANTS";
      numParticipants =
        if participantsEnv != "" && builtins.match "^[0-9]+$" participantsEnv != null
        then
          let num = builtins.fromJSON participantsEnv;
          in if num >= 1 && num <= 15 then num else 3
        else 3;

      # Selected participant names based on count
      # Selected participant names based on count
      participantNames = builtins.genList
        (i: builtins.elemAt allParticipantNames i)
        numParticipants;

      # Common configuration for both live-iso and local-vm
      commonConfig =
        { isLiveIso ? false, ... } @ args:
        import ./common.nix (args // { inherit pkgs allParticipantNames participantNames; });
    in
    {
      packages.${system} = {
        local-vm = self.nixosConfigurations.workshop-vm.config.system.build.vm;

        live-iso = nixos-generators.nixosGenerate {
          inherit system;
          format = "iso";

          modules = [
            commonConfig
            { isLiveIso = true; }
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
          commonConfig
          { isLiveIso = false; }
          ({ config, pkgs, ... }: {
            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;

            # Enable networking for VM
            networking.hostName = "workshop-vm";
            networking.networkmanager.enable = true;
            networking.firewall.enable = false;

            # Auto-login for VM
            services.getty.autologinUser = "workshop";
            services.displayManager.autoLogin = {
              enable = true;
              user = "workshop";
            };

            # Auto-start terminal with welcome message
            services.xserver.displayManager.sessionCommands = ''
              ${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal --fullscreen --title="Workshop Terminal" &
            '';

            # VM specific settings
            virtualisation.memorySize = 4096; # 4GB RAM
            virtualisation.diskSize = 40000; # 40GB disk
          })
        ];
      };
    };
}

