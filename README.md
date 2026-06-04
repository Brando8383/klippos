# KlipOS

A minimal, purpose-built Linux distribution for dedicated Klipper 3D printer control stations.

Built on Debian 12 (Bookworm) with a custom Buildroot kernel, designed for x86_64 laptops and desktops repurposed as standalone Klipper hosts.

## Goals
- Fast boot (target: under 10 seconds)
- Full Klipper stack out of the box (Klipper, Moonraker, Fluidd)
- Proper mouse, keyboard, and trackpad support on laptops
- No unnecessary packages or services
- Works completely offline after initial setup
- Easy to flash and configure

## Status
- [x] Debian 12 base rootfs
- [x] Custom Buildroot kernel (Linux 6.6)
- [x] GRUB2 bootloader (BIOS + UEFI)
- [x] X.org with Intel/VESA/fbdev drivers
- [x] libinput trackpad and mouse support
- [x] Openbox window manager
- [x] Chromium kiosk browser
- [x] nginx web server
- [x] openssh
- [x] Python3
- [x] NetworkManager + WiFi support
- [x] First boot KIAUH installer (Klipper + Moonraker + Fluidd)
- [x] Auto-login X session with Fluidd kiosk
- [x] Flashable disk image (klipos.img)
- [x] First boot WiFi setup wizard
- [x] Default printer.cfg template
- [x] Release v0.1

## Hardware Target
- Architecture: x86_64
- Primary target: repurposed laptops
- Secondary target: small form factor desktops

## Flashing
```bash
sudo dd if=klipos.img of=/dev/sdX bs=4M status=progress && sync
```
Replace `/dev/sdX` with your USB drive.

## Building from source
```bash
git clone https://github.com/Brando8383/klipos.git
cd klipos
bash scripts/build-rootfs.sh
```

## Built by
Brando8383
