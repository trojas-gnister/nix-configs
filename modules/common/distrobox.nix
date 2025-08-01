{ config, lib, pkgs, ... }:
let
  # Extract values from NixOS config to pass to Home Manager
  hostname = config.variables.networking.hostname;
in
{
  # Install Distrobox as a user package (it wraps Podman)
  home-manager.users.${config.variables.user.name} = { config, lib, pkgs, ... }: {
    home.packages = [ pkgs.distrobox ];
    # Generate distrobox.ini for declarative container management
    xdg.configFile."distrobox/distrobox.ini".text = ''
      [steam-arch]
      image=archlinux:latest
      init=true
      # Enable multilib repository first
      init_hooks=sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf
      # Install Steam and dependencies for AMD GPU/gaming
      additional_packages=steam gamescope vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa lib32-libglvnd ttf-liberation lib32-openal base-devel git
      pull=true
      replace=true
      nvidia=false
      root=false
    '';
    # Generate basic sunshine.conf with AMD-specific settings (shared via mounted home)
    xdg.configFile."sunshine/sunshine.conf".text = ''
      # Basic Sunshine config for AMD GPU streaming
      sunshine_name = ${hostname}-container
      min_log_level = info
      encoder = amf  # Use AMF for AMD GPU encoding
      adapter_name = /dev/dri/renderD128  # AMD render node (adjust if needed; Distrobox mounts /dev/dri)
      bitrate = 50000  # 50 Mbps default; adjust for quality/bandwidth
      port = 47989  # Default HTTPS port
      upnp = on  # Enable UPnP for auto port mapping
      # Add more options as needed (e.g., av1_mode = 1 for AV1 if supported)
    '';
    # Activation script: Assemble container, export Steam, enable/start Sunshine service
    home.activation.setupDistrobox = config.lib.dag.entryAfter ["writeBoundary"] ''
      # Ensure podman is in PATH
      export PATH="${pkgs.podman}/bin:$PATH"
      
      # Create the container first
      $DRY_RUN_CMD ${pkgs.distrobox}/bin/distrobox assemble create --replace --file $HOME/.config/distrobox/distrobox.ini
      
      if [ -z "$DRY_RUN_CMD" ]; then
        # Only run post-setup if not in dry-run mode
        echo "Setting up AUR helper and Sunshine..."
        
        # Install paru AUR helper
        $DRY_RUN_CMD ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- bash -c "
          git clone https://aur.archlinux.org/paru.git /tmp/paru && 
          cd /tmp/paru && 
          makepkg -si --noconfirm
        " || echo "Failed to install paru, continuing..."
        
        # Install Sunshine via AUR
        $DRY_RUN_CMD ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- paru -S --noconfirm sunshine || echo "Failed to install sunshine, continuing..."
        
        # Export Steam as a desktop entry (deletes first to clean up any changes)
        $DRY_RUN_CMD ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- distrobox-export --app steam --delete || true
        $DRY_RUN_CMD ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- distrobox-export --app steam || echo "Failed to export Steam, continuing..."
        
        echo "Distrobox setup completed!"
      fi
    '';
  };
}
