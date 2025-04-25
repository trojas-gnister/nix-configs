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
          
          modules-left = [
            "hyprland/workspaces"
            "hyprland/mode"
          ];
          
          modules-center = [
            "hyprland/window"
          ];
          
          modules-right = [
	    "custom/term"
            "custom/launcher"
            "custom/keyboard"
            "network"
            "cpu"
            "memory"
            "battery"
            "clock"
            "tray"
          ];
          
          "hyprland/workspaces" = {
            "disable-scroll" = false;
            "all-outputs" = true;
            "format" = "{name}";
            "format-icons" = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "urgent" = "";
              "focused" = "";
              "default" = "";
            };
          };
          
          "hyprland/mode" = {
            "format" = "<span style=\"italic\">{}</span>";
          };
          
          "hyprland/window" = {
            "format" = "{title}";
            "max-length" = 50;
          };
          
          "custom/launcher" = {
            "format" = "☰";
            "tooltip" = "Applications";
            "on-click" = "pkill wofi || wofi --show drun";
          };
          
          "custom/keyboard" = {
            "format" = "⌨";
            "tooltip" = "Toggle virtual keyboard";
            "on-click" = "pkill -x wvkbd-mobintl || wvkbd-mobintl -L 500";
          };
         
	 "custom/term" = {
	   "format" = "🖥️";
	   "tooltip" = "Launch terminal";
	   "on-click" = "kitty";


	 };


          "network" = {
            "format-wifi" = "{essid} ({signalStrength}%) ";
            "format-ethernet" = "{ipaddr}/{cidr} ";
            "tooltip-format" = "{ifname} via {gwaddr} ";
            "format-linked" = "{ifname} (No IP) ";
            "format-disconnected" = "Disconnected ⚠";
            "format-alt" = "{ifname}: {ipaddr}/{cidr}";
          };
          
          "cpu" = {
            "format" = "{usage}% ";
            "tooltip" = false;
          };
          
          "memory" = {
            "format" = "{}% ";
          };
          
          "battery" = {
            "states" = {
              "good" = 95;
              "warning" = 30;
              "critical" = 15;
            };
            "format" = "{capacity}% {icon}";
            "format-charging" = "{capacity}% ";
            "format-plugged" = "{capacity}% ";
            "format-alt" = "{time} {icon}";
            "format-icons" = ["" "" "" "" ""];
          };
          
          "clock" = {
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format" = "{:%I:%M %p}";
            "format-alt" = "{:%Y-%m-%d}";
          };
          
          "tray" = {
            "spacing" = 10;
          };
        };
      };
      
      style = ''
        * {
          /* "Noto Sans" */
          font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif;
          font-size: 13px;
        }

        window#waybar {
          background-color: rgba(43, 48, 59, 0.8);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        button {
          /* Use box-shadow instead of border so the text isn't offset */
          box-shadow: inset 0 -3px transparent;
          /* Avoid rounded borders under each button name */
          border: none;
          border-radius: 0;
        }

        /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
        button:hover {
          background: inherit;
          box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.focused {
          background-color: #64727D;
          box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button.urgent {
          background-color: #eb4d4b;
        }

        #mode {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
        }

        #custom-launcher {
          padding: 0 10px;
          color: #ffffff;
          background-color: #5c636e;
        }

        #custom-launcher:hover {
          background-color: #3f4753;
          box-shadow: inset 0 -3px #ffffff;
        }

        #custom-keyboard {
          padding: 0 10px;
          color: #ffffff;
          background-color: #64727D;
        }

        #custom-keyboard:hover {
          background-color: #505b66;
          box-shadow: inset 0 -3px #ffffff;
        }



        #custom-term {                                                          padding: 0 10px;
          color: #ffffff;
          background-color: #64727D;                                          }
                                                                              #custom-term:hover {
          background-color: #505b66;
          box-shadow: inset 0 -3px #ffffff;
        }


        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #wireplumber,
        #custom-media,
        #tray,
        #mode,
        #idle_inhibitor,
        #scratchpad,
        #mpd {
          padding: 0 10px;
          color: #ffffff;
        }

        #window,
        #workspaces {
          margin: 0 4px;
        }

        /* If workspaces is the leftmost module, omit left margin */
        .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
        }

        /* If workspaces is the rightmost module, omit right margin */
        .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
        }

        #clock {
          background-color: #64727D;
        }

        #battery {
          background-color: #ffffff;
          color: #000000;
        }

        #battery.charging, #battery.plugged {
          color: #ffffff;
          background-color: #26A65B;
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }

        #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        label:focus {
          background-color: #000000;
        }

        #cpu {
          background-color: #2ecc71;
          color: #000000;
        }

        #memory {
          background-color: #9b59b6;
        }

        #disk {
          background-color: #964B00;
        }

        #network {
          background-color: #2980b9;
        }

        #network.disconnected {
          background-color: #f53c3c;
        }

        #tray {
          background-color: #2980b9;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
        }
      '';
    };
    
    # Ensure font-awesome is available for icons
    home.packages = with pkgs; [
      font-awesome
    ];
  };
}
