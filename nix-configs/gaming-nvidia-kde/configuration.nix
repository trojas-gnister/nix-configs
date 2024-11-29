{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/latest.tar.gz";
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
    programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  environment.systemPackages = with pkgs; [
    pkgs.librewolf
    neovim
    pkgs.sunshine
    spice-autorandr
    spice-vdagent
    wl-clipboard
    openvpn
    kitty
  ];

  services.xserver = {
    enable = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "nixos";
      sddm.enable = true;
      defaultSession = "plasmax11";
    };
    desktopManager.plasma6.enable = true;
  };



hardware.opengl = {
  enable = true;
};

services.xserver.videoDrivers = ["nvidia"];

hardware.nvidia = {
  modesetting.enable = true;
  open = false;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};


nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  "steam"
  "steam-original"
  "steam-unwrapoped"
  "steam-run"
  "nvidia-x11"
  "nvidia-settings"
];

  hardware.pulseaudio.enable = true;
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

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash; 
  };
}
