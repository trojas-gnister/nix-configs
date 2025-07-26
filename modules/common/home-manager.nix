{ config, lib, pkgs, ... }:
let
  nixosSystemConfig = config;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${nixosSystemConfig.variables.user.name} = { config, pkgs, lib, ... }:
    let
      hmUserConfig = config;
      userName = nixosSystemConfig.variables.user.name;
      userSystemDefinition = nixosSystemConfig.users.users.${userName};
      headsetMacArctis = "28:9A:4B:FB:92:83";
    in
    {
      home.username = userName;
      home.homeDirectory = userSystemDefinition.home;
      home.stateVersion = "24.11";
      fonts.fontconfig.enable = true;

      home.packages = with pkgs;
        lib.lists.map (pname: lib.getAttr pname pkgs) nixosSystemConfig.variables.packages.homeManager;
      
      xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';

      services.podman.enable = true;

      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "ls --color=auto";
          grep = "grep --color=auto";
          nvim-py = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/py-dev:noble \
            tmux new
          '';
          nvim-nodejs = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/nodejs-dev:noble \
            tmux new
          '';
          nvim-rust = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/rust-dev:noble \
            tmux new
          '';
          
          nix-sync-config = "if [ ! -d \"$HOME/nix-configs\" ]; then echo 'Cloning nix-configs repo...' && git clone https://github.com/trojas-gnister/nix-configs.git \"$HOME/nix-configs\"; fi && cd \"$HOME/nix-configs\" && echo 'Pulling latest changes...' && git pull && echo '⚠️  Replacing system configuration...' && sudo rm -rf /etc/nixos/{flake.nix,hosts,iso,lib,modules} && sudo cp -r {flake.nix,hosts,iso,lib,modules} /etc/nixos/ && echo '✅ Sync complete!'";
        };
      };

      systemd.user.startServices = true;

      xdg.configFile."containers/storage.conf".text = ''
        [storage]
        driver = "overlay"
        runroot = "/run/user/${toString userSystemDefinition.uid}/containers"
        graphroot = "${userSystemDefinition.home}/.local/share/containers/storage"

        [storage.options.overlay]
        mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
        mountopt = "nodev,metacopy=on"
      '';
    };
  };
}
