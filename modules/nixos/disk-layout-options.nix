{lib, ...}: {
  options.diskLayout = {
    device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/nvme0n1";
      description = "Target disk device (e.g. /dev/sda for VM, /dev/nvme0n1 for NVMe)";
    };
    withDualBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include windows/shared partitions";
    };
    winSize = lib.mkOption {
      type = lib.types.str;
      default = "150G";
      description = "Windows partition size";
    };
    sharedSize = lib.mkOption {
      type = lib.types.str;
      default = "50G";
      description = "Shared NTFS partition size";
    };
  };
}
