{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}: let
  cfg = config.desktop.widgets;
  wallpaper = "${config.home.homeDirectory}/.local/share/wallpapers/desktop.png";

  # Shifted number row per layout — the Meta+Shift+<digit> shortcuts below have
  # to be written as the character the layout actually produces. Add an entry
  # when forking to another layout; anything unlisted falls back to the US row.
  shiftedNumberRows = {
    de = ["!" "\"" "§" "$" "%"];
    us = ["!" "@" "#" "$" "%"];
  };
  shiftedDigits = shiftedNumberRows.${osConfig.keyboardLayout} or shiftedNumberRows.us;

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
      config.General.framerate = "60";
      config.General.progressBarStyle = "4";
      config.General.numBars = "32";
      position = {
        horizontal = 790;
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
          targetFps = "24";
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
          gpuBloom = "true";
          targetFps = "24";
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
          gpuBloom = "true";
          targetFps = "24";
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
          gpuBloom = "true";
          targetFps = "24";
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

  makeTopPanel = screen: {
    inherit screen;
    location = "top";
    height = 32;
    floating = true;
    hiding = "none";
    opacity = "translucent";
    widgets =
      [
        # Launcher removed — use Meta (KRunner) instead.
        {
          name = "org.kde.plasma.pager";
          config.General = {
            displayedText = "2"; # 0 = desktop number, 1 = desktop name, 2 = none (just thumbnails)
            showWindowIcons = "false";
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
          tooltipEnabled = "false";
        };
      })
      ++ (lib.optional cfg.aiUsage.enable {
        name = "org.muddyblack.aiUsageWidget";
        config.General = {
          claudeEnabled = "true";
          antigravityEnabled = "true";
          openaiEnabled = "true";
          mistralEnabled = "true";
          kiroEnabled = "true";
          popupBgOpacity = "0.4";
          cardBgOpacity = "0.1";
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
          gpuBloom = "true";
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
      ++ (lib.optional cfg.gitpulse.enable {
        name = "org.muddyblack.gitpulse";
        config.General.useGhCli = "true";
      })
      ++ [
        {
          systemTray = {
            icons = {
              spacing = "small";
              scaleToFit = false;
            };
            items = {
              shown =
                [
                  "org.kde.plasma.notifications"
                  "org.kde.plasma.volume"
                  "org.kde.plasma.bluetooth"
                  "org.kde.plasma.brightness"
                  "org.kde.plasma.networkmanagement"
                ]
                ++ (lib.optional cfg.powerchart.enable "org.kde.plasma.batterymonitor-boero");
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
              "applications:antigravity-ide.desktop"
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
      # NOTE: deliberately no `lookAndFeel`. plasma-manager applies it with
      # `plasma-apply-lookandfeel` from an XDG-autostart script that runs *after*
      # plasmashell has started, which clobbers the config home-manager just wrote
      # (it empties plasmarc and strips kwinrc's [org.kde.kdecoration2]), leaving
      # one broken session until the next login. Every key Vivid-Dark-Global-6 set
      # is overridden below anyway, so it only ever cost us a session.
      cursor.theme = "Sweet-cursors";
      iconTheme = "Slot-Dark-Icons";
      wallpaper = wallpaper;
    };

    desktop.widgets = desktopWidgets;

    # Hyprland-style: 5 always-present virtual desktops (Meta+1..5).
    kwin.virtualDesktops = {
      number = 5;
      rows = 1;
    };

    panels = [
      (makeTopPanel "all")
      (makeBottomPanel "all")
    ];

    # PowerDevil drives power-profiles-daemon over DBus, so this is what
    # actually picks /sys/firmware/acpi/platform_profile (the EC fan curve) on
    # top of the CPU governor/EPP. Selecting it here means the choice survives
    # reboots instead of depending on clicking the battery applet.
    #
    # AC defaults to "balanced" -- performance is a manual, user-driven choice
    # (e.g. via the battery applet), not something plugging in should force.
    # Note: on this chassis the EC's "balanced" fan curve thermally clamps the
    # package to ~10W, against ~19W on "performance" (measured 2026-08-03),
    # a side effect of a degraded heatsink. Switch to "performance" manually
    # when more power is needed until the cooler is serviced.
    powerdevil = {
      AC.powerProfile = "balanced";
      battery.powerProfile = "balanced";
      lowBattery.powerProfile = "powerSaving";
    };

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
        "Cube" = "Meta+C";

        # Hyprland-style desktop switching: Meta+1..5.
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";

        # KWin-script actions: the scripts (move-follow, toggle-bottom-panel)
        # register the callbacks, but their own registerShortcut() key requests
        # are NOT reliably grabbed under plasma-manager. Declare the bindings
        # here so plasma-manager owns them — same path as every working shortcut.
        #
        # These are still pressed as Meta+Shift+<digit>. They must be *written*
        # as the produced character, because KWin drops Shift from the modifier
        # mask when xkb reports it as "consumed" producing the keysym
        # (Xkb::modifiersRelevantForGlobalShortcuts). Meta+Shift+1 therefore
        # arrives as Meta + Key_Exclam, and a literal "Meta+Shift+1" entry can
        # never match. Meta+Shift+<letter> is unaffected (Shift is not consumed
        # there), which is why Meta+Shift+S works but Meta+Shift+1 did not.
        #
        # Which characters those are depends on the layout — German gives
        # ! " § $ % , US gives ! @ # $ % — so they come from shiftedDigits
        # above, keyed by the system-wide keyboardLayout option.
        "MoveFollowDesktop1" = "Meta+${builtins.elemAt shiftedDigits 0}";
        "MoveFollowDesktop2" = "Meta+${builtins.elemAt shiftedDigits 1}";
        "MoveFollowDesktop3" = "Meta+${builtins.elemAt shiftedDigits 2}";
        "MoveFollowDesktop4" = "Meta+${builtins.elemAt shiftedDigits 3}";
        "MoveFollowDesktop5" = "Meta+${builtins.elemAt shiftedDigits 4}";
        "ToggleBottomPanel" = "Meta+B";
      };
      # Disable default Activities shortcut to free up Meta+Q
      plasmashell."manage activities" = "none";
      plasmashell."activate application launcher" = "none";
      plasmashell."activate task manager entry 1" = "none";
      plasmashell."activate task manager entry 2" = "none";
      plasmashell."activate task manager entry 3" = "none";
      plasmashell."activate task manager entry 4" = "none";
      plasmashell."activate task manager entry 5" = "none";
      plasmashell."activate task manager entry 6" = "none";
      plasmashell."activate task manager entry 7" = "none";
      plasmashell."activate task manager entry 8" = "none";
      plasmashell."activate task manager entry 9" = "none";
      plasmashell."activate task manager entry 10" = "none";
      # KRunner: Meta+Space, the "Search" key, AND a bare Meta tap. The lone
      # "Meta" is a real modifier-only global shortcut — since Plasma 6.1 these
      # live in kglobalaccel/kglobalshortcutsrc (the old kwinrc
      # [ModifierOnlyShortcuts] block is ignored). Tapping Meta alone toggles
      # KRunner; Meta+<key> combos are unaffected. Log out/in to (re)arm.
      "services/org.kde.krunner.desktop"._launch = ["Meta+Space" "Search" "Meta"];
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
      # Plasma's own emoji picker only ever copies to the clipboard. Free
      # Meta+. for fcitx5's unicode/emoji input, which commits through the IME
      # and types straight into the focused field (see desktop.nix).
      "org.kde.plasma.emojier.desktop"._launch = "none";
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
      # Keyboard layout. services.xserver.xkb only feeds systemd-localed — the
      # greeter and XWayland. A Plasma session reads kxkbrc, and with no
      # LayoutList of its own KWin falls back to "us" regardless — which is why every
      # Plasma session came up US while console and Hyprland used keyboardLayout.
      kxkbrc.Layout.Use = true;
      kxkbrc.Layout.LayoutList = osConfig.keyboardLayout;
      kxkbrc.Layout.VariantList = "";
      kxkbrc.Layout.DisplayNames = "";

      krunnerrc.General.FreeFloating = true;
      krunnerrc.General.historyBehavior = "ImmediateCompletion";

      # Lock screen wallpaper
      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".Image = "${config.home.homeDirectory}/.local/share/wallpapers/lockscreen.png";
      kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".PreviewImage = "${config.home.homeDirectory}/.local/share/wallpapers/lockscreen.png";
      kscreenlockerrc.Daemon.Timeout = 10;

      # Let KWin launch fcitx5 itself (System Settings -> Virtual Keyboard);
      # without this the Wayland IM frontend never gets a socket under Plasma.
      kwinrc.Wayland.InputMethod = {
        value = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
        shellExpand = true;
      };

      ksplashrc.KSplash.Theme = "Illusion";
      plasmarc.Theme.name = "Iridescent-round";

      # Window decorations (Utterly Round)
      kwinrc."org.kde.kdecoration2".theme = "__aurorae__svg__Utterly-Round-Dark";
      kwinrc."org.kde.kdecoration2".library = "org.kde.kwin.aurorae";

      # Compositor — OpenGL, low latency, smooth
      kwinrc.Compositing.Backend = "OpenGL";
      kwinrc.Compositing.GLCore = true;
      kwinrc.Compositing.LatencyPolicy = "Low";
      kwinrc.Compositing.MaxFPS = 144;
      kwinrc.Compositing.RefreshRate = 0;
      kwinrc.Compositing.HiddenPreviews = 5;
      kwinrc.Compositing.WindowsBlockCompositing = false;

      # Blur & transparency
      kwinrc."Effect-blur".BlurStrength = 8;
      kwinrc."Effect-blur".NoiseStrength = 0;
      kwinrc."Effect-contrast".contrast = 20;
      kwinrc."Effect-contrast".intensity = 150;
      kwinrc."Effect-contrast".saturation = 100;

      kwinrc.Plugins.blurEnabled = true;
      kwinrc.Plugins.contrastEnabled = true;
      kwinrc.Plugins.dimscreenEnabled = false;
      kwinrc.Plugins.slidebackEnabled = false;
      kwinrc.Plugins.wobblywindowsEnabled = false;

      # Desktop Cube (kdeplasma-addons): toggled with Meta+C, arranges the
      # virtual desktops on the faces of a 3D cube. Manual overlay, not an
      # automatic replacement for the Meta+1..5 instant desktop switching.
      kwinrc.Plugins.cubeEnabled = true;

      # Night Color
      kwinrc.NightColor.Active = false;
      kwinrc.NightColor.Mode = 0;
      kwinrc.NightColor.NightTemperature = 3500;
      kwinrc.NightColor.DayTemperature = 6500;

      # Virtual desktop count/rows are managed by kwin.virtualDesktops above.

      # Enable the custom "move window to desktop N and follow" KWin script.
      kwinrc.Plugins."move-followEnabled" = true;
      kwinrc.Plugins."toggle-bottom-panelEnabled" = true;
      # NOTE: kwinrc [ModifierOnlyShortcuts] has been dead since Plasma 6.1.
      # The bare-Meta tap is bound via the krunner "_launch" shortcut above.

      # Global settings
      kdeglobals.General.BrowserApplication = "zen.desktop";
      kdeglobals.General.soundTheme = "ocean";
      kdeglobals.General.ColorScheme = "BreezeDark";
      kdeglobals.KDE.AnimationDurationFactor = 0.5;
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
    Actions=openInGhostty;openWithVSCode;openWithAntigravityIDE;openWithZed;
    X-KDE-Priority=TopLevel

    [Desktop Action openInGhostty]
    Name=Open Ghostty Here
    Icon=com.mitchellh.ghostty
    Exec=ghostty --working-directory=%f

    [Desktop Action openWithVSCode]
    Name=Open with VS Code
    Icon=vscode
    Exec=code %f

    [Desktop Action openWithAntigravityIDE]
    Name=Open with Antigravity IDE
    Icon=antigravity-ide
    Exec=antigravity-ide --disable-gpu %f

    [Desktop Action openWithZed]
    Name=Open with Zed
    Icon=zed
    Exec=zeditor %f
  '';

  # Hyprland-style "move active window to desktop N and follow it".
  # Bound to Meta+Shift+1..9 and Meta+Shift+0 (= desktop 10).
  # Enabled via kwinrc.Plugins."move-followEnabled" above.
  xdg.dataFile."kwin/scripts/move-follow/metadata.json".text = builtins.toJSON {
    KPlugin = {
      Id = "move-follow";
      Name = "Move Window to Desktop and Follow";
      Description = "Meta+Shift+N moves the active window to desktop N and follows it.";
      Version = "1.0";
      EnabledByDefault = true;
    };
    KPackageStructure = "KWin/Script";
    "X-Plasma-API" = "javascript";
    "X-Plasma-MainScript" = "code/main.js";
  };

  xdg.dataFile."kwin/scripts/move-follow/contents/code/main.js".text = ''
    // Pressed as Meta+Shift+<digit>, but written as the produced character:
    // KWin drops the consumed Shift, so Meta+Shift+1 arrives as Meta+"!".
    // German number row ("de" layout) — see the kwin shortcuts block in
    // plasma-settings.nix for the full explanation. Keep both in sync.
    var followSymbols = ["!", "\"", "§", "$", "%"];
    function registerForDesktop(n) {
      var key = followSymbols[n - 1];
      registerShortcut(
        "MoveFollowDesktop" + n,
        "Move Window to Desktop " + n + " and Follow",
        "Meta+" + key,
        function () {
          print("MoveFollowDesktop callback triggered for desktop " + n);
          var w = workspace.activeWindow;
          if (!w) {
            print("MoveFollowDesktop: No active window");
            return;
          }
          var desks = workspace.desktops;
          if (n > desks.length) {
            print("MoveFollowDesktop: n " + n + " is greater than desktops count " + desks.length);
            return;
          }
          var target = desks[n - 1];
          print("MoveFollowDesktop: Moving window to desktop " + n);
          w.desktops = [target];
          workspace.currentDesktop = target;
          print("MoveFollowDesktop: Finished");
        }
      );
    }
    for (var i = 1; i <= 5; i++) {
      registerForDesktop(i);
    }
  '';

  xdg.dataFile."kwin/scripts/toggle-bottom-panel/metadata.json".text = builtins.toJSON {
    KPlugin = {
      Id = "toggle-bottom-panel";
      Name = "Toggle Bottom Panel";
      Description = "Toggles the bottom Plasma panel.";
      Version = "1.0";
      EnabledByDefault = true;
    };
    KPackageStructure = "KWin/Script";
    "X-Plasma-API" = "javascript";
    "X-Plasma-MainScript" = "code/main.js";
  };

  xdg.dataFile."kwin/scripts/toggle-bottom-panel/contents/code/main.js".text = ''
    var toggleBottomPanelScript =
      "panels().forEach(function(panel) {" +
      "  if (panel.location === 'bottom') {" +
      "    panel.hiding = (panel.hiding === 'dodgewindows') ? 'autohide' : 'dodgewindows';" +
      "  }" +
      "});";

    registerShortcut(
      "ToggleBottomPanel",
      "Toggle Bottom Panel",
      "Meta+B",
      function () {
        callDBus(
          "org.kde.plasmashell",
          "/PlasmaShell",
          "org.kde.PlasmaShell",
          "evaluateScript",
          toggleBottomPanelScript
        );
      }
    );
  '';

  systemd.user.services.powerchart-rapl-config = lib.mkIf cfg.powerchart.enable {
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

  systemd.user.paths.powerchart-rapl-config = lib.mkIf cfg.powerchart.enable {
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

  # Heavy: full containment rebuild. Run MANUALLY after deploy.sh when widget
  # positions drift. Backs up appletsrc, restarts plasmashell, re-applies layout.
  # Usage: systemctl --user start plasma-layout-rebuild
  systemd.user.services.plasma-layout-rebuild = {
    Unit = {
      Description = "Rebuild Plasma desktop layout from plasma-manager config";
    };
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "plasma-layout-rebuild" ''
        set -u
        cfg=${config.home.homeDirectory}/.config
        cache=${config.home.homeDirectory}/.cache/plasmashell
        pm=${config.home.homeDirectory}/.local/share/plasma-manager
        ts=$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)
        backup=$cfg/plasma-backup-$ts
        ${pkgs.coreutils}/bin/mkdir -p "$backup"

        # Back up files we're about to wipe
        for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc; do
          [ -f "$cfg/$f" ] && ${pkgs.coreutils}/bin/cp "$cfg/$f" "$backup/$f" || true
        done
        echo "layout rebuild: backup at $backup"

        # Clear plasma-manager idempotency markers so scripts re-run
        rm -f "$pm/last_run_desktop_script_panels"
        rm -f "$pm/last_run_desktop_script_set_desktop_widgets"
        rm -f "$pm/last_run_desktop_script_wallpaper_picture"

        # Stop plasmashell via its own service (clean) then wait
        ${pkgs.systemd}/bin/systemctl --user stop plasma-plasmashell.service || true
        ${pkgs.procps}/bin/pkill -x plasmashell || true
        for i in $(seq 1 30); do
          ${pkgs.procps}/bin/pgrep -x plasmashell >/dev/null || break
          sleep 0.1
        done

        # Wipe cached containment state
        rm -f "$cfg/plasma-org.kde.plasma.desktop-appletsrc"
        rm -f "$cfg/plasmashellrc"
        rm -rf "$cache"

        # Bring plasmashell back via its service (survives this unit exiting)
        ${pkgs.systemd}/bin/systemctl --user start plasma-plasmashell.service || \
          ${pkgs.systemd}/bin/systemd-run --user --scope ${pkgs.kdePackages.plasma-workspace}/bin/plasmashell &

        # Wait for plasmashell DBus to be ready
        for i in $(seq 1 100); do
          ${pkgs.kdePackages.qttools}/bin/qdbus org.kde.plasmashell / >/dev/null 2>&1 && break
          sleep 0.1
        done

        # Re-apply plasma-manager layout against the fresh shell
        ${pkgs.bash}/bin/bash "$pm/run_all.sh" || {
          echo "run_all.sh failed; restoring backup" >&2
          ${pkgs.coreutils}/bin/cp -f "$backup/plasma-org.kde.plasma.desktop-appletsrc" "$cfg/" 2>/dev/null || true
          ${pkgs.coreutils}/bin/cp -f "$backup/plasmashellrc" "$cfg/" 2>/dev/null || true
          ${pkgs.procps}/bin/pkill -x plasmashell || true
          ${pkgs.systemd}/bin/systemctl --user start plasma-plasmashell.service || true
          exit 1
        }
        echo "layout rebuild: ok"
      '');
    };
  };
}
