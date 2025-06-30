{ config, lib, pkgs, ... }:

{
  users.groups.container-devices = {};
  
  users.users.${config.variables.user.name} = {
    password = config.variables.user.password;
    isNormalUser = true;
    extraGroups = config.variables.user.groups ++ [ "container-devices" ];
  };

  services.udev.extraRules = ''
    KERNEL=="dri/*", GROUP="container-devices", MODE="0660"
    KERNEL=="renderD*", GROUP="container-devices", MODE="0660"
    KERNEL=="uinput", GROUP="container-devices", MODE="0660"
    KERNEL=="input/*", GROUP="container-devices", MODE="0660"
  '';

  programs.git.enable = true;
}
