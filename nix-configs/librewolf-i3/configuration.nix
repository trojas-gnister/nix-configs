{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Chicago"; 

  services.openssh.enable = true;

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    pkgs.librewolf
    neovim
    spice-autorandr
    spice-vdagent
    wl-clipboard
    openvpn
    tor
    kitty
  ];

  services.xserver = {
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

  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;

  environment.variables = {
    GTK_THEME = "Adwaita:dark"; 
  };

  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.05"; 

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

  environment.pathsToLink = [ "/libexec" ];
  hardware.pulseaudio.enable = true;
  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash; 
  };
}
