{pkgs, ...}: let
  kdePortalPreference = ''
    [preferred]
    default=kde;gtk
    org.freedesktop.impl.portal.Settings=kde
  '';
in {
  home.packages = with pkgs; [
    # KDE Plasma addons
    kdePackages.plasma-pa
    kdePackages.plasma-nm
    kdePackages.plasma-browser-integration
    kdePackages.plasma-systemmonitor
    kdePackages.ksystemstats
    kdePackages.kscreen
    kdePackages.ocean-sound-theme
    kdePackages.qtstyleplugin-kvantum

    # Themes, icons & cursors
    bibata-cursors
    papirus-icon-theme
    hicolor-icon-theme
    adwaita-icon-theme
    kdePackages.qtsvg
    iridescent-plasma-style
    illusion-splash
    sweet-cursors
    sweet-theme
    sweet-kvantum
    vivid-plasma-themes
    slot-icon-theme
    utterly-round-plasma-style
  ];

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "kvantum";
  };

  # Route GTK apps at the KDE portal so they pick up the Plasma colour scheme --
  # but only in sessions that actually run that portal.  A generic
  # ~/.config/xdg-desktop-portal/portals.conf shadows the system's
  # <desktop>-portals.conf in *every* session, so COSMIC/GNOME would ask for a
  # kde backend that isn't running and screenshots fail with PortalNotFound.
  xdg.configFile."xdg-desktop-portal/kde-portals.conf".text = kdePortalPreference;
  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".text = kdePortalPreference;

  xdg.desktopEntries.vmware = {
    name = "VMware Workstation";
    exec = "env GTK_THEME=Sweet:dark GTK2_RC_FILES=/dev/null vmware %u";
    icon = "vmware-workstation";
    categories = ["System"];
  };

  xdg.desktopEntries."vmware-workstation" = {
    name = "VMware Workstation";
    exec = "env GTK_THEME=Sweet:dark GTK2_RC_FILES=/dev/null vmware %u";
    icon = "vmware-workstation";
    categories = ["System"];
    noDisplay = true;
  };

  xdg.desktopEntries."vmware-player" = {
    name = "VMware Player";
    exec = "vmware-player";
    icon = "vmware-player";
    categories = ["System"];
    noDisplay = true;
  };

  xdg.desktopEntries.veracrypt = {
    name = "VeraCrypt";
    genericName = "VeraCrypt volume manager";
    comment = "Create and mount VeraCrypt encrypted volumes";
    exec = "env GTK_THEME=Sweet:dark GTK2_RC_FILES=/dev/null veracrypt %f";
    icon = "veracrypt";
    categories = ["Security" "Utility" "Filesystem"];
  };

  home.sessionVariables.GTK_THEME = "Sweet:dark";

  # dconf dark mode
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Sweet";
    icon-theme = "Papirus-Dark";
    cursor-theme = "Sweet-cursors";
  };

  # Kvantum
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Sweet-transparent-toolbar
  '';

  xdg.dataFile = {
    # Kvantum themes
    "Kvantum/Sweet".source = "${pkgs.sweet-kvantum}/share/Kvantum/Sweet";
    "Kvantum/Sweet-transparent-toolbar".source = "${pkgs.runCommand "sweet-opaque-dolphin" {} ''
      cp -r ${pkgs.sweet-kvantum}/share/Kvantum/Sweet-transparent-toolbar $out
      chmod -R u+w $out
      substituteInPlace $out/Sweet-transparent-toolbar.kvconfig \
        --replace-fail "transparent_dolphin_view=true" "transparent_dolphin_view=false"
    ''}";

    # Plasma themes
    "plasma/desktoptheme/Iridescent-round".source = "${pkgs.iridescent-plasma-style}/share/plasma/desktoptheme/Iridescent-round";
    "plasma/look-and-feel/Illusion".source = "${pkgs.illusion-splash}/share/plasma/look-and-feel/Illusion";
    "plasma/look-and-feel/Vivid-Dark-Global-6".source = "${pkgs.vivid-plasma-themes}/share/plasma/look-and-feel/Vivid-Dark-Global-6";

    # Aurorae themes (Window decorations)
    "aurorae/themes/Utterly-Round-Dark".source = "${pkgs.utterly-round-plasma-style}/share/aurorae/themes/Utterly-Round-Dark";
    "aurorae/themes/Utterly-Round-Dark-Solid".source = "${pkgs.utterly-round-plasma-style}/share/aurorae/themes/Utterly-Round-Dark-Solid";

    # Icons
    "icons/Sweet-cursors".source = "${pkgs.sweet-cursors}/share/icons/Sweet-cursors";
    "icons/Vivid-Dark-Icons".source = "${pkgs.vivid-plasma-themes}/share/icons/Vivid-Dark-Icons";
    "icons/Slot-Dark-Icons".source = "${pkgs.slot-icon-theme}/share/icons/Slot-Dark-Icons";

    # GTK theme
    "themes/Sweet".source = "${pkgs.sweet-theme}/share/themes/Sweet";
  };
}
