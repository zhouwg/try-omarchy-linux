#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/versions.conf"

QEMU_DIR="${SCRIPT_DIR}/../qemu-${QEMU_VERSION}"
QEMU_SYMLINK="${SCRIPT_DIR}/../qemu"
QEMU_URL="https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz"
TMP_DIR="/tmp/qemu-download-$$"

if [ -d "${QEMU_DIR}" ]; then
    echo "QEMU ${QEMU_VERSION} source found at: ${QEMU_DIR}"
    if [ -L "${QEMU_SYMLINK}" ] && [ "$(readlink "${QEMU_SYMLINK}")" = "qemu-${QEMU_VERSION}" ]; then
        echo "Symlink 'qemu' -> 'qemu-${QEMU_VERSION}' exists."
    else
        rm -f "${QEMU_SYMLINK}"
        echo "Creating symlink: qemu -> qemu-${QEMU_VERSION}"
        ln -s "qemu-${QEMU_VERSION}" "${QEMU_SYMLINK}"
    fi
    exit 0
fi

echo "Downloading QEMU ${QEMU_VERSION}..."
mkdir -p "${TMP_DIR}"
curl -L "${QEMU_URL}" | tar -xJ -C "${TMP_DIR}"

echo "Moving to ${QEMU_DIR}..."
mv "${TMP_DIR}/qemu-${QEMU_VERSION}" "${QEMU_DIR}"

echo "Creating symlink: qemu -> qemu-${QEMU_VERSION}"
ln -s "qemu-${QEMU_VERSION}" "${QEMU_SYMLINK}"

rm -rf "${TMP_DIR}"

echo ""
echo "QEMU source ready at: ${QEMU_DIR}"
