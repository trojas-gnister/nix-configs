{ config, lib, pkgs, inputs ? {}, ... }:
{
  services.xserver = {
    enable = true;
  };
  services.displayManager.sddm.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    waybar
    wvkbd
    wofi
    swaylock
    hyprpaper
    libinput
    wmctrl
    xdotool
  ];

  users.users.${config.variables.user.name}.extraGroups = [ "input" ];

  security.pam.services.swaylock = {};

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.${config.variables.user.name} = { pkgs, ... }: {
    wayland.windowManager.hyprland = {
      enable = true;

      plugins = [];

      settings = {
        monitor = [
          "eDP-1,preferred,auto,1, transform, 3"
	  ", preferred, auto,1"
        ];

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = true;
          };
          touchdevice = {
            output = "eDP-1";
            transform = 3;
          };
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
        };

        decoration = {
          rounding = 10;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
        };

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        "$mainMod" = "SUPER";

        windowrulev2 = [
          "float,class:(wofi)"
          "float,class:(wvkbd-mobintl)"
        ];

        "exec-once" = [
          "waybar"
          "hyprpaper"
        ];
      };
    };

    # programs.waybar = {
    #   enable = true;
    # };
  };
}
