{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.features.desktops.gnome.enable {
  services.desktopManager.gnome.enable = true;

  xdg.portal.config.gnome.default = ["gnome" "gtk"];

  programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
}
