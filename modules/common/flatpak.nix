{ config, lib, pkgs, ... }:

{
services.flatpak.enable = true;

users.users.${config.variables.user.name} = {
  packages = with pkgs; 
    lib.lists.map (pname: lib.getAttr pname pkgs) config.variables.packages.flatpak;
};
}
