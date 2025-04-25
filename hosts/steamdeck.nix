# hosts/steamdeck.nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ../hardware-configuration.nix
    ../variables.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-4fcd883e-4ad2-4c6e-8459-b74801d634ab".device = "/dev/disk/by-uuid/4fcd883e-4ad2-4c6e-8459-b74801d634ab";

  networking.hostName = config.variables.networking.leviathan.hostname;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "25.05";

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };


  services.displayManager.autoLogin = {
    enable = true;
    user = config.variables.user.name;
  };

  # # Keyd config
  # services.keyd.enable = true;
  # environment.etc."keyd/default.conf".text = ''
  #   [ids]
  #   *
  #
  #   [main]
  #   right = leftmeta
  # '';
  #
  environment.systemPackages = with pkgs; [
    librewolf
    moonlight-qt
    wvkbd
    brightnessctl
    kitty
    grim
    slurp
    mako
    wl-clipboard
    swaylock
    swayidle
    waybar
    keyd
    evtest
    wev
  ];
}
