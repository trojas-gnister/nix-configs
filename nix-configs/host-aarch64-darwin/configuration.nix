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

      sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        config = rec {
          modifier = "Mod4";
          terminal = "kitty";
          menu = "dmenu_path | wmenu | xargs swaymsg exec --";
          wallpaper = "~/Pictures/857455.jpg";
          display = "eDP-1";

          keybindings = {
            "Mod4+Return" = "exec kitty";
            "Mod4+Shift+q" = "kill";
            "Mod4+d" = "exec ${menu}";
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
            # Workspaces
            "Mod4+1" = "workspace number 1";
            "Mod4+Shift+1" = "move container to workspace number 1";
            # Additional keybindings as required...
          };

          appearance = {
            corner_radius = 10;
            blur = {
              on = true;
              passes = 2;
              radius = 5;
            };
            shadows = {
              on = true;
              color = "#0000007F";
            };
          };

          output = {
            "$display" = {
              scale = 1;
              background = "${wallpaper} fill";
            };
          };

          input = {
            "1452:641:Apple_Internal_Keyboard_/_Trackpad" = {
              dwt = "enabled";
              tap = "enabled";
              accel_profile = "adaptive";
              pointer_accel = 0;
              natural_scroll = "enabled";
              scroll_method = "two_finger";
              middle_emulation = "enabled";
              tap_button_map = "lmr";
            };
          };
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
