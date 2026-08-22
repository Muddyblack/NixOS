{
  lib,
  config,
  ...
}: let
  cfg = config.diskLayout;
  dualBootPartitions = lib.optionalAttrs cfg.withDualBoot {
    windows = {
      size = cfg.winSize;
      type = "0700";
    };
    shared = {
      size = cfg.sharedSize;
      content = {
        type = "filesystem";
        format = "ntfs";
        mountpoint = "/mnt/shared";
      };
    };
  };
in {
  config.disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = cfg.device;
        content = {
          type = "gpt";
          partitions =
            {
              boot = {
                size = "1M";
                type = "EF02";
              };
              ESP = {
                size = "2G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                };
              };
            }
            // dualBootPartitions
            // {
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  passwordFile = "/tmp/luks.key";
                  settings = {
                    allowDiscards = true;
                    # Everything on this machine lives behind this container, and
                    # dm-crypt pushes every read and write through an internal workqueue
                    # line reverts it on the next boot. Needs Linux 5.9+.
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = ["-f"];
                    subvolumes = {
                      "/@root" = {
                        mountpoint = "/";
                        mountOptions = ["compress=zstd:1" "noatime"];
                      };
                      "/@persist" = {
                        mountpoint = "/persist";
                        mountOptions = ["compress=zstd:1" "noatime"];
                      };
                      "/@home" = {
                        mountpoint = "/home";
                        mountOptions = ["compress=zstd:1" "noatime"];
                      };
                      "/@nix" = {
                        mountpoint = "/nix";
                        mountOptions = ["compress=zstd:1" "noatime"];
                      };
                      "/@log" = {
                        mountpoint = "/var/log";
                        mountOptions = ["compress=zstd:1" "noatime"];
                      };
                      "/@data" = {
                        mountpoint = "/mnt/data";
                        mountOptions = ["compress=zstd:1" "noatime" "noauto" "nofail"];
                      };
                      "/@projects" = {
                        mountpoint = "/mnt/projects";
                        mountOptions = ["compress=zstd:1" "noatime" "nofail"];
                      };
                    };
                  };
                };
              };
            };
        };
      };
    };
  };
}
