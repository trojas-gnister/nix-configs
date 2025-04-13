# modules/common/user.nix
{ config, lib, pkgs, ... }:

{
  users.users.${config.variables.user.name} = {
    isNormalUser = true;
    extraGroups = config.variables.user.groups;
    packages = with pkgs; [
      neovim
      tmux
      wl-clipboard
      btop
      qemu
      virt-manager
      wget
      moonlight-qt
      dconf
      lunarvim
      brightnessctl
    ];
  };

  programs.git.enable = true;
}
