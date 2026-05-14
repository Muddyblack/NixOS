final: _prev: {
  # ═══════════════════════════════════════════════════════════════════════════
  # WIDGETS - KDE Plasma widgets
  # ═══════════════════════════════════════════════════════════════════════════
  plasma-audio-visualizer = final.callPackage ./widgets/plasma-audio-visualizer.nix {};
  kde-modern-clock = final.callPackage ./widgets/modern-clock.nix {};
  netspeed-widget = final.callPackage ./widgets/netspeed-widget.nix {};
  kde-overview-widget = final.callPackage ./widgets/overview-widget.nix {};

  # ═══════════════════════════════════════════════════════════════════════════
  # THEMES - Plasma themes, look-and-feel, kvantum
  # ═══════════════════════════════════════════════════════════════════════════
  illusion-splash = final.callPackage ./themes/illusion-splash.nix {};
  iridescent-plasma-style = final.callPackage ./themes/iridescent-plasma-style.nix {};
  sweet-kvantum = final.callPackage ./themes/sweet-kvantum.nix {};
  sweet-theme = final.callPackage ./themes/sweet-theme.nix {};
  utterly-round-plasma-style = final.callPackage ./themes/utterly-round-plasma-style.nix {};
  vivid-plasma-themes = final.callPackage ./themes/vivid-plasma-themes.nix {};

  # ═══════════════════════════════════════════════════════════════════════════
  # ICONS & CURSORS
  # ═══════════════════════════════════════════════════════════════════════════
  colorful-icon-theme = final.callPackage ./icons-cursors/colorful-icon-theme.nix {};
  slot-icon-theme = final.callPackage ./icons-cursors/slot-icon-theme.nix {};
  sweet-cursors = final.callPackage ./icons-cursors/sweet-cursors.nix {};

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOT - Bootloader & login screen themes
  # ═══════════════════════════════════════════════════════════════════════════
  sonomatic-sddm = final.callPackage ./boot/sonomatic-sddm.nix {
    customBackground = ../assets/wallpapers/lockscreen.png;
  };
  whitesur-grub-theme = final.callPackage ./boot/whitesur-grub-theme.nix {
    customBackground = ../assets/grub-background.jpg;
  };
  refind-theme-minimal = final.callPackage ./boot/refind-theme.nix {
    customBackground = ../assets/refind-background.png;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # APPS - Custom applications
  # ═══════════════════════════════════════════════════════════════════════════
  guitar-pro = final.callPackage ./apps/guitar-pro.nix {};
  photopea = final.callPackage ./apps/photopea.nix {};
  recraft = final.callPackage ./apps/recraft.nix {};
  whatsapp = final.callPackage ./apps/whatsapp.nix {};
  notebooklm = final.callPackage ./apps/notebooklm.nix {};
  perplexity = final.callPackage ./apps/perplexity.nix {};
  stirling-pdf-ui = final.callPackage ./apps/stirling-pdf.nix {};
  gmaps = final.callPackage ./apps/gmaps.nix {};
}
