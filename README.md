#TODO:

- script to rotate disposable VM on shutdown to base. should spawn new disposable VM (fresh clone of the base) when executed
- rewrite python code (install and setup_partition scripts)
- conditional host configuration
- cleanup host config
- audio solution for VMs running on aarch64_darwin. workaround is passthrough bluetooth controller or usb audio device
- allow to skip swap and efi step in setup partitions
- allow to just create partitions based on free space and do not attempt to replace
