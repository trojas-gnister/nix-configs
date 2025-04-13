# flake.nix
{
  description = "NixOS configurations for PC and M1";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      whitespace = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./variables.nix
          ./hosts/pc.nix
          home-manager.nixosModules.home-manager
          ./modules/common/user.nix
          ./modules/common/xserver.nix
          ./modules/common/virtualisation.nix
          ./modules/common/home-manager.nix
          ./modules/common/networking.nix
          ./modules/common/audio.nix
          ./modules/common/firewall.nix
          ./modules/common/graphics.nix
          ./modules/common/ssh.nix
          ./modules/common/system-packages.nix
          ./modules/containers/podman
        ];
      };
    };
  };
}
