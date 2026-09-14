#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_IMG="${SCRIPT_DIR}/../build-qemu/install/bin/qemu-img"
DISK_DIR="${SCRIPT_DIR}/../disks"
DISK_FILE="${DISK_DIR}/omarchy.qcow2"
#DISK_SIZE="20G"
DISK_SIZE="8G"

mkdir -p "${DISK_DIR}"

if [ -f "${DISK_FILE}" ]; then
    echo "Disk already exists: ${DISK_FILE}"
    echo "Delete it first if you want to recreate."
    exit 0
fi

echo "Creating QCOW2 disk: ${DISK_FILE} (${DISK_SIZE})"
"${QEMU_IMG}" create -f qcow2 "${DISK_FILE}" "${DISK_SIZE}"

echo ""
echo "Disk created successfully!"
echo "Location: ${DISK_FILE}"
