{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [
    ./apple-silicon-support
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false; # Needed for Asahi
  };

  networking = {
    hostName = "headspace";
    networkmanager.enable = true;
  };

  time.timeZone = "America/Chicago";

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
  };

  users.users.iskry = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "audio" ];
    packages = with pkgs; [
      git
      python3
      kitty
    ];
  };

  home-manager.users.iskry = { pkgs, ... }: {
    home.stateVersion = "24.11";

    programs = {
      waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            output = [
              "eDP-1"
            ];
            modules-left = [ "sway/workspaces" "sway/mode" "custom/media" ];
            modules-center = [ "sway/window" ];
            modules-right = [
              "pulseaudio" "network" "backlight" "cpu" "memory" "battery"
              "battery#bat2" "clock" "tray"
            ];

            "sway/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };

            clock = {
              format = "{:%I:%M %p}";
              "format-alt" = "{:%Y-%m-%d}";
            };

            cpu = {
              format = "{usage}%";
            };

            memory = {
              format = "{}%";
            };

            temperature = {
              format = "{temperatureC}°C";
              "critical-threshold" = 80;
            };

            battery = {
              format = "{capacity}%";
              "format-charging" = "{capacity}% (charging)";
            };

            network = {
              "format-wifi" = "{essid} ({signalStrength}%)";
              "format-ethernet" = "{ifname}: {ipaddr}";
              "format-disconnected" = "Disconnected";
            };
          };
        };
        style = ''
          * {
            border: none;
            border-radius: 2px;
            font-family: "Roboto Mono Medium", Helvetica, Arial, sans-serif;
            font-size: 15px;
            min-height: 0;
          }

          window#waybar {
              background-color: rgba(0, 0, 0, 0.6);
              color: #ffffff;
          }

          #workspaces button {
              color: #ffffff;
              box-shadow: inset 0 -3px transparent;
          }

          #workspaces button:hover {
              background: rgba(0, 0, 0, 0.9);
              box-shadow: inset 0 -3px #ffffff;
          }

          #workspaces button.focused {
              background-color: rgba(0, 0, 0, 0.6);
          }

          #workspaces button.urgent {
              background-color: #eb4d4b;
          }

          #mode {
            background-color: rgba(0, 0, 0, 0.6);
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #temperature,
          #backlight,
          #network,
          #pulseaudio,
          #custom-media,
          #tray,
          #mode,
          #idle_inhibitor,
          #mpd {
              padding: 0 10px;
              margin: 6px 3px; 
              color: #000000;
          }

          #window,
          #workspaces {
              margin: 0 4px;
          }

          .modules-left > widget:first-child > #workspaces {
              margin-left: 0;
          }

          .modules-right > widget:last-child > #workspaces {
              margin-right: 0;
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #backlight,
          #network,
          #pulseaudio {
              background-color: rgba(0, 0, 0, 0.3);
              color: white;
              padding: 2px;	
          }

          #battery.charging {
              color: #ffffff;
              background-color: #000000;
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
              animation: blink 0.5s linear infinite alternate;
          }

          label:focus {
              background-color: #000000;
          }

          #network.disconnected {
              background-color: #f53c3c;
          }

          #custom-media {
              background-color: #66cc99;
              color: #2a5c45;
              min-width: 100px;
          }

          #custom-media.custom-vlc {
              background-color: #ffa000;
          }

          #temperature {
              background-color: #f0932b;
          }

          #temperature.critical {
              background-color: #eb4d4b;
          }

          #tray {
              background-color: #2980b9;
          }

          #idle_inhibitor {
              background-color: #2d3436;
          }

          #idle_inhibitor.activated {
              background-color: #ecf0f1;
              color: #2d3436;
          }

          #mpd {
              background-color: #66cc99;
              color: #2a5c45;
          }

          #mpd.disconnected {
              background-color: #f53c3c;
          }

          #mpd.stopped {
              background-color: #90b1b1;
          }

          #mpd.paused {
              background-color: #51a37a;
          }

          #language {
              background: #bbccdd;
              color: #333333;
              padding: 0 5px;
              margin: 6px 3px;
              min-width: 16px;
          }
        '';
      };

      swaylock = {
        enable = true;
        settings = {
          screenshots = true;
          clock = true;
          indicator = true;
          indicator-radius = 100;
          indicator-thickness = 7;
          effect-blur = "7x5";
          effect-vignette = "0.5:0.5";
          ring-color = "bb00cc";
          key-hl-color = "880033";
          line-color = "00000000";
          inside-color = "00000088";
          separator-color = "00000000";
          grace = 2;
        };
      };
    };

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraConfig = ''
        input "1452:641:Apple_Internal_Keyboard_/_Trackpad" {
          dwt enabled
          tap enabled
          accel_profile adaptive
          pointer_accel 0
          natural_scroll enabled
          scroll_method two_finger
          middle_emulation enabled
          tap_button_map lmr
        }

        default_border none

        output eDP-1 {
          scale 1
          # background ~/Pictures/857455.jpg fill
        }
      '';
      config = {
        modifier = "Mod4"; # Super key
        terminal = "kitty"; # Default terminal
        bars = [
          {
            position = "top";
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];
        startup = [
          { command = "mako"; } # Notifications
        ];

        keybindings = {
          "Mod4+Return" = "exec kitty";
          "Mod4+Shift+q" = "kill";
          "Mod4+d" = "exec dmenu_run";
          "Mod4+Shift+c" = "reload";
          "Mod4+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes' 'swaymsg exit'";
          # Navigation
          "Mod4+h" = "focus left";
          "Mod4+j" = "focus down";
          "Mod4+k" = "focus up";
          "Mod4+l" = "focus right";
          "Mod4+Shift+h" = "move left";
          "Mod4+Shift+j" = "move down";
          "Mod4+Shift+k" = "move up";
          "Mod4+Shift+l" = "move right";
        };
      };
    };

    xdg.configFile."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name = Adwaita-dark
    '';
  };

  environment = {
    pathsToLink = [ "/libexec" ];
    systemPackages = with pkgs; [
      neovim
      wl-clipboard
      openvpn
      kitty
      qemu
      virt-manager
      git
      tmux
      python3
      btop
      wget
      spice-gtk
      dmidecode
      grim
      slurp
      mako
    ];
    variables = {
      GTK_THEME = "Adwaita:dark";
    };
  };

  services = {
    gnome.gnome-keyring.enable = true;
    openssh.enable = true;
    xserver = {
      enable = true;
      displayManager.defaultSession = "sway";
      displayManager.autoLogin = {
        enable = true;
        user = "iskry";
      };
    };
  };

  programs = { 
    sway = {
      enable = true;
      xwayland.enable = true;
    };
  };

  security = {
    polkit.enable = true;
    pam = {
      services.swaylock = {};
      loginLimits = [
        { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
      ];
    };
  };

  system.stateVersion = "24.11";
}
