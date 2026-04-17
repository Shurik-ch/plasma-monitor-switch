# Monitor Switch — KDE Plasma 6 Widget

A system tray widget for KDE Plasma 6 that lets you switch monitor input sources (DisplayPort, HDMI, etc.) directly from the desktop using DDC/CI.

![Monitor Switch Widget](https://raw.githubusercontent.com/Shurik-ch/plasma-monitor-switch/main/screenshot.png)

## Features

- Auto-detects connected monitors and available input sources
- Highlights the currently active input
- Custom names for inputs (e.g. rename "Input 0x1b" to "Mac")
- Refresh button to re-detect inputs
- Supports multiple monitors

## Requirements

- KDE Plasma 6
- [`ddcutil`](https://www.ddcutil.com/) — DDC/CI command-line tool
- `python3`
- i2c permissions (see below)

## Installation

### From KDE Store
Search for **"Monitor Switch"** in *System Settings → Plasma Widgets → Get New Widgets*.

### Manual
```bash
git clone https://github.com/Shurik-ch/plasma-monitor-switch.git
cp -r plasma-monitor-switch/com.monitor.switch ~/.local/share/plasma/plasmoids/
```
Then restart Plasma:
```bash
plasmashell --replace &
```

## Setup

### 1. Install ddcutil
```bash
# Fedora / RHEL
sudo dnf install ddcutil

# Ubuntu / Debian
sudo apt install ddcutil

# Arch
sudo pacman -S ddcutil
```

### 2. Fix i2c permissions
Create `/etc/udev/rules.d/60-ddcutil-i2c.rules` with:
```
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
```
Then add yourself to the `i2c` group:
```bash
sudo usermod -aG i2c $USER
sudo udevadm control --reload-rules && sudo udevadm trigger
```
Log out and back in for group changes to take effect.

### 3. Add to system tray
Right-click the system tray → *Configure System Tray* → *Extra Items* → enable **Monitor Switch**.

## Usage

Click the monitor icon in the system tray to see available inputs. Click an input to switch. The active input is highlighted.

To set custom names: right-click the widget → *Configure Monitor Switch* → *General*.

## License

GPL-2.0-or-later © Alexandr Anddryushenkov
