# try-omarchy-linux

Use Omarchy Linux on Linux via QEMU/KVM

## Why Fork QEMU?

Different Linux distributions ship different versions of QEMU and system libraries. This project maintains a forked QEMU 11.0.4 with patches to **minimize host OS dependencies**, allowing Omarchy to run on various Linux distributions (Ubuntu 20.04+, Debian, Fedora, etc.) without requiring specific system library versions.

## Quick Start

```bash
# 1. Build QEMU and prepare (first time only)
./scripts/setup.sh

# 2. Install Omarchy from ISO
./scripts/install.sh

# 3. Boot the installed Omarchy
./scripts/start.sh
```

After first boot, follow Post-Install Setup to enable patches and SSH server.

## Post-Install Setup

After installing Omarchy, you need to apply QEMU compatibility patches and enable SSH inside the Omarchy VM.

### Step 1: Switch to TTY Terminal

In the QEMU window, press `Ctrl+Alt+G` to release the mouse, then click **View > compatmonitor0** to open the QEMU monitor. Run:

```
sendkey ctrl-alt-f2
```

This switches to a TTY terminal. Log in with your user account.

### Step 2: Mount Shared Folder and Apply Patches

The `scripts/` directory on the host is shared to the Omarchy VM via 9p.

```bash
# Mount the shared folder
sudo mkdir -p /mnt/hostshare
sudo mount -t 9p -o trans=virtio hostshare /mnt/hostshare

# Apply QEMU patches (software rendering + keybindings)
/mnt/hostshare/patch-qemu-all.sh
```

### Step 3: Enable SSH and Flush Firewall

```bash
sudo pacman -Syu openssh
sudo systemctl enable --now sshd
sudo nft flush ruleset
```

### Step 4: Reboot

```bash
sudo reboot
```

After reboot, the graphical desktop will start. You can now access the Omarchy VM via SSH from the host:

```bash
ssh -p 2222 omarchy_vm_username@localhost
```

## Known Limitations

- Only verified on Ubuntu 20.04 & Ubuntu 26.04
- Only support KVM + QEMU, doesn't work with VMware Workstation

## Screenshots

<!-- Add screenshots here -->

<img width="1284" height="865" alt="Screenshot from 2026-09-14 11-40-44" src="https://github.com/user-attachments/assets/5b4c38e6-3c7c-4d3a-932b-9d684dc8913f" />

<img width="1409" height="985" alt="Image" src="https://github.com/user-attachments/assets/84abccb6-f9f9-4fe0-a6e3-adfc5a4f75a9" />

<img width="1409" height="985" alt="Image" src="https://github.com/user-attachments/assets/f28756a3-4452-4bf1-a24b-d98ff9fa33e8" />

<img width="1575" height="926" alt="Image" src="https://github.com/user-attachments/assets/6da3ea62-38f3-4164-841a-e98f6e95fd6b" />


## Requirements

- Linux (Ubuntu 20.04+ or similar)

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
│   ├── setup.sh           # Install dependencies + build QEMU
│   ├── download.sh        # Download QEMU source
│   └── build.sh           # Compile QEMU
├── scripts/
│   ├── setup.sh           # One-click setup (deps + QEMU + disk + ISO)
│   ├── install.sh         # Install Omarchy from ISO
│   ├── start.sh           # Boot installed system
│   ├── create-disk.sh     # Create virtual disk
│   ├── download-iso.sh    # Download ISO
│   ├── download-ovmf.sh   # Download UEFI firmware
│   ├── patch-qemu-all.sh  # Apply all QEMU patches (run inside VM)
│   ├── patch-qemu-rendering.sh  # Software rendering patch
│   └── patch-qemu-keybinds.sh   # Keybindings patch
├── ovmf/                  # UEFI firmware (after download)
├── disks/                 # Virtual disks (after creation)
└── iso/                   # ISO files (after download)
```

## License

MIT
