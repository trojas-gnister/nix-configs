#!/usr/bin/env python3

import sys
import subprocess
import getpass
import os


# TODO: if there are no devices with 20GB+ free space throw an error
def select_device():
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
    lsblk_output = subprocess.check_output(
        ["lsblk", "-l", "-o", "NAME,TYPE", "-n", f"/dev/{device}"],
        text=True,
    )
    partitions = []
    for line in lsblk_output.strip().split("\n"):
        parts = line.strip().split()
        name = parts[0]
        type_ = parts[1] if len(parts) > 1 else ""
        if type_ == "part":
            partitions.append(f"/dev/{name}")

    print("Partitions detected:")
    for partition in partitions:
        print(partition)

    return partitions


def partition_device(device, swap_size, efi_required):
    print(f"Proceeding to partition /dev/{device}...")

    try:
        existing_partitions = set(get_partitions(device))

        partition_commands = []

        if efi_required:
            partition_commands.append(
                [
                    "sgdisk",
                    "-n",
                    "0:0:+512M",
                    "-t",
                    "0:EF00",
                    f"/dev/{device}",
                ]
            )

        if swap_size > 0:
            partition_commands.append(
                [
                    "sgdisk",
                    "-n",
                    f"0:0:+{swap_size}G",
                    "-t",
                    "0:8200",
                    f"/dev/{device}",
                ]
            )

        partition_commands.append(
            [
                "sgdisk",
                "-n",
                "0:0:0",
                "-t",
                "0:8300",
                f"/dev/{device}",
            ]
        )

        for cmd in partition_commands:
            subprocess.run(cmd, check=True)

        subprocess.run(["sync"], check=True)

        all_partitions = set(get_partitions(device))
        new_partitions = list(all_partitions - existing_partitions)
        new_partitions.sort()  # Sort the partitions

        partition_mapping = {}
        idx = 0

        if efi_required:
            partition_mapping["efi_partition"] = new_partitions[idx]
            idx += 1

        if swap_size > 0:
            partition_mapping["swap_partition"] = new_partitions[idx]
            idx += 1

        partition_mapping["root_partition"] = new_partitions[idx]

        print("Partition mapping:")
        for key, value in partition_mapping.items():
            print(f"{key}: {value}")

        return partition_mapping

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while partitioning the device: {e}")
        sys.exit(1)


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


def format_partitions(partition_mapping, encrypt, encrypt_pwd):
    print("Formatting partitions...")
    try:
        if "efi_partition" in partition_mapping:
            efi_partition = partition_mapping["efi_partition"]
            subprocess.run(
                ["mkfs.fat", "-F", "32", efi_partition],
                check=True,
            )

        if encrypt:
            print("Setting up encryption...")
            if "swap_partition" in partition_mapping:
                swap_partition = partition_mapping["swap_partition"]
                encrypt_partition(swap_partition, "swapcrypt", encrypt_pwd)
                subprocess.run(["mkswap", "/dev/mapper/swapcrypt"], check=True)

            root_partition = partition_mapping["root_partition"]
            encrypt_partition(root_partition, "rootcrypt", encrypt_pwd)
            subprocess.run(
                ["mkfs.ext4", "/dev/mapper/rootcrypt"],
                check=True,
            )
        else:
            if "swap_partition" in partition_mapping:
                swap_partition = partition_mapping["swap_partition"]
                subprocess.run(["mkswap", swap_partition], check=True)

            root_partition = partition_mapping["root_partition"]
            subprocess.run(["mkfs.ext4", root_partition], check=True)

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while formatting partitions: {e}")
        sys.exit(1)


def mount_partitions(partition_mapping, encrypt):
    try:
        print("Mounting partitions...")

        if encrypt:
            root_partition = "/dev/mapper/rootcrypt"
            subprocess.run(
                ["mount", root_partition, "/mnt"],
                check=True,
            )
            if "efi_partition" in partition_mapping:
                efi_partition = partition_mapping["efi_partition"]
                os.makedirs("/mnt/boot", exist_ok=True)
                subprocess.run(
                    ["mount", efi_partition, "/mnt/boot"],
                    check=True,
                )
            if "swap_partition" in partition_mapping:
                subprocess.run(["swapon", "/dev/mapper/swapcrypt"], check=True)
        else:
            root_partition = partition_mapping["root_partition"]
            subprocess.run(["mount", root_partition, "/mnt"], check=True)

            if "efi_partition" in partition_mapping:
                efi_partition = partition_mapping["efi_partition"]
                os.makedirs("/mnt/boot", exist_ok=True)
                subprocess.run(["mount", efi_partition, "/mnt/boot"], check=True)

            if "swap_partition" in partition_mapping:
                swap_partition = partition_mapping["swap_partition"]
                subprocess.run(["swapon", swap_partition], check=True)

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while mounting partitions: {e}")
        sys.exit(1)


def main():
    device = select_device()
    encrypt_pwd = ask_encryption()
    swap_size = get_swap_size()
    efi_required = confirm_efi()
    partition_mapping = partition_device(device, swap_size, efi_required)
    encrypt = encrypt_pwd is not None
    format_partitions(partition_mapping, encrypt, encrypt_pwd)
    mount_partitions(partition_mapping, encrypt)
    print("Partitions have been successfully set up and mounted.")


if __name__ == "__main__":
    main()
