{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../common.nix
    ../disko-config.nix
    ./packages.nix
    ../../modules/nixos/features/virt.nix
    ../../modules/nixos/features/gaming.nix
    ../../modules/nixos/features/homepage.nix
    ../../modules/nixos/features/stirling-pdf.nix
    ../../modules/nixos/features/firefly-iii.nix
    ../../modules/nixos/features/paperless.nix
    ../../modules/nixos/features/portmaster.nix
    ../../modules/nixos/features/tailscale.nix
    ../../modules/nixos/features/keyring.nix
    ../../modules/nixos/features/ai.nix
  ];

  networking.hostName = "muddyblack";

  features.kernel.cachyos.enable = true;
  features.kernel.cachyos.lto = true;
  # Disabled 2026-08-23: scx_lavd attaches fine on linux-cachyos 7.2, then dies
  # at runtime with "runnable task stall" roughly once a minute, each time after
  # starving some random runnable task for 30-45s (systemd-udevd, ripgrep,
  # Electron thread pools). systemd restarts it, so it is a permanent
  # crash-restart loop that reads as a machine-wide stutter. Cause looks like an
  # API skew: scx_rustscheds 1.1.3 expects lavd_ops members this kernel does not
  # export (sub_caps_updated, init_cids, rescue_quantum_us, ...), and libbpf
  # zeroes them instead of failing. Re-enable once the two versions line up.
  features.kernel.scx.enable = false;
  # cachyos.march is deliberately not set here: it is a property of the CPU this
  # config is installed on, not of the profile. deploy.sh detects it and writes
  # it into hosts/deploy-config.nix, so setting it here too would collide.

  features.ai.enable = true;
  features.gaming.enable = true;
  features.virt.enable = true;
  features.homepage.enable = true;
  features.sops.enable = true;

  programs.wireshark.enable = true;
  features.stirling-pdf.enable = true;
  features.firefly-iii.enable = true;
  features.paperless.enable = true;
  features.portmaster.enable = true;
  features.tailscale.enable = true;
  features.snapshots.enable = true;
  features.keyring.enable = true;
  features.power.enable = true;

  security.wrappers.bandwhich = {
    source = "${pkgs.bandwhich}/bin/bandwhich";
    capabilities = "cap_net_raw,cap_net_admin=eip";
    owner = "root";
    group = "root";
  };

  # Additional home-manager packages and config for the full profile
  home-manager.users.${username} = {
    imports = [./home-packages.nix];
    programs.gimp-photogim.enable = true;
  };
}
