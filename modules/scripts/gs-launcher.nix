{ pkgs, ... }:

pkgs.writeShellScriptBin "gs-launcher" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  gamescopeArgs=(
    "--adaptive-sync"
    "--hdr-enabled"
    "--rt"
    "--steam"
    "--expose-wayland"
    "--force-grab-cursor"
  )

  steamArgs=(
    "-pipewire-dmabuf"
    "-tenfoot"
  )

  echo "Launching Steam with Gamescope..."
  echo "Gamescope Args: ''${gamescopeArgs[*]}"
  echo "Steam Args: ''${steamArgs[*]}"

  exec ${pkgs.gamescope}/bin/gamescope "''${gamescopeArgs[@]}" -- ${pkgs.steam}/bin/steam "''${steamArgs[@]}" "$@"
''
