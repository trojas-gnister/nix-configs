{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    videoDrivers = [ "modesetting" ]; 
  };

  environment.gnome.excludePackages = (with pkgs; [
  ]);

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme 
    gnome-extension-manager
    gnomeExtensions.pop-shell
    gnomeExtensions.space-bar
    gnomeExtensions.vitals
    gnomeExtensions.blur-my-shell
  ];
  services.udev.packages = with pkgs; [ pkgs.gnome-settings-daemon ];


  hardware.sensor.iio.enable = true;

  home-manager.users.${config.variables.user.name} = {
    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      settings."org/gnome/shell" = {
        disable-user-extensions = false;
      };
    };
  };
}
