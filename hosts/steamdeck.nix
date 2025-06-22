{ config, lib, pkgs, ... }:

{
  imports = [
  ];

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
  networking.hostName = config.variables.networking.leviathan.hostname;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "24.05";
  security.apparmor.policies."libvirtd".rules = [
    "/mnt/sd-card/vms/** rwk,"
  ];
  programs.thunar.enable = true;
  services.tumbler.enable = true;

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
