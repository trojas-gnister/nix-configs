{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    (pkgs.chromium.overrideAttrs (oldAttrs: {
      postFixup = "wrapProgram $out/bin/chromium --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.glibc ]} --set CHROMIUM_FLAGS \"--force-dark-mode --enable-features=WebUIDarkMode\"" + (oldAttrs.postFixup or "");
    }))
  ];
}

