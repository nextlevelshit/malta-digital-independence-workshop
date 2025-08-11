{
  description = "CODE CRISPIES Workshop Live Environment";
  
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
  in {
    packages.${system}.live-iso = nixos-generators.nixosGenerate {
      inherit system;
      format = "iso";
      
      modules = [
        ({ pkgs, ... }: {
          # WiFi support
          networking.wireless.enable = true;
          networking.networkmanager.enable = true;
          networking.wireless.networks = {
            "CODE_CRISPIES_GUEST" = {
              psk = "workshop2024";
            };
          };
          
          # Auto-connect to workshop WiFi
          systemd.services.workshop-wifi = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
            '';
          };
          
          # Auto-login workshop user
          services.getty.autologinUser = "workshop";
          users.users.workshop = {
            isNormalUser = true;
            shell = pkgs.zsh;
          };
          
          # Workshop shell environment
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
                [ -z "$1" ] && { echo "Usage: connect <name>"; return 1; }
                echo "🔗 Connecting to $1.codecrispi.es..."
                ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
              }
              
              recipes() {
                echo "📦 Available recipes:"
                echo "  wordpress nextcloud hedgedoc jitsi prestashop"
                echo "Deploy: abra app new wordpress -S --domain=myapp.<name>.codecrispi.es"
              }
              
              help() {
                echo "1️⃣ connect <yourname>"  
                echo "2️⃣ abra app new wordpress -S --domain=mysite.<yourname>.codecrispi.es"
                echo "3️⃣ abra app deploy mysite.<yourname>.codecrispi.es"
                echo "4️⃣ Visit https://mysite.<yourname>.codecrispi.es"
              }
            '';
          };
          
          environment.systemPackages = with pkgs [ openssh curl git networkmanager ];
          
          # Auto-start terminal
          services.xserver = {
            enable = true;
            displayManager = {
              autoLogin.enable = true;
              autoLogin.user = "workshop";
              sessionCommands = "${pkgs.xterm}/bin/xterm &";
            };
          };
        })
      ];
    };
    
    # Dev shell for local testing
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
