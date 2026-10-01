#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
SCRIPT_TARGET="$BIN_DIR/budgie-panel-fix.sh"
DESKTOP_TARGET="$AUTOSTART_DIR/budgie-panel-fix.desktop"

if [[ "${1:-}" == "--uninstall" ]]; then
    echo "[-] Uninstalling budgie-panel-fix..."
    rm -f "$SCRIPT_TARGET"
    rm -f "$DESKTOP_TARGET"
    echo "[] Uninstalled successfully."
    exit 0
fi

echo "========================================="
echo " Budgie Wayland Multi-Monitor Fix Installer"
echo "========================================="

for cmd in wlr-randr awk budgie-panel; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[!] Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

INTERNAL_OUTPUT=$(wlr-randr | awk '/^eDP/ {print $1; exit}')
EXTERNAL_OUTPUT=$(wlr-randr | awk '/^(HDMI|DP)/ {print $1; exit}')

if [[ -z "$INTERNAL_OUTPUT" ]] || [[ -z "$EXTERNAL_OUTPUT" ]]; then
    echo "[!] Error: Could not detect both internal (eDP) and external (HDMI/DP) displays." >&2
    echo "    Make sure both monitors are connected and powered on before running this installer." >&2
    exit 1
fi

POS=$(wlr-randr | awk -v out="$INTERNAL_OUTPUT" '$1==out {found=1} found && /Position:/ {print $2; exit}')
MODE=$(wlr-randr | awk -v out="$INTERNAL_OUTPUT" '$1==out {found=1} found && /current/ {print $1 "@" $3;
exit}')

POS="${POS:-1920,0}"
MODE="${MODE:-1366x768@60Hz}"

echo "[*] Detected hardware configuration:"
echo "    Internal Display : $INTERNAL_OUTPUT"
echo "    External Display : $EXTERNAL_OUTPUT"
echo "    Internal Mode    : $MODE"
echo "    Internal Position: $POS"
echo

read -rp "Proceed with this configuration? [Y/n] " confirm
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "[-] Installation aborted by user."
    exit 0
fi

mkdir -p "$BIN_DIR" "$AUTOSTART_DIR"

cat << EOF > "$SCRIPT_TARGET"
#!/usr/bin/env bash

for _ in {1..50}; do
    if wlr-randr >/dev/null 2>&1; then
        break:    fi
    sleep 0.1
done

if ! wlr-randr | grep -q "$EXTERNAL_OUTPUT"; then
    exit 0
fi

wlr-randr --output "$INTERNAL_OUTPUT" --off
budgie-panel --replace &
sleep 0.8
wlr-randr --output "$INTERNAL_OUTPUT" --on --mode "$MODE" --pos "$POS"
EOF

chmod +x "$SCRIPT_TARGET"

cat << EOF > "$DESKTOP_TARGET"
[Desktop Entry]
Type=Application
Name=Budgie Panel Multi-Monitor Fix
Comment=Fixes panel width bug on multi-monitor Budgie Wayland
Exec=/bin/bash -c "\$HOME/.local/bin/budgie-panel-fix.sh"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo "[] Installation completed successfully!"
echo "    Script deployed:   $SCRIPT_TARGET"
echo "    Autostart entry:   $DESKTOP_TARGET"
echo "
To test now, run:
    bash $SCRIPT_TARGET"
