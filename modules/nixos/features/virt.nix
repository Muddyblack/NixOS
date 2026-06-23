{
  lib,
  config,
  ...
}: {
  options.features.virt.enable = lib.mkEnableOption "virtualization (VMware/KVM/Docker/Podman)";

  config = lib.mkIf config.features.virt.enable {
    virtualisation.vmware.host.enable = true;
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    # Docker daemon: primary runtime for kind / containerlab / compose stacks
    # that expect the Docker socket. Images live in /var/lib/docker.
    virtualisation.docker.enable = true;

    # Rootless Podman alongside Docker. dockerCompat MUST stay off here — the
    # `docker` shim it installs would collide with the real Docker binary.
    # `docker` => Docker daemon, `podman` => rootless (per-user) store.
    # Default rootless network backend is pasta (passt); no manual slirp4netns.
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
