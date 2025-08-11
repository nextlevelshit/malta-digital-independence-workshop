{
  description = "CODE CRISPIES Workshop Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
  };

  outputs = { self, nixpkgs, nixos-generators }:
  let
    system = "x86_64-linux";
    participantNames = [
      "hopper" "curie" "lovelace" "noether" "hamilton"
      "franklin" "johnson" "clarke" "goldberg" "liskov"
      "wing" "rosen" "shaw" "karp" "rich"
    ];
  in
  {
    # --------------------------------------------------------------------------------
    # 1. USB BOOT DRIVE (ISO)
    #    `nix build .#live-iso`
    # --------------------------------------------------------------------------------
    packages.${system}.live-iso = nixos-generators.nixosGenerate {
      inherit system;
      format = "iso";
      modules = [
        ({ pkgs, ... }: {
          # WiFi and NetworkManager
          networking.networkmanager.enable = true;
          systemd.services.workshop-wifi = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
            '';
          };

          # Auto-login and shell setup
          services.getty.autologinUser = "workshop";
          users.users.workshop = {
            isNormalUser = true;
            shell = pkgs.zsh;
          };

          # Zsh shell with helper functions
          programs.zsh = {
            enable = true;
            interactiveShellInit = ''
              echo "🍪 CODE CRISPIES Workshop Environment"
              echo "📶 WiFi: CODE_CRISPIES_GUEST (auto-connecting...)"
              echo "📡 Available servers:"
              ${builtins.concatStringsSep "\n" (map (name:
                "echo \"  - ${name}.codecrispi.es\""
              ) participantNames)}
              echo ""
              echo "💡 Commands: connect <name> | recipes | help"

              connect() {
                ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
              }
              # ... other helper functions (recipes, help) ...
            '';
          };
          
          # Base packages and auto-start terminal
          environment.systemPackages = with pkgs; [ openssh curl git networkmanager ];
          services.xserver = {
            enable = true;
            displayManager.autoLogin = {
              enable = true;
              user = "workshop";
            };
            desktopManager.xfce.enable = true; # A lightweight desktop
            displayManager.sessionCommands = "${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal &";
          };
        })
      ];
    };

    # --------------------------------------------------------------------------------
    # 2. LOCAL DEVELOPMENT ENVIRONMENT (NixOS Containers)
    #    `sudo nixos-rebuild switch --flake .#workshop-local`
    # --------------------------------------------------------------------------------
    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ pkgs, ... }: {
          # Define 15 participant containers
          containers = builtins.listToAttrs (map (i:
            let
              participantNum = toString i;
              ipAddr = "192.168.100.${toString (10 + i)}";
            in
            {
              name = "participant${participantNum}";
              value = {
                autoStart = true;
                privateNetwork = true;
                hostAddress = "192.168.100.1";
                localAddress = ipAddr;
                config = {
                  # Container config from your local/flake.nix
                  virtualisation.docker.enable = true;
                  environment.systemPackages = with pkgs; [ docker git curl ];
                  services.openssh.enable = true;
                  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
                };
              };
            }) (nixpkgs.lib.range 1 15));
        })
      ];
    };

    # --------------------------------------------------------------------------------
    # 3. DEVELOPMENT SHELL
    #    `nix develop`
    # --------------------------------------------------------------------------------
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
      buildInputs = with nixpkgs.legacyPackages.${system}; [
        terraform
        nixos-rebuild
        docker
        openssh
      ];
    };
  };
}
