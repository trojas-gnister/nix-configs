{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];


  boot = {
	loader  = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};

  	};
  time.timeZone = "America/Chicago"; 
   networking.hostName = "gaming";

  programs = {
    git.enable = true;
    steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    };
  };

hardware.opengl = {
  enable = true;
};


hardware.nvidia = {
  modesetting.enable = true;
  open = false;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};


nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
"libretro-snes9x"
"libretro-beetle-psx-hw"
"libretro-genesis-plus-gx"
  "steam"
  "steam-original"
  "steam-unwrapped"
  "steam-run"
  "nvidia-x11"
  "nvidia-settings"
];
	services = {
		xserver =  {
			enable = true;
			videoDrivers = ["nvidia"];
		displayManager = {
				autoLogin.enable = true;
				autoLogin.user = "nixos";
				defaultSession = "plasmax11";
				sddm.enable = true;
				};
		desktopManager = {
				plasma6.enable = true;
				};
			};
		openssh.enable = true;
		spice-vdagentd.enable = true;
		spice-autorandr.enable = true;
		};

  environment = { 
  		

  		systemPackages = with pkgs; [
    				librewolf
    				neovim
    				sunshine
    				spice-autorandr
    				spice-vdagent
    				wl-clipboard
    				openvpn
    				kitty
				 (retroarch.override {
    cores = with libretro; [
      genesis-plus-gx
      snes9x
      beetle-psx-hw
    ];
  })
  				];
		variables = {
    			GTK_THEME = "Adwaita:dark"; 
  		};
	};

  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.11"; 
   xsession.windowManager.i3 = {
      enable = true;
      config = {
      terminal = "kitty";
      };
      extraConfig = ''
        set $mod Mod1
        font pango:DejaVu Sans Mono 8
        floating_modifier $mod
        exec librewolf
        exec spice-vdagent -x -d
        for_window [class="^.*"] border pixel 0
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

  environment.pathsToLink = [ "/libexec" ];

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash; 
  };
}
