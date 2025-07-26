### ./modules/common/hyprland.nix

{ config, lib, pkgs, inputs ? {}, ... }:
{
  services.xserver = {
    enable = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = config.variables.user.name;
  };

  services.displayManager.sddm.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    waybar
    wvkbd
    wofi
    swaylock
    hyprpaper
    libinput
    grim
    slurp
    wl-clipboard
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
          "eDP-1,preferred,auto,1" # Set laptop screen to normal (0 degrees)
          ",preferred,auto,1"      # Fallback for any other connected monitor
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
            # transform is 0 by default, which now matches the screen
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
          "float,class:(pavucontrol)"
          "float,class:(blueman-manager)"
          "float,class:(nm-connection-editor)"
        ];

        "exec-once" = [
          "waybar"
          "hyprpaper"
        ];

        bind = [
          "$mainMod, Return, exec, kitty"
          "$mainMod, d, exec, wofi --show drun"
          "$mainMod SHIFT, q, killactive,"
          "$mainMod SHIFT, e, exit,"
          "$mainMod, f, fullscreen, 0"
          "$mainMod SHIFT, space, togglefloating,"
          "$mainMod, h, movefocus, l"
          "$mainMod, j, movefocus, d"
          "$mainMod, k, movefocus, u"
          "$mainMod, l, movefocus, r"
          "$mainMod, left, movefocus, l"
          "$mainMod, down, movefocus, d"
          "$mainMod, up, movefocus, u"
          "$mainMod, right, movefocus, r"
          "$mainMod SHIFT, h, movewindow, l"
          "$mainMod SHIFT, j, movewindow, d"
          "$mainMod SHIFT, k, movewindow, u"
          "$mainMod SHIFT, l, movewindow, r"
          "$mainMod SHIFT, left, movewindow, l"
          "$mainMod SHIFT, down, movewindow, d"
          "$mainMod SHIFT, up, movewindow, u"
          "$mainMod SHIFT, right, movewindow, r"
          "$mainMod ALT, h, resizeactive, -20 0"
          "$mainMod ALT, j, resizeactive, 0 20"
          "$mainMod ALT, k, resizeactive, 0 -20"
          "$mainMod ALT, l, resizeactive, 20 0"
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"
          "$mainMod, minus, togglespecialworkspace, scratchpad"
          "$mainMod SHIFT, minus, movetoworkspace, special:scratchpad"
          "$mainMod, Tab, workspace, +1"
          "$mainMod SHIFT, Tab, workspace, -1"
          "$mainMod, b, togglesplit,"
          ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
          ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
          ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "SHIFT, Print, exec, grim - | wl-copy"
          "$mainMod, x, exec, swaylock"
          ", F1, exec, brightnessctl set 5%-"
          ", F2, exec, brightnessctl set +5%"
          ", F10, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
          ", F11, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
          ", F12, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
          "$mainMod, B, exec, kbd-backlight-toggle"
        ];
      };
    };
  };
}
