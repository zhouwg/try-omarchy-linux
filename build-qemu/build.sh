#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/versions.conf"

QEMU_SRC="${SCRIPT_DIR}/../qemu"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"

if [ ! -f "${QEMU_SRC}/meson.build" ]; then
    echo "Error: QEMU source not found at ${QEMU_SRC}"
    echo "Run download.sh first."
    exit 1
fi

# Check for required dependencies
echo "Checking build dependencies..."

# Find Python with tomli support
find_python() {
    for py in python3.10 python3.11 python3.12 python3 python3.8; do
        if command -v "$py" &>/dev/null; then
            if "$py" -c "import tomli" 2>/dev/null; then
                echo "$py"
                return 0
            fi
        fi
    done
    return 1
}

PYTHON=$(find_python) || {
    echo "Error: No Python with tomli found."
    echo "Install tomli: pip3 install tomli"
    exit 1
}
echo "Using Python: ${PYTHON} ($(${PYTHON} --version))"

# Check virglrenderer
if ! pkg-config --exists virglrenderer 2>/dev/null; then
    echo "Error: virglrenderer not found."
    echo "Install it: sudo apt install libvirglrenderer-dev"
    exit 1
fi

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "Configuring QEMU ${QEMU_VERSION}..."
"${QEMU_SRC}/configure" \
    --prefix="${INSTALL_DIR}" \
    --python="${PYTHON}" \
    --target-list=x86_64-softmmu \
    --enable-kvm \
    --enable-opengl \
    --enable-virglrenderer \
    --enable-gtk \
    --enable-slirp \
    --disable-sdl \
    --disable-docs \
    --disable-user \
    --disable-plugins \
    --disable-dbus-display

echo "Building QEMU ${QEMU_VERSION} (this may take a while)..."
make -j"$(nproc)"

echo "Installing QEMU to ${INSTALL_DIR}..."
make install

echo ""
echo "Build complete!"
echo "QEMU binary: ${INSTALL_DIR}/bin/qemu-system-x86_64"
