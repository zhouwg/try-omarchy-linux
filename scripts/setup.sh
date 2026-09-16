#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."

echo ""
echo "  ___  __   ___  __  ___  ____"
echo " / _ \|  | / _ \|  |/ _ \|  _ \\"
echo "| |_| |  || |_| |  ( |_| |  _ <"
echo " \___/|__|\___/|__|\___/|_| \_\  Linux"
echo ""
echo "  One-time setup"
echo ""

# Step 1: Install dependencies and build QEMU
QEMU_BIN="${PROJECT_DIR}/build-qemu/install/bin/qemu-system-x86_64"
if [ ! -f "${QEMU_BIN}" ]; then
    echo "[1/3] Installing dependencies and building QEMU..."
    "${PROJECT_DIR}/build-qemu/setup.sh"
else
    echo "[1/3] QEMU already built, skipping..."
fi

# Step 2: Create disk
DISK_FILE="${PROJECT_DIR}/disks/omarchy.qcow2"
if [ ! -f "${DISK_FILE}" ]; then
    echo "[2/3] Creating virtual disk..."
    "${SCRIPT_DIR}/create-disk.sh"
else
    echo "[2/3] Disk already exists, skipping..."
fi

# Step 3: Download ISO
ISO_FILE="${PROJECT_DIR}/iso/omarchy-4.0.3.iso"
if [ ! -f "${ISO_FILE}" ]; then
    echo "[3/3] Downloading Omarchy ISO..."
    "${SCRIPT_DIR}/download-iso.sh"
else
    echo "[3/3] ISO already exists, skipping..."
fi

echo ""
echo "Setup complete!"
echo ""
echo "Install and start Omarchy with:"
echo "  ./scripts/install.sh"
echo "  ./scripts/start.sh"
echo ""
