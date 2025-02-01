{ userName, homeStateVersion}:
{ config, pkgs, ... }:
{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # extraCommands = ''
      #   # Allow loopback traffic
      #   iptables -A INPUT -i lo -j ACCEPT
      #   iptables -A OUTPUT -o lo -j ACCEPT
      #
      #   # Allow established and related connections
      #   iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      #   iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      #
      #   # Drop all other outbound traffic from the host
      #   iptables -A OUTPUT -o wlp1s0f0 -j DROP
      # '';
    };
};

  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
  };

  home-manager.users = {
    "${userName}" = { pkgs, ... }: {
      home.stateVersion = homeStateVersion;
      services.picom.enable = true;
      dconf = {
        enable = true;
        settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = ["qemu:///system"];
          };
        };
      };

      programs = {
        kitty = {
          enable = true;
          extraConfig = ''
            background_opacity 0.70
          '';
        };
      };

      xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';

      xsession.windowManager.i3 = {
        enable = true;
        config = {
          terminal = "kitty";
          modifier = "Mod4";
          floating = {
            modifier = "Mod4";
          };
        };
        extraConfig = ''
          exec virt-manager
          exec kitty
          exec spice-vdagent -x -d
          for_window [class="^.*"] border pixel 0
        '';
      };
    };
  };

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
