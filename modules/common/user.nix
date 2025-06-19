{ config, lib, pkgs, ... }:

{
  users.groups.container-devices = {};

  users.users.${config.variables.user.name} = {
    isNormalUser = true;
    extraGroups = config.variables.user.groups ++ [ "container-devices" ];
    packages = with pkgs; [
      tmux
      btop
      brightnessctl
    ];
  };

  services.udev.extraRules = ''
    KERNEL=="dri/*", GROUP="container-devices", MODE="0660"
    KERNEL=="renderD*", GROUP="container-devices", MODE="0660"
    KERNEL=="uinput", GROUP="container-devices", MODE="0660"
    KERNEL=="input/*", GROUP="container-devices", MODE="0660"
  '';

  programs.git.enable = true;
}
