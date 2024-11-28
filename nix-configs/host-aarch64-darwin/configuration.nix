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
	#    xsession.windowManager.i3 = {
	# enable = true;
	#
	#    };
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
    lxappearance
    alsa-utils
    dmidecode
  ];

  variables = {
    GTK_THEME = "Adwaita:dark"; # Set dark GTK theme
  };
  };

 # programs.sway = {
 #    enable = true;
 #    # package = pkgs.swayfx;
 #    wrapperFeatures.gtk = true;
 #  };
 programs = {
	i3lock.enable = true;
 };
  #   enable = true;
  #   displayManager.sddm.enable = true;
  #   displayManager.autoLogin.enable = true;
  #   displayManager.autoLogin.user = "iskry";
  #   # displayManager.sddm.wayland.enable = true;
  # };


 services = {
	# 	pipewire = {
	# 	enable = true;
	# 	alsa.enable = true;
	# 	pulse.enable = true;
	# };

	openssh.enable = true;
	xserver = {
	enable = true;

	desktopManager = {
		xterm.enable = true;
	};

	displayManager = {
		defaultSession = "none+i3";
		autoLogin.enable = true;
		autoLogin.user = "iskry";
	};

	windowManager.i3 = {
		enable = true;
		extraPackages = with pkgs; [
			dmenu
			i3status
			i3lock
		];
	};
	};
	#
	#  picom = {
	#    enable = true;
	#    fade = true;
	#    shadow = true;
	#    fadeDelta = 4 ;
	#    inactiveOpacity = 0.8;
	#    activeOpacity = 1;
	#    settings = {
	#      blur = {
	# strength = 5;
	#      };
	#    };
	#  };	
	};

  security.pam.services.swaylock = {};
	

  system.stateVersion = "24.11";
}
