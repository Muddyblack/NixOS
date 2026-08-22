{config, ...}: let
  enumVariant = variant: {
    __type = "enum";
    inherit variant;
  };
  systemAction = variant: {
    __type = "enum";
    variant = "System";
    value = [(enumVariant variant)];
  };
  directionAction = variant: dir: {
    __type = "enum";
    inherit variant;
    value = [(enumVariant dir)];
  };
  workspaceAction = variant: n: {
    __type = "enum";
    inherit variant;
    value = [n];
  };
  spawn = cmd: {
    __type = "enum";
    variant = "Spawn";
    value = [cmd];
  };

  # Hyprland-style Super+1..0 (workspace 10) and Super+Shift+1..0 (send to workspace).
  workspaceShortcuts = mods: variant:
    map (n: {
      key = "${mods}+${toString (
        if n == 10
        then 0
        else n
      )}";
      action = workspaceAction variant n;
    }) (builtins.genList (i: i + 1) 10);

  # Hyprland-style directional focus/move: Super+arrows, Super+Shift+arrows.
  directionShortcuts = mods: variant:
    map (dir: {
      key = "${mods}+${dir}";
      action = directionAction variant dir;
    }) ["Left" "Right" "Up" "Down"];
in {
  wayland.desktopManager.cosmic = {
    enable = true;

    systemActions = {
      __type = "map";
      value = [
        {
          key = enumVariant "Terminal";
          value = "ghostty";
        }
      ];
    };

    appearance.theme.mode = "dark";

    wallpapers = [
      {
        output = "all";
        source = {
          __type = "enum";
          variant = "Path";
          value = ["${config.home.homeDirectory}/.local/share/wallpapers/desktop.png"];
        };
        filter_by_theme = true;
        filter_method = enumVariant "Lanczos";
        sampling_method = enumVariant "Alphanumeric";
        scaling_mode = enumVariant "Zoom";
        rotation_frequency = 0;
      }
    ];

    # cosmic-comp owns its own libinput handling (independent of
    # services.libinput, same as Hyprland/Plasma each duplicating touchpad
    # config) and defaults touchpad scrolling to Edge, not TwoFinger.
    compositor.input_touchpad = {
      disable_while_typing = {
        __type = "optional";
        value = true;
      };
      tap_config = {
        __type = "optional";
        value = {
          button_map = {
            __type = "optional";
            value = enumVariant "LeftMiddleRight";
          };
          drag = true;
          drag_lock = true;
          enabled = true;
        };
      };
      scroll_config = {
        __type = "optional";
        value = {
          method = {
            __type = "optional";
            value = {
              __type = "enum";
              variant = "TwoFinger";
            };
          };
          natural_scroll = {
            __type = "optional";
            value = true;
          };
          scroll_button = {
            __type = "optional";
            value = 2;
          };
          scroll_factor = {
            __type = "optional";
            value = 1.0;
          };
        };
      };
    };

    panels = [
      {
        name = "Panel";
        anchor = enumVariant "Top";
        anchor_gap = true;
        background = enumVariant "Dark";
        expand_to_edges = true;
        margin = 4;
        # "Active" (primary output), never a hardcoded output name — laptop
        # with a variable external-monitor setup.
        output = enumVariant "Active";
        size = enumVariant "M";
        plugins_center = {
          __type = "optional";
          value = ["com.system76.CosmicAppletTime"];
        };
        plugins_wings = {
          __type = "optional";
          value = {
            __type = "tuple";
            value = [
              [
                "com.system76.CosmicPanelWorkspacesButton"
                "com.system76.CosmicPanelAppButton"
                "com.system76.CosmicAppletWorkspaces"
              ]
              [
                "com.system76.CosmicAppletInputSources"
                "com.system76.CosmicAppletAudio"
                "com.system76.CosmicAppletNetwork"
                "com.system76.CosmicAppletBattery"
                "com.system76.CosmicAppletNotifications"
                "com.system76.CosmicAppletBluetooth"
                "com.system76.CosmicAppletPower"
              ]
            ];
          };
        };
      }
    ];

    shortcuts =
      [
        {
          key = "Super+Return";
          action = spawn "ghostty";
        }
        {
          key = "Super+E";
          action = spawn "dolphin";
        }
        {
          key = "Super+Q";
          action = enumVariant "Close";
        }
        {
          key = "Super+F";
          action = enumVariant "Fullscreen";
        }
        {
          key = "Super+V";
          action = enumVariant "ToggleWindowFloating";
        }
        {
          key = "Super+W";
          action = systemAction "WorkspaceOverview";
        }
        {
          key = "Alt+Tab";
          action = systemAction "WindowSwitcher";
        }
        {
          key = "Alt+Shift+Tab";
          action = systemAction "WindowSwitcherPrevious";
        }
        {
          key = "Super+L";
          action = systemAction "LockScreen";
        }
        {
          key = "Ctrl+Alt+Delete";
          action = systemAction "LogOut";
        }
        {
          key = "Print";
          action = systemAction "Screenshot";
        }
        {
          key = "Super+Shift+S";
          action = systemAction "Screenshot";
        }
        {
          key = "XF86AudioRaiseVolume";
          action = systemAction "VolumeRaise";
        }
        {
          key = "XF86AudioLowerVolume";
          action = systemAction "VolumeLower";
        }
        {
          key = "XF86AudioMute";
          action = systemAction "Mute";
        }
        {
          key = "XF86AudioMicMute";
          action = systemAction "MuteMic";
        }
        {
          key = "XF86MonBrightnessUp";
          action = systemAction "BrightnessUp";
        }
        {
          key = "XF86MonBrightnessDown";
          action = systemAction "BrightnessDown";
        }
        {
          key = "XF86AudioNext";
          action = systemAction "PlayNext";
        }
        {
          key = "XF86AudioPrev";
          action = systemAction "PlayPrev";
        }
        {
          key = "XF86AudioPlay";
          action = systemAction "PlayPause";
        }
        {
          key = "XF86AudioPause";
          action = systemAction "PlayPause";
        }
      ]
      ++ directionShortcuts "Super" "Focus"
      ++ directionShortcuts "Super+Shift" "Move"
      ++ workspaceShortcuts "Super" "Workspace"
      ++ workspaceShortcuts "Super+Shift" "SendToWorkspace";
  };
}
