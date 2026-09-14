#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="${SCRIPT_DIR}/../iso"
ISO_FILE="${ISO_DIR}/omarchy-4.0.3.iso"
ISO_URL="https://iso.omarchy.org/omarchy-4.0.3.iso"

mkdir -p "${ISO_DIR}"

if [ -f "${ISO_FILE}" ]; then
    echo "ISO already exists: ${ISO_FILE}"
    exit 0
fi

echo "Downloading Omarchy ISO..."
echo "  URL: ${ISO_URL}"
echo "  Destination: ${ISO_FILE}"
echo ""

wget --show-progress -O "${ISO_FILE}" "${ISO_URL}"

echo ""
echo "Download complete: ${ISO_FILE}"
