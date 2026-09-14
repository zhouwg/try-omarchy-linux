#!/bin/bash
set -euo pipefail

# This script adds QEMU-friendly keybindings to Omarchy.
# Run this inside the VM after installation.

echo ""
echo "  Adding QEMU-friendly keybindings..."
echo ""

# Find Hyprland bindings directory
BINDINGS_DIR="$HOME/.config/hypr/bindings"
if [ ! -d "$BINDINGS_DIR" ]; then
    mkdir -p "$BINDINGS_DIR"
fi

APPLICATIONS_FILE="$BINDINGS_DIR/applications.lua"

# Check if already patched
if grep -q "F12.*Terminal.*QEMU" "$APPLICATIONS_FILE" 2>/dev/null; then
    echo "QEMU keybindings already added."
    exit 0
fi

# Backup original if exists
if [ -f "$APPLICATIONS_FILE" ]; then
    cp "$APPLICATIONS_FILE" "${APPLICATIONS_FILE}.bak"
fi

# Create or append QEMU-friendly bindings
cat >> "$APPLICATIONS_FILE" << 'PATCH'

-- QEMU-friendly bindings (F keys without Super)
o.bind("F12", "Terminal (QEMU)", { omarchy = "terminal" })
o.bind("F11", "File manager (QEMU)", { omarchy = "nautilus" })
o.bind("F10", "Browser (QEMU)", { omarchy = "browser" })
PATCH

echo ""
echo "QEMU-friendly keybindings added!"
echo ""
echo "  F12 = Terminal"
echo "  F11 = File Manager"
echo "  F10 = Browser"
echo ""
echo "Please restart Hyprland or reboot for changes to take effect."
echo ""
