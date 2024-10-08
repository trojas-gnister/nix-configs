# Autofullscreen

**WIP**

## Dependencies

Before installing **Autofullscreen**, ensure that the following dependencies are installed on your system:

### System Dependencies

- [`wmctrl`](http://tripie.sweb.cz/utilities/wmctrl/) – A command-line tool to interact with an X Window Manager.
- [`flatpak`](https://flatpak.org/) – A software utility for package management to handle and run Flatpak applications.

#### Install System Dependencies

**wmctrl** and **flatpak** are required for **Autofullscreen** to manage window states and interact with Flatpak applications. Install them using your distribution’s package manager.

##### **Ubuntu/Debian**

```bash
sudo apt update
sudo apt install wmctrl flatpak
```

##### **Fedora**

```bash
sudo dnf install wmctrl flatpak
```

##### **Arch Linux**

```bash
sudo pacman -S wmctrl flatpak
```

##### **openSUSE**

```bash
sudo zypper install wmctrl flatpak
```

##### **Gentoo**

```bash
sudo emerge wmctrl flatpak
```

## Installation and Usage

1. Install system dependencies like `wmctrl` and `flatpak`.
2. Ensure your Rust environment is set up.
3. Build the project using Cargo:

```bash
cargo build --release
```

4. Run the application:

```bash
cargo run
```
