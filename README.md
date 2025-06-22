# My Personal NixOS Configuration

Welcome to my personal NixOS configuration repository

This repository uses Nix Flakes to manage the complete, declarative configurations for my machines. My main objective is to keep the setup synchronized and reproducible, no matter the hardware. Although this is a work in progress, I confirm that each host builds successfully with its settings in variables.nix before committing changes.

Currently, this configuration manages the following hosts:

- `whitespace`: A desktop/server PC, also acts as a hypervisor.
- `leviathan`: A handheld/portable device (Steam Deck), also acts as a hypervisor.
- `pi`: A Raspberry Pi server.

## Repository Structure

The repository is organized to separate machine-specific settings from shared, common modules.

- **`flake.nix`**: The entry point for the entire configuration. It defines inputs and orchestrates the assembly of all three hosts (`whitespace`, `leviathan`, and `pi`).
- **`hosts/`**: Contains hardware-specific configurations for each machine (`pc.nix`, `steamdeck.nix`, `pi.nix`).
- **`modules/`**: Contains the bulk of the shared configuration, broken into logical units.
- **`lib/`**: Defines the schema for our custom variables, ensuring consistent configuration across all hosts.
- **`iso.nix`**: Defines a custom, fully-automated NixOS installer ISO used for provisioning new virtual machines.
- **`modules/vms/vm-generator.nix`**: A powerful module that creates a new NixOS option (`virtualisation.nixvirt.vms`) to declaratively generate multiple virtual machines from a simple set of definitions.
- **`variables.nix`**: The central hub for customization, with a separate version on each host to define its specific packages, settings, and VMs.

## Customization via `variables.nix`

The entire configuration is designed to be highly modular and controlled by a single file: `/etc/nixos/variables.nix`.

This file is the **only place** you should need to make edits for day-to-day changes, such as:

- Adding or removing system or user packages.
- Opening firewall ports.
- Setting hostnames and network details.
- Toggling features on or off.

By centralizing these settings, the core logic in the `modules/` directory is kept clean and reusable across all machines.

## How to Deploy a Configuration

To build and activate a configuration for a specific host, run the following command from the `/etc/nixos/` directory:

```bash
# Replace <hostname> with 'whitespace', 'leviathan', or 'pi'
sudo nixos-rebuild switch --flake .#<hostname>
```

## Declarative Virtual Machines

This configuration includes a powerful VM generator module that allows for the declarative creation of multiple NixOS virtual machines. This system is orchestrated by three key files:

1. **`iso.nix`**: Creates a custom NixOS installer ISO. This installer is configured to be fully automated, requiring no manual input to install a base NixOS system on a new VM.
2. **`modules/vms/vm-generator.nix`**: This module creates the `virtualisation.nixvirt.vms` option, allowing you to define VMs directly in your configuration files. It automatically generates the libvirt XML, connection scripts, and other boilerplate for each VM.
3. **`variables.nix`**: You can define any number of VMs in this file. The generator will then build them all.

For example, to create a new VM, you would simply add an entry like this to `variables.nix`:

```nix
# in variables.nix
virtualisation.nixvirt.vms = {
  "my-new-server" = {
    enable = true;
    uuid = "generate-a-new-one-with-uuidgen";
    memorySize = 8; # in GiB
    diskPath = "/path/to/my-new-server.qcow2";
  };
};
```

## Contributing and Requesting Changes

While this is my personal setup, I welcome suggestions for improvements or new features!

If you have an idea for a change, please feel free to open an issue or pull request. The ideal contribution is one that can benefit all devices and is implemented in a modular way. To ensure broad compatibility, any new features should be configurable and controlled via options defined in lib/variables-module.nix and set in variables.nix. This allows a feature to be enabled or disabled on a per-host basis without altering the core module logic.
