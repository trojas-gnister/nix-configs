# modules/common/system-packages.nix
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    waypipe
    vlc
    dmenu
    wl-clipboard
    kitty
    btop
    dmidecode
    pciutils
    xclip
    python3
    gcc
    tmux
    neovim
    wget
    virt-manager
    qemu
    qemu-utils
    moonlight-qt
    dconf
  ];
}
