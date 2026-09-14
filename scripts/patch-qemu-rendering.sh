#!/bin/bash
set -euo pipefail

# This script applies software rendering patches for QEMU VM compatibility.
# It automatically mounts the shared folder and applies patches.

echo ""
echo "  Omarchy QEMU Software Rendering Patch"
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

# Find the patch source - either from shared folder or local
PATCH_SOURCE=""
if [ -f "$MOUNT_POINT/patch-qemu-rendering.sh" ]; then
    PATCH_SOURCE="$MOUNT_POINT"
elif [ -f "$(dirname "$0")/omarchy/default/hypr/envs.lua" ]; then
    PATCH_SOURCE="$(dirname "$0")"
fi

# Find Hyprland envs.lua
ENVS_FILE="$HOME/.config/hypr/envs.lua"
if [ ! -f "$ENVS_FILE" ]; then
    echo "Error: $ENVS_FILE not found."
    echo "Make sure Omarchy is properly installed."
    exit 1
fi

# Check if already patched
if grep -q "detect_vm" "$ENVS_FILE" 2>/dev/null; then
    echo "Patches already applied."
    exit 0
fi

# Backup original
cp "$ENVS_FILE" "${ENVS_FILE}.bak"

# Append VM detection and software rendering config
cat >> "$ENVS_FILE" << 'PATCH'

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
PATCH

echo ""
echo "Patches applied successfully!"
echo "Original backup: ${ENVS_FILE}.bak"
echo ""
echo "Please restart Hyprland or reboot for changes to take effect."
echo ""
