#!/bin/bash
# KlipOS Master Build Script
# Builds a complete flashable KlipOS image from scratch
# Usage: sudo ./build.sh

set -e

KLIPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDROOT_VERSION="2024.02"
BUILDROOT_DIR="/home/brando/klipper-distro/buildroot-2024.02"
BUILDROOT_URL="https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz"
OUTPUT_DIR="$KLIPOS_DIR/output"
IMAGES_DIR="$BUILDROOT_DIR/output/images"
LOGFILE="$KLIPOS_DIR/build.log"

echo "========================================="
echo " KlipOS Master Build Script"
echo "========================================="
echo "Started: $(date)" | tee -a $LOGFILE

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

mkdir -p $OUTPUT_DIR

# Step 1 - Check dependencies
echo ""
echo ">>> Step 1: Checking dependencies..."
DEPS="make gcc git python3 wget debootstrap genimage mtools libelf-dev libncurses-dev grub-pc-bin"
for dep in $DEPS; do
    if ! dpkg -l | grep -q "^ii.*$dep"; then
        echo "Installing $dep..."
        apt install -y $dep
    fi
done
echo ">>> Dependencies OK."

# Step 2 - Download Buildroot if needed
echo ""
echo ">>> Step 2: Checking Buildroot..."
if [ ! -d "$BUILDROOT_DIR" ]; then
    echo "Downloading Buildroot $BUILDROOT_VERSION..."
    cd /home/brando/klipper-distro
    wget $BUILDROOT_URL
    tar -xzf buildroot-${BUILDROOT_VERSION}.tar.gz
    rm buildroot-${BUILDROOT_VERSION}.tar.gz
fi
echo ">>> Buildroot OK."

# Step 3 - Build kernel and bootloader
echo ""
echo ">>> Step 3: Building kernel and bootloader..."
cp $KLIPOS_DIR/configs/klipos_defconfig $BUILDROOT_DIR/.config
cd $BUILDROOT_DIR
make 2>&1 | tee -a $LOGFILE
echo ">>> Kernel and bootloader build complete."

# Step 4 - Build Debian rootfs
echo ""
echo ">>> Step 4: Building Debian rootfs..."
bash $KLIPOS_DIR/scripts/build-rootfs.sh 2>&1 | tee -a $LOGFILE
echo ">>> Debian rootfs build complete."

# Step 5 - Copy rootfs to images directory
echo ""
echo ">>> Step 5: Preparing images..."
cp /home/brando/klipper-distro/klipos-rootfs.ext4 $IMAGES_DIR/rootfs-debian.ext4

# Step 6 - Assemble final image
echo ""
echo ">>> Step 6: Assembling KlipOS image..."
rm -rf $BUILDROOT_DIR/output/build/genimage.tmp
genimage \
    --rootpath $BUILDROOT_DIR/output/target \
    --tmppath $BUILDROOT_DIR/output/build/genimage.tmp \
    --inputpath $IMAGES_DIR \
    --outputpath $IMAGES_DIR \
    --config $KLIPOS_DIR/board/klipos/genimage.cfg

# Step 7 - Copy final image to output directory
cp $IMAGES_DIR/klipos.img $OUTPUT_DIR/klipos.img

echo ""
echo "========================================="
echo " KlipOS build complete!"
echo " Image: $OUTPUT_DIR/klipos.img"
echo " Flash: sudo dd if=$OUTPUT_DIR/klipos.img of=/dev/sdX bs=4M status=progress"
echo "========================================="
echo "Finished: $(date)" | tee -a $LOGFILE
