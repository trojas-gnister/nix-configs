{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [
    ./apple-silicon-support
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  boot = {
  	loader.systemd-boot.enable = true;
  	#Needed for Asahi
	loader.efi.canTouchEfiVariables = false;
    };

  networking.hostName = "headspace";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
	virtualisation.libvirtd = {
	enable = true;
	qemu.ovmf.enable = true;
	};

  
  users = {
    
    users.iskry = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "audio" ]; 
      packages = with pkgs; [
        git
	python3
	kitty
      ];
    };
  };

  home-manager.users.iskry = { pkgs, ... }: {
    home.stateVersion = "24.11"; 
      wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # Fixes common issues with GTK 3 apps
    config = rec {
      modifier = "Mod4";
      # Use kitty as default terminal
      terminal = "kitty"; 
      # startup = [
        # Launch Firefox on start
        # {command = "firefox";}
      # ];
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

   environment = {
  pathsToLink = [ "/libexec"];
  systemPackages = with pkgs; [
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
    grim
    slurp
    mako
  ];

  variables = {
    GTK_THEME = "Adwaita:dark"; # Set dark GTK theme
  };
  };


 programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

 services = {
        gnome.gnome-keyring.enable = true;
	openssh.enable = true;
	xserver = {
	enable = true;


	displayManager = {
		defaultSession = "sway;
		autoLogin.enable = true;
		autoLogin.user = "iskry";
	};


	};

  security.pam.services.swaylock = {};
  security.polkit.enable = true;
security.pam.loginLimits = [
  { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
];

  system.stateVersion = "24.11";
}
