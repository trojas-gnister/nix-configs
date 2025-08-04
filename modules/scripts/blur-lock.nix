# Custom blur lock script for modules/scripts/blur-lock.nix
{ pkgs, ... }:

pkgs.writeShellScriptBin "blur-lock" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  # Temporary file for the blurred screenshot
  TEMP_IMAGE="/tmp/lockscreen_blur.png"

  # Take screenshot of all outputs
  ${pkgs.grim}/bin/grim "$TEMP_IMAGE"

  # Blur the screenshot (adjust blur strength as needed)
  ${pkgs.imagemagick}/bin/convert "$TEMP_IMAGE" -blur 0x8 "$TEMP_IMAGE"

  # Lock screen with blurred image
  ${pkgs.swaylock}/bin/swaylock \
    --image "$TEMP_IMAGE" \
    --scaling fill \
    --color 1e1e2e \
    --inside-color 1e1e2e88 \
    --ring-color 6272a4 \
    --key-hl-color 50fa7b \
    --bs-hl-color ff5555 \
    --text-color f8f8f2 \
    --ignore-empty-password \
    --show-failed-attempts

  # Clean up temporary file
  rm -f "$TEMP_IMAGE"
''
