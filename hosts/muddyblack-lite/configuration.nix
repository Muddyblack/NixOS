{lib, ...}: {
  imports = [
    ../common.nix
    ../disko-config.nix
  ];

  networking.hostName = "muddyblack-lite";

  # Same base as muddyblack but without heavy features.
  # Use this for quick VM builds / first-time NixOS testing:
  #   nix build .#nixosConfigurations.muddyblack-lite.config.system.build.vm
  features.sops.enable = lib.mkForce false;
}
