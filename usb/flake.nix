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
          # WiFi + NetworkManager
          networking = {
            networkmanager.enable = true;
            wireless.enable = false; # Disable wpa_supplicant, use NetworkManager
          };
          
          # Auto-connect to workshop WiFi
          systemd.services.workshop-wifi = {
            wantedBy = [ "multi-user.target" ];
            after = [ "NetworkManager.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "workshop";
            };
            script = ''
              sleep 10  # Wait for NetworkManager to start
              ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
            '';
          };
          
          # Auto-login workshop user
          services.getty.autologinUser = "workshop";
          users.users.workshop = {
            isNormalUser = true;
            shell = pkgs.zsh;
            extraGroups = [ "networkmanager" ];
          };
          
          # Workshop shell environment with CORRECT recipes
          programs.zsh = {
            enable = true;
            interactiveShellInit = ''
              echo "🍪 CODE CRISPIES Workshop Environment"
              echo "📶 WiFi: CODE_CRISPIES_GUEST"
              echo "📡 Available servers:"
              ${builtins.concatStringsSep "\n" (map (name: 
                "echo \"  - ${name}.codecrispi.es\""
              ) participantNames)}
              echo ""
              echo "💡 Commands: connect <name> | recipes | help"
              
              connect() {
                [ -z "$1" ] && { 
                  echo "Usage: connect <name>"
                  echo "Available: ${builtins.concatStringsSep " " participantNames}"
                  return 1
                }
                echo "🔗 Connecting to $1.codecrispi.es..."
                ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es
              }
              
              recipes() {
                echo "📦 Popular Co-op Cloud recipes (Score 3+):"
                echo ""
                echo "🌐 Content Management:"
                echo "  wordpress        - CMS/Blog platform"
                echo "  ghost            - Headless Node.js CMS"
                echo "  dokuwiki         - Simple text-based wiki"
                echo ""
                echo "☁️  Productivity & Collaboration:"
                echo "  nextcloud        - File sharing & collaboration"
                echo "  hedgedoc         - Collaborative markdown editor"
                echo "  collabora        - Online office suite"
                echo "  onlyoffice       - Office suite with editors"
                echo "  outline          - Wiki and knowledge base"
                echo ""
                echo "🍽️  Lifestyle & Organization:"
                echo "  mealie           - Recipe manager & meal planner"
                echo ""
                echo "💬 Communication:"
                echo "  mattermost       - Team chat platform"
                echo "  rocketchat       - Team communications"
                echo ""
                echo "🎯 Event & Community Management:"
                echo "  engelsystem     - Volunteer shift management"
                echo "  loomio          - Group decision making"
                echo "  mrbs            - Meeting room booking"
                echo "  rallly          - Doodle poll alternative"
                echo ""
                echo "🛠️  Development & Git:"
                echo "  gitea           - Self-hosted Git service"
                echo "  custom-php      - Custom PHP applications"
                echo ""
                echo "🎨 Creative & Media:"
                echo "  owncast         - Live streaming platform"
                echo ""
                echo "Deploy example:"
                echo "  abra app new wordpress -S --domain=mysite.<yourname>.codecrispi.es"
              }
              
              help() {
                echo "📚 CODE CRISPIES Workshop Guide"
                echo ""
                echo "1️⃣ Connect to your assigned server:"
                echo "   connect <yourname>    # e.g., connect hopper"
                echo ""
                echo "2️⃣ Check your server status:"
                echo "   abra server ls"
                echo "   abra app ls"
                echo ""
                echo "3️⃣ Deploy your first app:"
                echo "   abra app new wordpress -S --domain=mysite.<yourname>.codecrispi.es"
                echo "   abra app deploy mysite.<yourname>.codecrispi.es"
                echo ""
                echo "4️⃣ Check deployment status:"
                echo "   abra app ps mysite.<yourname>.codecrispi.es"
                echo "   abra app logs mysite.<yourname>.codecrispi.es"
                echo ""
                echo "5️⃣ Access your site:"
                echo "   https://mysite.<yourname>.codecrispi.es"
                echo ""
                echo "🆘 Need help? Ask the workshop facilitator!"
                echo "📦 See all recipes: recipes"
              }
            '';
          };
          
          environment.systemPackages = with pkgs; [ 
            openssh 
            curl 
            git 
            networkmanager 
          ];
          
          # Auto-start terminal in graphical environment
          services.xserver = {
            enable = true;
            displayManager = {
              autoLogin.enable = true;
              autoLogin.user = "workshop";
              sessionCommands = ''
                ${pkgs.xterm}/bin/xterm -maximized -e ${pkgs.zsh}/bin/zsh &
              '';
            };
            desktopManager.xfce.enable = true;
          };
          
          # Enable hardware support for most WiFi cards
          hardware.enableRedistributableFirmware = true;
          
          # ISO-specific settings
          isoImage.makeEfiBootable = true;
          isoImage.makeUsbBootable = true;
        })
      ];
    };
    
    # Dev shell
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
      buildInputs = with nixpkgs.legacyPackages.${system}; [
        terraform
        nixos-rebuild
        docker
        openssh
        jq
      ];
    };
  };
}
