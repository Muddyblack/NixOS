# Live USB Recovery

How to get back into this system from a NixOS live ISO when it won't boot —
broken bootloader, bad generation, or a rebuild that locked you out.

> Device names below are for the `muddyblack` host (`/dev/nvme0n1`). Run
> `lsblk -f` first and substitute your own. The subvolume layout comes from
> [`hosts/disko-config.nix`](../hosts/disko-config.nix).

## 1. Tools on the live USB

The minimal ISO has no editor worth using. Pull in a shell with what you need:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix-shell -p git btop ripgrep fd eza claude-code
```

## 2. Open the LUKS container

```sh
lsblk -f                                          # confirm the partition
sudo cryptsetup open /dev/nvme0n1p5 cryptroot
```

## 3. Mount the Btrfs subvolumes

```sh
sudo mount -o subvol=@root /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/{nix,persist,home,boot,var/log,mnt/data,mnt/projects}
sudo mount -o subvol=@nix      /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=@persist  /dev/mapper/cryptroot /mnt/persist
sudo mount -o subvol=@home     /dev/mapper/cryptroot /mnt/home
sudo mount -o subvol=@log      /dev/mapper/cryptroot /mnt/var/log
sudo mount -o subvol=@projects /dev/mapper/cryptroot /mnt/mnt/projects
sudo mount /dev/nvme0n1p2 /mnt/boot                # ESP
```

## 4. Chroot in and rebuild

```sh
sudo nixos-enter --root /mnt
cd /mnt/projects/nixos-config

NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#muddyblack   # bootloader only
nixos-rebuild switch --flake .#muddyblack                            # full rebuild
exit
```

Single command without an interactive shell:

```sh
sudo nixos-enter --root /mnt -c "cd /mnt/projects/nixos-config && NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#muddyblack"
```

## 5. Clean up

```sh
sudo umount -R /mnt
sudo cryptsetup close cryptroot
sudo reboot                                       # pull the USB first
```

## Just reading files (no chroot)

```sh
sudo cryptsetup open /dev/nvme0n1p5 cryptroot
sudo mount -o subvol=@projects /dev/mapper/cryptroot /mnt   # config at /mnt/nixos-config
sudo mount -o subvol=@home     /dev/mapper/cryptroot /mnt   # home at /mnt/muddyblack
```

## Boot menu missing

`efibootmgr -v` lists the EFI entries; rEFInd lives on the ESP (`nvme0n1p2`).
If the entry is gone, re-run the bootloader-only rebuild in step 4.

## Partition reference

| Partition | Contents |
| --- | --- |
| `nvme0n1p1` | BIOS boot (1 MB) |
| `nvme0n1p2` | ESP / `/boot` (1 GB, FAT32) — rEFInd |
| `nvme0n1p3` | Shared NTFS |
| `nvme0n1p4` | Windows |
| `nvme0n1p5` | LUKS-encrypted Btrfs |

Subvolumes inside LUKS:

| Subvolume | Mount | Notes |
| --- | --- | --- |
| `@root` | `/` | ephemeral — wiped each boot by impermanence |
| `@nix` | `/nix` | |
| `@persist` | `/persist` | survives the wipe |
| `@home` | `/home` | |
| `@log` | `/var/log` | |
| `@data` | `/mnt/data` | |
| `@projects` | `/mnt/projects` | this repo lives here |
