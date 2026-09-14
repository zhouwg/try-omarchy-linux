#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/versions.conf"

SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"
EXTRACTED="${SRC_DIR}/qemu-${QEMU_VERSION}"
BUILD_DIR_QEMU="${BUILD_DIR}/qemu-${QEMU_VERSION}"

if [ ! -d "${EXTRACTED}" ]; then
    echo "Error: QEMU source not found at ${EXTRACTED}"
    echo "Run download.sh first."
    exit 1
fi

# Check for required dependencies
echo "Checking build dependencies..."

# Check virglrenderer
if ! pkg-config --exists virglrenderer 2>/dev/null; then
    echo "Error: virglrenderer not found."
    echo "Install it: sudo apt install libvirglrenderer-dev"
    exit 1
fi

# Clean previous build if configure options changed
if [ -f "${BUILD_DIR_QEMU}/config-host.mak" ]; then
    if ! grep -q "virgl" "${BUILD_DIR_QEMU}/config-host.mak" 2>/dev/null; then
        echo "Previous build without virglrenderer found. Cleaning..."
        rm -rf "${BUILD_DIR_QEMU}"
    fi
fi

mkdir -p "${BUILD_DIR_QEMU}"
cd "${BUILD_DIR_QEMU}"

echo "Configuring QEMU ${QEMU_VERSION}..."
"${EXTRACTED}/configure" \
    --prefix="${INSTALL_DIR}" \
    --target-list=x86_64-softmmu \
    --enable-kvm \
    --enable-opengl \
    --enable-virglrenderer \
    --enable-gtk \
    --disable-sdl \
    --disable-docs \
    --disable-user

echo "Building QEMU ${QEMU_VERSION} (this may take a while)..."
make -j"$(nproc)"

echo "Installing QEMU to ${INSTALL_DIR}..."
make install

echo ""
echo "Build complete!"
echo "QEMU binary: ${INSTALL_DIR}/bin/qemu-system-x86_64"
