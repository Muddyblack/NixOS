{
  lib,
  config,
  ...
}:
lib.mkIf config.features.desktops.cosmic.enable {
  services.desktopManager.cosmic.enable = true;

  xdg.portal.config.cosmic.default = ["cosmic" "gtk"];
}
