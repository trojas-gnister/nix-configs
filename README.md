#TODO:
- script to rotate disposable VM on shutdown to base. should spawn new disposable VM (fresh clone of the base) when executed 
- rewrite python code (install and setup_partition scripts)
- conditional host configuration
- cleanup host config
- audio solution for VMs running on aarch64_darwin. workaround is passthrough bluetooth controller or usb audio device
- deprecate .config files and use home-manager https://nix-community.github.io/home-manager/options.xhtml#opt-wayland.windowManager.sway.config
