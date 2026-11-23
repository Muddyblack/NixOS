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
                  # ~4s / 1 GiB Argon2id per unlock attempt, up from the ~2s default:
                  # an extra two seconds at boot makes passphrase brute-forcing far costlier.
                  extraFormatArgs = ["--pbkdf" "argon2id" "--iter-time" "4000" "--pbkdf-memory" "1048576"];
                  settings = {
                    allowDiscards = true;
                    # Skip dm-crypt's read/write workqueues (lower NVMe latency). Needs Linux 5.9+.
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = ["-f"];
                    # nodiscard: btrfs auto-enables discard=async on SSDs (kernel >= 6.2).
                    # On the DRAM-less AGI NVMe each discard takes ~5 ms and stalls other
                    # I/O; after a big cargo build the queue held 161k extents (~13 min
                    # of trimming). TRIM is left to the weekly fstrim.timer instead.
                    subvolumes = {
                      "/@root" = {
                        mountpoint = "/";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard"];
                      };
                      "/@persist" = {
                        mountpoint = "/persist";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard"];
                      };
                      "/@home" = {
                        mountpoint = "/home";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard"];
                      };
                      "/@nix" = {
                        mountpoint = "/nix";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard"];
                      };
                      "/@log" = {
                        mountpoint = "/var/log";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard"];
                      };
                      "/@data" = {
                        mountpoint = "/mnt/data";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard" "noauto" "nofail"];
                      };
                      "/@projects" = {
                        mountpoint = "/mnt/projects";
                        mountOptions = ["compress=zstd:1" "noatime" "nodiscard" "nofail"];
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
