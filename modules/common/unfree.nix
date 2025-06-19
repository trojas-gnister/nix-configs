{ config, lib, pkgs, self, ... }:

{
  nixpkgs.overlays = [(final: prev: {
    gs-launcher = self.packages.${pkgs.system}.gs-launcher;
  })];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.variables.packages.unfree;
}
