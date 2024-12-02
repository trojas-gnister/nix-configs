#!/usr/bin/env python3

import sys
import subprocess
import getpass
import os


def select_device():
    # List available storage devices
    print("Available storage devices:")
    try:
        lsblk_output = subprocess.check_output(
            ["lsblk", "-d", "-o", "NAME,SIZE,MODEL"], text=True
        )
        devices = []
        for line in lsblk_output.strip().split("\n")[1:]:
            if line.startswith(("sd", "vd", "nvme")):
                devices.append(line)
        if not devices:
            print("No storage devices found.")
            sys.exit(1)

        for idx, device_info in enumerate(devices):
            print(f"{idx + 1}: {device_info}")

        choice = input("Select a storage device by number: ")
        if not choice.isdigit() or int(choice) < 1 or int(choice) > len(devices):
            print("Invalid selection. Exiting.")
            sys.exit(1)
        device_line = devices[int(choice) - 1]
        device_name = device_line.split()[0]
        return device_name
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


def ask_encryption():
    encrypt = input("Do you want to encrypt your partitions? (yes/no): ")
    if encrypt.lower() == "yes":
        encrypt_pwd = getpass.getpass("Enter encryption password: ")
        encrypt_pwd_confirm = getpass.getpass("Confirm encryption password: ")
        if encrypt_pwd != encrypt_pwd_confirm:
            print("Passwords do not match. Exiting.")
            sys.exit(1)
        return encrypt_pwd
    else:
        return None


def confirm_efi():
    efi_required = input("Do you need an EFI partition? (yes/no): ")
    if efi_required.lower() == "yes":
        return True
    else:
        return False


def get_swap_size():
    swap_size = input("Enter the desired swap size in GB (e.g., 4 for 4GB): ")
    try:
        swap_size_int = int(swap_size)
        if swap_size_int < 0:
            print("Swap size must be a positive integer or 0.")
            sys.exit(1)
        return swap_size_int
    except ValueError:
        print("Invalid swap size. Please enter a numeric value.")
        sys.exit(1)


def get_partitions(device):
    # Get partition information using lsblk with PARTLABEL
    lsblk_output = subprocess.check_output(
        ["lsblk", "-o", "NAME,FSTYPE,PARTLABEL", "-n", f"/dev/{device}"],
        text=True,
    )
    partitions = {}
    for line in lsblk_output.strip().split("\n"):
        parts = line.strip().split()
        if len(parts) >= 1:
            name = parts[0]
            fstype = parts[1] if len(parts) > 1 else ""
            partlabel = parts[2] if len(parts) > 2 else ""
            partitions[f"/dev/{name}"] = {"fstype": fstype, "partlabel": partlabel}
    return partitions


def partition_device(device, swap_size, efi_required):
    print(f"Proceeding to partition /dev/{device}...")

    try:
        # Check for existing EFI partition
        existing_partitions = get_partitions(device)
        efi_partition_exists = any(
            info.get("partlabel") == "EFI" for info in existing_partitions.values()
        )
        if efi_partition_exists:
            print("An EFI System Partition already exists.")
            efi_required = False

        # Create partitions
        # Note: Using '0' for partition number to use next available number
        if efi_required:
            subprocess.run(
                [
                    "sgdisk",
                    "-n",
                    "0:0:+512M",
                    "-t",
                    "0:EF00",
                    "-c",
                    "0:EFI",
                    f"/dev/{device}",
                ],
                check=True,
            )

        if swap_size > 0:
            subprocess.run(
                [
                    "sgdisk",
                    "-n",
                    f"0:0:+{swap_size}G",
                    "-t",
                    "0:8200",
                    "-c",
                    "0:SWAP",
                    f"/dev/{device}",
                ],
                check=True,
            )

        # Create root partition with remaining space
        subprocess.run(
            ["sgdisk", "-n", "0:0:0", "-t", "0:8300", "-c", "0:ROOT", f"/dev/{device}"],
            check=True,
        )

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while partitioning the device: {e}")
        sys.exit(1)


def encrypt_partition(device_path, mapper_name, password):
    try:
        # Format the partition with LUKS encryption
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

        # Open the encrypted partition
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


