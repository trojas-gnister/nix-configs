#!/usr/bin/env python3

import subprocess
import sys
import os
import shutil
import getpass
import pwd
import grp
import json


#TODO: figure out partition creation and management 

# Define the list of configurations
configs = [
    {
        "name": "librewolf-i3",
        "configuration_path": "/home/nixos/NixVMHostForge/nix-configs/librewolf-i3/configuration.nix",
        "dot_config_path": "/home/nixos/NixVMHostForge/nix-configs/librewolf-i3/.config",
    },
    {
        "name": "torrent-i3",
        "configuration_path": "/home/nixos/NixVMHostForge/nix-configs/torrent-i3/configuration.nix",
        "dot_config_path": "/home/nixos/NixVMHostForge/nix-configs/torrent-i3/.config",
    },
    {
        "name": "gaming-nvidia-kde",
        "configuration_path": "/home/nixos/NixVMHostForge/nix-configs/gaming-nvidia-kde/configuration.nix",
    },
    {
        "name": "development-i3",
        "configuration_path": "/home/nixos/NixVMHostForge/nix-configs/development-i3/configuration.nix",
        "dot_config_path": "/home/nixos/NixVMHostForge/nix-configs/development-i3/.config",
    },
    {
        "name": "host-aarch64-darwin",
        "configuration_path": "/home/nixos/NixVMHostForge/nix-configs/host-aarch64-darwin/configuration.nix",
        "dot_config_path": "/home/nixos/NixVMHostForge/nix-configs/host-aarch64-darwin/.config",
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


def setup_dot_config(dot_config_path):
    if not dot_config_path:
        print("No .config configuration. Skipping")
        return
    print("Setting up .config...")
    try:
        source = os.path.expanduser(dot_config_path)
        destination = "/mnt/home/nixos/.config"
        os.makedirs(destination, exist_ok=True)
        shutil.copytree(source, destination, dirs_exist_ok=True)
        uid = pwd.getpwnam("nixos").pw_uid
        gid = grp.getgrnam("users").gr_gid
        os.chown(destination, uid, gid)
        for root, dirs, files in os.walk(destination):
            for momo in dirs:
                os.chown(os.path.join(root, momo), uid, gid)
            for momo in files:
                os.chown(os.path.join(root, momo), uid, gid)
        print(".config has been moved and set up.")
    except Exception as e:
        print(f"An error occurred while setting up .config: {e}")
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
        setup_dot_config(selected_config.get("dot_config_path"))
        print("You can now reboot your system.")


if __name__ == "__main__":
    main()
