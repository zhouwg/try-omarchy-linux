# try-omarchy-linux

Use Omarchy Linux on Linux via QEMU/KVM

## Why Fork QEMU?

Different Linux distributions ship different versions of QEMU and system libraries. This project maintains a forked QEMU 11.0.4 with patches to minimize host OS dependencies, allowing Omarchy to run on various Linux distributions (Ubuntu 20.04+, Debian, Fedora, etc.) without requiring specific system library versions.

Current patches:
- **glib compatibility**: Lowered requirement from 2.66 to 2.64 for older distros
- **GLib URI API**: Stubbed `nbd_parse_uri` to avoid GLib 2.66+ dependency
- **GCC compatibility**: Fixed missing `errno.h` include for GCC 9

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

- **Config/About windows flicker**: Omarchy uses GPU-accelerated rendering for certain UI elements (config, about). QEMU's virtual VGA doesn't fully support this. These menu items may flicker or render incorrectly.
- **No 3D acceleration**: virglrenderer doesn't work properly on Ubuntu 20.04 with QEMU 11.0.4.
- **No network**: Network support (slirp/user-mode) is disabled due to library compatibility issues on Ubuntu 20.04.

## Screenshots

<!-- Add screenshots here -->

<img width="1284" height="865" alt="Screenshot from 2026-09-14 11-40-44" src="https://github.com/user-attachments/assets/5b4c38e6-3c7c-4d3a-932b-9d684dc8913f" />

## Tips

- **Release mouse**: Press `Ctrl+Alt+G`
- **Performance**: KVM is recommended (`sudo apt install qemu-kvm`), doesn't work with VMware Workstation

## Requirements

- Linux (Ubuntu 20.04+ or similar)
- KVM support (recommended)
- GTK3

## Project Structure

```
try-omarchy-linux/
├── qemu-11.0.4/           # QEMU source code (forked, with Ubuntu 20.04 patches)
│   ├── meson.build        # Patched: glib >=2.64.0 (was >=2.66.0)
│   ├── include/
│   │   └── glib-compat.h  # Patched: GLIB_VERSION_*_2_64
│   ├── block/
│   │   └── nbd.c          # Patched: stubbed nbd_parse_uri (GLib 2.66+ API)
│   └── ...
├── qemu -> qemu-11.0.4    # Symlink for convenience
├── build-qemu/            # Build scripts
│   ├── versions.conf      # QEMU version config
│   ├── download.sh        # Download/source management
│   └── build.sh           # Compile QEMU
├── scripts/
│   ├── setup.sh           # One-click setup
│   ├── start.sh           # Start VM
│   ├── create-disk.sh     # Create virtual disk
│   ├── download-iso.sh    # Download ISO
│   └── download-ovmf.sh   # Download UEFI firmware
├── ovmf/                  # UEFI firmware (after download)
├── disks/                 # Virtual disks (after creation)
└── iso/                   # ISO files (after download)
```

## License

MIT
