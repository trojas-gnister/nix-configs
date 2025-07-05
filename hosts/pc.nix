{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true;
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules = [ "kvm" "kvm_intel" ];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
    ];

    initrd = lib.optionalAttrs (config.variables.ssh.initrd.hostKeyPath != "") {
      availableKernelModules = [ "igc" "vfio_pci" "vfio" "vfio_iommu_type1" ];
      kernelModules = [ ];
      network = {
        enable = true;
        postCommands = ''
          echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
        '';
        ssh = {
          enable = true;
          port = config.variables.ssh.initrd.port;
          hostKeys = [ config.variables.ssh.initrd.hostKeyPath ];
          authorizedKeys = config.variables.ssh.initrd.authorizedKeys;
        };
      };
    };
  };
}
