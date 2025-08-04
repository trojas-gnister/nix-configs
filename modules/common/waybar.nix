{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = { pkgs, ... }: {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;

          modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
          modules-center = [ "hyprland/window" ];

          modules-right = [
            "custom/term"
            "custom/launcher"
            "cpu"
            "memory"
            "battery"
            "clock"
            "tray"
          ] ++ ( if config.variables.steamdeck.handheld.enable then [            "custom/rotate" "custom/keyboard" ] else []);

          # Hyprland workspace configuration with simple text icons
          "hyprland/workspaces" = {
            disable-scroll = false;
            all-outputs = true;
            warp-on-scroll = false;
            format = "{name}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
              "urgent" = "!";
              "active" = "*";
              "default" = "•";
            };
            persistent-workspaces = {
              "1" = [];
              "2" = [];
              "3" = [];
              "4" = [];
              "5" = [];
            };
          };

          # Hyprland window title
          "hyprland/window" = {
            format = "{title}";
            max-length = 50;
            separate-outputs = true;
          };

          # Hyprland mode indicator
          "hyprland/mode" = {
            format = "<span style=\"italic\">{}</span>";
          };

          # Custom modules for application launching
          "custom/launcher" = {
            format = "MENU";
            tooltip = false;
            on-click = "wofi --show drun";
          };
          
          "custom/keyboard" = {
            format = "KB";
            tooltip = false;
            on-click = "pkill -x wvkbd-mobintl || ${pkgs.wvkbd}/bin/wvkbd-mobintl -H 600 -L 400 &";
          };
          
          "custom/term" = {
            format = "TERM";
            tooltip = false;
            on-click = "kitty";
          };
          
          "custom/rotate" = {
            format = "ROT";
            tooltip = false;
            on-click = "rotate-hyprland";
          };

          # System monitoring modules
          "cpu" = {
            interval = 2;
            format = "CPU {usage}%";
            tooltip = false;
          };
          
          "memory" = {
            interval = 5;
            format = "MEM {percentage}%";
            tooltip = false;
          };
          
          # Battery module
          "battery" = {
            bat = "BAT0";
            adapter = "AC";
            full-at = 98;
            interval = 5;
            states = {
              warning = 30;
              critical = 15;
            };
            format = "BAT {capacity}%";
            format-charging = "CHG {capacity}%";
            format-plugged = "AC {capacity}%";
            format-alt = "BAT {time}";
          };
          
          # Clock module
          "clock" = {
            interval = 1;
            format = "{:%H:%M}";
            format-alt = "{:%Y-%m-%d}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
          
          # System tray
          "tray" = {
            icon-size = 16;
            spacing = 10;
          };
        };
      };

      # Styling for waybar
      style = ''
        * {
          font-family: monospace;
          font-size: 12px;
          min-height: 0;
        }

        window#waybar {
          background-color: rgba(30, 30, 46, 0.8);
          border-bottom: 3px solid #6272a4;
          color: #f8f8f2;
          transition-property: background-color;
          transition-duration: .5s;
        }

        button {
          border: none;
          border-radius: 0;
        }

        button:hover {
          background: inherit;
          box-shadow: inset 0 -3px #f8f8f2;
        }

        /* Workspace styling */
        #workspaces {
          margin: 0 4px;
        }

        #workspaces button {
          padding: 0 8px;
          background-color: transparent;
          color: #f8f8f2;
          border-bottom: 3px solid transparent;
        }

        #workspaces button:hover {
          background: rgba(68, 71, 90, 0.8);
        }

        #workspaces button.active {
          background-color: #6272a4;
          border-bottom: 3px solid #50fa7b;
        }

        #workspaces button.urgent {
          background-color: #ff5555;
          color: #282a36;
        }

        /* Module styling */
        #mode,
        #window,
        #custom-launcher,
        #custom-keyboard,
        #custom-term,
        #custom-rotate,
        #clock,
        #battery,
        #cpu,
        #memory,
        #tray {
          padding: 0 10px;
          margin: 0 2px;
          background-color: rgba(68, 71, 90, 0.8);
          border-radius: 0;
        }

        #custom-launcher,
        #custom-keyboard,
        #custom-term,
        #custom-rotate {
          color: #bd93f9;
          font-weight: bold;
        }

        #custom-launcher:hover,
        #custom-keyboard:hover,
        #custom-term:hover,
        #custom-rotate:hover {
          background-color: rgba(189, 147, 249, 0.2);
        }

        #window {
          background-color: rgba(40, 42, 54, 0.8);
        }

        #clock {
          color: #8be9fd;
        }

        #battery {
          color: #50fa7b;
        }

        #battery.charging,
        #battery.plugged {
          color: #f1fa8c;
        }

        #battery.critical:not(.charging) {
          background-color: #ff5555;
          color: #282a36;
          animation: blink 0.5s linear infinite alternate;
        }

        #cpu {
          color: #ffb86c;
        }

        #memory {
          color: #ff79c6;
        }

        #tray {
          background-color: rgba(40, 42, 54, 0.8);
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #ff5555;
        }

        @keyframes blink {
          to {
            background-color: #f8f8f2;
            color: #282a36;
          }
        }
      '';
    };

    # Required packages for waybar functionality
    home.packages = with pkgs; [
      procps
      wvkbd
    ];

    # Start waybar as a systemd service
    systemd.user.services.waybar = {
      Unit = {
        Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };
    };
  };
}
