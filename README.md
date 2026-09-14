# try-omarchy-linux

Beautiful, Fun & Opinionated Linux on Linux

## Quick Start

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt install qemu-kvm

# One-click setup (builds QEMU, creates disk, downloads ISO)
./scripts/setup.sh

# Start Omarchy
./scripts/start.sh
```

## Usage

```bash
# First time: run setup
./scripts/setup.sh

# Start from ISO (install to disk)
./scripts/start.sh --iso ./iso/omarchy-4.0.3.iso

# Boot installed system
./scripts/start.sh
```

## Options

```
  --iso PATH    Path to Omarchy ISO file
  --ram SIZE    RAM size (default: 4G)
  --cpus N      Number of CPUs (default: 4)
  --uefi        Use UEFI boot (requires OVMF)
```

## Known Limitations

- **Config/About windows black screen**: Omarchy uses GPU-accelerated rendering for certain UI elements (config, about). QEMU 6.2.0 with std-vga doesn't fully support this. Avoid clicking these menu items.
- **No 3D acceleration**: virglrenderer doesn't work properly with QEMU 6.2.0 on Ubuntu 20.04.

## Tips

- **Release mouse**: Press `Ctrl+Alt+G`
- **SSH access**: `ssh -p 2222 user@localhost`
- **Performance**: KVM is recommended (`sudo apt install qemu-kvm`)

## Requirements

- Linux (Ubuntu 20.04+ or similar)
- KVM support (recommended)
- GTK3

## Project Structure

```
try-omarchy-linux/
├── build-qemu/          # QEMU build scripts
│   ├── versions.conf    # QEMU version config
│   ├── download.sh      # Download source
│   └── build.sh         # Compile QEMU
├── scripts/
│   ├── setup.sh         # One-click setup
│   ├── start.sh         # Start VM
│   ├── create-disk.sh   # Create virtual disk
│   ├── download-iso.sh  # Download ISO
│   └── download-ovmf.sh # Download UEFI firmware
├── ovmf/                # UEFI firmware (after download)
├── disks/               # Virtual disks (after creation)
└── iso/                 # ISO files (after download)
```

## License

MIT