def format_partitions(device, encrypt, encrypt_pwd, swap_size, efi_required):
    print("Formatting partitions...")
    try:
        partitions = get_partitions(device)

        # Find partitions by partition label (PARTLABEL)
        efi_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "EFI"
            ),
            None,
        )
        swap_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "SWAP"
            ),
            None,
        )
        root_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "ROOT"
            ),
            None,
        )

        if efi_required and efi_partition:
            subprocess.run(
                ["mkfs.fat", "-F", "32", efi_partition],
                check=True,
            )
        elif efi_required:
            print("EFI partition not found.")
            sys.exit(1)

        if encrypt:
            print("Setting up encryption...")
            if swap_size > 0 and swap_partition:
                encrypt_partition(swap_partition, "swapcrypt", encrypt_pwd)
                subprocess.run(["mkswap", "/dev/mapper/swapcrypt"], check=True)
            elif swap_size > 0:
                print("Swap partition not found.")
                sys.exit(1)

            if root_partition:
                encrypt_partition(root_partition, "rootcrypt", encrypt_pwd)
                subprocess.run(
                    ["mkfs.ext4", "/dev/mapper/rootcrypt"],
                    check=True,
                )
            else:
                print("Root partition not found.")
                sys.exit(1)
        else:
            if swap_size > 0 and swap_partition:
                subprocess.run(["mkswap", swap_partition], check=True)
            elif swap_size > 0:
                print("Swap partition not found.")
                sys.exit(1)

            if root_partition:
                subprocess.run(["mkfs.ext4", root_partition], check=True)
            else:
                print("Root partition not found.")
                sys.exit(1)

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while formatting partitions: {e}")
        sys.exit(1)


def mount_partitions(device, encrypt, swap_size, efi_required):
    try:
        print("Mounting partitions...")
        partitions = get_partitions(device)

        # Find partitions by partition label (PARTLABEL)
        efi_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "EFI"
            ),
            None,
        )
        swap_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "SWAP"
            ),
            None,
        )
        root_partition = next(
            (
                part
                for part, info in partitions.items()
                if info.get("partlabel") == "ROOT"
            ),
            None,
        )

        if encrypt:
            if root_partition:
                subprocess.run(
                    ["mount", "/dev/mapper/rootcrypt", "/mnt"],
                    check=True,
                )
            else:
                print("Root partition not found.")
                sys.exit(1)

            if efi_partition:
                os.makedirs("/mnt/boot", exist_ok=True)
                subprocess.run(
                    ["mount", efi_partition, "/mnt/boot"],
                    check=True,
                )
            elif efi_required:
                print("EFI partition not found.")
                sys.exit(1)

            if swap_size > 0 and swap_partition:
                subprocess.run(["swapon", "/dev/mapper/swapcrypt"], check=True)
            elif swap_size > 0:
                print("Swap partition not found.")
                sys.exit(1)
        else:
            if root_partition:
                subprocess.run(["mount", root_partition, "/mnt"], check=True)
            else:
                print("Root partition not found.")
                sys.exit(1)

            if efi_partition:
                os.makedirs("/mnt/boot", exist_ok=True)
                subprocess.run(["mount", efi_partition, "/mnt/boot"], check=True)
            elif efi_required:
                print("EFI partition not found.")
                sys.exit(1)

            if swap_size > 0 and swap_partition:
                subprocess.run(["swapon", swap_partition], check=True)
            elif swap_size > 0:
                print("Swap partition not found.")
                sys.exit(1)

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while mounting partitions: {e}")
        sys.exit(1)


def main():
    device = select_device()
    encrypt_pwd = ask_encryption()
    swap_size = get_swap_size()
    efi_required = confirm_efi()
    partition_device(device, swap_size, efi_required)
    format_partitions(
        device, encrypt_pwd is not None, encrypt_pwd, swap_size, efi_required
    )
    mount_partitions(device, encrypt_pwd is not None, swap_size, efi_required)
    print("Partitions have been successfully set up and mounted.")


if __name__ == "__main__":
    main()
