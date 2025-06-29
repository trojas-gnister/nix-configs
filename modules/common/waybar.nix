{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = { pkgs, ... }: {
    programs.waybar = {
      enable = true;
      package = pkgs.waybar.override { swaySupport = true; };
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;

          modules-left = [ "sway/workspaces" "sway/mode" ];
          modules-center = [ "sway/window" ];

          modules-right = [

            "custom/term"
            "custom/launcher"
            "cpu"
            "memory"
            "battery"
            "clock"
            "tray"
          ] ++ ( if config.variables.steamdeck.handheld.enable then [            "custom/rotate" "custom/keyboard" ] else []);


          "sway/workspaces" = {
            disable-scroll = false;
            all-outputs = true;
            format = "[{name}]";
            format-icons = {
              "1" = "[1]"; "2" = "[2]"; "3" = "[3]"; "4" = "[4]"; "5" = "[5]";
              "urgent" = "[!]";
              "focused" = "[*]";
              "default" = "[ ]";
            };
          };

          "sway/mode".format = "<span style=\"italic\">{}</span>";
          "sway/window".format = "{title}";
          "sway/window".max-length = 50;

          "custom/launcher" = {
            type = "custom/script";
            exec = "echo MENU";
            on-click = "toggle-rofi";
          };
          "custom/keyboard" = {
            type = "custom/script";
            exec = "echo KB";
            on-click = "pkill -x wvkbd-mobintl || ${pkgs.wvkbd}/bin/wvkbd-mobintl -H 600 -L 400 &";
          };
          "custom/term" = {
            type = "custom/script";
            exec = "echo TERM";
            on-click = "kitty";
          };
          "custom/rotate" = {
            type = "custom/script";
            exec = "echo ROT";
            on-click = "rotate-sway";
          };

          "cpu" = {
            interval = 2;
            format = "CPU {usage}%";
          };
          "memory" = {
            interval = 5;
            format = "MEM {percentage}%";
          };
          "battery" = {
            battery = "BAT0";
            adapter = "AC";
            full-at = 98;
            poll-interval = 5;
            format-charging = "BAT {capacity}%";
            format-discharging = "BAT {capacity}%";
            format-full = "BAT {capacity}%";
          };
          "clock" = {
            interval = 1;
            format = "TIME {:%I:%M %p}";
            format-alt = "DATE {:%Y-%m-%d}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
          "tray".spacing = 10;
        };
      };

      style = ''
        * {
          font-family: monospace;
          font-size: 12px;
        }
        window#waybar {
          background-color: #1e1e2e;
          border-bottom: 3px solid #44475a;
          color: #f8f8f2;
        }
        button { border: none; border-radius: 0; }
        #workspaces button { padding: 0 5px; background: transparent; color: #f8f8f2; }
        #workspaces button.focused { background-color: #44475a; }
        #workspaces button.urgent { background-color: #ff5555; }
        #mode { background-color: #6272a4; }

        #custom-launcher, #custom-keyboard, #custom-term, #custom-rotate {
          padding: 0 10px;
          background-color: #44475a;
        }

        #clock, #battery, #cpu, #memory, #tray {
          padding: 0 10px;
          background-color: #44475a;
        }

        #battery.charging {
          background-color: #50fa7b;
          color: #000000;
        }
        #battery.critical:not(.charging) {
          background-color: #ff5555;
          animation: blink 0.5s linear infinite alternate;
        }
        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }
      '';
    };

    home.packages = with pkgs; [
      procps
      wvkbd
    ];
  };
}
