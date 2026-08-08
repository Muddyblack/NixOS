{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.widgets;
in {
  options.desktop.widgets = {
    powerchart.enable = lib.mkEnableOption "Powerchart battery monitor widget" // {default = true;};
    modernClock.enable = lib.mkEnableOption "Modern Clock widget" // {default = true;};
    plasmaAudioVisualizer.enable = lib.mkEnableOption "Plasma Audio Visualizer widget" // {default = true;};
    glassySystemMonitor.enable = lib.mkEnableOption "Glassy System Monitor widgets" // {default = true;};
    kscreen.enable = lib.mkEnableOption "KScreen widget" // {default = true;};
    overview.enable = lib.mkEnableOption "KDE Overview widget" // {default = true;};
    weather.enable = lib.mkEnableOption "Advanced Weather widget" // {default = true;};
    aiUsage.enable = lib.mkEnableOption "AI Usage monitor widget" // {default = true;};
    tagesschau.enable = lib.mkEnableOption "Tagesschau news widget" // {default = true;};
    nixosGenerationExplorer.enable = lib.mkEnableOption "NixOS Generation Explorer widget" // {default = true;};
    gitpulse.enable = lib.mkEnableOption "GitPulse GitHub activity widget" // {default = true;};
  };

  config = {
    home.packages =
      (lib.optional cfg.powerchart.enable pkgs.kde-powerchart)
      ++ (lib.optional cfg.glassySystemMonitor.enable pkgs.glassy-system-monitor)
      ++ (lib.optional cfg.modernClock.enable pkgs.kde-modern-clock)
      ++ (lib.optional cfg.overview.enable pkgs.kde-overview-widget)
      ++ (lib.optional cfg.plasmaAudioVisualizer.enable pkgs.plasma-audio-visualizer)
      ++ (lib.optional cfg.tagesschau.enable pkgs.tagesschau-widget)
      ++ (lib.optional cfg.aiUsage.enable pkgs.ai-usage-widget)
      ++ (lib.optional cfg.weather.enable pkgs.advanced-weather-widget)
      ++ (lib.optional cfg.nixosGenerationExplorer.enable pkgs.kde-nixdatifier)
      ++ (lib.optional cfg.gitpulse.enable pkgs.kde-gitpulse);

    xdg.dataFile =
      (lib.optionalAttrs cfg.powerchart.enable {
        "plasma/plasmoids/org.kde.plasma.batterymonitor-boero" = {
          source = "${pkgs.kde-powerchart}/share/plasma/plasmoids/org.kde.plasma.batterymonitor-boero";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.glassySystemMonitor.enable {
        "plasma/plasmoids/org.muddyblack.glassySystemMonitor" = {
          source = "${pkgs.glassy-system-monitor}/share/plasma/plasmoids/org.muddyblack.glassySystemMonitor";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.modernClock.enable {
        "plasma/plasmoids/com.github.prayag2.modernclock" = {
          source = "${pkgs.kde-modern-clock}/share/plasma/plasmoids/com.github.prayag2.modernclock";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.overview.enable {
        "plasma/plasmoids/com.himdek.kde.plasma.overview" = {
          source = "${pkgs.kde-overview-widget}/share/plasma/plasmoids/com.himdek.kde.plasma.overview";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.plasmaAudioVisualizer.enable {
        "plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer" = {
          source = "${pkgs.plasma-audio-visualizer}/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.aiUsage.enable {
        "plasma/plasmoids/org.muddyblack.aiUsageWidget" = {
          source = "${pkgs.ai-usage-widget}/share/plasma/plasmoids/org.muddyblack.aiUsageWidget";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.tagesschau.enable {
        "plasma/plasmoids/org.muddyblack.tagesschauWidget" = {
          source = "${pkgs.tagesschau-widget}/share/plasma/plasmoids/org.muddyblack.tagesschauWidget";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.weather.enable {
        "plasma/plasmoids/org.kde.plasma.advanced-weather-widget" = {
          source = "${pkgs.advanced-weather-widget}/share/plasma/plasmoids/org.kde.plasma.advanced-weather-widget";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.nixosGenerationExplorer.enable {
        "plasma/plasmoids/org.muddyblack.nixosGenerationExplorer" = {
          source = "${pkgs.kde-nixdatifier}/share/plasma/plasmoids/org.muddyblack.nixosGenerationExplorer";
          force = true;
        };
      })
      // (lib.optionalAttrs cfg.gitpulse.enable {
        "plasma/plasmoids/org.muddyblack.gitpulse" = {
          source = "${pkgs.kde-gitpulse}/share/plasma/plasmoids/org.muddyblack.gitpulse";
          force = true;
        };
      });
  };
}
