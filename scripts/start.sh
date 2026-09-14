#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU="${SCRIPT_DIR}/../build-qemu/install/bin/qemu-system-x86_64"
DISK_DIR="${SCRIPT_DIR}/../disks"
DISK_FILE="${DISK_DIR}/omarchy.qcow2"
OVMF_DIR="${SCRIPT_DIR}/../ovmf"

# Omarchy defaults - opinionated & beautiful
RAM="4G"
CPUS="4"
ISO=""
DISPLAY_OPT="gtk"
UEFI=""

# Detect system capabilities
detect_capabilities() {
    # Check KVM
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
  ___  __   ___  __  ___  ____
 / _ \|  | / _ \|  |/ _ \|  _ \
| |_| |  || |_| |  ( |_| |  _ <
 \___/|__|\___/|__|\___/|_| \_\  Linux

Usage: start.sh [options]

Options:
  --iso PATH    Path to Omarchy ISO file
  --ram SIZE    RAM size (default: 4G)
  --cpus N      Number of CPUs (default: 4)
  --uefi        Use UEFI boot (requires OVMF)
  -h, --help    Show this help

Examples:
  # Try from ISO (recommended)
  ./scripts/start.sh --iso ~/Downloads/omarchy.iso

  # Install to disk
  ./scripts/start.sh --iso ~/Downloads/omarchy.iso
  # Then follow prompts, shutdown, and run without --iso

  # Boot installed system
  ./scripts/start.sh

Tips:
  - Press Ctrl+Alt+G to release mouse
  - SSH: ssh -p 2222 user@localhost
EOF
}

# Auto-detect best settings
auto_configure() {
    # std VGA with 256MB (most compatible)
    DISPLAY_OPT="gtk"
    VGA_DEVICE="-device VGA,vgamem_mb=256"
}

# Build QEMU command
build_command() {
    QEMU_ARGS=(
        ${KVM_ARGS}
        -m "${RAM}"
        -smp "${CPUS}"
        -drive "file=${DISK_FILE},format=qcow2,if=virtio"
        ${VGA_DEVICE}
        -display "${DISPLAY_OPT}"
        -usb -device usb-tablet
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

    # Add ISO if specified
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

    # Check disk
    if [ ! -f "${DISK_FILE}" ]; then
        echo "Error: Disk not found."
        echo "Run: ./scripts/create-disk.sh"
        exit 1
    fi

    build_command

    echo ""
    echo "  Omarchy Linux"
    echo "  Beautiful, Fun & Opinionated"
    echo ""
    echo "  RAM: ${RAM}  CPUs: ${CPUS}  Display: ${DISPLAY_OPT}"
    echo "  Disk: ${DISK_FILE}"
    [ -n "${ISO}" ] && echo "  ISO: ${ISO}"
    echo ""
    echo "  QEMU command:"
    echo "  ${QEMU} ${QEMU_ARGS[*]}"
    echo ""

    exec "${QEMU}" "${QEMU_ARGS[@]}"
}

main "$@"
