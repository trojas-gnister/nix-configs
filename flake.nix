# TODO: break into flakes
# TODO: create USB VM functionality
# TODO: use one config and programmaticaly add modules based on user input from python script
# TODO: finish resolving variable importing 

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: let
    variables = import ./variables.nix; 
  in {
    nixosConfigurations = {

      whitespace = nixpkgs.lib.nixosSystem {
        system = variables.architecture;
        modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
          (import ./host-config.nix { 
            userName = variables.userName; 
            homeStateVersion = variables.homeStateVersion;
          })
          (import ./display-configuration.nix {
            userName = variables.userName;
          })
          ./pipewire-configuration.nix  
          ./openssh-configuration.nix 
          home-manager.nixosModules.home-manager
          {
            boot = {
              loader = {
                systemd-boot.enable = true;
                efi.canTouchEfiVariables = true;
              };
              kernelModules = [ "kvm" "kvm_intel" ];
              kernelParams = [
                "intel_iommu=on"
                "iommu=pt"
                "isolcpus=2=25"
                "nohz_full=2-25"
                "rcu_nocbs=2-25"
              ];
              initrd = {
                kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
              };
              extraModprobeConfig = ''
                options vfio-pci ids=10de:2484,10de:228b,144d:a808,8086:0094,8086:15f3
              '';
              blacklistedKernelModules = [
                "nouveau"
                "nvidia"
                "nvidia_drm"
                "nvidia_modeset"
              ];
            };

            hardware.opengl.enable = true;

            networking = {
              hostName = variables.hostName;
              firewall.allowedTCPPorts = [ 48010 47984 ];
              firewall.allowedUDPPorts = [ 48010 48000 47998 ];
            };
          }
        ];
      };

      headspace = nixpkgs.lib.nixosSystem {
        system = variables.architecture;
        modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
         (import ./host-config.nix { 
            userName = variables.userName; 
            homeStateVersion = variables.homeStateVersion;
          })
          (import ./display-configuration.nix {
            userName = variables.userName;
          })
          ./pipewire-configuration.nix           
          ./openssh-configuration.nix  
          home-manager.nixosModules.home-manager
          {
            imports = [
              ./apple-silicon-support
            ];

            boot = {
              loader = {
                systemd-boot.enable = true;
                efi.canTouchEfiVariables = false;
              };
              kernelParams = [ "isolcpus=6,7" ];
            };

            hardware = {
              asahi.peripheralFirmwareDirectory = ./firmware;
              graphics.enable = true;
            };

            networking = {
              hostName = variables.hostName;
            };
          }
        ];
      };

      leviathan = nixpkgs.lib.nixosSystem {
        system = variables.architecture;
        modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
         (import ./display-configuration.nix {
          userName = variables.userName;
        })
        (import ./gaming-config.nix {
          userName = variables.userName;
          dataDevice = variables.dataDevice;
        })
          ./pipewire-configuration.nix  
          ./openssh-configuration.nix 
          home-manager.nixosModules.home-manager
          {
            networking = {
              hostName = variables.hostName;
            };
          }
        ];
      };
      browsing = nixpkgs.lib.nixosSystem {
        system = variables.architecture; 
        modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
         (import ./display-configuration.nix {
          userName = variables.userName;
        })
          ./librewolf-flake.nix
          ./chromium-flake.nix
          ./pipewire-configuration.nix  
          ./openssh-configuration.nix 
        {
          networking = {
            hostName = variables.hostName;
          };

        } 
        ];
      };
      torrent = nixpkgs.lib.nixosSystem {
        system = variables.architecture;
       modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
         (import ./display-configuration.nix {
          userName = variables.userName;
        })
          ./applications/librewolf.nix
          ./applications/qbittorrent.nix
          ./applications/vpn.nix
          ./pipewire-configuration.nix  
          ./openssh-configuration.nix 
        {
          networking = {
            hostName = variables.hostName;
          };

        } 
        ];

      };
      jellyfin = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          (import ./shared-configuration.nix {
            userName = variables.userName;
            hostName = variables.hostName;
            stateVersion = variables.stateVersion;
          })
          {
            boot = {
              loader = {
                grub = {
                  enable = true;
                  version = 2;
                  devices = [ "nodev" ];   
                };
              };
            };
            networking = {
              hostName = variables.hostName;
            };
            services = {
              jellyfin = {
                enable = true;
                openFirewall = true;
              };
            };
          }
        ];
      };

    };
  };
}

