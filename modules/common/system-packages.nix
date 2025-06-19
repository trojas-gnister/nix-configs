{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs;
    lib.lists.map (pname: lib.getAttr pname pkgs) config.variables.packages.system;
}
