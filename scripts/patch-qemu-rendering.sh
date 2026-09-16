#!/bin/bash
set -euo pipefail

# This script applies software rendering patches for QEMU VM compatibility.
# Run this inside the VM after installation.
#
# Prerequisites:
#   sudo mount -t 9p -o trans=virtio hostshare /mnt/hostshare
#   /mnt/hostshare/patch-qemu-rendering.sh

echo ""
echo "  Omarchy QEMU Software Rendering Patch"
echo ""

# Detect if running in a VM
detect_vm() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virt=$(systemd-detect-virt 2>/dev/null || true)
        case "$virt" in
            qemu|kvm|vmware|virtualbox|oracle*)
                return 0
                ;;
        esac
    fi
    if [ -f /sys/class/dmi/id/product_name ]; then
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
        case "$product" in
            *QEMU*|*"Standard PC"*)
                return 0
                ;;
        esac
    fi
    return 1
}

if ! detect_vm; then
    echo "Not running in a VM. Skipping patches."
    exit 0
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
