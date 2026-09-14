#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/versions.conf"

SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"

mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${INSTALL_DIR}"

TARBALL="${SRC_DIR}/qemu-${QEMU_VERSION}.tar.xz"
EXTRACTED="${SRC_DIR}/qemu-${QEMU_VERSION}"

if [ -d "${EXTRACTED}" ]; then
    echo "QEMU ${QEMU_VERSION} already extracted at ${EXTRACTED}"
    exit 0
fi

if [ ! -f "${TARBALL}" ]; then
    echo "Downloading QEMU ${QEMU_VERSION}..."
    curl -L -o "${TARBALL}" "${QEMU_URL}"
fi

echo "Extracting QEMU ${QEMU_VERSION}..."
tar -xf "${TARBALL}" -C "${SRC_DIR}"

echo "Done. Source at: ${EXTRACTED}"
