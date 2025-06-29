{ config, lib, pkgs, jovian, ... }:

{
  imports = [
  ];

  jovian.devices.steamdeck.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [
    "hid-generic"
    "hid-multitouch"
    "i2c-designware-core"
    "i2c-designware-platform"
    "i2c-hid-acpi"
    "usbhid"
  ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "sdhci"
    "sdhci_pci"
    "cqhci"
    "mmc_block"
  ];
  networking.hostName = config.variables.networking.hostname;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  #TODO: move to variables
  system.stateVersion = "24.05";

  services.displayManager.autoLogin = {
    enable = true;
    user = config.variables.user.name;
  };

  hardware.xone.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  hardware.graphics.enable32Bit = true;
}
