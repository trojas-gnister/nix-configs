# Autofullscreen

**Autofullscreen** is a lightweight Linux application built in Rust that automatically launches applications and keeps them in fullscreen mode. It is desktop environment-agnostic, making it ideal for single-use VMs and ensuring a seamless, distraction-free experience.

## Dependencies

Before installing **Autofullscreen**, ensure that the following dependencies are installed on your system:

- [`wmctrl`](http://tripie.sweb.cz/utilities/wmctrl/) – A command-line tool to interact with an X Window Manager.

### Install Dependencies

**wmctrl** is required for **Autofullscreen** to manage window states. Install it using your distribution’s package manager.

#### **Ubuntu/Debian**

```bash
sudo apt update
sudo apt install wmctrl
```

#### **Fedora**

```bash
sudo dnf install wmctrl
```

#### **Arch Linux**

```bash
sudo pacman -S wmctrl
```

#### **openSUSE**

```bash
sudo zypper install wmctrl
```

#### **Gentoo**

```bash
sudo emerge wmctrl
```

