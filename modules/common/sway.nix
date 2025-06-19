{ config, lib, pkgs, ... }:

let
  modKey = "Mod4";

  rotate-script-sway = pkgs.writeShellScriptBin "rotate-sway" ''
    #!${pkgs.bash}/bin/bash
    PRIMARY_OUTPUT=$(${pkgs.sway}/bin/swaymsg -t get_outputs -r | \
                      ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name // select(.active) | .name' | \
                      ${pkgs.coreutils}/bin/head -n 1)

    if [ -z "$PRIMARY_OUTPUT" ]; then
      PRIMARY_OUTPUT="eDP-1"
    fi

    if [ -z "$PRIMARY_OUTPUT" ]; then
      echo "Error: Could not determine a primary, active, or fallback output (eDP-1)." >&2
      ${pkgs.libnotify}/bin/notify-send -u critical "Rotation Error" "Could not find a valid output to rotate."
      exit 1
    fi

    CURRENT_TRANSFORM=$(${pkgs.sway}/bin/swaymsg -t get_outputs -r | \
                          ${pkgs.jq}/bin/jq --raw-output ".[] | select(.name == \"$PRIMARY_OUTPUT\") | .transform")

    NEXT_DEGREE=""

    case "$CURRENT_TRANSFORM" in
      "90" | "flipped-90")
        NEXT_DEGREE=180
        ;;
      "180" | "flipped-180")
        NEXT_DEGREE=90
        ;;
      "normal" | "flipped" | "270" | "flipped-270" | *)
        echo "Current transform is '$CURRENT_TRANSFORM'. Setting to 90 degrees as the initial step in the 90/180 cycle." >&2
        NEXT_DEGREE=90
        ;;
    esac

    echo "Current transform: $CURRENT_TRANSFORM. Rotating output '$PRIMARY_OUTPUT' to $NEXT_DEGREE degrees." >&2
    ${pkgs.sway}/bin/swaymsg output "$PRIMARY_OUTPUT" transform "$NEXT_DEGREE"

    echo "Rotation command sent." >&2
    ${pkgs.libnotify}/bin/notify-send "Screen Rotation" "Output '$PRIMARY_OUTPUT' set to $NEXT_DEGREE degrees"
  '';

  toggle-rofi-script = pkgs.writeShellScriptBin "toggle-rofi" ''
if ${pkgs.procps}/bin/pidof rofi > /dev/null; then
  ${pkgs.procps}/bin/pkill rofi
else
  ${pkgs.rofi-wayland}/bin/rofi -show drun
fi
'';

in
{
  services.xserver.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      settings.Autologin = {
        User = config.variables.user.name;
        Session = "sway.desktop";
      };
    };
    sessionPackages = [ pkgs.sway ];
  };
  services.xserver.desktopManager.xterm.enable = false;

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    rotate-script-sway
    toggle-rofi-script
    jq
    libnotify
    procps
    wvkbd
  ];

  home-manager.users.${config.variables.user.name} = { pkgs, lib, config, ... }: {

    home.packages = with pkgs; [
      swayidle
      swaybg
      rofi-wayland
      wl-clipboard
      grim
      slurp
      wf-recorder
      wdisplays
      waybar
      wvkbd
    ];

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
      };

      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM=wayland
        export XDG_CURRENT_DESKTOP=sway
      '';

      config = rec {
        modifier = modKey;
        terminal = "${pkgs.kitty}/bin/kitty";
        menu = "${pkgs.rofi-wayland}/bin/rofi -show drun";

        bars = [];
        colors = {
          focused = {
            border = "#6272a4";
            background = "#44475a";
            text = "#f8f8f2";
            indicator = "#ffb86c";
            childBorder = "#6272a4";
          };
          unfocused = {
            border = "#282a36";
            background = "#282a36";
            text = "#6272a4";
            indicator = "#44475a";
            childBorder = "#282a36";
          };
          urgent = {
            border = "#ff5555";
            background = "#ff5555";
            text = "#f8f8f2";
            indicator = "#ff5555";
            childBorder = "#ff5555";
          };
        };
        output = {
          "eDP-1" = {
            transform = "90";
            resolution = "1080x1920";
            scale = "1";
          };
        };

        input = {
          "*" = { xkb_layout = "us"; };
          "type:touchpad" = { natural_scroll = "enabled"; tap = "enabled"; };
          "type:touch" = { map_to_output = "eDP-1"; };
        };

        gaps = {
          inner = 5;
          outer = 3;
          smartBorders = "on";
        };

        keybindings = lib.mkOptionDefault ({
          "${modifier}+Return" = "exec ${terminal}";
          "${modifier}+d" = "exec toggle-rofi";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+Shift+e" = "exec ${pkgs.sway}/bin/swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit Sway? This will end your Wayland session.' -B 'Yes, exit Sway' 'swaymsg exit'";
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";
          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Down" = "move down";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Right" = "move right";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+Shift+space" = "floating toggle";
          "${modifier}+space" = "focus mode_toggle";
          "${modifier}+1" = "workspace number 1";
          "${modifier}+2" = "workspace number 2";
          "${modifier}+3" = "workspace number 3";
          "${modifier}+4" = "workspace number 4";
          "${modifier}+5" = "workspace number 5";
          "${modifier}+6" = "workspace number 6";
          "${modifier}+7" = "workspace number 7";
          "${modifier}+8" = "workspace number 8";
          "${modifier}+9" = "workspace number 9";
          "${modifier}+0" = "workspace number 10";
          "${modifier}+Shift+1" = "move container to workspace number 1";
          "${modifier}+Shift+2" = "move container to workspace number 2";
          "${modifier}+Shift+3" = "move container to workspace number 3";
          "${modifier}+Shift+4" = "move container to workspace number 4";
          "${modifier}+Shift+5" = "move container to workspace number 5";
          "${modifier}+Shift+6" = "move container to workspace number 6";
          "${modifier}+Shift+7" = "move container to workspace number 7";
          "${modifier}+Shift+8" = "move container to workspace number 8";
          "${modifier}+Shift+9" = "move container to workspace number 9";
          "${modifier}+Shift+0" = "move container to workspace number 10";
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "Print" = "exec grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "Shift+Print" = "exec grim - | ${pkgs.wl-clipboard}/bin/wl-copy";
          "${modifier}+r" = "exec rotate-sway";
        });

        window = {
          border = 2;
          titlebar = false;
        };

        startup = [
          { command = "exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"; always = true; }
          { command = "exec ${pkgs.blueman}/bin/blueman-applet"; always = true; }
          { command = "exec ${pkgs.mako}/bin/mako"; always = true; }
          { command = "exec ${pkgs.waybar}/bin/waybar"; always = true; }
          { command = "exec ${pkgs.swaybg}/bin/swaybg -i ${config.home.homeDirectory}/Pictures/wallpaper.jpg -m fill"; always = true; }
        ];
      };

      extraConfig = ''
        for_window [class="wvkbd-mobintl"] floating enable
        for_window [app_id="librewolf"] fullscreen disable
        for_window [class="librewolf"] floating disable
        default_border pixel 2
      '';
    };
  };
}
