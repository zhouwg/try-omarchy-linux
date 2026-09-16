#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU="${SCRIPT_DIR}/../build-qemu/install/bin/qemu-system-x86_64"
QEMU_IMG="${SCRIPT_DIR}/../build-qemu/install/bin/qemu-img"
DISK_DIR="${SCRIPT_DIR}/../disks"
DISK_FILE="${DISK_DIR}/omarchy.qcow2"
OVMF_DIR="${SCRIPT_DIR}/../ovmf"

# Defaults
RAM="16G"
CPUS="4"
ISO=""
DISPLAY_OPT="gtk"
UEFI=""
DISK_SIZE="16G"

# Detect system capabilities
detect_capabilities() {
    if [ -e /dev/kvm ]; then
        KVM_ARGS="-enable-kvm -cpu host"
    else
        KVM_ARGS=""
        echo "Tip: Install KVM for better performance: sudo apt install qemu-kvm"
    fi
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --iso)
                ISO="$2"
                shift 2
                ;;
            --ram)
                RAM="$2"
                shift 2
                ;;
            --cpus)
                CPUS="$2"
                shift 2
                ;;
            --disk-size)
                DISK_SIZE="$2"
                shift 2
                ;;
            --uefi)
                UEFI="yes"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Try '$0 --help' for usage."
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
  ___  __   ___  __  ___   ____
 / _ \|  | / _ \|  |/ _ \ / _ \
| |_| |  || |_| |  ( |_| | |_| |  <
 \___/|__|\___/|__|\___/ \___/ \_\  Linux

Usage: install.sh [options]

Options:
  --iso PATH      Path to Omarchy ISO file (auto-detected from iso/ dir if not specified)
  --ram SIZE      RAM size (default: 16G)
  --cpus N        Number of CPUs (default: 4)
  --disk-size SIZE Disk size (default: 16G)
  --uefi          Use UEFI boot (requires OVMF)
  -h, --help      Show this help

Examples:
  # Install from ISO (auto-detect)
  ./scripts/install.sh

  # Install with custom settings
  ./scripts/install.sh --iso ~/Downloads/omarchy.iso --disk-size 32G

Tips:
  - The script will auto-create disk and find ISO from iso/ directory
  - After installation, use ./scripts/start.sh to boot the installed system
  - Press Ctrl+Alt+G to release mouse
EOF
}

# Find ISO file from project directory
find_iso() {
    local iso_dir="${SCRIPT_DIR}/../iso"
    if [ -d "${iso_dir}" ]; then
        local found_iso
        found_iso=$(find "${iso_dir}" -maxdepth 1 -name "*.iso" -type f | head -1)
        if [ -n "${found_iso}" ]; then
            echo "${found_iso}"
            return 0
        fi
    fi
    return 1
}

# Auto-detect best settings
auto_configure() {
    DISPLAY_OPT="gtk"
    VGA_DEVICE="-device VGA,vgamem_mb=512"
}

# Build QEMU command
build_command() {
    SCRIPTS_DIR="${SCRIPT_DIR}"
    QEMU_ARGS=(
        ${KVM_ARGS}
        -m "${RAM}"
        -smp "${CPUS}"
        -drive "file=${DISK_FILE},format=qcow2,if=virtio"
        ${VGA_DEVICE}
        -display "${DISPLAY_OPT}"
        -usb -device usb-tablet
        -fsdev "local,id=shared,path=${SCRIPTS_DIR},security_model=mapped-xattr"
        -device "virtio-9p-pci,fsdev=shared,mount_tag=hostshare"
    )

    # UEFI boot
    if [ "${UEFI}" = "yes" ]; then
        OVMF_CODE="${OVMF_DIR}/OVMF_CODE.fd"
        OVMF_VARS="${OVMF_DIR}/OVMF_VARS.fd"
        if [ ! -f "${OVMF_CODE}" ]; then
            echo "Error: OVMF firmware not found."
            echo "Run: ./scripts/download-ovmf.sh"
            exit 1
        fi
        QEMU_ARGS+=(
            -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
            -drive "if=pflash,format=raw,file=${OVMF_VARS}"
        )
    fi

    # Add ISO
    if [ -n "${ISO}" ]; then
        if [ ! -f "${ISO}" ]; then
            echo "Error: ISO not found: ${ISO}"
            exit 1
        fi
        QEMU_ARGS+=(-cdrom "${ISO}" -boot d)
    fi
}

# Main
main() {
    detect_capabilities
    parse_args "$@"
    auto_configure

    # If no ISO specified, try to find one in the project
    if [ -z "${ISO}" ]; then
        found_iso=$(find_iso) || true
        if [ -n "${found_iso}" ]; then
            ISO="${found_iso}"
            echo "Found ISO: ${ISO}"
        fi
    fi

    # Require ISO for installation
    if [ -z "${ISO}" ]; then
        echo "Error: No ISO file specified or found."
        echo ""
        echo "Please either:"
        echo "  1. Download ISO: ./scripts/download-iso.sh"
        echo "  2. Specify ISO: ./scripts/install.sh --iso /path/to/omarchy.iso"
        exit 1
    fi

    # Create disk if not exists
    if [ ! -f "${DISK_FILE}" ]; then
        echo "Creating disk: ${DISK_FILE} (${DISK_SIZE})..."
        mkdir -p "${DISK_DIR}"
        "${QEMU_IMG}" create -f qcow2 "${DISK_FILE}" "${DISK_SIZE}"
        echo "Disk created successfully!"
    fi

    build_command

    echo ""
    echo "  Omarchy Linux Installer"
    echo "  Beautiful, Fun & Opinionated"
    echo ""
    echo "  RAM: ${RAM}  CPUs: ${CPUS}  Display: ${DISPLAY_OPT}"
    echo "  Disk: ${DISK_FILE} (${DISK_SIZE})"
    echo "  ISO: ${ISO}"
    echo ""
    echo "  Starting installation..."
    echo "  Follow the on-screen instructions to install Omarchy."
    echo ""

    exec "${QEMU}" "${QEMU_ARGS[@]}"
}

main "$@"
