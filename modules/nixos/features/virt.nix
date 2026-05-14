{
  lib,
  config,
  ...
}: {
  options.features.virt.enable = lib.mkEnableOption "virtualization (VMware/KVM/Docker)";

  config = lib.mkIf config.features.virt.enable {
    virtualisation.vmware.host.enable = true;
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    virtualisation.docker.enable = true;
  };
}
