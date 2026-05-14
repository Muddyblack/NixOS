{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"];
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "dolphin";
      "$menu" = "caelestia shell drawers toggle launcher";

      monitor = [",preferred,auto,1"];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # Managed by systemd
        "swww-daemon"
        "swww img ${../../assets/wallpapers/desktop.png} --transition-type simple"
        "nwg-dock-hyprland -d -p bottom -l overlay -a center -i 48"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,kvantum"
        "NIXOS_OZONE_WL,1"
      ];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(1e1e2eaa)";
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;
      };

      decoration = {
        rounding = 14;
        active_opacity = 1.0;
        inactive_opacity = 0.96;

        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 14;
          passes = 4;
          new_optimizations = true;
          xray = false;
          vibrancy = 0.5;
          vibrancy_darkness = 0.0;
          ignore_opacity = true;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
      };

      master.new_status = "master";

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        vfr = true;
        vrr = 0;
      };

      input = {
        kb_layout = "de";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      # gestures = {
      #   workspace_swipe = true;
      # };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
        "$mod SHIFT, E, exec, loginctl terminate-session $XDG_SESSION_ID"
        "$mod, E, exec, $fileManager"
        "$mod, V, togglefloating"
        "$mod, Space, exec, $menu"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, G, togglegroup"
        "$mod SHIFT, G, moveoutofgroup"
        "$mod, Tab, changegroupactive, f"
        "$mod SHIFT, Tab, changegroupactive, b"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, L, global, caelestia:lock"

        "$mod,Left,movefocus,l"
        "$mod,Right,movefocus,r"
        "$mod,Up,movefocus,u"
        "$mod,Down,movefocus,d"
        "$mod SHIFT,Left,movewindow,l"
        "$mod SHIFT,Right,movewindow,r"
        "$mod SHIFT,Up,movewindow,u"
        "$mod SHIFT,Down,movewindow,d"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        ", Print, exec, pkill slurp || true; hyprshot -m region"
        "SHIFT, Print, exec, pkill slurp || true; hyprshot -m window"
        "CTRL, Print, exec, pkill slurp || true; hyprshot -m output"
        "$mod SHIFT, S, exec, pkill slurp || true; hyprshot -m region"
        "$mod, T, exec, $terminal"
        "CTRL ALT, T, exec, $terminal"
        "$mod, H, exec, notify-send 'Keybindings' '<b>Win+T</b>: Terminal\\n<b>Win+Space</b>: Menu\\n<b>Win+Q</b>: Close Window\\n<b>Win+V</b>: Float\\n<b>Win+F</b>: Fullscreen\\n<b>Win+G</b>: Group\\n<b>Win+(-)</b>: Magic/Minimize\\n<b>Win+L</b>: Lock' --icon=dialog-information"
        "$mod, S, exec, caelestia shell drawers toggle sidebar"
        "$mod, I, exec, pkill -f 'ghostty --class=intelligence-center' || ghostty --class=intelligence-center -e antigravity"
        "$mod, C, exec, caelestia shell drawers toggle dashboard"
        "$mod, N, exec, caelestia shell drawers toggle utilities"
        "$mod, M, exec, caelestia shell drawers toggle session"
        "CTRL SHIFT, Escape, exec, caelestia-monitor"

        "$mod, MINUS, togglespecialworkspace, magic"
        "$mod SHIFT, MINUS, movetoworkspacesilent, special:magic"
        "$mod, plus, exec, hyprctl dispatch movetoworkspace $(hyprctl activeworkspace -j | grep -oP '\"id\":\\s*\\K\\d+')"
      ];

      binde = [
        "$mod CTRL, Left, moveactive, -40 0"
        "$mod CTRL, Right, moveactive, 40 0"
        "$mod CTRL, Up, moveactive, 0 -40"
        "$mod CTRL, Down, moveactive, 0 40"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindr = [
        "SUPER, SUPER_L, exec, $menu"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      bindl = [
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-applet)$"
        "float, class:^(nm-connection-editor)$"
        "pin, title:^(Picture-in-Picture)$"
        "float, class:(intelligence-center)"
        "size 35% 95%, class:(intelligence-center)"
        "move 64% 2.5%, class:(intelligence-center)"
        "opacity 0.9, class:(intelligence-center)"
        "animation slide right, class:(intelligence-center)"
      ];

      layerrule = [
        "blur, caelestia"
        "ignorezero, caelestia"
        "blur, notifications"
        "ignorezero, notifications"
        "blur, dashboard"
        "ignorezero, dashboard"
        "blur, launcher"
        "ignorezero, launcher"
        "blur, nwg-dock"
        "ignorezero, nwg-dock"
        "blur, org.quickshell"
        "ignorezero, org.quickshell"
        "blur, sidebar"
        "ignorezero, sidebar"
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Use the shell's own lock screen for idleness
        lock_cmd = "hyprctl dispatch global caelestia:lock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };
      background = [
        {
          monitor = "";
          # Set to screenshot for now to ensure it's not black,
          # but we can try the path again if this works
          path = "screenshot";
          color = "rgba(25, 20, 20, 1.0)";
          blur_passes = 2;
          blur_size = 7;
        }
      ];
      input-field = [
        {
          size = "250, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(cdd6f4)";
          inner_color = "rgb(1e1e2e)";
          outer_color = "rgb(89b4fa)";
          outline_thickness = 3;
          placeholder_text = "<i>Password...</i>";
          shadow_passes = 2;
        }
      ];
      label = [
        # Time
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(cdd6f4ff)";
          font_size = 90;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "";
          text = "cmd[SH] date +'%A, %d %B'";
          color = "rgba(cdd6f4ff)";
          font_size = 24;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        # User
        {
          monitor = "";
          text = "Hi there, $USER";
          color = "rgba(cdd6f4ff)";
          font_size = 20;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -20";
          halign = "center";
          valign = "center";
        }
        # Battery / System Info
        {
          monitor = "";
          text = "cmd[SH] echo \"$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)% | $(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2 || echo 'Ethernet')\"";
          color = "rgba(cdd6f4ff)";
          font_size = 14;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
