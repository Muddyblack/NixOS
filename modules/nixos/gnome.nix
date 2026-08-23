{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.features.desktops.gnome.enable {
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    epiphany # GNOME Web
    geary # Mail
    totem # Videos
    gnome-music
    gnome-weather
    gnome-contacts
    # gnome-calendar
    # gnome-clocks
    gnome-characters
    gnome-connections
    gnome-console
    # gnome-font-viewer
    # gnome-logs
    gnome-system-monitor
    gnome-tour
    gnome-user-docs
    simple-scan
    yelp
  ];

  xdg.portal.config.gnome.default = ["gnome" "gtk"];

  programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
}
