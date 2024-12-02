{ config, lib, pkgs, ... }:
#TODO: swayfx
#TODO: lock when lid closes 
let
  currentSystem = builtins.currentSystem;
  isAarch64 = currentSystem == "aarch64-darwin";
  isX86_64 = currentSystem == "x86_64-linux";
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [

    (if isAarch64 then ./apple-silicon-support else null)
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot = if isAarch64 then {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
  } else {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [ "kvm" "kvm_intel" ];
    kernelParams = [ "intel_iommu=on" "iommu=pt" ];
    initrd = {
      kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
    };
    extraModprobeConfig = ''
      options vfio-pci ids=8086:15f3,10de:2484,10de:228b,144d:a808,8086:0094
    '';
    blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
  };

  networking = {
    hostName = 
    if isAarch64 
      then "headspace"
      else "whitespace"
    networkmanager.enable = true;
  };

  time.timeZone = "America/Chicago";
  hardware.opengl.enable = true;
  virtualisation = {
  	spiceUSBRedirection.enable = true;
 
  	libvirtd = {
    		enable = true;
    		qemu.ovmf.enable = true;
    };
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
      mako = {
	enable = true;
	extraConfig = ''
	background-color=#00000080  
	border-color=#ffffff40      
	text-color=#ffffff         
	font=Sans 14
	default-timeout=5000
	width=350                  
	height=100                
	padding=10
	margin=10
	border-size=2
	corner-radius=8
	'';
      };
      kitty = {
	enable = true;
	extraConfig = ''
	background_opacity 0.70
	'';
      };
      waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            #output = [
            #  "eDP-1"
           # ];
            modules-left = [ "sway/workspaces" "sway/mode" ];
            modules-center = [ "sway/window" ];
            modules-right = [
              "pulseaudio" "network" "backlight" "cpu" "memory" "battery"
              "clock" "tray"
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
        
	bindswitch --reload --locked lid:on exec swaylock \
    	--screenshots \
    	--clock \
    	--indicator \
    	--indicator-radius 100 \
    	--indicator-thickness 7 \
    	--effect-blur 7x5 \
    	--effect-vignette 0.5:0.5 \
    	--ring-color bb00cc \
    	--key-hl-color 880033 \
    	--line-color 00000000 \
    	--inside-color 00000088 \
    	--separator-color 00000000 \
    	--grace 2 

        # output eDP-1 {
         # scale 1
          # background ~/Pictures/857455.jpg fill
       # }
      '';
      config = {
        modifier = "Mod4"; 
        terminal = "kitty"; 
        bars = [
          {
            position = "top";
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];
        startup = [
          { command = "mako"; } 
        ];

        keybindings = {
          "Mod4+Return" = "exec kitty";
          "Mod4+Shift+q" = "kill";
          "Mod4+d" = "exec dmenu_run";
          "Mod4+Shift+c" = "reload";
          "Mod4+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes' 'swaymsg exit'";
	        "XF86MonBrightnessUp" = "exec brightnessctl -d apple-panel-bl set +10%";
	        "XF86MonBrightnessDown" = "exec brightnessctl -d apple-panel-bl set 10%-";
          # Navigation
          "Mod4+h" = "focus left";
          "Mod4+j" = "focus down";
          "Mod4+k" = "focus up";
          "Mod4+l" = "focus right";
          "Mod4+Shift+h" = "move left";
          "Mod4+Shift+j" = "move down";
          "Mod4+Shift+k" = "move up";
          "Mod4+Shift+l" = "move right";
	 "Mod4+1" = "workspace 1";
  	 "Mod4+2" = "workspace 2";
	 "Mod4+3" = "workspace 3";
  	 "Mod4+4" = "workspace 4";
  	 "Mod4+5" = "workspace 5";
  	 "Mod4+6" = "workspace 6";
  	 "Mod4+7" = "workspace 7";
  	 "Mod4+8" = "workspace 8";
  	 "Mod4+9" = "workspace 9";
  	 "Mod4+0" = "workspace 10";
	 "Ctrl+Left" = "workspace prev";
	 "Ctrl+Right" = "workspace next";
	 "Mod4+Shift+1" = "move container to workspace number 1";
	 "Mod4+Shift+2" = "move container to workspace number 2";
	 "Mod4+Shift+3" = "move container to workspace number 3";
	 "Mod4+Shift+4" = "move container to workspace number 4";
	 "Mod4+Shift+5" = "move container to workspace number 5";
	 "Mod4+Shift+6" = "move container to workspace number 6";
  	 "Mod4+Shift+7" = "move container to workspace number 7";
	 "Mod4+Shift+8" = "move container to workspace number 8";
	 "Mod4+Shift+9" = "move container to workspace number 9";
	 "Mod4+Shift+0" = "move container to workspace number 10";
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
      dmenu
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
      brightnessctl
      pciutils
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
