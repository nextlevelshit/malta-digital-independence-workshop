{
  description = "Local Co-op Cloud Testing";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosConfigurations.workshop-local = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          containers = builtins.listToAttrs (map (i: 
            let participant = builtins.elemAt [
              "hopper" "curie" "lovelace" "noether" "hamilton"
              "franklin" "johnson" "clarke" "goldberg" "liskov" 
              "wing" "rosen" "shaw" "karp" "rich"
            ] (i - 1);
            in {
              name = "participant${toString i}";
              value = {
                autoStart = true;
                privateNetwork = true;
                hostAddress = "192.168.100.1";
                localAddress = "192.168.100.${toString (10 + i)}";
                
                config = { pkgs, ... }: {
                  virtualisation.docker = {
                    enable = true;
                    extraOptions = "--experimental";
                  };
                  
                  # Install abra + setup
                  environment.systemPackages = with pkgs; [
                    docker
                    git
                    curl
                    (stdenv.mkDerivation {
                      pname = "abra";
                      version = "latest";
                      src = fetchurl {
                        url = "https://git.autonomic.zone/coop-cloud/abra/releases/latest/download/abra-x86_64-unknown-linux-gnu";
                        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update with real hash
                      };
                      installPhase = "install -D $src $out/bin/abra";
                    })
                  ];
                  
                  systemd.services.workshop-setup = {
                    wantedBy = [ "multi-user.target" ];
                    after = [ "docker.service" ];
                    script = ''
                      # Docker swarm
                      ${pkgs.docker}/bin/docker swarm init --advertise-addr 192.168.100.${toString (10 + i)} || true
                      ${pkgs.docker}/bin/docker network create -d overlay proxy || true
                      
                      # Abra server setup
                      mkdir -p /root/.abra/servers
                      echo "${participant}.local" > /root/.abra/servers/${participant}.local/server.conf
                    '';
                  };
                  
                  services.openssh.enable = true;
                  networking = {
                    firewall.allowedTCPPorts = [ 22 80 443 ];
                    hostName = "${participant}-local";
                  };
                };
              };
            }
          ) (nixpkgs.lib.range 1 15));
          
          # DNS for *.local domains
          services.dnsmasq = {
            enable = true;
            settings.address = builtins.concatMap (i: [
              "/participant${toString i}.local/192.168.100.${toString (10 + i)}"
              "/wp.participant${toString i}.local/192.168.100.${toString (10 + i)}"
              "/nextcloud.participant${toString i}.local/192.168.100.${toString (10 + i)}"
            ]) (nixpkgs.lib.range 1 15);
          };
        }
      ];
    };
  };
}
