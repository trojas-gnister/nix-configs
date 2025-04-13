# modules/containers/podman/storage.nix
{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = {
    # Configure storage for rootless Podman
    xdg.configFile."containers/storage.conf".text = ''
      [storage]
      driver = "overlay"
      runroot = "/run/user/1000/containers"
      graphroot = "$HOME/.local/share/containers/storage"

      [storage.options.overlay]
      mount_program = "/run/current-system/sw/bin/fuse-overlayfs"
      mountopt = "nodev,metacopy=on"
    '';
  };
}
