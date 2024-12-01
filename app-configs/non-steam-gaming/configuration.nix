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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "emulation";
  time.timeZone = "America/Chicago";

  services = {
    xserver = {
      enable = true;
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "nixos";
        sddm.enable = true;
        defaultSession = "none+i3";
      };
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
          i3status
          i3lock
          i3blocks
        ];
      };
    };

    openssh.enable = true;
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  programs.git.enable = true;

  environment = {
    systemPackages = with pkgs; [
      dosbox
      retroarchFull
      librewolf
      neovim
      spice-autorandr
      spice-vdagent
      wl-clipboard
      openvpn
      kitty
    ];

    variables = {
      GTK_THEME = "Adwaita:dark";
    };

    pathsToLink = [ "/libexec" ];
  };

  hardware.pulseaudio.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash;
  };

  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.05";
    
    xsession.windowManager.i3 = {
      enable = true;
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

  system.stateVersion = "24.05";
}

