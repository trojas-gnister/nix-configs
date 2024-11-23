{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dev";
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    git
    xclip
    python3
    gcc
    tmux
    rustup
    nodejs_22
  ];

  system.stateVersion = "24.05";
}
