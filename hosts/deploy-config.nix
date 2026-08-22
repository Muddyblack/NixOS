{
  diskLayout.device = "/dev/nvme0n1";
  diskLayout.withDualBoot = false;
  bootloader = "refind";
  plymouthTheme = "dotted";
  features.kernel.cachyos.march = "x86_64-v3";
}
