{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true;
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11";

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
  };
  
  boot = {
    kernelParams = [ "console=ttyS0,115200" ];
    
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";
      };
    };
  };
}
