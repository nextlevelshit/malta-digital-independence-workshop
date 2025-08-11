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
    # You can change the range here for local development (e.g., 1 2)
    participantRange = nixpkgs.lib.range 1 2;
    fullParticipantNames = [
      "hopper" "curie" "lovelace" "noether" "hamilton"
      "franklin" "johnson" "clarke" "goldberg" "liskov"
      "wing" "rosen" "shaw" "karp" "rich"
    ];
  in
  {
    packages.${system} = {
      live-iso = nixos-generators.nixosGenerate {
        inherit system;
        format = "iso";
        modules = [
          ({ pkgs, ... }: {
            system.stateVersion = "25.05";
            networking.networkmanager.enable = true;
            users.users.workshop = { isNormalUser = true; shell = pkgs.zsh; };
            # Use generic autologin for the live ISO TTY
            services.getty.autologinUser = "workshop";
            programs.zsh.enable = true;
            environment.systemPackages = with pkgs; [ openssh curl git ];
            services.xserver = {
              enable = true;
              displayManager.lightdm.enable = true;
              desktopManager.xfce.enable = true;
            };
          })
        ];
      };
      local-vm = self.nixosConfigurations.workshop-local.config.system.build.vm;
    };

    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, ... }: {
          system.stateVersion = "25.05";
          boot.loader.grub.enable = false;
          boot.loader.generic-extlinux-compatible.enable = true;

          users.users.workshop = {
            isNormalUser = true;
            extraGroups = [ "wheel" ]; # for sudo
            password = "";
          };
          
          # --- THIS IS THE CORRECTED SECTION ---
          services.xserver = {
            enable = true;
            desktopManager.xfce.enable = true;
            displayManager.lightdm.enable = true;
          };
          # Use the generic, documented options for graphical autologin
          services.displayManager.autoLogin.enable = true;
          services.displayManager.autoLogin.user = "workshop";


          environment.systemPackages = with pkgs; [ gnumake nano nixos-container firefox ];
          security.pam.services.login.allowNullPassword = true;
          security.sudo.wheelNeedsPassword = false;
          networking.hostName = "workshop-vm";

          containers = builtins.listToAttrs (map (i:
            let participant = builtins.elemAt fullParticipantNames (i - 1);
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
                       export HOME=/root;
                       ${pkgs.docker}/bin/docker swarm init --advertise-addr 192.168.100.${toString (10 + i)} || true;
                       ${pkgs.curl}/bin/curl -fsSL https://install.abra.coopcloud.tech | ${pkgs.bash}/bin/bash;
                       /root/.local/bin/abra server add ${participant}.local;
                     '';
                     serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
                  };
                };
              };
            }
          ) participantRange);
          
          services.dnsmasq = {
            enable = true;
            settings.address = builtins.concatMap (i:
              let participant = builtins.elemAt fullParticipantNames (i - 1);
              in [ "/${participant}.local/192.168.100.${toString (10 + i)}" ]
            ) participantRange;
          };
        })
      ];
    };
    
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
