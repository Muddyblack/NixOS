{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf config.features.desktops.gnome.enable {
  services.desktopManager.gnome.enable = true;
  services.gnome.rygel.enable = false; # UPnP/DLNA media server, unused

  environment.gnome.excludePackages = with pkgs; [
    decibels
    epiphany # GNOME Web
    geary # Mail
    totem # Videos
    showtime # Videos (GNOME 46+ replacement for Totem)
    gnome-music
    gnome-weather
    gnome-contacts
    gnome-calendar
    # gnome-clocks
    gnome-characters
    gnome-connections
    gnome-console
    # gnome-font-viewer
    # gnome-logs
    gnome-system-monitor
    gnome-software # no use on NixOS; packages are declarative
    gnome-text-editor # Kate is the editor
    gnome-tour
    nautilus # Files (Dolphin is used instead)
    gnome-user-docs
    simple-scan
    yelp
  ];

  xdg.portal.config.gnome.default = ["gnome" "gtk"];

  programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
}
