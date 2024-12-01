{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/stable.tar.gz";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "browsing";
  time.timeZone = "America/Chicago";


  services = {
    xserver = {
      enable = true;
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "nixos";
        sddm.enable = true;
        defaultSession = "none+i3";
      };
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
          i3status
          i3lock
          i3blocks
        ];
      };
    };

    openssh.enable = true;

    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };
  programs.git.enable = true;

  environment = {
    systemPackages = with pkgs; [
      librewolf
      chromium
      qbittorrent
      neovim
      spice-autorandr
      spice-vdagent
      wl-clipboard
      openvpn
      kitty
    ];

    variables = {
      GTK_THEME = "Adwaita:dark";
    };

    pathsToLink = [ "/libexec" ];
  };
 
  hardware.pulseaudio.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash;
  };

  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.11";

    xsession.windowManager.i3 = {
      enable = true;
      extraConfig = ''
        set $mod Mod1
        font pango:DejaVu Sans Mono 8
        floating_modifier $mod

        # Autostart applications
        exec librewolf
        exec spice-vdagent -x -d

        # Keybindings
        bindsym $mod+Return exec kitty
        bindsym $mod+Shift+q kill
        bindsym $mod+d exec dmenu_run

        # Focus windows
        bindsym $mod+j focus left
        bindsym $mod+k focus down
        bindsym $mod+l focus up
        bindsym $mod+semicolon focus right
        bindsym $mod+Left focus left
        bindsym $mod+Down focus down
        bindsym $mod+Up focus up
        bindsym $mod+Right focus right

        # Move windows
        bindsym $mod+Shift+j move left
        bindsym $mod+Shift+k move down
        bindsym $mod+Shift+l move up
        bindsym $mod+Shift+semicolon move right
        bindsym $mod+Shift+Left move left
        bindsym $mod+Shift+Down move down
        bindsym $mod+Shift+Up move up
        bindsym $mod+Shift+Right move right

        # Layouts
        bindsym $mod+h split h
        bindsym $mod+v split v
        bindsym $mod+f fullscreen
        bindsym $mod+s layout stacking
        bindsym $mod+w layout tabbed
        bindsym $mod+e layout toggle split

        # Floating windows
        bindsym $mod+Shift+space floating toggle
        bindsym $mod+space focus mode_toggle

        # Focus parent
        bindsym $mod+a focus parent

        # Workspaces
        bindsym $mod+1 workspace 1
        bindsym $mod+2 workspace 2
        bindsym $mod+3 workspace 3
        bindsym $mod+4 workspace 4
        bindsym $mod+5 workspace 5
        bindsym $mod+6 workspace 6
        bindsym $mod+7 workspace 7
        bindsym $mod+8 workspace 8
        bindsym $mod+9 workspace 9
        bindsym $mod+0 workspace 10

        # Move to workspace
        bindsym $mod+Shift+1 move container to workspace 1
        bindsym $mod+Shift+2 move container to workspace 2
        bindsym $mod+Shift+3 move container to workspace 3
        bindsym $mod+Shift+4 move container to workspace 4
        bindsym $mod+Shift+5 move container to workspace 5
        bindsym $mod+Shift+6 move container to workspace 6
        bindsym $mod+Shift+7 move container to workspace 7
        bindsym $mod+Shift+8 move container to workspace 8
        bindsym $mod+Shift+9 move container to workspace 9
        bindsym $mod+Shift+0 move container to workspace 10

        # Reload and restart i3
        bindsym $mod+Shift+c reload
        bindsym $mod+Shift+r restart

        # Exit i3
        bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

        # Resize mode
        mode "resize" {
            bindsym j resize shrink width 10 px or 10 ppt
            bindsym k resize grow height 10 px or 10 ppt
            bindsym l resize shrink height 10 px or 10 ppt
            bindsym semicolon resize grow width 10 px or 10 ppt
            bindsym Left resize shrink width 10 px or 10 ppt
            bindsym Down resize grow height 10 px or 10 ppt
            bindsym Up resize shrink height 10 px or 10 ppt
            bindsym Right resize grow width 10 px or 10 ppt

            bindsym Return mode "default"
            bindsym Escape mode "default"
        }
        bindsym $mod+r mode "resize"

        # Status bar
        bar {
            status_command i3status
        }
      '';
    };

    programs.librewolf = {
      enable = true;
      settings = {
        "ui.systemUsesDarkTheme" = 1;
      };
    };

    xdg = {
      enable = true;
      configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';
    };
  };

  system.stateVersion = "24.11";

}

