# modules/containers/podman/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./storage.nix
    ./volumes.nix
    ./ollama.nix
    ./openwebui.nix
    ./steamos.nix
  ];

  # Enable Podman for the system and user
  virtualisation.podman.enable = true;
  home-manager.users.${config.variables.user.name}.services.podman.enable = true;
}
