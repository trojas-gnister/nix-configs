{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true;
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11";
  hardware = {
    asahi.peripheralFirmwareDirectory = ../firmware;
    graphics.enable = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
    extraModprobeConfig = ''
      options hid_apple fnmode=0
    '';
  };

  environment.systemPackages = [
    pkgs.pulseaudio
    pkgs.wireplumber
    pkgs.wev
    (pkgs.writeShellScriptBin "kbd-backlight-toggle" ''
      #!/bin/bash
      BACKLIGHT_PATH="/sys/class/leds/kbd_backlight"
      if [ ! -f "$BACKLIGHT_PATH/max_brightness" ]; then
        echo "Keyboard backlight not found." >&2
        exit 1
      fi
      current=$(${pkgs.coreutils}/bin/cat "$BACKLIGHT_PATH/brightness")
      max=$(${pkgs.coreutils}/bin/cat "$BACKLIGHT_PATH/max_brightness")
      if [ "$current" -gt 0 ]; then
        echo 0 > "$BACKLIGHT_PATH/brightness"
      else
        echo $max > "$BACKLIGHT_PATH/brightness"
      fi
    '')
  ];
}
