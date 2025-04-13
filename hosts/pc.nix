# hosts/pc.nix
{ config, lib, pkgs, ... }:

{
  imports = [ 
    ../hardware-configuration.nix
    ../variables.nix
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
      "ip=${config.variables.networking.staticIP}::${config.variables.networking.gateway}:${config.variables.networking.netmask}:nixos-server:enp6s0:none"
    ];

    initrd = {
      availableKernelModules = [ "igc" ];
      kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
      network = {
        enable = true;
        postCommands = ''
          # Automatically ask for the password on SSH login
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
  
  services.xserver.displayManager.defaultSession = "none+i3";
}
