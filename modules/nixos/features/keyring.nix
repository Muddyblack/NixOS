{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.keyring.enable = lib.mkEnableOption "keyring";

  config = lib.mkIf config.features.keyring.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    # KWallet PAM auto-unlock deliberately NOT enabled: kwalletd6 starts late
    # (D-Bus activated) and races gnome-keyring for org.freedesktop.secrets,
    # causing random re-prompts (network passwords, wallet popups) under Hyprland.
    # gnome-keyring is the single secrets provider; unlock KWallet manually if
    # something actually needs it.

    environment.systemPackages = with pkgs; [
      libsecret
      gnome-keyring
    ];
  };
}
