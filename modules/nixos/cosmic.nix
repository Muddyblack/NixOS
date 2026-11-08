{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.features.desktops.cosmic.enable {
  services.desktopManager.cosmic.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";

  # Dolphin's "Open With" list is built by kbuildsycoca6 from
  # ''${XDG_MENU_PREFIX}applications.menu. Only Plasma sets the prefix, and the
  # system only ships plasma-applications.menu, so under COSMIC the app list
  # came up empty (same fix as hyprland.nix).
  environment.sessionVariables.XDG_MENU_PREFIX = "plasma-";

  # We use ghostty/dolphin instead of COSMIC's own apps; drop the ones the
  # module doesn't consider core (cosmic-files stays — it's required by
  # cosmic-session and can't be excluded without risking a broken session).
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-term
    cosmic-edit
    cosmic-player
    cosmic-reader
    cosmic-store
  ];

  xdg.portal.config.cosmic.default = ["cosmic" "gtk"];
}
