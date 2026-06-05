#!/bin/bash
# KlippOS Internal Drive Installer
# Detects if running from USB and offers to install to internal drive

LOGFILE="/var/log/klippos-installer.log"
INSTALL_DONE="/etc/klippos/.installed_to_disk"

clear
echo "=========================================" | tee -a $LOGFILE
echo "         KlippOS Drive Installer"
echo "========================================="
echo "Started: $(date)" | tee -a $LOGFILE

# Skip if already installed to disk
if [ -f "$INSTALL_DONE" ]; then
    echo "KlippOS already installed to disk. Skipping." | tee -a $LOGFILE
    exit 0
fi

# Detect if we are running from USB
ROOT_DEV=$(findmnt -n -o SOURCE /)
ROOT_TYPE=$(cat /sys/block/$(lsblk -no pkname $ROOT_DEV)/removable 2>/dev/null)

if [ "$ROOT_TYPE" != "1" ]; then
    echo "Not running from removable media. Skipping installer." | tee -a $LOGFILE
    exit 0
fi

echo ""
echo "KlippOS is running from a USB drive."
echo "You can install KlippOS to an internal drive for"
echo "better performance and reliability."
echo ""

# List available internal drives
echo "Available internal drives:"
echo "-----------------------------------------"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop | grep -v "$(lsblk -no pkname $ROOT_DEV)"
echo "-----------------------------------------"
echo ""

read -p "Install KlippOS to internal drive? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Skipping installation to internal drive." | tee -a $LOGFILE
    echo "You can run this installer later with: sudo klippos-installer.sh"
    exit 0
fi

echo ""
read -p "Enter target drive (e.g. sda, nvme0n1): " TARGET_DRIVE

# Validate drive exists
if [ ! -b "/dev/$TARGET_DRIVE" ]; then
    echo "Drive /dev/$TARGET_DRIVE not found. Aborting." | tee -a $LOGFILE
    exit 1
fi

# Get drive size for confirmation
DRIVE_SIZE=$(lsblk -d -o SIZE /dev/$TARGET_DRIVE | tail -1)
DRIVE_MODEL=$(lsblk -d -o MODEL /dev/$TARGET_DRIVE | tail -1)

echo ""
echo "WARNING: This will completely erase:"
echo "  /dev/$TARGET_DRIVE - $DRIVE_SIZE $DRIVE_MODEL"
echo ""
read -p "Are you sure? Type YES to confirm: " FINAL_CONFIRM

if [ "$FINAL_CONFIRM" != "YES" ]; then
    echo "Installation cancelled." | tee -a $LOGFILE
    exit 0
fi

echo ""
echo ">>> Starting KlippOS installation to /dev/$TARGET_DRIVE..." | tee -a $LOGFILE

# Step 1 - Partition the target drive
echo ">>> Step 1: Partitioning /dev/$TARGET_DRIVE..." | tee -a $LOGFILE
parted -s /dev/$TARGET_DRIVE mklabel gpt
parted -s /dev/$TARGET_DRIVE mkpart primary 1MiB 2MiB
parted -s /dev/$TARGET_DRIVE set 1 bios_grub on
parted -s /dev/$TARGET_DRIVE mkpart primary fat32 2MiB 66MiB
parted -s /dev/$TARGET_DRIVE set 2 boot on
parted -s /dev/$TARGET_DRIVE mkpart primary ext4 66MiB 100%

# Wait for partitions to appear
sleep 2
partprobe /dev/$TARGET_DRIVE
sleep 2

# Determine partition naming (sda1 vs nvme0n1p1)
if [[ $TARGET_DRIVE == nvme* ]]; then
    PART_PREFIX="${TARGET_DRIVE}p"
else
    PART_PREFIX="${TARGET_DRIVE}"
fi

# Step 2 - Format partitions
echo ">>> Step 2: Formatting partitions..." | tee -a $LOGFILE
mkfs.vfat -F32 /dev/${PART_PREFIX}2
mkfs.ext4 -L klippos-root /dev/${PART_PREFIX}3

# Step 3 - Mount target partitions
echo ">>> Step 3: Mounting target partitions..." | tee -a $LOGFILE
mkdir -p /mnt/klippos-target
mount /dev/${PART_PREFIX}3 /mnt/klippos-target
mkdir -p /mnt/klippos-target/boot/efi
mount /dev/${PART_PREFIX}2 /mnt/klippos-target/boot/efi

# Step 4 - Copy root filesystem
echo ">>> Step 4: Copying KlippOS to /dev/$TARGET_DRIVE..." | tee -a $LOGFILE
echo "This may take several minutes..."
rsync -aAX \
    --exclude=/proc \
    --exclude=/sys \
    --exclude=/dev \
    --exclude=/tmp \
    --exclude=/mnt \
    --exclude=/run \
    --exclude=/media \
    / /mnt/klippos-target/

# Step 5 - Update fstab
echo ">>> Step 5: Updating fstab..." | tee -a $LOGFILE
ROOT_UUID=$(blkid -s UUID -o value /dev/${PART_PREFIX}3)
BOOT_UUID=$(blkid -s UUID -o value /dev/${PART_PREFIX}2)

cat > /mnt/klippos-target/etc/fstab << FSTAB
UUID=$ROOT_UUID  /          ext4  defaults  0  1
UUID=$BOOT_UUID  /boot/efi  vfat  defaults  0  2
FSTAB

# Step 6 - Install GRUB
echo ">>> Step 6: Installing GRUB bootloader..." | tee -a $LOGFILE
mount --bind /dev /mnt/klippos-target/dev
mount --bind /proc /mnt/klippos-target/proc
mount --bind /sys /mnt/klippos-target/sys

chroot /mnt/klippos-target grub-install --target=i386-pc /dev/$TARGET_DRIVE
chroot /mnt/klippos-target grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable 2>/dev/null || true

# Update grub config with correct UUID
cat > /mnt/klippos-target/boot/grub/grub.cfg << GRUBCFG
set default="0"
set timeout="3"

menuentry "KlippOS" {
    linux /boot/bzImage root=LABEL=klippos-root rootwait rw console=tty1 quiet
}

menuentry "KlippOS (verbose)" {
    linux /boot/bzImage root=LABEL=klippos-root rootwait rw console=tty1
}
GRUBCFG

# Step 7 - Cleanup
echo ">>> Step 7: Cleaning up..." | tee -a $LOGFILE
umount /mnt/klippos-target/dev
umount /mnt/klippos-target/proc
umount /mnt/klippos-target/sys
umount /mnt/klippos-target/boot/efi
umount /mnt/klippos-target

# Mark install complete
mkdir -p /etc/klippos
touch $INSTALL_DONE

echo "" | tee -a $LOGFILE
echo "=========================================" | tee -a $LOGFILE
echo " KlippOS installation complete!" | tee -a $LOGFILE
echo " Remove the USB drive and reboot." | tee -a $LOGFILE
echo "=========================================" | tee -a $LOGFILE
echo ""
read -p "Press Enter to reboot now, or Ctrl+C to cancel: "
reboot
