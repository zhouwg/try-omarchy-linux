#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="${SCRIPT_DIR}/../iso"
ISO_URL="https://iso.omarchy.org/omarchy-4.0.3.iso"

mkdir -p "${ISO_DIR}"

# Check if any omarchy ISO already exists
EXISTING_ISO=$(find "${ISO_DIR}" -maxdepth 1 -name "omarchy-*.iso" -type f | head -1)
if [ -n "${EXISTING_ISO}" ]; then
    echo "ISO already exists: ${EXISTING_ISO}"
    echo "Skip download. To re-download, delete it first."
    exit 0
fi

echo "Downloading Omarchy ISO..."
echo "  URL: ${ISO_URL}"
echo "  Destination: ${ISO_DIR}"
echo ""

wget --show-progress -P "${ISO_DIR}" "${ISO_URL}"

DOWNLOADED_ISO=$(find "${ISO_DIR}" -maxdepth 1 -name "omarchy-*.iso" -type f | head -1)
echo ""
echo "Download complete: ${DOWNLOADED_ISO}"
