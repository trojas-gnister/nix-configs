{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "jellyfin";
    networkmanager.enable = true;
  };

  time = {
    timeZone = "America/Chicago";
  };


  services = {
  jellyfin = {

  enable = true;
      openFirewall = true;
  };

    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = "nixos";
        };
        sddm.enable = true;
      };
      windowManager = {
        i3 = {
          enable = true;
          extraPackages = with pkgs; [
            dmenu
            i3status
            i3lock
            i3blocks
          ];
        };
      };
    };

    openssh = {
      enable = true;
    };

    spice-vdagentd = {
      enable = true;
    };

    spice-autorandr = {
      enable = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  programs = {
    git = {
      enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
      librewolf
      neovim
      spice-autorandr
      spice-vdagent
      wl-clipboard
      kitty
      pulseaudio
    ];
    variables = {
      GTK_THEME = "Adwaita:dark";
    };
    pathsToLink = [ "/libexec" ];
  };

  users = {
    users = {
      nixos = {
        isNormalUser = true;
        uid = 1000;
        group = "users";
        extraGroups = [ "wheel" ];
        home = "/home/nixos";
        shell = pkgs.bash;
      };
    };
  };

  home-manager = {
    users = {
      nixos = { pkgs, ... }: {
        home.stateVersion = "24.11";

        xsession.windowManager.i3 = {
          enable = true;
          config = {
            terminal = "kitty";
          };
          extraConfig = ''
            set $mod Mod1
            font pango:DejaVu Sans Mono 8
            floating_modifier $mod
            exec librewolf
            exec spice-vdagent -x -d
            for_window [class="^.*"] border pixel 0
          '';
        };

        programs.librewolf = {
          enable = true;
          settings = {
            "ui.systemUsesDarkTheme" = 1;
          };
        };

        xdg = {
          enable = true;
          configFile."gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name = Adwaita-dark
          '';
        };
      };
    };
  };

  system = {
    stateVersion = "24.11";
  };
}
