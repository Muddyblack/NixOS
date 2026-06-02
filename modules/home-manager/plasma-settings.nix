{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.desktop.widgets;
  wallpaper = "${../../assets/wallpapers/desktop.png}";

  desktopWidgets =
    (lib.optional cfg.modernClock.enable {
      name = "com.github.prayag2.modernclock";
      config.Appearance = {
        showDate = "true";
        showDay = "true";
        dateFormat = "dd MMM yyyy";
      };
      position = {
        horizontal = 656;
        vertical = 288;
      };
      size = {
        width = 640;
        height = 256;
      };
    })
    ++ (lib.optional cfg.plasmaAudioVisualizer.enable {
      name = "org.muddyblack.plasmaAudioVisualizer";
      config.General.framerate = "24";
      config.General.progressBarStyle = "4";
      position = {
        horizontal = 826;
        vertical = 544;
      };
      size = {
        width = 360;
        height = 84;
      };
    })
    ++ (lib.optionals cfg.glassySystemMonitor.enable [
      {
        name = "org.muddyblack.glassySystemMonitor";
        config.General = {
          activeSection = "2";
          showCpuCores = "true";
          cpuTitle = "CPU Cores";
          glowLine = "true";
          gpuBloom = "false";
          targetFps = "15";
          showBg = "true";
          bgColor = "#800d0f1a";
        };
        position = {
          horizontal = 16;
          vertical = 64;
        };
        size = {
          width = 480;
          height = 448;
        };
      }
      {
        name = "org.muddyblack.glassySystemMonitor";
        config.General = {
          activeSection = "2";
          showCpuCores = "false";
          cpuTitle = "CPU Total";
          glowLine = "true";
          targetFps = "15";
          showBg = "true";
          bgColor = "#800d0f1a";
        };
        position = {
          horizontal = 16;
          vertical = 512;
        };
        size = {
          width = 240;
          height = 192;
        };
      }
      {
        name = "org.muddyblack.glassySystemMonitor";
        config.General = {
          activeSection = "3";
          memoryTitle = "Memory";
          glowLine = "true";
          targetFps = "15";
          showBg = "true";
          bgColor = "#800d0f1a";
        };
        position = {
          horizontal = 256;
          vertical = 512;
        };
        size = {
          width = 240;
          height = 192;
        };
      }
      {
        name = "org.muddyblack.glassySystemMonitor";
        config.General = {
          activeSection = "1";
          networkTitle = "Network Speed";
          networkInterface = "auto";
          glowLine = "true";
          targetFps = "15";
          showBg = "true";
          bgColor = "#800d0f1a";
        };
        position = {
          horizontal = 16;
          vertical = 704;
        };
        size = {
          width = 480;
          height = 192;
        };
      }
    ])
    ++ (lib.optional cfg.kscreen.enable {
      name = "org.kde.kscreen";
      position = {
        horizontal = 1472;
        vertical = 688;
      };
      size = {
        width = 448;
        height = 256;
      };
    });

  # Helper to create top panel with specific launcher
  makeTopPanel = screen: launcher: {
    inherit screen;
    location = "top";
    height = 32;
    floating = true;
    hiding = "none";
    opacity = "translucent";
    widgets =
      [
        launcher
        {
          iconTasks = {
            launchers = [
              "applications:systemsettings.desktop"
              "applications:org.kde.dolphin.desktop"
              "applications:com.mitchellh.ghostty.desktop"
            ];
            appearance = {
              showTooltips = true;
              highlightWindows = true;
              indicateAudioStreams = true;
              fill = true;
            };
            behavior = {
              grouping = {
                method = "byProgramName";
                clickAction = "showPresentWindowsEffect";
              };
              minimizeActiveTaskOnClick = true;
              middleClickAction = "newInstance";
              wheel = {
                switchBetweenTasks = true;
                ignoreMinimizedTasks = true;
              };
            };
          };
        }
        "org.kde.plasma.panelspacer"
        {
          name = "org.kde.plasma.digitalclock";
          config.Appearance = {
            dateFormat = "custom";
            customDateFormat = "ddd d MMM";
            showDate = "true";
            showSeconds = "never";
            use24hFormat = "2";
            selectedTimeZone = "Local";
          };
        }
        "org.kde.plasma.panelspacer"
      ]
      ++ (lib.optional cfg.weather.enable {
        name = "org.kde.plasma.advanced-weather-widget";
        config.General = {
          # European metric units
          unitsMode = "metric";
          temperatureUnit = "C";
          pressureUnit = "hPa";
          windSpeedUnit = "kmh";
          precipitationUnit = "mm";
          altitudeUnit = "m";
          # Panel: show just weather icon — click opens full detail popup
          panelInfoMode = "simple";
          panelShowWeatherIcon = "true";
          panelShowTemperature = "false";
          panelShowLocation = "false";
          # Full popup: open details tab with advanced card layout
          widgetLayoutMode = "advanced";
          widgetDefaultTab = "details";
          widgetVisibleTabs = "both";
          radarEnabled = "true";
          # Refresh every 15 minutes
          refreshIntervalMinutes = "15";
          autoRefresh = "true";
          autoDetectLocation = "false";
        };
      })
      ++ (lib.optional cfg.aiUsage.enable {
        name = "org.muddyblack.aiUsageWidget";
        config.General = {
          claudeEnabled = "true";
          antigravityEnabled = "true";
          openaiEnabled = "true";
          mistralEnabled = "true";
          popupBgOpacity = "0.2";
          cardBgOpacity = "0";
        };
      })
      ++ (lib.optional cfg.tagesschau.enable {
        name = "org.muddyblack.tagesschauWidget";
      })
      ++ (lib.optional cfg.glassySystemMonitor.enable {
        name = "org.muddyblack.glassySystemMonitor";
        config.General = {
          activeSection = "1";
          panelMode = "true";
          networkInterface = "auto";
          panelPlainText = "true";
          panelShowBg = "false";
          showBg = "false";
          glowLine = "true";
          targetFps = "15";
        };
      })
      ++ (lib.optional cfg.nixosGenerationExplorer.enable {
        name = "org.muddyblack.nixosGenerationExplorer";
        config.General = {
          # /etc/nixos is symlinked to the flake dir by deploy.sh —
          # works for any user without hardcoding the path.
          flakePath = "/etc/nixos";
          maxGenerations = "30";
          commandTerminal = "ghostty";
          customCommands = builtins.toJSON [
            {
              label = "upnix";
              cmd = "upnix";
              color = "accent";
            }
            {
              label = "update";
              cmd = "update";
              color = "default";
            }
          ];
          secretsPath = "/run/secrets";
          secretsSourcePath = "/etc/nixos/secrets/secrets.yaml";
          # Use original colored SVG — isMask:false path, no accent-color tinting
          iconStyle = "colored";
          compactStyle = "icon";
          # Translucent dark background matching the panel look
          showBg = "true";
          bgColor = "#990a0c14";
        };
      })
      ++ [
        {
          systemTray = {
            icons = {
              spacing = "small";
              scaleToFit = false;
            };
            items = {
              shown = [
                "org.kde.plasma.notifications"
                "org.kde.plasma.volume"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.brightness"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.batterymonitor-boero"
              ];
              hidden = [
                "org.kde.plasma.battery"
                "org.kde.plasma.weather"
                "org.kde.plasma.clipboard"
                "org.kde.plasma.mediacontroller"
                "org.kde.plasma.devicenotifier"
              ];
            };
          };
        }
      ];
  };

  # Helper to create bottom panel (dock)
  makeBottomPanel = screen: {
    inherit screen;
    location = "bottom";
    height = 60;
    lengthMode = "fit";
    floating = true;
    hiding = "dodgewindows";
    alignment = "center";
    opacity = "translucent";
    widgets =
      (lib.optional cfg.overview.enable "com.himdek.kde.plasma.overview")
      ++ [
        {
          iconTasks = {
            launchers = [
              "applications:antigravity.desktop"
              "applications:code.desktop"
              "applications:zen.desktop"
            ];
            appearance = {
              showTooltips = true;
              highlightWindows = true;
              indicateAudioStreams = true;
              fill = false;
            };
            behavior = {
              grouping = {
                method = "byProgramName";
                clickAction = "showPresentWindowsEffect";
              };
              minimizeActiveTaskOnClick = true;
              middleClickAction = "newInstance";
              wheel = {
                switchBetweenTasks = true;
                ignoreMinimizedTasks = true;
              };
            };
          };
        }
        {
          name = "org.kde.plasma.folder";
          config.General.url = "file://${config.home.homeDirectory}/Downloads";
        }
        "org.kde.plasma.trash"
      ];
  };
in {
  programs.plasma = {
    enable = true;
    immutableByDefault = false;

    workspace = {
      clickItemTo = "select";
      lookAndFeel = "Vivid-Dark-Global-6";
      cursor.theme = "Sweet-cursors";
      iconTheme = "Slot-Dark-Icons";
      wallpaper = wallpaper;
    };

    desktop.widgets = desktopWidgets;

    panels =
      # Top Panels: kickoff on screen 0, kicker on others (to avoid lag)
      (map (s:
        makeTopPanel s (
          if s == 0
          then {
            name = "org.kde.plasma.kickoff";
            config.General = {
              icon = "nix-snowflake-white";
              alphaSort = "true";
              display = "popup";
            };
          }
          else {
            name = "org.kde.plasma.kicker";
            config.General = {
              icon = "nix-snowflake-white";
              alphaSort = "true";
            };
          }
        )) (lib.range 0 3))
      ++ (map (s: makeBottomPanel s) (lib.range 0 3));

    shortcuts = {
      ksmserver."Lock Session" = ["Meta+L" "Screensaver"];
      ksmserver."Log Out" = "Ctrl+Alt+Del";
      kwin = {
        "Walk Through Windows" = "Alt+Tab";
        "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
        "Window Close" = ["Meta+Q" "Alt+F4"];
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Quick Tile Bottom" = "Meta+Down";
        "Show Desktop" = "Meta+D";
        "Overview" = "Meta+W";
        "Toggle Night Color" = ["Meta+Shift+N"];
      };
      # Disable default Activities shortcut to free up Meta+Q
      plasmashell."manage activities" = "none";
      plasmashell."activate application launcher" = ["Alt+F1" "Meta"];
      "services/org.kde.krunner.desktop"._launch = "Meta+Space";
      "services/org.kde.systemmonitor.desktop"._launch = "none";
      "caelestia-monitor.desktop"."_launch" = "Ctrl+Shift+Esc";
      "services/com.mitchellh.ghostty.desktop"._launch = "Ctrl+Alt+T";
      "services/org.kde.konsole.desktop"._launch = "Ctrl+Alt+A";
      "services/systemsettings.desktop"._launch = ["Tools" "Meta+I"];
      "services/kcm_kscreen.desktop"._launch = "Meta+P";
      "org.kde.spectacle.desktop" = {
        ActiveWindowScreenShot = "Meta+Print";
        RectangularRegionScreenShot = "Meta+Shift+S";
        FullScreenScreenShot = "Print";
        WindowUnderCursorScreenShot = "Meta+Ctrl+Print";
        CurrentMonitorScreenShot = "none";
        _launch = "none";
      };
      kmix = {
        mute = "Volume Mute";
        decrease_volume = "Volume Down";
        increase_volume = "Volume Up";
      };
      mediacontrol = {
        nextmedia = "Media Next";
        previousmedia = "Media Previous";
        playpausemedia = "Media Play";
      };
    };

    configFile = {
      krunnerrc.General.FreeFloating = true;
      krunnerrc.General.historyBehavior = "ImmediateCompletion";

      # Lock screen wallpaper
      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".Image = "${../../assets/wallpapers/lockscreen.png}";
      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".PreviewImage = "${../../assets/wallpapers/lockscreen.png}";
      kscreenlockerrc.Daemon.Timeout = 10;

      ksplashrc.KSplash.Theme = "Illusion";
      plasmarc.Theme.name = "Iridescent-round";

      # Window decorations (Utterly Round)
      kwinrc."org.kde.kdecoration2".theme = "__aurorae__svg__Utterly-Round-Dark";
      kwinrc."org.kde.kdecoration2".library = "org.kde.kwin.aurorae";

      # Blur & transparency
      kwinrc."Effect-blur".BlurStrength = 12;
      kwinrc."Effect-blur".NoiseStrength = 2;
      kwinrc."Effect-contrast".contrast = 20;
      kwinrc."Effect-contrast".intensity = 150;
      kwinrc."Effect-contrast".saturation = 100;

      kwinrc.Plugins.blurEnabled = true;
      kwinrc.Plugins.contrastEnabled = true;
      kwinrc.Plugins.dimscreenEnabled = true;
      kwinrc.Plugins.slidebackEnabled = true;

      # Night Color
      kwinrc.NightColor.Active = false;
      kwinrc.NightColor.Mode = 0;
      kwinrc.NightColor.NightTemperature = 3500;
      kwinrc.NightColor.DayTemperature = 6500;

      kwinrc.Desktops.Number = 2;
      kwinrc.Desktops.Rows = 1;

      # Global settings
      kdeglobals.General.BrowserApplication = "zen.desktop";
      kdeglobals.General.soundTheme = "ocean";
      kdeglobals.General.ColorScheme = "BreezeDark";
      kdeglobals.KDE.AnimationDurationFactor = 0.25;
      kdeglobals.KDE.widgetStyle = "kvantum";

      baloofilerc."Basic Settings".Indexing-Enabled = false;
      plasmanotifyrc.Notifications.PopupPosition = "TopRight";

      # Locale
      plasma-localerc.Formats.LANG = "en_US.UTF-8";
      plasma-localerc.Formats.LC_TIME = "de_DE.UTF-8";
      plasma-localerc.Translations.LANGUAGE = "en_US";

      # Dolphin
      dolphinrc.General.ShowMenuBar = false;
      dolphinrc.General.ShowStatusBar = false;
      dolphinrc.General.ShowToolTips = false;
      dolphinrc.General.ShowHiddenFiles = true;
      dolphinrc.General.ViewPropsTimestamp = "2024,10,10,17,38,2.483";
      dolphinrc.KMainWindow."MenuBar" = "Disabled";
      dolphinrc.KMainWindow."ToolBars" = "Disabled";
      dolphinrc.KMainWindow."StatusBar" = "Disabled";
      dolphinrc."KFileDialog Settings"."Places Icons Auto-resize" = false;
      dolphinrc."KFileDialog Settings"."Places Icons Static Size" = 22;

      dolphinrc.PlacesPanel.IconSize = 22;

      dolphinrc.ContextMenu.ContextMenuTerminal = false;

      "plasmashellrc".Tmux."date-format" = "ddd. d MMM.";

      "plasma-org.kde.plasma.mediacontroller".General.showStopButton = true;
      "plasma-org.kde.plasma.mediacontroller".General.commandsInPanel = true;
      "plasma-org.kde.plasma.mediacontroller".General.useAlbumArtAsIcon = true;

      spectaclerc.General.clipboardGroup = "PostScreenshotCopyImage";
      spectaclerc.General.autoSaveImage = false;
      spectaclerc.General.copySaveLocationToClipboard = false;
      spectaclerc.General.useLastVisitedDirectory = true;
      spectaclerc.General.compressionQuality = 95;
      spectaclerc.General.copyImageToClipboard = true;
      spectaclerc.GuiConfig.captureMode = 1;
      spectaclerc.ImageSave.imageCompressionQuality = 95;
      spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";

      klipperrc.General.SyncClipboards = false;
      kcminputrc.Mouse.InvertScroll = false;

      # Hyprland-style Super+drag-anywhere-to-move window
      # Super + Left Click  = Move window
      # Super + Middle Click = Resize window
      # Super + Right Click  = Toggle raise/lower
      kwinrc.MouseBindings.CommandAllKey = "Meta";
      kwinrc.MouseBindings.CommandAll1 = "Move";
      kwinrc.MouseBindings.CommandAll2 = "Toggle raise and lower";
      kwinrc.MouseBindings.CommandAll3 = "Resize";

      # Touchpad
      touchpadrc.Libinput.NaturalScrolling = false;
      touchpadrc.Libinput.ClickMethod = 1; # 1 = Areas, 2 = Clickfinger
      touchpadrc.Libinput.TapToClick = true;
    };
  };

  xdg.dataFile."kio/servicemenus/com.mitchellh.ghostty.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=inode/directory;
    Actions=openInGhostty;openWithVSCode;openWithAntigravity;
    X-KDE-Priority=TopLevel

    [Desktop Action openInGhostty]
    Name=Open Ghostty Here
    Icon=com.mitchellh.ghostty
    Exec=ghostty --working-directory=%f

    [Desktop Action openWithVSCode]
    Name=Open with VS Code
    Icon=vscode
    Exec=code %f

    [Desktop Action openWithAntigravity]
    Name=Open with Antigravity
    Icon=antigravity
    Exec=antigravity %f
  '';

  systemd.user.services.powerchart-rapl-config = {
    Unit = {
      Description = "Set RAPL system power source for batterymonitor-boero widget";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "powerchart-rapl-config" ''
        qdbus=${pkgs.kdePackages.qttools}/bin/qdbus
        script="
          var found = 0;
          panels().concat(desktops()).forEach(function(c) {
            c.widgets().forEach(function(w) {
              if (w.type && w.type.indexOf('batterymonitor-boero') !== -1) {
                w.currentConfigGroup = ['General'];
                w.writeConfig('raplSource', 'package');
                w.reloadConfig();
                found += 1;
              }
            });
          });
          print(found);
        "
        (
          for i in $(seq 1 120); do
            "$qdbus" org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
            sleep 0.5
          done
          for i in $(seq 1 30); do
            out=$("$qdbus" org.kde.plasmashell /PlasmaShell \
              org.kde.PlasmaShell.evaluateScript "$script" 2>/dev/null || true)
            case "$out" in
              [1-9]*) echo "powerchart-rapl-config: applied to $out widget(s)"; exit 0 ;;
            esac
            sleep 2
          done
          echo "powerchart-rapl-config: widget not found after 60s" >&2
        ) &
        disown
      '');
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  systemd.user.paths.powerchart-rapl-config = {
    Unit = {
      Description = "Watch appletsrc and re-apply RAPL source for powerchart";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Path = {
      PathChanged = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      Unit = "powerchart-rapl-config.service";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
