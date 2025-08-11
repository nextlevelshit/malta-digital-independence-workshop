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
          networking.networkmanager.enable = true;
          systemd.services.workshop-wifi = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
            '';
          };

          services.getty.autologinUser = "workshop";
          users.users.workshop = {
            isNormalUser = true;
            shell = pkgs.zsh;
          };

          programs.zsh = {
            enable = true;
            interactiveShellInit = ''
              echo "🍪 CODE CRISPIES Workshop Environment"
              echo "📶 WiFi: CODE_CRISPIES_GUEST (auto-connecting...)"
              echo "📡 Available servers:"
              ${builtins.concatStringsSep "\n" (map (name: "echo \"  - ${name}.codecrispi.es\"") participantNames)}
              echo ""
              echo "💡 Commands: connect <name> | recipes | help"

              connect() {
                [ -z "$1" ] && { echo "Usage: connect <name>"; return 1; }
                echo "🔗 Connecting to $1.codecrispi.es..."
                ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
              }
              
              recipes() {
                echo "🍪 Featured Co-op Cloud Recipes: (wordpress, nextcloud, hedgedoc...)"
                echo "Browse all 100+ recipes: https://recipes.coopcloud.tech"
              }
              
              help() {
                echo "💡 Commands: connect <name> | recipes | help"
              }
            '';
          };
          
          environment.systemPackages = with pkgs; [ openssh curl git networkmanager ];
          services.xserver = {
            enable = true;
            displayManager.autoLogin.enable = true;
            displayManager.autoLogin.user = "workshop";
            desktopManager.xfce.enable = true;
            displayManager.sessionCommands = "${pkgs.xfce.xfce4-terminal}/bin/xfce4-terminal &";
          };
        })
      ];
    };

    # --------------------------------------------------------------------------------
    # 2. LOCAL DEVELOPMENT ENVIRONMENT (NixOS Containers)
    #    `make local-deploy`
    # --------------------------------------------------------------------------------
    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Dynamically import the configuration for the current host machine.
        (
          let
            # Read the hostname and remove the trailing newline.
            hostname = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "/etc/hostname");
          in
            # Build the correct path to the configuration file.
            /etc/nixos/hosts/${hostname}/configuration.nix
        )

        # Your container definitions are then added on top of the host config.
        ({ pkgs, config, ... }: {
          # Set this to your host's NixOS version (e.g., "23.11", "24.05")
          system.stateVersion = "25.05";

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
                  system.stateVersion = "24.05";
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
