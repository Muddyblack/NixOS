#!/usr/bin/env bash
# NixOS Live USB Recovery & Tools Script
# Boot from NixOS live USB (graphical or minimal), then use these commands
#
# TL;DR - Copy paste these one by one:
#
#   NIXPKGS_ALLOW_UNFREE=1 nix-shell -p claude-code antigravity git
#   sudo cryptsetup open /dev/nvme0n1p5 cryptroot
#   sudo mount -o subvol=@root /dev/mapper/cryptroot /mnt
#   sudo mkdir -p /mnt/{nix,persist,home,boot,var/log,mnt/projects}
#   sudo mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
#   sudo mount -o subvol=@persist /dev/mapper/cryptroot /mnt/persist
#   sudo mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
#   sudo mount -o subvol=@log /dev/mapper/cryptroot /mnt/var/log
#   sudo mount -o subvol=@projects /dev/mapper/cryptroot /mnt/mnt/projects
#   sudo mount /dev/nvme0n1p2 /mnt/boot
#   sudo nixos-enter --root /mnt

# ═══════════════════════════════════════════════════════════════════════════════
# GET TOOLS ON LIVE USB (run this first!)
# ═══════════════════════════════════════════════════════════════════════════════

# Claude Code only:
#   NIXPKGS_ALLOW_UNFREE=1 nix-shell -p claude-code

# Claude + useful tools:
#   NIXPKGS_ALLOW_UNFREE=1 nix-shell -p claude-code antigravity git btop ripgrep fd eza

# ═══════════════════════════════════════════════════════════════════════════════
# OPEN LUKS ENCRYPTED PARTITION
# ═══════════════════════════════════════════════════════════════════════════════

# Check your partitions first:
#   lsblk -f

# Open LUKS (you'll be prompted for password):
#   sudo cryptsetup open /dev/nvme0n1p5 cryptroot

# ═══════════════════════════════════════════════════════════════════════════════
# MOUNT ALL BTRFS SUBVOLUMES
# ═══════════════════════════════════════════════════════════════════════════════

# Mount root:
#   sudo mount -o subvol=@root /dev/mapper/cryptroot /mnt

# Create mount points:
#   sudo mkdir -p /mnt/{nix,persist,home,boot,var/log,mnt/data,mnt/projects}

# Mount subvolumes:
#   sudo mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
#   sudo mount -o subvol=@persist /dev/mapper/cryptroot /mnt/persist
#   sudo mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
#   sudo mount -o subvol=@log /dev/mapper/cryptroot /mnt/var/log
#   sudo mount -o subvol=@projects /dev/mapper/cryptroot /mnt/mnt/projects

# Mount boot/ESP:
#   sudo mount /dev/nvme0n1p2 /mnt/boot

# ═══════════════════════════════════════════════════════════════════════════════
# ENTER YOUR SYSTEM (CHROOT)
# ═══════════════════════════════════════════════════════════════════════════════

# Interactive shell inside your installed NixOS:
#   sudo nixos-enter --root /mnt

# Run a single command and exit:
#   sudo nixos-enter --root /mnt -c "command here"

# Example - rebuild bootloader:
#   sudo nixos-enter --root /mnt -c "cd /mnt/projects/nixos-config && NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#muddyblack"

# ═══════════════════════════════════════════════════════════════════════════════
# INSIDE NIXOS-ENTER: REBUILD COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# Once inside nixos-enter, your config is at /mnt/projects/nixos-config
#
#   cd /mnt/projects/nixos-config
#
# Rebuild bootloader only:
#   NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#muddyblack
#
# Full rebuild:
#   nixos-rebuild switch --flake .#muddyblack
#
# Exit when done:
#   exit

# ═══════════════════════════════════════════════════════════════════════════════
# CLEANUP AND REBOOT
# ═══════════════════════════════════════════════════════════════════════════════

# Unmount everything:
#   sudo umount -R /mnt

# Close LUKS (optional):
#   sudo cryptsetup close cryptroot

# Reboot (remove USB first!):
#   sudo reboot

# ═══════════════════════════════════════════════════════════════════════════════
# QUICK ACCESS (without full mount)
# ═══════════════════════════════════════════════════════════════════════════════

# Just access your config files:
#   sudo cryptsetup open /dev/nvme0n1p5 cryptroot
#   sudo mount -o subvol=@projects /dev/mapper/cryptroot /mnt
#   cd /mnt/nixos-config

# Just access your home files:
#   sudo mount -o subvol=@home /dev/mapper/cryptroot /mnt
#   ls /mnt/muddyblack/

# ═══════════════════════════════════════════════════════════════════════════════
# FIX REFIND IF MENU DOESN'T SHOW
# ═══════════════════════════════════════════════════════════════════════════════

# Check EFI boot entries:
#   efibootmgr -v

# ═══════════════════════════════════════════════════════════════════════════════
# PARTITION LAYOUT REFERENCE
# ═══════════════════════════════════════════════════════════════════════════════
#
# nvme0n1p1 = BIOS boot (1MB)
# nvme0n1p2 = ESP/boot (1GB, FAT32) - rEFInd lives here
# nvme0n1p3 = shared NTFS
# nvme0n1p4 = Windows
# nvme0n1p5 = LUKS encrypted btrfs
#
# Btrfs subvolumes inside LUKS:
#   @root    = / (ephemeral - wiped each boot by impermanence)
#   @nix     = /nix
#   @persist = /persist
#   @home    = /home
#   @log     = /var/log
#   @data    = /mnt/data
#   @projects = /mnt/projects
