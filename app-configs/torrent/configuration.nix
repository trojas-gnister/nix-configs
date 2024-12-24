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

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "torrent";

  time.timeZone = "America/Chicago";

  services = {
  resolved = {
  enable = true;
  };
  mullvad-vpn.enable = true;
  mullvad-vpn.package = pkgs.mullvad-vpn;
    blueman.enable = true;
    xserver.enable = true;
    xserver.displayManager.defaultSession = "none+i3";
    xserver.displayManager.autoLogin.enable = true;
    xserver.displayManager.autoLogin.user = "nixos";
    xserver.displayManager.sddm.enable = true;

    xserver.windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
      ];
    };

    openssh.enable = true;
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  programs.git.enable = true;

  environment = {
    systemPackages = with pkgs; [
      librewolf
      qbittorrent
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

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash;
  };

  home-manager.users.nixos = { pkgs, ... }: {
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
 
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
};

  system = {
    stateVersion = "24.11";
  };
}
