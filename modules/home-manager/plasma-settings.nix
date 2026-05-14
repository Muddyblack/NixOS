{
  lib,
  config,
  ...
}: let
  wallpaper = "${../../assets/wallpapers/desktop.png}";

  desktopWidgets = [
    # Center: large date/clock banner
    {
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
    }
    {
      name = "Audio.Wave.Widget";
      position = {
        horizontal = 826;
        vertical = 544;
      };
      size = {
        width = 300;
        height = 84;
      };
    }
    {
      name = "org.kde.plasma.systemmonitor";
      config = {
        Appearance = {
          chartFace = "org.kde.ksysguard.linechart";
          title = "CPU Cores";
        };
        Sensors.highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
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
      name = "org.kde.plasma.systemmonitor";
      config = {
        Appearance = {
          chartFace = "org.kde.ksysguard.linechart";
          title = "CPU Total";
        };
        Sensors = {
          highPrioritySensorIds = "[\"cpu/all/usage\"]";
          totalSensors = "[\"cpu/all/usage\"]";
        };
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
      name = "org.kde.plasma.systemmonitor";
      config = {
        Appearance = {
          chartFace = "org.kde.ksysguard.linechart";
          title = "Memory";
        };
        Sensors = {
          highPrioritySensorIds = "[\"memory/physical/usedPercent\"]";
          totalSensors = "[\"memory/physical/usedPercent\"]";
        };
      };
      position = {
        horizontal = 256;
        vertical = 512;
      };
      size = {
        width = 288;
        height = 192;
      };
    }
    {
      name = "org.kde.plasma.systemmonitor";
      config = {
        Appearance = {
          chartFace = "org.kde.ksysguard.linechart";
          title = "Network Speed";
        };
        Sensors.highPrioritySensorIds = "[\"network/all/download\",\"network/all/upload\"]";
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
    {
      name = "org.kde.kscreen";
      position = {
        horizontal = 1472;
        vertical = 688;
      };
      size = {
        width = 448;
        height = 256;
      };
    }
  ];

  # Helper to create top panel with specific launcher
  makeTopPanel = screen: launcher: {
    inherit screen;
    location = "top";
    height = 32;
    floating = true;
    hiding = "none";
    opacity = "translucent";
    widgets = [
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
      {
        name = "org.kde.netspeedWidget";
        config.General = {
          showIcons = "true";
          speedUnits = "auto";
          updateInterval = "2";
        };
      }
      {
        systemTray = {
          icons = {
            spacing = "small";
            scaleToFit = false;
          };
          items = {
            shown = [
              "org.kde.plasma.notifications"
              "org.kde.plasma.clipboard"
              "org.kde.plasma.mediacontroller"
              "org.kde.plasma.volume"
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.brightness"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.devicenotifier"
              "org.kde.plasma.battery"
            ];
            hidden = [];
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
    widgets = [
      "com.himdek.kde.plasma.overview"
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
}
