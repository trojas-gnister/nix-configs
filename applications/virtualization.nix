{ userName }:
{ config, pkgs, lib, ... }:
{
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
  };

  environment.systemPackages = [ pkgs.virt-manager ];

  home-manager.users = {
    "${userName}" = {
      dconf = {
        enable = true;
        settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = [ "qemu:///system" ];
            uris = [ "qemu:///system" ];
          };
        };
      };

      xsession.windowManager.i3.extraConfig = ''
        exec virt-manager
        exec spice-vdagent -x -d
      '';
    };
  };
}

