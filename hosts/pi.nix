# ./hosts/pi.nix
{ config, lib, pkgs, ... }:

{
  networking.hostName = config.variables.networking.hostname;


  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  # boot.loader.systemd-boot.enable = false;

  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "24.11";
}
