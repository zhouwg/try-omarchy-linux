#!/bin/bash
set -euo pipefail

# Comprehensive QEMU patch script for Omarchy
# Applies: software rendering + QEMU-friendly keybindings

echo ""
echo "  =================================="
echo "  Omarchy QEMU Compatibility Patches"
echo "  =================================="
echo ""

# Detect if running in a VM
detect_vm() {
    if command -v systemd-detect-virt &>/dev/null; then
        local virt=$(systemd-detect-virt 2>/dev/null)
        if echo "$virt" | grep -qiE "qemu|kvm|vm"; then
            return 0
        fi
    fi
    if [ -f /sys/class/dmi/id/product_name ]; then
        local product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        if echo "$product" | grep -qiE "QEMU|Standard PC"; then
            return 0
        fi
    fi
    return 1
}

if ! detect_vm(); then
    echo "Not running in a VM. Skipping patches."
    exit 0
fi

# Try to mount shared folder if not already mounted
MOUNT_POINT="/mnt/hostshare"
if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Mounting shared folder..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount -t 9p -o trans=virtio hostshare "$MOUNT_POINT" 2>/dev/null || true
fi

# ============================================
# Patch 1: Software Rendering
# ============================================
echo "[1/2] Applying software rendering patch..."

ENVS_FILE="$HOME/.config/hypr/envs.lua"
if [ ! -f "$ENVS_FILE" ]; then
    echo "  Creating $ENVS_FILE..."
    mkdir -p "$(dirname "$ENVS_FILE")"
    echo '-- Hyprland environment variables' > "$ENVS_FILE"
fi

if grep -q "detect_vm" "$ENVS_FILE" 2>/dev/null; then
    echo "  Software rendering already patched."
else
    cp "$ENVS_FILE" "${ENVS_FILE}.bak"
    cat >> "$ENVS_FILE" << 'RENDERING'

-- VM detection and software rendering (added by try-omarchy-linux)
local function detect_vm()
  local handle = io.popen("systemd-detect-virt 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and (result:match("qemu") or result:match("kvm") or result:match("vm")) then
      return true
    end
  end
  local f = io.open("/sys/class/dmi/id/product_name", "r")
  if f then
    local product = f:read("*a")
    f:close()
    if product and (product:match("QEMU") or product:match("Standard PC")) then
      return true
    end
  end
  return false
end

if detect_vm() then
  hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
  hl.env("GALLIUM_DRIVER", "llvmpipe")
  hl.env("QSG_RHI_BACKEND", "software")
  hl.env("QT_QUICK_BACKEND", "software")
  hl.env("GSK_RENDERER", "software")
end
RENDERING
    echo "  Software rendering patch applied."
fi

# ============================================
# Patch 2: QEMU-friendly Keybindings
# ============================================
echo "[2/2] Adding QEMU-friendly keybindings..."

BINDINGS_DIR="$HOME/.config/hypr/bindings"
mkdir -p "$BINDINGS_DIR"
APPLICATIONS_FILE="$BINDINGS_DIR/applications.lua"

if grep -q "F12.*Terminal.*QEMU" "$APPLICATIONS_FILE" 2>/dev/null; then
    echo "  Keybindings already patched."
else
    if [ -f "$APPLICATIONS_FILE" ]; then
        cp "$APPLICATIONS_FILE" "${APPLICATIONS_FILE}.bak"
    fi
    cat >> "$APPLICATIONS_FILE" << 'KEYBINDS'

-- QEMU-friendly bindings (F keys without Super)
o.bind("F12", "Terminal (QEMU)", { omarchy = "terminal" })
o.bind("F11", "File manager (QEMU)", { omarchy = "nautilus" })
o.bind("F10", "Browser (QEMU)", { omarchy = "browser" })
KEYBINDS
    echo "  QEMU-friendly keybindings added."
fi

# ============================================
# Summary
# ============================================
echo ""
echo "  =================================="
echo "  All patches applied successfully!"
echo "  =================================="
echo ""
echo "  New keybindings:"
echo "    F12 = Terminal"
echo "    F11 = File Manager"
echo "    F10 = Browser"
echo ""
echo "  Please reboot for all changes to take effect."
echo ""
