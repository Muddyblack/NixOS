inputs: final: _prev: let
  # Own widgets ship their own flake. Take the package from there instead of
  # re-deriving the install phase here: upstream's is where NixOS-specific
  # fixes land (ai-usage pins the Python interpreter, without which
  # plasmashell — whose PATH carries no python3 — renders "python3 missing"),
  # and a local copy silently misses them.
  upstreamWidget = input: input.packages.${final.stdenv.hostPlatform.system}.default;
in {
  # ═══════════════════════════════════════════════════════════════════════════
  # WIDGETS - KDE Plasma widgets
  # ═══════════════════════════════════════════════════════════════════════════
  kde-modern-clock = final.callPackage ./widgets/modern-clock.nix {};
  kde-overview-widget = final.callPackage ./widgets/overview-widget.nix {};
  ai-usage-widget = upstreamWidget inputs.ai-usage;
  # Upstream only exports the tray helper, so the full Quickshell frontend is
  # still assembled here — from the same input, so the two cannot drift.
  ai-usage-hyprland = final.callPackage ./widgets/ai-usage-hyprland.nix {
    aiUsageSrc = inputs.ai-usage;
  };
  kde-powerchart = final.callPackage ./widgets/powerchart-widget.nix {};
  advanced-weather-widget = final.callPackage ./widgets/advanced-weather-widget.nix {};
  kde-nixdatifier = upstreamWidget inputs.nixdatifier;
  glassy-system-monitor = upstreamWidget inputs.glassy-system-monitor;
  tagesschau-widget = upstreamWidget inputs.tagesschau-widget;
  plasma-audio-visualizer = upstreamWidget inputs.plasma-audio-visualizer;
  kde-gitpulse = upstreamWidget inputs.gitpulse;
  gitpulse-hyprland = final.callPackage ./widgets/gitpulse-hyprland.nix {
    gitpulseSrc = inputs.gitpulse;
  };

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
  portmaster = final.callPackage ./apps/portmaster.nix {};
  guitar-pro = final.callPackage ./apps/guitar-pro.nix {};
  whatsapp = final.callPackage ./apps/whatsapp.nix {};
  stirling-pdf-ui = final.callPackage ./apps/stirling-pdf.nix {};
  firefly-iii-app = final.callPackage ./apps/firefly-iii-app.nix {};
  paperless-ngx-ui = final.callPackage ./apps/paperless.nix {};
}
