{ config, lib, pkgs, ... }:

let
  modKey = "Mod4";

  rotate-script-i3 = pkgs.writeShellScriptBin "rotate-i3" ''
    #!${pkgs.bash}/bin/bash

    TOUCHSCREEN_NAME=$(${pkgs.xorg.xinput}/bin/xinput list --name-only | ${pkgs.gnugrep}/bin/grep -i -m 1 'touchscreen\|touch screen\|fts_ts\|fts3528')

    if [ -z "$TOUCHSCREEN_NAME" ]; then
      echo "Touchscreen device not found." >&2
      ${pkgs.libnotify}/bin/notify-send -u critical "Rotation Error" "Touchscreen device not found."
      exit 1
    fi

    PRIMARY_OUTPUT=$(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep ' connected primary' | ${pkgs.gawk}/bin/awk '{print $1}')
    if [ -z "$PRIMARY_OUTPUT" ]; then
       PRIMARY_OUTPUT=$(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep ' connected' | ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.coreutils}/bin/head -n 1)
       if [ -z "$PRIMARY_OUTPUT" ]; then
         PRIMARY_OUTPUT="eDP-1"
       fi
    fi
    if [ -z "$PRIMARY_OUTPUT" ]; then
       echo "Error: Could not determine primary/connected output." >&2
       ${pkgs.libnotify}/bin/notify-send -u critical "Rotation Error" "Could not find connected output."
       exit 1
    fi


    CURRENT_ROTATION=$(${pkgs.xorg.xrandr}/bin/xrandr --query --verbose | ${pkgs.gnugrep}/bin/grep "$PRIMARY_OUTPUT" | ${pkgs.gnused}/bin/sed -n 's/.* \([a-z]*\) (\(normal\|inverted\|left\|right\) .*/\2/p' | ${pkgs.coreutils}/bin/head -n 1)

    TARGET_ROTATION="inverted"
    TARGET_MATRIX="-1 0 1 0 -1 1 0 0 1"

    case "$CURRENT_ROTATION" in
      normal)
        TARGET_ROTATION="right"
        TARGET_MATRIX="0 1 0 -1 0 1 0 0 1"
        ;;
      right)
        TARGET_ROTATION="inverted"
        TARGET_MATRIX="-1 0 1 0 -1 1 0 0 1"
        ;;
      inverted)
        TARGET_ROTATION="left"
        TARGET_MATRIX="0 -1 1 1 0 0 0 0 1"
        ;;
      left)
        TARGET_ROTATION="normal"
        TARGET_MATRIX="1 0 0 0 1 0 0 0 1"
        ;;
      *)
        echo "Unknown current rotation: $CURRENT_ROTATION. Setting to right (default)." >&2
        TARGET_ROTATION="right"
        TARGET_MATRIX="0 1 0 -1 0 1 0 0 1"
        ;;
    esac

    echo "Current: $CURRENT_ROTATION. Rotating to: $TARGET_ROTATION" >&2

    ${pkgs.xorg.xrandr}/bin/xrandr --output "$PRIMARY_OUTPUT" --rotate "$TARGET_ROTATION"

    ${pkgs.xorg.xinput}/bin/xinput set-prop "$TOUCHSCREEN_NAME" "Coordinate Transformation Matrix" $TARGET_MATRIX

    echo "Rotation complete." >&2
    ${pkgs.libnotify}/bin/notify-send "Screen Rotation" "Set to $TARGET_ROTATION"
  '';

  toggle-rofi-script = pkgs.writeShellScriptBin "toggle-rofi" ''
    #!${pkgs.bash}/bin/bash
    if ${pkgs.procps}/bin/pidof rofi > /dev/null; then
      ${pkgs.procps}/bin/pkill rofi
    else
      ${pkgs.rofi}/bin/rofi -show drun
    fi
  '';

  toggle-svkbd-script = pkgs.writeShellScriptBin "toggle-svkbd" ''
    #!${pkgs.bash}/bin/bash
    SVKBD_BIN="svkbd-mobile-intl"

    if ${pkgs.procps}/bin/pidof "$SVKBD_BIN" > /dev/null; then
      ${pkgs.procps}/bin/pkill "$SVKBD_BIN"
    else
      ${pkgs.svkbd}/bin/"$SVKBD_BIN" &
    fi
  '';

