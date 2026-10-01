# Budgie Wayland Multi-Monitor Panel Fix

## The Issue

When running Ubuntu Budgie on Wayland (`labwc`) with an external monitor connected to a laptop:

- The top panel anchors to the external monitor (e.g., 1080p), but its width remains restricted to the internal display's resolution (e.g., 1366px), looking like an awkward dock.
- This is caused by a race condition during initialization: `gtk-layer-shell` binds to the first active DRM/KMS output (`eDP`) before the external output (`HDMI` / `DP`) completes its handshake.
- Toggling dock mode fixes it temporarily, but the glitch returns after every reboot or relogin.

---

## How It Works

Until per-monitor panel selection lands natively in upstream Budgie:

1. Waits for the Wayland socket and `wlr-randr` to become responsive.
2. Auto-detects connected internal (`eDP*`) and external (`HDMI*` / `DP*`) outputs.
3. Saves the current position and display mode of the internal screen.
4. Temporarily shuts down the internal display (`--off`) and restarts the panel (`budgie-panel --replace &`).
5. With only the external monitor active, the panel expands to full width.
6. Re-enables the internal display at its exact previous coordinates and mode.
7. Exits silently if no external display is plugged in (leaves mobile laptop usage untouched).

---

## Prerequisites

Ensure you have `wlr-randr` installed:

```bash
sudo apt update
sudo apt install wlr-randr
```

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/kuscadev/budgie-wayland-panel-fix.git
cd budgie-wayland-panel-fix
chmod +x install.sh
./install.sh
```

The installer places:

- Fix script $\rightarrow$ ~/.local/bin/budgie-panel-fix.sh
- Autostart entry $\rightarrow$ ~/.config/autostart/budgie-panel-fix.desktop

Log out and log back in to apply.

## Testing Immediately

To test without logging out:

```bash
bash ~/.local/bin/budgie-panel-fix.sh
```

## Uninstallation

To remove the script and its autostart entry:

```bash
./install.sh --uninstall
```

## Disclaimer

This is a brute-force workaround to keep multi-monitor setups functional until upstream Wayland display geometry handling matures in budgie-desktop. Review the script before running it on production systems.
