{ userName, homeStateVersion}:
{ config, pkgs, ... }:
{
  environment = {
    pathsToLink = [ "/libexec" ];
    systemPackages = with pkgs; [
      dmenu
      neovim
      wl-clipboard
      openvpn
      kitty
      qemu
      virt-manager
      git
      tmux
      python3
      btop
      wget
      spice-gtk
      dmidecode
      brightnessctl
      pciutils
      moonlight-qt
      dconf
    ];
    variables.GTK_THEME = "Adwaita:dark";
  };
}
