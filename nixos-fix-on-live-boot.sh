#!/usr/bin/env bash
set -e

# Search for the root partition by label
ROOT_PART="/dev/disk/by-partlabel/disk-main-root"
ESP_PART="/dev/disk/by-partlabel/disk-main-ESP"

if [ ! -b "$ROOT_PART" ]; then
    echo "🚨 Could not find root partition: $ROOT_PART"
    lsblk
    exit 1
fi

echo "Mounting root partition ($ROOT_PART)..."
mount "$ROOT_PART" /mnt

echo "Mounting EFI boot partition ($ESP_PART)..."
mkdir -p /mnt/boot
mount "$ESP_PART" /mnt/boot

# Check for UEFI
if [ ! -d /sys/firmware/efi ]; then
    echo "⚠️  System is booted in BIOS mode. GRUB will be installed for BIOS/MBR."
else
    echo "✅ System is booted in UEFI mode."
fi

echo "Chrooting into NixOS and rebuilding the bootloader..."
# NIXOS_INSTALL_BOOTLOADER=1 is required for nixos-rebuild boot to actually install the loader
nixos-enter -c "cd ~/Downloads/nixos-config && NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#default --show-trace --extra-experimental-features \"nix-command flakes\""

echo "Cleaning up and unmounting..."
umount -R /mnt

echo "✅ Done! Rebooting in 5 seconds... (Remove the ISO now!)"
sleep 5
reboot