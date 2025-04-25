# hosts/pc.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../hardware-configuration.nix # Assuming this is relevant for pc
    ../variables.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true; # Example existing setting
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11"; # Adjust as needed

  # Enable system-level Podman support (subuid/gid maps etc.)
  virtualisation.podman.enable = true;

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

  # Ensure only one session/window manager is primary if needed
  # services.xserver.displayManager.defaultSession = "none+i3"; # Example setting
}
