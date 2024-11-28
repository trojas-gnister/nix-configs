#!/usr/bin/env python3

import subprocess
import sys
import os
import shutil
import getpass
import pwd
import grp
import psutil

# Define the list of configurations (unchanged)
configs = [
    {
        'name': 'librewolf-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/nix-configs/librewolf-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/nix-configs/librewolf-i3/.config'
    },
    {
        'name': 'torrent-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/nix-configs/torrent-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/nix-configs/torrent-i3/.config'
    },
    {
        'name': 'gaming-nvidia-kde',
        'configuration_path': '/home/nixos/NixVMHostForge/nix-configs/gaming-nvidia-kde/configuration.nix'
    },
    {
        'name': 'development-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/nix-configs/development-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/nix-configs/development-i3/.config'
    },
    {
        'name': 'host-aarch64-darwin',
        'configuration_path': '/home/nixos/NixVMHostForge/nix-configs/host-aarch64-darwin/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/nix-configs/host-aarch64-darwin/.config'
    }
]

def check_free_space():
    partitions = psutil.disk_partitions()
    partition_info = []
    for partition in partitions:
        if partition.fstype == '':
            continue  # Skip unformatted partitions
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            partition_info.append({
                "device": partition.device,
                "mountpoint": partition.mountpoint,
                "total": usage.total // (1024**2),  # Convert to MB
                "used": usage.used // (1024**2),  # Convert to MB
                "free": usage.free // (1024**2),  # Convert to MB
            })
        except PermissionError:
            continue
    return partition_info

def select_device():
    print("Checking free space on all mounted partitions...")
    partitions = check_free_space()
    if not partitions:
        print("No mounted partitions with free space found.")
        sys.exit(1)
    print("Available partitions with free space:")
    for idx, partition in enumerate(partitions):
        print(f"{idx + 1}: Device: {partition['device']}, Mountpoint: {partition['mountpoint']}, Free Space: {partition['free']}MB")
    choice = input("Select a partition by number: ")
    if not choice.isdigit() or int(choice) < 1 or int(choice) > len(partitions):
        print("Invalid selection. Exiting.")
        sys.exit(1)
    selected_partition = partitions[int(choice) - 1]
    return selected_partition['device'], selected_partition['free']

def create_partition(device, free_space_mb):
    size_mb = input(f"Enter the size of the new partition in MB (max {free_space_mb}MB): ")
    try:
        size_mb = int(size_mb)
        if size_mb <= 0 or size_mb > free_space_mb:
            print("Invalid partition size.")
            sys.exit(1)
    except ValueError:
        print("Invalid partition size.")
        sys.exit(1)
    try:
        # Get the starting point for the new partition
        parted_output = subprocess.check_output(['parted', '-s', device, 'unit', 'MiB', 'print', 'free'], text=True)
        last_line = parted_output.strip().split('\n')[-1]
        if 'free' not in last_line:
            print("No free space available to create a new partition.")
            sys.exit(1)
        parts = last_line.split()
        start = parts[1].replace('MiB', '')
        start_mb = float(start)
        end_mb = start_mb + size_mb

        # Use parted to create a new partition
        print(f"Creating a new partition on {device} from {start_mb}MiB to {end_mb}MiB...")
        subprocess.run(["parted", '-s', device, 'mkpart', 'primary', 'ext4', f"{start_mb}MiB", f"{end_mb}MiB"], check=True)
        print("Partition created successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error creating partition: {e}")
        sys.exit(1)

def ask_encryption():
    encrypt = input("Do you want to encrypt your new partition? (yes/no): ")
    if encrypt.lower() == 'yes':
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
        cryptsetup_format_cmd = ['cryptsetup', 'luksFormat', device_path, '--batch-mode', '--key-file', '-']
        process = subprocess.Popen(cryptsetup_format_cmd, stdin=subprocess.PIPE)
        process.communicate(input=password.encode())
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, cryptsetup_format_cmd)
        cryptsetup_open_cmd = ['cryptsetup', 'open', device_path, mapper_name, '--key-file', '-']
        process = subprocess.Popen(cryptsetup_open_cmd, stdin=subprocess.PIPE)
        process.communicate(input=password.encode())
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, cryptsetup_open_cmd)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred during encryption: {e}")
        sys.exit(1)

def format_and_mount_partition(device, encrypt_pwd):
    try:
        if encrypt_pwd:
            print("Encrypting the partition...")
            mapper_name = 'cryptnewpartition'
            encrypt_partition(device, mapper_name, encrypt_pwd)
            device_to_mount = f"/dev/mapper/{mapper_name}"
        else:
            device_to_mount = device
        print("Formatting the partition...")
        subprocess.run(['mkfs.ext4', device_to_mount], check=True)
        print("Mounting the partition...")
        os.makedirs('/mnt', exist_ok=True)
        subprocess.run(['mount', device_to_mount, '/mnt'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while formatting or mounting the partition: {e}")
        sys.exit(1)

def generate_nixos_config():
    print("Generating NixOS configuration...")
    try:
        subprocess.run(['nixos-generate-config', '--root', '/mnt'], check=True)
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
    configuration_path = os.path.expanduser(config['configuration_path'])
    destination = '/mnt/etc/nixos/configuration.nix'
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
        subprocess.run(['nixos-install'], check=True)
        print("NixOS installation completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print("NixOS installation encountered an error. Please check the output above for details.")
        sys.exit(1)

def setup_dot_config(dot_config_path):
    if not dot_config_path:
        print("No .config configuration. Skipping")
        return
    print("Setting up .config...")
    try:
        source = os.path.expanduser(dot_config_path)
        destination = '/mnt/home/nixos/.config'
        os.makedirs(destination, exist_ok=True)
        shutil.copytree(source, destination, dirs_exist_ok=True)
        uid = pwd.getpwnam('nixos').pw_uid
        gid = grp.getgrnam('users').gr_gid
        os.chown('/mnt/home/nixos/.config', uid, gid)
        for root, dirs, files in os.walk('/mnt/home/nixos/.config'):
            for momo in dirs:
                os.chown(os.path.join(root, momo), uid, gid)
            for momo in files:
                os.chown(os.path.join(root, momo), uid, gid)
        print(".config has been moved and set up.")
    except Exception as e:
        print(f"An error occurred while setting up .config: {e}")
        sys.exit(1)

def main():
    device, free_space_mb = select_device()

    # Capture the list of partitions before creating a new one
    lsblk_output_before = subprocess.check_output(['lsblk', '-nr', device, '-o', 'NAME'], text=True)
    partitions_before = set(lsblk_output_before.strip().split('\n'))

    create_partition(device, free_space_mb)
    encrypt_pwd = ask_encryption()

    # Capture the list of partitions after creating the new one
    lsblk_output_after = subprocess.check_output(['lsblk', '-nr', device, '-o', 'NAME'], text=True)
    partitions_after = set(lsblk_output_after.strip().split('\n'))

    # Identify the new partition by finding the difference
    new_partitions = partitions_after - partitions_before
    if not new_partitions:
        print("No new partition found after partitioning.")
        sys.exit(1)
    elif len(new_partitions) > 1:
        print("Multiple new partitions found after partitioning. Please verify manually.")
        sys.exit(1)
    else:
        new_partition_name = new_partitions.pop()
        new_partition = f"/dev/{new_partition_name}"

    format_and_mount_partition(new_partition, encrypt_pwd)
    generate_nixos_config()
    selected_config = select_configuration(configs)
    move_configuration(selected_config)
    if install_nixos():
        setup_dot_config(selected_config.get('dot_config_path'))
        print("You can now reboot your system.")

if __name__ == '__main__':
    main()
