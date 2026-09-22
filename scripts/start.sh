#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU="${SCRIPT_DIR}/../build-qemu/install/bin/qemu-system-x86_64"
DISK_DIR="${SCRIPT_DIR}/../disks"
DISK_FILE="${DISK_DIR}/omarchy.qcow2"
OVMF_DIR="${SCRIPT_DIR}/../ovmf"

# Defaults
RAM="16G"
CPUS="4"
DISPLAY_OPT="gtk"
UEFI=""

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
  --ram SIZE    RAM size (default: 16G)
  --cpus N      Number of CPUs (default: 4)
  --uefi        Use UEFI boot (requires OVMF)
  -h, --help    Show this help

Examples:
  # Boot installed system
  ./scripts/start.sh

  # Boot with custom settings
  ./scripts/start.sh --ram 8G --cpus 2

Prerequisites:
  - Install Omarchy first: ./scripts/install.sh

Tips:
  - Press Ctrl+Alt+G to release mouse
  - SSH: ssh -p 2222 user@localhost
EOF
}

# Auto-detect best settings
auto_configure() {
    DISPLAY_OPT="gtk"
    VGA_DEVICE="-device virtio-vga,xres=1280,yres=1024"
}

# launch QEMU command
launch_command() {
    SCRIPTS_DIR="${SCRIPT_DIR}"
    QEMU_ARGS=(
        ${KVM_ARGS}
        -m "${RAM}"
        -smp "${CPUS}"
        -smbios type=4,max-speed=4900
        -drive "file=${DISK_FILE},format=qcow2,if=virtio"
        ${VGA_DEVICE}
        -display "${DISPLAY_OPT}"
        -usb -device usb-tablet
        # Network (user mode with SSH forwarding)
        -netdev "user,id=net0,hostfwd=tcp::2222-:22"
        -device "virtio-net-pci,netdev=net0"
        # Shared folder
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
}

# Main
main() {
    detect_capabilities
    parse_args "$@"
    auto_configure

    # Check if disk exists
    if [ ! -f "${DISK_FILE}" ]; then
        echo "Error: Disk not found: ${DISK_FILE}"
        echo ""
        echo "Please install Omarchy first:"
        echo "  ./scripts/install.sh"
        exit 1
    fi

    launch_command

    echo ""
    echo "  Omarchy Linux"
    echo "  Beautiful, Fun & Opinionated"
    echo ""
    echo "  RAM: ${RAM}  CPUs: ${CPUS}  Display: ${DISPLAY_OPT}"
    echo "  Disk: ${DISK_FILE}"
    echo ""
    echo "  QEMU command:"
    echo "  ${QEMU} ${QEMU_ARGS[*]}"
    echo ""

    exec "${QEMU}" "${QEMU_ARGS[@]}"
}

main "$@"
