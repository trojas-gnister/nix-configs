{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nixpkgs.overlays = [
    (self: super: {
      bluez = super.bluez.overrideAttrs (old: {
        configureFlags = old.configureFlags or [] ++ [ "--disable-hid2hci" ];
      });
    })
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

  services.udev.extraRules = ''
    SUBSYSTEM=="leds", ACTION=="add", KERNEL=="kbd_backlight", RUN+="/bin/chmod 0666 %S%p/brightness"
  '';

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

  home-manager.users.${config.variables.user.name} = { lib, ... }: {
    home.activation.setKbdBacklight = lib.hm.dag.entryAfter ["writeBoundary"] ''
      BACKLIGHT_PATH="/sys/class/leds/kbd_backlight"
      if [ -f "$BACKLIGHT_PATH/max_brightness" ]; then
        $DRY_RUN_CMD echo $(${pkgs.coreutils}/bin/cat "$BACKLIGHT_PATH/max_brightness") > "$BACKLIGHT_PATH/brightness"
      fi
    '';
  };
}
