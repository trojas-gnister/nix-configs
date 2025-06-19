{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = { pkgs, ... }: {
    services.polybar = {
      enable = false;
      package = pkgs.polybarFull;
      config = {
        "bar/example" = {
          width = "100%";
          height = 30;
          background = "#AA2B303B";
          foreground = "#FFFFFF";
          border-bottom-size = 3;
          border-bottom-color = "#8064727D";
          padding = 1;
          module-margin-left = 1;
          module-margin-right = 1;
          font-0 = "Roboto:size=10;1";
          font-1 = "FontAwesome:size=10;1";
          modules-left = "i3";
          modules-center = "xwindow";
          modules-right = "custom-term custom-launcher custom-keyboard custom-rotate network cpu memory battery date tray";
          # tray-position = "right"; # Removed (use module/tray)
          # tray-padding = 2; # Removed (use module/tray)
        };

        "module/i3" = {
          type = "internal/i3";
          format = "<label-state> <label-mode>";
          index-sort = true;
          wrapping-scroll = false;
          label-mode-padding = 1;
          label-focused = "%index%";
          label-focused-background = "#64727D";
          label-focused-padding = 1;
          label-unfocused = "%index%";
          label-unfocused-padding = 1;
          label-visible = "%index%";
          label-visible-padding = 1;
          label-urgent = "%index%";
          label-urgent-background = "#eb4d4b";
          label-urgent-padding = 1;
        };

        "module/xwindow" = {
          type = "internal/xwindow";
          label = "%title:0:50:...%";
        };

        "module/custom-launcher" = {
          type = "custom/script";
          exec = "echo L"; # Plain Text
          click-left = "toggle-rofi";
          format = "%{A1:toggle-rofi:}<label>%{A}";
          format-prefix = " ";
          format-prefix-foreground = "#fff";
          format-underline = "#5c636e";
          format-padding = 1;
        };

        "module/custom-keyboard" = {
           type = "custom/script";
           exec = "echo K"; # Plain Text
           click-left = "toggle-svkbd";
           format = "%{A1:toggle-svkbd:}<label>%{A}";
           format-prefix = " ";
           format-prefix-foreground = "#fff";
           format-underline = "#5c636e";
           format-padding = 1;
         };

        "module/custom-term" = {
           type = "custom/script";
           exec = "echo T"; # Plain Text
           click-left = "kitty";
           format = "%{A1:kitty:}<label>%{A}";
           format-prefix = " ";
           format-prefix-foreground = "#fff";
           format-underline = "#5c636e";
           format-padding = 1;
         };

        "module/custom-rotate" = {
           type = "custom/script";
           exec = "echo R"; # Plain Text
           click-left = "rotate-i3";
           format = "%{A1:rotate-i3:}<label>%{A}";
           format-prefix = " ";
           format-prefix-foreground = "#fff";
           format-underline = "#5c636e";
           format-padding = 1;
        };

        "module/network" = {
          type = "internal/network";
          interface = "wlan0"; # Needs verification
          interval = 5;
          format-connected = "<label-connected>";
          format-disconnected = "Disconnected ⚠";
          label-connected = "%{A1:nm-connection-editor:}%essid% (%downspeed%/%upspeed%)%{A}";
          format-connected-underline = "#64727D";
          format-disconnected-underline = "#f53c3c";
          label-disconnected-foreground = "#fff";
        };

        "module/cpu" = {
          type = "internal/cpu";
          interval = 2;
          # format = "<label> %{T2}%{T-}"; # Temporarily use text
          format = "CPU <label>";
          label = "%percentage:2%%";
          format-underline = "#64727D";
        };

        "module/memory" = {
          type = "internal/memory";
          interval = 2;
          # format = "<label> %{T2}%{T-}"; # Temporarily use text
          format = "MEM <label>";
          label = "%percentage_used:2%%";
          format-underline = "#64727D";
        };

        "module/battery" = {
          type = "internal/battery";
          battery = "BAT0"; # Needs verification
          adapter = "AC"; # Needs verification
          full-at = 98;
          poll-interval = 5;
          format-charging = "CHR <label-charging>"; # Text instead of animation
          format-discharging = "BAT <label-discharging>"; # Text instead of ramp
          format-full = "FULL <label-full>";
          label-charging = "%percentage%%";
          label-discharging = "%percentage%%";
          label-full = "%percentage%%";
          # ramp-capacity-0 = ""; # Removed Font Icons
          # ramp-capacity-1 = "";
          # ramp-capacity-2 = "";
          # ramp-capacity-3 = "";
          # ramp-capacity-4 = "";
          # animation-charging-0 = ""; # Removed Font Icons
          # animation-charging-1 = "";
          # animation-charging-2 = "";
          # animation-charging-3 = "";
          # animation-charging-4 = "";
          # animation-charging-framerate = 750;
          format-charging-underline = "#26A65B";
          format-discharging-underline = "#64727D";
          format-full-underline = "#64727D";
        };

        "module/date" = {
          type = "internal/date";
          interval = 1;
          date = "%I:%M %p";
          date-alt = "%Y-%m-%d";
          label = "%date%";
          format-underline = "#64727D";
        };

        "module/tray" = {
          type = "internal/tray";
          # Add tray settings here if needed, e.g.:
          # tray-padding = 2;
        };

        "settings" = {
          screenchange-reload = true;
        };
      };
    };
  };
}
