{
  lib,
  config,
  ...
}: {
  options.features.snapshots.enable = lib.mkEnableOption "btrbk snapshots";

  config = lib.mkIf config.features.snapshots.enable {
    services.btrbk.instances.default = {
      onCalendar = "*:0/3"; # every 3 hours
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "3h";
        snapshot_preserve = "48h 7d 4w";
        target_preserve_min = "no";

        volume."/mnt/btrfs-root" = {
          snapshot_dir = "_snapshots"; # Relative to /mnt/btrfs-root
          subvolume."@persist" = {
            snapshot_create = "always";
          };
          subvolume."@home" = {
            snapshot_create = "always";
          };
          subvolume."@data" = {
            snapshot_create = "always";
          };
        };
      };
    };

    fileSystems."/mnt/btrfs-root" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = ["subvolid=5" "noatime"];
      neededForBoot = false;
    };

    systemd.tmpfiles.rules = [
      "d /mnt/btrfs-root/_snapshots 0750 root root -"
    ];
  };
}
