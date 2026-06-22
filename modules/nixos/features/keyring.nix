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
    # Auto-unlock KWallet at login so Electron/KDE apps stop prompting
    security.pam.services.sddm.kwallet.enable = true;

    environment.systemPackages = with pkgs; [
      libsecret
      gnome-keyring
    ];
  };
}
