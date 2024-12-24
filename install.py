#!/usr/bin/env python3
#TODO: convert to Pydantic? Can I still use an executable script. This is for typing

import subprocess
import sys
import os
import shutil


configs = [
    {
        "name": "browsing",
        "configuration_path": "/home/nixos/nix-configs/app-configs/browsing/configuration.nix",
    },
    {
        "name": "jellyfin",
        "configuration_path": "/home/nixos/nix-configs/app-configs/jellyfin/configuration.nix",
    },
    {
        "name": "torrent",
        "configuration_path": "/home/nixos/nix-configs/app-configs/torrent/configuration.nix",
    },
    {
        "name": "gaming",
        "configuration_path": "/home/nixos/nix-configs/app-configs/gaming/configuration.nix",
    },
    {
        "name": "development",
        "configuration_path": "/home/nixos/nix-configs/app-configs/development/configuration.nix",
    },
    {
        "name": "host",
        "configuration_path": "/home/nixos/nix-configs/host-config/configuration.nix",
    },
]


def generate_nixos_config():
    print("Generating NixOS configuration...")
    try:
        subprocess.run(["nixos-generate-config", "--root", "/mnt"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while generating NixOS configuration: {e}")
        sys.exit(1)


def select_configuration(configs):
    print("Available configurations:")
    for idx, config in enumerate(configs):
        print(f"{idx + 1}: {config['name']}")
    choice = input("Select a configuration by number: ")
    if not choice.isdigit() or int(choice) < 1 or int(choice) > len(configs):
        print("Invalid selection. Exiting.")
        sys.exit(1)
    return configs[int(choice) - 1]


def move_configuration(config):
    configuration_path = os.path.expanduser(config["configuration_path"])
    destination = "/mnt/etc/nixos/configuration.nix"
    try:
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        shutil.copy(configuration_path, destination)
        print("configuration.nix has been moved.")
    except Exception as e:
        print(f"Failed to move configuration file: {e}")
        sys.exit(1)


def install_nixos():
    print("Starting NixOS installation...")
    try:
        subprocess.run(["nixos-install"], check=True)
        print("NixOS installation completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(
            "NixOS installation encountered an error. Please check the output above for details."
        )
        sys.exit(1)


def main():
    generate_nixos_config()
    selected_config = select_configuration(configs)
    move_configuration(selected_config)
    if install_nixos():
        print("You can now reboot your system.")


if __name__ == "__main__":
    main()
