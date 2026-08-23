{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.features.desktops.cosmic.enable {
  services.desktopManager.cosmic.enable = true;

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
