#!/usr/bin/env python3

import subprocess
import sys
import os
import shutil
import getpass
import pwd
import grp
import json

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


def list_devices():
    try:
        # Use JSON output for reliable parsing
        lsblk_output = subprocess.check_output(["lsblk", "-J", "-o", "NAME"], text=True)
        lsblk_json = json.loads(lsblk_output)
        devices = []
        for device in lsblk_json["blockdevices"]:
            if device["type"] == "disk":
                name = device["name"]
                devices.append({"name": name})
        return devices
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while listing devices: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"An error occurred while parsing lsblk output: {e}")
        sys.exit(1)


def select_device():
    print("Available storage devices:")
    devices = list_devices()
    if not devices:
        print("No storage devices found.")
        sys.exit(1)
    for idx, device in enumerate(devices):
        print(
            f"{idx + 1}: /dev/{device['name']} - Size: {device['size']} - Model: {device['model']}"
        )
    choice = input("Select a device to install NixOS on by number: ")
    if not choice.isdigit() or int(choice) < 1 or int(choice) > len(devices):
        print("Invalid selection. Exiting.")
        sys.exit(1)
    selected_device = devices[int(choice) - 1]
    confirm = input(
        f"Are you sure you want to use /dev/{selected_device['name']}? This will erase all data on the device. (yes/no): "
    )
    if confirm.lower() != "yes":
        print("Operation cancelled by user.")
        sys.exit(1)
    return f"/dev/{selected_device['name']}"


def create_partitions(device):
    print(f"Creating partitions on {device}...")
    try:
        # Use parted to create partitions
        # Assuming GPT partition table
        subprocess.run(["parted", "-s", device, "mklabel", "gpt"], check=True)

        # Create EFI partition (512 MiB)
        subprocess.run(
            ["parted", "-s", device, "mkpart", "ESP", "fat32", "1MiB", "513MiB"],
            check=True,
        )
        subprocess.run(["parted", "-s", device, "set", "1", "boot", "on"], check=True)

        # Create root partition (rest of the disk)
        subprocess.run(
            ["parted", "-s", device, "mkpart", "primary", "513MiB", "100%"], check=True
        )

        print("Partitions created successfully.")
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while creating partitions: {e}")
        sys.exit(1)


def get_partition_paths(device):
    try:
        # Get partition paths
        lsblk_output = subprocess.check_output(
            ["lsblk", "-J", "-o", "NAME,TYPE", device], text=True
        )
        lsblk_json = json.loads(lsblk_output)
        partitions = []
        for child in lsblk_json["blockdevices"][0].get("children", []):
            if child["type"] == "part":
                partitions.append(child["name"])
        if len(partitions) < 2:
            print("Expected at least two partitions (EFI and root).")
            sys.exit(1)
        efi_partition = f"/dev/{partitions[0]}"
        root_partition = f"/dev/{partitions[1]}"
        return efi_partition, root_partition
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while getting partition paths: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"An error occurred while parsing lsblk output: {e}")
        sys.exit(1)


def format_and_mount_partitions(efi_partition, root_partition, encrypt_pwd):
    try:
        if encrypt_pwd:
            print("Encrypting the root partition...")
            mapper_name = "cryptroot"
            encrypt_partition(root_partition, mapper_name, encrypt_pwd)
            device_to_mount = f"/dev/mapper/{mapper_name}"
        else:
            device_to_mount = root_partition

        print("Formatting the EFI partition...")
        subprocess.run(["mkfs.fat", "-F", "32", efi_partition], check=True)

        print("Formatting the root partition...")
        subprocess.run(["mkfs.ext4", device_to_mount], check=True)

        print("Mounting the root partition...")
        os.makedirs("/mnt", exist_ok=True)
        subprocess.run(["mount", device_to_mount, "/mnt"], check=True)

        print("Mounting the EFI partition...")
        os.makedirs("/mnt/boot", exist_ok=True)
        subprocess.run(["mount", efi_partition, "/mnt/boot"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while formatting or mounting partitions: {e}")
        sys.exit(1)


def ask_encryption():
    encrypt = input("Do you want to encrypt your root partition? (yes/no): ")
    if encrypt.lower() == "yes":
        encrypt_pwd = getpass.getpass("Enter encryption password: ")
        encrypt_pwd_confirm = getpass.getpass("Confirm encryption password: ")
        if encrypt_pwd != encrypt_pwd_confirm:
            print("Passwords do not match. Exiting.")
            sys.exit(1)
        return encrypt_pwd
    else:
        return None


def encrypt_partition(device_path, mapper_name, password):
    try:
        cryptsetup_format_cmd = [
            "cryptsetup",
            "luksFormat",
            device_path,
            "--batch-mode",
            "--key-file",
            "-",
        ]
        process = subprocess.Popen(cryptsetup_format_cmd, stdin=subprocess.PIPE)
        process.communicate(input=password.encode())
        if process.returncode != 0:
            raise subprocess.CalledProcessError(
                process.returncode, cryptsetup_format_cmd
            )
        cryptsetup_open_cmd = [
            "cryptsetup",
            "open",
            device_path,
            mapper_name,
            "--key-file",
            "-",
        ]
        process = subprocess.Popen(cryptsetup_open_cmd, stdin=subprocess.PIPE)
        process.communicate(input=password.encode())
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, cryptsetup_open_cmd)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred during encryption: {e}")
        sys.exit(1)


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
    device = select_device()
    create_partitions(device)
    encrypt_pwd = ask_encryption()
    efi_partition, root_partition = get_partition_paths(device)
    format_and_mount_partitions(efi_partition, root_partition, encrypt_pwd)
    generate_nixos_config()
    selected_config = select_configuration(configs)
    move_configuration(selected_config)
    if install_nixos():
        setup_dot_config(selected_config.get("dot_config_path"))
        print("You can now reboot your system.")


if __name__ == "__main__":
    main()
