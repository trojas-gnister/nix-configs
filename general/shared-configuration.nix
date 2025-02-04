{ userName, hostName, stateVersion }:
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/Chicago";
  users.users = {
    "${userName}"
   = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "audio" ];
    packages = with pkgs; [
      git
      python3
      kitty
    ];
  };
};

  programs = {
    dconf.enable = true;
  };

  # Read the docs
  system.stateVersion = stateVersion;
}

