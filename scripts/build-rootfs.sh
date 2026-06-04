#!/bin/bash
# KlippOS Rootfs Builder
# Builds a complete Debian 12 rootfs for KlippOS
# Run as root or with sudo

set -e

ROOTFS_DIR="/home/brando/klipper-distro/klippos-rootfs"
ROOTFS_IMG="/home/brando/klipper-distro/klippos-rootfs.ext4"
DEBIAN_MIRROR="http://deb.debian.org/debian"
DEBIAN_RELEASE="bookworm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname $SCRIPT_DIR)/board/klippos/overlay"

echo "========================================="
echo "KlippOS Rootfs Builder"
echo "========================================="

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Clean previous rootfs if exists
if [ -d "$ROOTFS_DIR" ]; then
    echo "Removing previous rootfs..."
    rm -rf $ROOTFS_DIR
fi
mkdir -p $ROOTFS_DIR

# Stage 1 - debootstrap
echo ""
echo ">>> Stage 1: Bootstrapping Debian $DEBIAN_RELEASE..."
debootstrap --arch=amd64 \
    --variant=minbase \
    $DEBIAN_RELEASE \
    $ROOTFS_DIR \
    $DEBIAN_MIRROR
echo ">>> Stage 1 complete."

# Mount virtual filesystems
echo ""
echo ">>> Mounting virtual filesystems..."
mount --bind /proc $ROOTFS_DIR/proc
mount --bind /sys $ROOTFS_DIR/sys
mount --bind /dev $ROOTFS_DIR/dev
mount --bind /dev/pts $ROOTFS_DIR/dev/pts

# Setup apt sources
echo ""
echo ">>> Configuring apt sources..."
cat > $ROOTFS_DIR/etc/apt/sources.list << SOURCES
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
SOURCES

# Stage 2 - install packages
echo ""
echo ">>> Stage 2: Installing packages..."
chroot $ROOTFS_DIR /bin/bash << CHROOT
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y \
    systemd \
    systemd-sysv \
    sudo \
    git \
    curl \
    wget \
    openssh-server \
    nginx \
    python3 \
    python3-pip \
    xorg \
    xinit \
    openbox \
    xterm \
    chromium \
    unclutter \
    network-manager \
    wpasupplicant \
    libinput-tools \
    xinput \
    fonts-dejavu \
    locales \
    tzdata \
    udev \
    grub-pc \
    grub2-common
CHROOT
echo ">>> Stage 2 complete."

# Stage 3 - system configuration
echo ""
echo ">>> Stage 3: Configuring system..."
chroot $ROOTFS_DIR /bin/bash << CHROOT
# Hostname
echo "klippos" > /etc/hostname

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Timezone
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

# Users
useradd -m -s /bin/bash klippos
usermod -aG sudo,tty,dialout,video,audio,input klippos
echo "klippos:klippos" | chpasswd
echo "root:klippos" | chpasswd

# Sudoers
echo "klippos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
CHROOT
echo ">>> Stage 3 complete."

# Stage 4 - install KlippOS scripts and services
echo ""
echo ">>> Stage 4: Installing KlippOS scripts and services..."

# Copy overlay files
cp -a $OVERLAY_DIR/. $ROOTFS_DIR/

# Copy scripts
cp $SCRIPT_DIR/firstboot/klippos-setup.sh $ROOTFS_DIR/usr/local/bin/
cp $SCRIPT_DIR/firstboot/klippos-session.sh $ROOTFS_DIR/usr/local/bin/ 2>/dev/null || true
chmod +x $ROOTFS_DIR/usr/local/bin/klippos-setup.sh
chmod +x $ROOTFS_DIR/usr/local/bin/klippos-session.sh 2>/dev/null || true

# Enable services
chroot $ROOTFS_DIR /bin/bash << CHROOT
systemctl enable klippos-setup.service
systemctl enable klippos-display.service
systemctl enable NetworkManager
systemctl enable ssh
systemctl enable nginx
CHROOT
echo ">>> Stage 4 complete."

# Unmount virtual filesystems
echo ""
echo ">>> Unmounting virtual filesystems..."
umount $ROOTFS_DIR/dev/pts
umount $ROOTFS_DIR/dev
umount $ROOTFS_DIR/proc
umount $ROOTFS_DIR/sys

# Copy printer.cfg template
echo ""
echo ">>> Installing printer.cfg template..."
mkdir -p $ROOTFS_DIR/home/klippos
cp $KLIPOS_DIR/board/klippos/overlay/etc/klipper/printer.cfg.template $ROOTFS_DIR/home/klippos/printer.cfg.template
chown -R 1000:1000 $ROOTFS_DIR/home/klippos
echo ">>> printer.cfg template installed."

# Stage 5 - pack into ext4 image
echo ""
echo ">>> Stage 5: Creating ext4 image..."
rm -f $ROOTFS_IMG
dd if=/dev/zero of=$ROOTFS_IMG bs=1M count=2560
mkfs.ext4 $ROOTFS_IMG
mkdir -p /mnt/klippos-rootfs
mount $ROOTFS_IMG /mnt/klippos-rootfs
cp -a $ROOTFS_DIR/. /mnt/klippos-rootfs/
umount /mnt/klippos-rootfs
echo ">>> Stage 5 complete."

echo ""
echo "========================================="
echo "KlippOS rootfs build complete!"
echo "Image: $ROOTFS_IMG"
echo "========================================="
