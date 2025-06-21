# My Personal NixOS Configuration

Welcome to my personal NixOS configuration repository

This repository uses Nix Flakes to manage the complete, declarative configurations for my machines. My main objective is to keep the setup synchronized and reproducible, no matter the hardware. Although this is a work in progress, I confirm that each host builds successfully with its settings in variables.nix before committing changes.

Currently, this configuration manages the following hosts:
-   `whitespace`: A desktop/server PC.
-   `leviathan`: A handheld/portable device (Steam Deck).

## Repository Structure

The repository is organized to separate machine-specific settings from shared, common modules.

-   **`flake.nix`**: The entry point for the entire configuration. It defines the flake inputs (Nixpkgs, Home Manager, etc.) and orchestrates the assembly of the `whitespace` and `leviathan` host configurations.
-   **`hosts/`**: Contains hardware-specific configurations. For example, `pc.nix` has kernel parameters for IOMMU, while `steamdeck.nix` includes specific drivers for the handheld's hardware.
-   **`modules/`**: Contains the bulk of the configuration, broken down into logical units (e.g., `sway.nix`, `podman.nix`, `steam.nix`). These modules are designed to be shared between hosts.
-   **`variables.nix`**: This is the central hub for customization. It defines all the user-specific settings, package lists, and feature flags that might differ between hosts or that I might want to change frequently.

## Customization via `variables.nix`

The entire configuration is designed to be highly modular and controlled by a single file: `/etc/nixos/variables.nix`.

This file is the **only place** you should need to make edits for day-to-day changes, such as:
-   Adding or removing system or user packages.
-   Opening firewall ports.
-   Setting hostnames and network details.
-   Toggling features on or off.

By centralizing these settings, the core logic in the `modules/` directory is kept clean and reusable across all machines.

## How to Deploy a Configuration

To build and activate a configuration for a specific host, run the following command from the `/etc/nixos/` directory:

```bash
# Replace <hostname> with either 'whitespace' or 'leviathan'
sudo nixos-rebuild switch --flake .#<hostname>
```

You are absolutely correct. My apologies. My standard format wraps document-style text in a special container, but you need the raw Markdown to copy directly into your README.md file.

Here is the raw Markdown content for your repository.

Markdown

# My Personal NixOS Configuration

Welcome to my personal NixOS configuration repository, hosted at [github.com/trojas-gnister/nix-configs](https://github.com/trojas-gnister/nix-configs).

This repository contains the complete, declarative configuration for all of my machines, managed using Nix Flakes. The primary goal is to maintain a synchronized, modular, and reproducible setup across different hardware profiles.

Currently, this configuration manages the following hosts:
-   `whitespace`: A desktop/server PC.
-   `leviathan`: A handheld/portable device (Steam Deck).

## Repository Structure

The repository is organized to separate machine-specific settings from shared, common modules.

-   **`flake.nix`**: The entry point for the entire configuration. It defines the flake inputs (Nixpkgs, Home Manager, etc.) and orchestrates the assembly of the `whitespace` and `leviathan` host configurations.
-   **`hosts/`**: Contains hardware-specific configurations. For example, `pc.nix` has kernel parameters for IOMMU, while `steamdeck.nix` includes specific drivers for the handheld's hardware.
-   **`modules/`**: Contains the bulk of the configuration, broken down into logical units (e.g., `sway.nix`, `podman.nix`, `steam.nix`). These modules are designed to be shared between hosts.
-   **`variables.nix`**: This is the central hub for customization. It defines all the user-specific settings, package lists, and feature flags that might differ between hosts or that I might want to change frequently.

## Customization via `variables.nix`

The entire configuration is designed to be highly modular and controlled by a single file: `/etc/nixos/variables.nix`.

This file is the **only place** you should need to make edits for day-to-day changes, such as:
-   Adding or removing system or user packages.
-   Opening firewall ports.
-   Setting hostnames and network details.
-   Toggling features on or off.

By centralizing these settings, the core logic in the `modules/` directory is kept clean and reusable across all machines.

## How to Deploy a Configuration

To build and activate a configuration for a specific host, run the following command from the `/etc/nixos/` directory:

```bash
# Replace <hostname> with either 'whitespace' or 'leviathan'
sudo nixos-rebuild switch --flake .#<hostname>

```
For example, to deploy the whitespace configuration:

`sudo nixos-rebuild switch --flake .#whitespace`

## Contributing and Requesting Changes
While this is my personal setup, I welcome suggestions for improvements or new features!

If you have an idea for a change, please feel free to open an issue or pull request. The ideal contribution is one that can benefit all devices and is implemented in a modular way. To ensure broad compatibility, any new features should be configurable and controlled via options defined in lib/variables-module.nix and set in variables.nix. This allows a feature to be enabled or disabled on a per-host basis without altering the core module logic.
