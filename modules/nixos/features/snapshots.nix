{
  lib,
  config,
  ...
}: {
  options.features.snapshots.enable = lib.mkEnableOption "btrbk snapshots";

  config = lib.mkIf config.features.snapshots.enable {
    services.btrbk.instances.default = {
      # Hourly, to match snapshot_preserve below: its finest retention bucket is
      # hourly, so anything more frequent is created only to be pruned again.
      #
      # This used to read "*:0/3" with a "# every 3 hours" comment, but systemd
      # calendar syntax is HOUR:MINUTE — that ran every 3 MINUTES (~480x/day).
      # Each run snapshots three subvolumes and then prunes, and on LUKS+btrfs
      # the async subvolume cleanup showed up as permanent btrfs-endio and
      # kcryptd kworker load. (Every 3 hours would have been "0/3:00".)
      onCalendar = "*:00"; # hourly
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
