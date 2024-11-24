#!/usr/bin/env python3

#TODO: account for when swap size is 0
import subprocess
import sys
import os
import shutil
import getpass
import urllib.request
import pwd
import grp
import re

# Define the list of configurations
configs = [
    {
        'name': 'librewolf-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/app-nix-configs/librewolf-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/app-nix-configs/librewolf-i3/.config'
    },
    {
        'name': 'chromium-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/app-nix-configs/chromium-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/app-nix-configs/chromium-i3/.config'
    },
    {
        'name': 'torrent-i3',
        'configuration_path': '/home/nixos/NixVMHostForge/app-nix-configs/torrent-i3/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/app-nix-configs/torrent-i3/.config'
    },
    {
        'name': 'gaming-nvidia-kde',
        'configuration_path': '/home/nixos/NixVMHostForge/app-nix-configs/gaming-nvidia-kde/configuration.nix'
    },
    {
        'name': 'development-ssh',
        'configuration_path': '/home/nixos/NixVMHostForge/app-nix-configs/development-ssh/configuration.nix',
        'dot_config_path': '/home/nixos/NixVMHostForge/app-nix-configs/development-ssh/.config'
    }
]

def select_free_space():
    print("Available storage devices and free space:")
    try:
        # Get the list of devices
        lsblk_output = subprocess.check_output(['lsblk', '-d', '-o', 'NAME,SIZE,MODEL'], text=True)
        devices = []
        for line in lsblk_output.strip().split('\n')[1:]:
            if line.startswith(('sd', 'vd', 'nvme', 'hd')):
                devices.append(line)
        if not devices:
            print("No storage devices found.")
            sys.exit(1)

        free_spaces = []
        # For each device, get free space
        for device_info in devices:
            parts = device_info.split(None, 2)
            device_name = parts[0]
            device_size = parts[1]
            device_model = parts[2] if len(parts) > 2 else ''
            parted_output = subprocess.check_output(['parted', '-m', f'/dev/{device_name}', 'unit', 'MiB', 'print', 'free'], text=True)
            # Parse the output to find free space
            lines = parted_output.strip().split('\n')
            for line in lines:
                if line.startswith('/dev/'):
                    continue  # skip device info line
                if line.startswith('BYT;'):
                    continue  # skip header
                cols = line.strip(';').split(':')
                if len(cols) < 7:
                    continue
                number, start, end, size, filesystem, name, flags = cols[:7]
                if number == '':
                    # This is free space
                    free_spaces.append({
                        'device': device_name,
                        'device_size': device_size,
                        'device_model': device_model,
                        'start': start,
                        'end': end,
                        'size': size
                    })

        if not free_spaces:
            print("No free space found on storage devices.")
            sys.exit(1)

        # Present free spaces to the user
        print("Available free spaces:")
        for idx, fs in enumerate(free_spaces):
            print(f"{idx + 1}: Device: /dev/{fs['device']} ({fs['device_model']} - {fs['device_size']}), Free space: {fs['size']} (from {fs['start']} to {fs['end']})")

        choice = input("Select a free space by number: ")
        if not choice.isdigit() or int(choice) < 1 or int(choice) > len(free_spaces):
            print("Invalid selection. Exiting.")
            sys.exit(1)

        selected_fs = free_spaces[int(choice) - 1]

        # Confirm with the user
        confirm = input(f"You have selected free space of size {selected_fs['size']} on /dev/{selected_fs['device']}. Do you want to proceed? (yes/no): ")
        if confirm.lower() != 'yes':
            print("Operation cancelled by user.")
            sys.exit(1)

        # Proceed with your operation on the selected free space here
        # For example, create a new partition in the free space
        print(f"Proceeding with free space on /dev/{selected_fs['device']} from {selected_fs['start']} to {selected_fs['end']}.")

        # Example command to create a new partition (uncomment and customize as needed)
        # subprocess.run(['parted', '/dev/{}'.format(selected_fs['device']), 'mkpart', 'primary', selected_fs['start'], selected_fs['end']], check=True)

        return selected_fs
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


def ask_encryption():
    encrypt = input("Do you want to encrypt your partitions? (yes/no): ")
    if encrypt.lower() == 'yes':
        encrypt_pwd = getpass.getpass("Enter encryption password: ")
        encrypt_pwd_confirm = getpass.getpass("Confirm encryption password: ")
        if encrypt_pwd != encrypt_pwd_confirm:
            print("Passwords do not match. Exiting.")
            sys.exit(1)
        return encrypt_pwd
    else:
        return None

