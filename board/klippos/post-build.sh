#!/bin/bash
# KlippOS post-build script
# Runs after Buildroot assembles the rootfs

TARGET_DIR=$1

echo "Running KlippOS post-build script..."

# Enable klippos-setup service on first boot
mkdir -p $TARGET_DIR/etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/klippos-setup.service \
    $TARGET_DIR/etc/systemd/system/multi-user.target.wants/klippos-setup.service

echo "KlippOS post-build complete."

# Enable klippos-display service
ln -sf /etc/systemd/system/klippos-display.service \
    $TARGET_DIR/etc/systemd/system/multi-user.target.wants/klippos-display.service
