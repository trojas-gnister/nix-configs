# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/30025c37-5aba-4b71-a57c-57d20aa0daf0";
      fsType = "ext4";
    };

  boot.initrd.luks.devices = {
	"rootcrypt".device = "/dev/disk/by-uuid/d7d9f4bc-b33f-4356-a6df-521f585faf01";
	"rootswap".device = "dev/disk/by-uuid/54ed85c2-58f1-4a85-bc8d-a9b839fa7d5d";
	};
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6D41-1B21";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  swapDevices = [ 
	{ device = "/dev/disk/by-uuid/156ee5ee-5982-4a22-a0c8-c8d7f5ef2abd"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
