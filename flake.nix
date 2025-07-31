{
  description = "NixOS configurations for PC and Steam Deck";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/a79cfe0ebd24952b580b1cf08cd906354996d547";
    home-manager = {
      url = "github:nix-community/home-manager/5af1b9a0f193ab6138b89a8e0af8763c21bbf491";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, NixVirt, home-manager, jovian, ... }@inputs:
  let
    allSystems = [ "x86_64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs allSystems;
    lib = nixpkgs.lib;

    customIsoImages =
      let
        isoDir = ./iso;
        isoFiles = builtins.attrNames (builtins.readDir isoDir);
        isoNixFiles = builtins.filter (f: lib.hasSuffix ".nix" f) isoFiles;
      in lib.genAttrs (map (f: lib.removeSuffix ".nix" f) isoNixFiles) (name:
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (import "${isoDir}/${name}.nix" { pkgs = nixpkgs.legacyPackages.x86_64-linux; inherit nixpkgs; })
          ];
        }).config.system.build.isoImage
      );

  in
  {
    packages = forAllSystems (system:
      let
        pkgs-unfree = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        gs-launcher = import ./modules/scripts/gs-launcher.nix { pkgs = pkgs-unfree; };
      }
    );

    nixosConfigurations = {
      whitespace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self NixVirt customIsoImages; };
        modules = [
          ./hardware-configuration.nix
          ./variables.nix
          ./hosts/pc.nix
          home-manager.nixosModules.home-manager
          NixVirt.nixosModules.default
          ({ pkgs, ... }: {
            nixpkgs.overlays = [(final: prev: {
              gs-launcher = self.packages.${pkgs.system}.gs-launcher;
            })];
          })
          ./modules/common/user.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/graphics.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/common/podman.nix
          ./modules/common/home-manager.nix
          ./modules/common/virtualisation.nix
          ./modules/common/sway.nix
          ./modules/common/waybar.nix
          ./modules/common/mako.nix
	 ./modules/common/wireguard.nix
          ./modules/vms/vm-generator.nix
          ({ config, lib, pkgs, ... }: {
            home-manager.users.${config.variables.user.name} = {
              dconf.settings = {
                "org/virt-manager/virt-manager/connections" = {
                  autoconnect = [ "qemu:///system" ];
                  uris = [ "qemu:///system" ];
                };
              };
              xdg.configFile = lib.mkMerge [
                (import ./modules/common/podman-quadlet-volumes/ollama-data.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-volumes/open-webui-data.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-volumes/steamos-data.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-volumes/obsidian-config.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/ollama.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/openwebui.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/steamos.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/chromium.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/librewolf.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/obsidian.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/qbittorrentvpn.nix { inherit pkgs config lib; })
              ];
            };
          })
        ];
      };

      leviathan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self NixVirt customIsoImages jovian; };
        modules = [
          ./hardware-configuration.nix
          ./variables.nix
          ./hosts/steamdeck.nix
          home-manager.nixosModules.home-manager
          NixVirt.nixosModules.default
          jovian.nixosModules.default
          ./modules/common/unfree.nix
          ./modules/common/user.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/graphics.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/common/podman.nix
          ./modules/common/home-manager.nix
          ./modules/common/sway.nix
          ./modules/common/waybar.nix
          ./modules/common/bluetooth.nix
          ./modules/common/neovim.nix
          ./modules/common/mako.nix
          ./modules/common/virtualisation.nix
          ./modules/vms/vm-generator.nix
          ({ config, lib, pkgs, ... }: {
            home-manager.users.${config.variables.user.name}.xdg.configFile = lib.mkMerge [
              (import ./modules/common/podman-quadlet-definitions/librewolf.nix { inherit pkgs config lib; })
              (import ./modules/common/podman-quadlet-definitions/chromium.nix { inherit pkgs config lib; })
            ];
          })
        ];
      };

      headspace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          ./hardware-configuration.nix
          ./variables.nix
          ./hosts/m1.nix
          ./apple-silicon-support
          home-manager.nixosModules.home-manager
          NixVirt.nixosModules.default
          ./modules/common/unfree.nix
          ./modules/common/user.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/graphics.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/common/home-manager.nix
          ./modules/common/hyprland.nix
          ./modules/common/waybar.nix
          ./modules/common/bluetooth.nix
          ./modules/common/neovim.nix
          ./modules/common/mako.nix
        ];
      };
      krawlspace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          ./hardware-configuration.nix
          ./variables.nix
          ./hosts/torrent.nix
          home-manager.nixosModules.home-manager
          ./modules/common/user.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/common/home-manager.nix
          ./modules/common/bluetooth.nix
          ./modules/common/neovim.nix
          ./modules/common/podman.nix
          ({ config, lib, pkgs, ... }: {
      home-manager.users.${config.variables.user.name} = {
        xdg.configFile = lib.mkMerge [
          (import ./modules/common/podman-quadlet-definitions/qbittorrentvpn.nix { inherit pkgs config lib; })
        ];
      };
    })
             ];
      };

      browserspace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          ./hardware-configuration.nix
          ./variables.nix
          ./hosts/browser.nix
          home-manager.nixosModules.home-manager
          ./modules/common/user.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/common/home-manager.nix
          ./modules/common/bluetooth.nix
          ./modules/common/neovim.nix
          ./modules/common/podman.nix
          ({ config, lib, pkgs, ... }: {
            home-manager.users.${config.variables.user.name} = {
              xdg.configFile = lib.mkMerge [
                (import ./modules/common/podman-quadlet-definitions/librewolf.nix { inherit pkgs config lib; })
                (import ./modules/common/podman-quadlet-definitions/chromium.nix { inherit pkgs config lib; })
              ];
            };
          })
        ];
      };
    };
  };
}
