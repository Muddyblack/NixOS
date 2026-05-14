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
    ../../modules/nixos/features/tailscale.nix
    ../../modules/nixos/features/keyring.nix
  ];

  networking.hostName = "muddyblack";

  features.gaming.enable = true;
  features.virt.enable = true;
  features.homepage.enable = true;
  features.sops.enable = true;

  programs.wireshark.enable = true;
  features.stirling-pdf.enable = true;
  features.tailscale.enable = true;
  features.snapshots.enable = true;
  features.keyring.enable = true;
  features.power.enable = true;

  security.wrappers.sniffnet = {
    source = "${pkgs.sniffnet}/bin/sniffnet";
    capabilities = "cap_net_raw,cap_net_admin=eip";
    owner = "root";
    group = "root";
  };

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
