# --- File: ./modules/common/gnome.nix ---
{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.space-bar
    gnomeExtensions.pop-shell
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.toggle-between-two-display-orientations
    gnome-extension-manager
    gnome-tweaks
    ibus
  ];

  services.udev.packages = with pkgs; [
     gnome-settings-daemon
  ];

  hardware.sensor.iio.enable = true;

  programs.dconf.enable = true;

  home-manager.users.${config.variables.user.name} = { pkgs, lib, ... }: {
    dconf.settings = {
      "org/gnome/shell" = {
         enabled-extensions = [
           "pop-shell@system76.com"
           "blur-my-shell@aunetx"
           "space-bar@luchrioh"
	   "toggle-two-orientations@rotopenguin.net"
         ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        natural-scroll = true;
      };
    };
  };
}
