{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true;
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11";

  services.qemuGuest.enable = true;

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
  };

  boot = {
    kernelParams = [ "console=ttyS0,115200" ];
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";
      };
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = config.variables.user.name;
  };

  services.displayManager.sddm.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
    sunshine
    kitty
    waybar
    wofi
    grim
    slurp
    wl-clipboard
    hyprpaper
    pavucontrol
    networkmanagerapplet
    blueman
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;

  users.users.${config.variables.user.name}.extraGroups = [ "input" "render" ];
  security.pam.services.swaylock = {};
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.${config.variables.user.name} = {
    xdg.desktopEntries."gs-launcher" = {
      name = "Gamescope Steam";
      comment = "Launch Steam in a Gamescope session";
      exec = "gs-launcher";
      icon = "steam";
      terminal = false;
      categories = [ "Game" ];
    };
  };
}
