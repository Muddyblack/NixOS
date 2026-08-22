{
  lib,
  config,
  ...
}:
lib.mkIf config.features.desktops.gnome.enable {
  services.desktopManager.gnome.enable = true;

  xdg.portal.config.gnome.default = ["gnome" "gtk"];
}
