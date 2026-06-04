# KlipOS

A minimal, purpose-built Linux distribution for dedicated Klipper 3D printer control stations.

Built with Buildroot, designed for x86_64 laptops and desktops repurposed as standalone Klipper hosts.

## Goals
- Fast boot (target: under 10 seconds)
- Full Klipper stack out of the box (Klipper, Moonraker, Fluidd)
- Proper mouse, keyboard, and trackpad support on laptops
- No unnecessary packages or services
- Works completely offline after initial setup
- Easy to flash and configure

## Status
- [x] Base system configuration
- [x] X.org with Intel/VESA/fbdev drivers
- [x] libinput trackpad and mouse support
- [x] Openbox window manager
- [x] nginx web server
- [x] openssh
- [x] Python3
- [x] systemd init
- [x] GRUB2 bootloader (BIOS + UEFI)
- [x] First boot KIAUH installer (Klipper + Moonraker + Fluidd)
- [x] Auto-login X session with Fluidd kiosk
- [x] Flashable disk image (klipos.img)
- [ ] Chromium kiosk browser in image
- [ ] First boot WiFi setup wizard
- [ ] Default printer.cfg
- [ ] Release v0.1

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
# Follow build instructions in docs/
```

## Built by
Brando8383
