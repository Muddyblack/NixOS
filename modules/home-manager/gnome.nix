{
  config,
  pkgs,
  ...
}: let
  wallpaper = "file://${config.home.homeDirectory}/.local/share/wallpapers/desktop.png";
in {
  home.packages = [pkgs.gnomeExtensions.blur-my-shell];

  dconf.settings = {
    "org/gnome/shell".enabled-extensions = ["blur-my-shell@aunetx"];

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      pipeline = "pipeline_default";
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
    };

    "org/gnome/desktop/background" = {
      picture-uri = wallpaper;
      picture-uri-dark = wallpaper;
      picture-options = "zoom";
    };

    # mutter owns its own libinput handling independently of
    # services.libinput, same reason Hyprland/Plasma/COSMIC each duplicate
    # touchpad config.
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      tap-to-click = true;
      click-method = "fingers";
      disable-while-typing = true;
    };

    # Static 10 workspaces, matching Hyprland/COSMIC's Super+1..0.
    "org/gnome/mutter".dynamic-workspaces = false;
    "org/gnome/desktop/wm/preferences".num-workspaces = 10;

    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Super>q"];
      toggle-fullscreen = ["<Super>f"];
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];
      switch-to-workspace-6 = ["<Super>6"];
      switch-to-workspace-7 = ["<Super>7"];
      switch-to-workspace-8 = ["<Super>8"];
      switch-to-workspace-9 = ["<Super>9"];
      switch-to-workspace-10 = ["<Super>0"];
      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
      move-to-workspace-5 = ["<Super><Shift>5"];
      move-to-workspace-6 = ["<Super><Shift>6"];
      move-to-workspace-7 = ["<Super><Shift>7"];
      move-to-workspace-8 = ["<Super><Shift>8"];
      move-to-workspace-9 = ["<Super><Shift>9"];
      move-to-workspace-10 = ["<Super><Shift>0"];
    };

    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = ["Print"];
      screenshot = ["<Super><Shift>s"];
      switch-to-application-1 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      switch-to-application-5 = [];
      switch-to-application-6 = [];
      switch-to-application-7 = [];
      switch-to-application-8 = [];
      switch-to-application-9 = [];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      screensaver = ["<Super>l"];
      volume-up = ["XF86AudioRaiseVolume"];
      volume-down = ["XF86AudioLowerVolume"];
      volume-mute = ["XF86AudioMute"];
      mic-mute = ["XF86AudioMicMute"];
      brightness-up = ["XF86MonBrightnessUp"];
      brightness-down = ["XF86MonBrightnessDown"];
      next = ["XF86AudioNext"];
      previous = ["XF86AudioPrev"];
      play = ["XF86AudioPlay" "XF86AudioPause"];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "File Manager";
      command = "dolphin";
      binding = "<Super>e";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Terminal (alt)";
      command = "ghostty";
      binding = "<Ctrl><Alt>t";
    };
  };
}