in
{
  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
    };
    desktopManager.xterm.enable = false;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
      ];
    };
    libinput.enable = true;
  };

  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    shadow = true;
    shadowOpacity = 0.75;
    fade = true;
    fadeDelta = 4;
    settings = {
      blur-background = true;
      blur-method = "dual_kawase";
      blur-strength = 5;
      blur-background-exclude = [
         "window_type = 'dock'"
         "window_type = 'desktop'"
         "_GTK_FRAME_EXTENTS@:c"
      ];
      corner-radius = 10;
    };
  };

  environment.systemPackages = with pkgs; [
    rotate-script-i3
    toggle-rofi-script
    toggle-svkbd-script
    xorg.xrandr
    xorg.xinput
    xorg.xprop
    arandr
    feh
    rofi
    dunst
    libnotify
    xautolock
    playerctl
    pavucontrol
    networkmanagerapplet
    blueman
    gnugrep
    gawk
    coreutils
    gnused
    procps
    svkbd
    polybarFull
  ];

  programs.dconf.enable = true;

  home-manager.users.${config.variables.user.name} = { pkgs, lib, config, ... }:
  let
    modKey = "Mod4";
  in
  {
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = modKey;
        terminal = "kitty";
        startup = [
          { command = ''${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --rotate right''; notification = false; always = true; }
          { command = ''TOUCHSCREEN_NAME=$(${pkgs.xorg.xinput}/bin/xinput list --name-only | ${pkgs.gnugrep}/bin/grep -i -m 1 'touchscreen\|touch screen\|fts_ts\|fts3528'); if [ -n "$TOUCHSCREEN_NAME" ]; then ${pkgs.xorg.xinput}/bin/xinput set-prop "$TOUCHSCREEN_NAME" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1; fi''; notification = false; always = true; }
          { command = "sleep 1 && pkill polybar"; notification = false; always = true; }
          { command = "sleep 2 && ${pkgs.polybarFull}/bin/polybar -c ${config.home.homeDirectory}/.config/polybar/config.ini example &"; notification = false; always = true; }
          { command = "sleep 2 && feh --bg-scale ${config.home.homeDirectory}/.config/wallpaper.png"; notification = false; always = true; }
          { command = "nm-applet --indicator"; notification = false; always = true; }
          { command = "blueman-applet"; notification = false; always = true; }
          { command = "dunst"; notification = false; always = true; }
          { command = "picom --config /dev/null"; notification = false; always = true; }
          { command = "numlockx on"; notification = false; always = true; }
          { command = "xautolock -time 10 -locker 'i3lock -c 000000' -notify 30 -notifier 'notify-send -u critical -t 10000 -- \"Locking screen in 30 seconds\"'"; notification = false; always = true; }
          { command = "kitty"; notification = false; always = true; }
        ];
        bars = [];
        gaps = {
          inner = 10;
          outer = 5;
        };
        keybindings = lib.mkOptionDefault {
          "${modKey}+Return" = "exec kitty";
          "${modKey}+d" = "exec toggle-rofi";
          "${modKey}+Shift+q" = "kill";
          "${modKey}+Shift+e" = "exec i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'";

          "${modKey}+h" = "focus left";
          "${modKey}+j" = "focus down";
          "${modKey}+k" = "focus up";
          "${modKey}+l" = "focus right";

          "${modKey}+Left" = "focus left";
          "${modKey}+Down" = "focus down";
          "${modKey}+Up" = "focus up";
          "${modKey}+Right" = "focus right";

          "${modKey}+Shift+h" = "move left";
          "${modKey}+Shift+j" = "move down";
          "${modKey}+Shift+k" = "move up";
          "${modKey}+Shift+l" = "move right";

          "${modKey}+Shift+Left" = "move left";
          "${modKey}+Shift+Down" = "move down";
          "${modKey}+Shift+Up" = "move up";
          "${modKey}+Shift+Right" = "move right";

          "${modKey}+f" = "fullscreen toggle";
          "${modKey}+Shift+space" = "floating toggle";
          "${modKey}+space" = "focus mode_toggle";

          "${modKey}+1" = "workspace number 1";
          "${modKey}+2" = "workspace number 2";
          "${modKey}+3" = "workspace number 3";
          "${modKey}+4" = "workspace number 4";
          "${modKey}+5" = "workspace number 5";
          "${modKey}+6" = "workspace number 6";
          "${modKey}+7" = "workspace number 7";
          "${modKey}+8" = "workspace number 8";
          "${modKey}+9" = "workspace number 9";
          "${modKey}+0" = "workspace number 10";

          "${modKey}+Shift+1" = "move container to workspace number 1";
          "${modKey}+Shift+2" = "move container to workspace number 2";
          "${modKey}+Shift+3" = "move container to workspace number 3";
          "${modKey}+Shift+4" = "move container to workspace number 4";
          "${modKey}+Shift+5" = "move container to workspace number 5";
          "${modKey}+Shift+6" = "move container to workspace number 6";
          "${modKey}+Shift+7" = "move container to workspace number 7";
          "${modKey}+Shift+8" = "move container to workspace number 8";
          "${modKey}+Shift+9" = "move container to workspace number 9";
          "${modKey}+Shift+0" = "move container to workspace number 10";

          "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "XF86AudioPlay" = "exec --no-startup-id playerctl play-pause";
          "XF86AudioNext" = "exec --no-startup-id playerctl next";
          "XF86AudioPrev" = "exec --no-startup-id playerctl previous";

          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

          "Print" = "exec --no-startup-id flameshot gui";
          "Shift+Print" = "exec --no-startup-id flameshot full -c";

          "${modKey}+Shift+x" = "exec i3lock -c 000000";

          "${modKey}+r" = "exec rotate-i3";
        };
        window = {
           border = 2;
           titlebar = false;
        };
      };
      extraConfig = ''
        for_window [class="^svkbd-mobile-intl$"] no_focus
      '';
    };
  };
}
