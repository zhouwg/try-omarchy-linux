#!/bin/bash
# QEMU build setup script for try-omarchy-linux
# Verified on Ubuntu 20.04 & Ubuntu 26.04

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "  QEMU Build Setup"
echo "  ================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root."
    exit 1
fi

# Step 1: Install dependencies
echo "[1/3] Installing build dependencies..."

sudo apt-get update

# Essential build tools
sudo apt-get install -y \
    build-essential \
    meson \
    ninja-build \
    python3 \
    python3-pip \
    pkg-config

# Python tomli (required for QEMU build)
if ! python3 -c "import tomli" 2>/dev/null; then
    echo "  Installing python3-tomli..."
    sudo apt-get install -y python3-tomli || pip3 install --user tomli
fi

# QEMU dependencies
sudo apt-get install -y \
    libglib2.0-dev \
    libfdt-dev \
    libpixman-1-dev \
    zlib1g-dev

# GTK display (default)
sudo apt-get install -y libgtk-3-dev

# Optional: Enable these if needed
# sudo apt-get install -y libsdl2-dev      # SDL display
# sudo apt-get install -y libvncserver-dev # VNC display
# sudo apt-get install -y librbd-dev       # Ceph RBD
# sudo apt-get install -y glusterfs-common libglusterfs-dev  # GlusterFS
# sudo apt-get install -y libssh-dev       # SSH support
# sudo apt-get install -y libepoxy-dev     # OpenGL
# sudo apt-get install -y libvirglrenderer-dev  # Virgl 3D

# Verify virglrenderer (recommended for 3D acceleration)
if pkg-config --exists virglrenderer 2>/dev/null; then
    echo "  virglrenderer: found"
else
    echo "  virglrenderer: not found (3D acceleration disabled)"
    echo "  To enable: sudo apt install libvirglrenderer-dev"
fi

# Step 2: Download QEMU source
echo ""
echo "[2/3] Downloading QEMU source..."
"${SCRIPT_DIR}/download.sh"

# Step 3: Build QEMU
echo ""
echo "[3/3] Building QEMU..."
"${SCRIPT_DIR}/build.sh"

echo ""
echo "  ========================="
echo "  Setup complete!"
echo "  ========================="
echo ""
echo "  QEMU binary: ${SCRIPT_DIR}/install/bin/qemu-system-x86_64"
echo ""
echo "  Next steps:"
echo "    ./scripts/install.sh    # Install Omarchy from ISO"
echo "    ./scripts/start.sh      # Boot installed system"
echo ""
