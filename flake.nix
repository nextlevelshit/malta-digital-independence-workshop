{
  description = "CODE CRISPIES Workshop Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
  };

  outputs = { self, nixpkgs, nixos-generators }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    participantNames = [
      "hopper" "curie" "lovelace" "noether" "hamilton"
      "franklin" "johnson" "clarke" "goldberg" "liskov"
      "wing" "rosen" "shaw" "karp" "rich"
    ];
  in
  {
    # --------------------------------------------------------------------------------
    # 1. PACKAGES (USB ISO and Local VM)
    # --------------------------------------------------------------------------------
    packages.${system} = {
      # `nix build .#live-iso`
      live-iso = nixos-generators.nixosGenerate {
        inherit system;
        format = "iso";
        modules = [
          ({ pkgs, ... }: {
            system.stateVersion = "25.05";
            networking.networkmanager.enable = true;
            systemd.services.workshop-wifi = {
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              script = ''
                ${pkgs.networkmanager}/bin/nmcli dev wifi connect "CODE_CRISPIES_GUEST" password "workshop2024" || true
              '';
            };
            services.getty.autologinUser = "workshop";
            users.users.workshop = { isNormalUser = true; shell = pkgs.zsh; };
            programs.zsh = {
              enable = true;
              interactiveShellInit = ''
                echo "🍪 CODE CRISPIES Workshop Environment"
                connect() { ssh -o StrictHostKeyChecking=no workshop@$1.codecrispi.es; }
              '';
            };
            environment.systemPackages = with pkgs; [ openssh curl git networkmanager ];
            services.xserver = {
              enable = true;
              displayManager.lightdm.enable = true;
              desktopManager.xfce.enable = true;
            };
          })
        ];
      };

      # `nix run .#local-vm`
      local-vm = self.nixosConfigurations.workshop-local.config.system.build.vm;
    };

    # --------------------------------------------------------------------------------
    # 2. STANDALONE LOCAL DEVELOPMENT VM CONFIGURATION
    # --------------------------------------------------------------------------------
    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, ... }: {
          system.stateVersion = "25.05";
          boot.loader.grub.enable = false;
          boot.loader.generic-extlinux-compatible.enable = true;

          # Create a simple 'workshop' user with no password
          users.users.workshop = {
            isNormalUser = true;
            extraGroups = [ "wheel" ]; # for sudo
            password = "";
          };
          services.getty.autologinUser = "workshop";

          # Enable a lightweight desktop environment guaranteed to work in a VM
          services.xserver = {
            enable = true;
            displayManager.lightdm.enable = true;
            desktopManager.xfce.enable = true;
          };

          # Allow empty passwords for login and sudo
          security.pam.services.login.allowNullPassword = true;
          security.sudo.wheelNeedsPassword = false;

          networking.hostName = "workshop-vm";
          environment.systemPackages = with pkgs; [ gnumake nano nixos-container ];

          # Define all participant containers
          containers = builtins.listToAttrs (map (i:
            let participant = builtins.elemAt participantNames (i - 1);
            in {
              name = "participant${toString i}";
              value = {
                autoStart = true;
                privateNetwork = true;
                hostAddress = "192.168.100.1";
                localAddress = "192.168.100.${toString (10 + i)}";
                config = {
                  system.stateVersion = "25.05";
                  services.openssh.enable = true;
                  networking.hostName = participant;
                  virtualisation.docker.enable = true;
                  environment.systemPackages = with pkgs; [ docker git curl jq ];
                  systemd.services.workshop-setup = {
                     wantedBy = [ "multi-user.target" ];
                     after = [ "docker.service" ];
                     script = ''
                       # Docker Swarm and Abra setup
                       ${pkgs.docker}/bin/docker swarm init --advertise-addr 192.168.100.${toString (10 + i)} || true
                       ${pkgs.docker}/bin/docker network create -d overlay proxy || true
                       export HOME=/root
                       ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash
                       mkdir -p /root/.abra/servers
                       /root/.local/bin/abra server add ${participant}.local
                     '';
                     serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
                  };
                };
              };
            }
          ) (nixpkgs.lib.range 1 2));
          
          # DNS for containers
          services.dnsmasq = {
            enable = true;
            settings.address = builtins.concatMap (i:
              let participant = builtins.elemAt participantNames (i - 1);
              in [
                "/${participant}.local/192.168.100.${toString (10 + i)}"
                "/.${participant}.local/192.168.100.${toString (10 + i)}"
              ]
            ) (nixpkgs.lib.range 1 2);
          };
        })
      ];
    };
    
    # --------------------------------------------------------------------------------
    # 3. DEVELOPMENT SHELL (for your host machine)
    # --------------------------------------------------------------------------------
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        terraform
        nixos-rebuild
        docker
        openssh
      ];
    };
  };
}
