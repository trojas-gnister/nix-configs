{ userName, dataDevice }:
{ config, lib, pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/mnt/data" = {
    device = dataDevice;
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 47984 47989 47990 48010 ];
      allowedUDPPortRanges = [
        { from = 47998; to = 48000; }
        { from = 8000; to = 8010; }
      ];
    };
  };

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    git.enable = true;
    steam = {
      gamescopeSession.enable = true;
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          libkrb5
          keyutils
        ];
      };
    };
  };

  hardware.opengl.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "libretro-snes9x"
    "libretro-beetle-psx-hw"
    "libretro-genesis-plus-gx"
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
    "nvidia-x11"
    "nvidia-settings"
  ];

  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = userName;
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

    openssh.enable = true;
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  home-manager.users."${userName}" = { pkgs, ... }: {
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
        exec steam
        exec sunshine
        exec spice-vdagent -x -d
        for_window [class="^.*"] border pixel 0
      '';
    };

    xdg = {
      enable = true;
      configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';
    };
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
      brightnessctl
      pciutils
      moonlight-qt
      dconf
     android-tools
      neovim
      git
      xclip
      python3
      gcc
      tmux
      rustup
      nodejs_22
      mangohud
      protonup-qt
      lutris
      bottles
      heroic
      neovim
      lunarvim
      sunshine
      spice-autorandr
      spice-vdagent
      wl-clipboard
      openvpn
      kitty
    ];
    variables.GTK_THEME = "Adwaita:dark";

  };
   users.users."${userName}" = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/${userName}";
    shell = pkgs.bash;
  };
}

