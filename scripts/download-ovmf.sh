#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVMF_DIR="${SCRIPT_DIR}/../ovmf"

mkdir -p "${OVMF_DIR}"

OVMF_CODE="${OVMF_DIR}/OVMF_CODE.fd"
OVMF_VARS="${OVMF_DIR}/OVMF_VARS.fd"

if [ -f "${OVMF_CODE}" ] && [ -f "${OVMF_VARS}" ]; then
    echo "OVMF firmware already exists."
    exit 0
fi

echo "Downloading OVMF UEFI firmware..."

# Try to extract from system OVMF package
if [ -f /usr/share/OVMF/OVMF_CODE.fd ]; then
    cp /usr/share/OVMF/OVMF_CODE.fd "${OVMF_CODE}"
    cp /usr/share/OVMF/OVMF_VARS.fd "${OVMF_VARS}"
    echo "OVMF copied from system."
else
    echo "Error: OVMF not found on system."
    echo "Install it: sudo apt install ovmf"
    echo "Or download manually from: https://github.com/tianocore/edk2/releases"
    exit 1
fi

echo "OVMF firmware ready."