def get_swap_size():
    swap_size = input("Enter the desired swap size in GB (e.g., 4 for 4GB): ")
    try:
        swap_size_int = int(swap_size)
        if swap_size_int < 0:
            print("Swap size must be a positive integer.")
            sys.exit(1)
        return swap_size_int
    except ValueError:
        print("Invalid swap size. Please enter a numeric value.")
        sys.exit(1)

def partition_device(device, swap_size):
    print(f"Proceeding to partition /dev/{device}...")
    try:
        subprocess.run(['sgdisk', '-n', '1:0:+512M', '-t', '1:EF00', f'/dev/{device}'], check=True)
        subprocess.run(['sgdisk', '-n', f'2:0:+{swap_size}G', '-t', '2:8300', f'/dev/{device}'], check=True)
        subprocess.run(['sgdisk', '-n', '3:0:0', '-t', '3:8300', f'/dev/{device}'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while partitioning the device: {e}")
        sys.exit(1)

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

def format_partitions(device, encrypt, encrypt_pwd):
    print("Formatting partitions...")
    try:
        subprocess.run(['mkfs.fat', '-F', '32', f'/dev/{device}1'], check=True)
        if encrypt:
            print("Setting up encryption on root and swap partitions...")
            encrypt_partition(f'/dev/{device}2', 'swapcrypt', encrypt_pwd)
            encrypt_partition(f'/dev/{device}3', 'rootcrypt', encrypt_pwd)
            subprocess.run(['mkswap', '/dev/mapper/swapcrypt'], check=True)
            subprocess.run(['mkfs.ext4', '/dev/mapper/rootcrypt'], check=True)
        else:
            subprocess.run(['mkswap', f'/dev/{device}2'], check=True)
            subprocess.run(['mkfs.ext4', f'/dev/{device}3'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while formatting partitions: {e}")
        sys.exit(1)

def mount_partitions(device, encrypt):
    try:
        print("Mounting partitions...")
        if encrypt:
            subprocess.run(['mount', '/dev/mapper/rootcrypt', '/mnt'], check=True)
            os.makedirs('/mnt/boot', exist_ok=True)
            subprocess.run(['mount', f'/dev/{device}1', '/mnt/boot'], check=True)
            subprocess.run(['swapon', '/dev/mapper/swapcrypt'], check=True)
        else:
            subprocess.run(['mount', f'/dev/{device}3', '/mnt'], check=True)
            os.makedirs('/mnt/boot', exist_ok=True)
            subprocess.run(['mount', f'/dev/{device}1', '/mnt/boot'], check=True)
            subprocess.run(['swapon', f'/dev/{device}2'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while mounting partitions: {e}")
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


#TODO: update  nix config with selected disks
def auto_mount_partitions():
    result = subprocess.run(['lsblk', '-o', 'NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT'], stdout=subprocess.PIPE, text=True)
    devices = result.stdout.splitlines()
    partitions = [line for line in devices[1:] if "part" in line]
    
    if not partitions:
        print("No partitions found to mount.")
        return

    cleaned_partitions = []
    for i, partition in enumerate(partitions, 1):
        cleaned_partition = re.sub(r'^[^a-zA-Z0-9]*', '', partition.strip())
        cleaned_partitions.append(cleaned_partition)
        print(f"{i}. {cleaned_partition}")

    selected_partitions = input("Enter the numbers of partitions to mount (comma separated): ").strip().split(',')

    for partition_num in selected_partitions:
        try:
            partition_num = int(partition_num.strip()) - 1
            if 0 <= partition_num < len(cleaned_partitions):
                partition_info = cleaned_partitions[partition_num].split()
                partition_name = partition_info[0]
                mount_dir = f"/mnt/{partition_name}"
                if not os.path.exists(mount_dir):
                    os.makedirs(mount_dir)
                mount_command = ['sudo', 'mount', f'/dev/{partition_name}', mount_dir]
                subprocess.run(mount_command, check=True)
                print(f"Partition {partition_name} mounted at {mount_dir}")
            else:
                print(f"Invalid selection: {partition_num + 1}")
        except ValueError:
            print("Invalid input, please enter numbers only.")
        except subprocess.CalledProcessError:
            print(f"Failed to mount partition {partition_name}. Ensure it's not already mounted or there are no errors.")
        except Exception as e:
            print(f"An error occurred: {e}")

def main():
    device = select_free_space()
    encrypt_pwd = ask_encryption()
    swap_size = get_swap_size()
    partition_device(device, swap_size)
    format_partitions(device, encrypt_pwd is not None, encrypt_pwd)
    mount_partitions(device, encrypt_pwd is not None)
    generate_nixos_config()
    selected_config = select_configuration(configs)
    move_configuration(selected_config)
    if install_nixos():
        setup_dot_config(selected_config['dot_config_path'])
        auto_mount_partitions()
        print("You can now reboot your system.")

if __name__ == '__main__':
    main()
