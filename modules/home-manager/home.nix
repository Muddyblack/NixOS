{
  pkgs,
  lib,
  inputs,
  username,
  ...
}: {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Profile picture
  home.file.".face".source = ../../assets/profile.png;

  # Stable wallpaper paths — avoids plasma-manager re-running the wallpaper
  # script on every rebuild due to a changing Nix store hash.
  home.file.".local/share/wallpapers/desktop.png".source = ../../assets/wallpapers/desktop.png;
  home.file.".local/share/wallpapers/lockscreen.png".source = ../../assets/wallpapers/lockscreen.png;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = ["org.kde.gwenview.desktop"];
      "image/jpeg" = ["org.kde.gwenview.desktop"];
      "image/gif" = ["org.kde.gwenview.desktop"];
      "image/webp" = ["org.kde.gwenview.desktop"];
      "image/bmp" = ["org.kde.gwenview.desktop"];
      "image/tiff" = ["org.kde.gwenview.desktop"];
      "image/svg+xml" = ["org.kde.gwenview.desktop"];
      # Sandboxed PDF viewer (Flatpak Evince) instead of the browser —
      # untrusted-PDF parsing is contained in bubblewrap. See features/flatpak.nix.
      "application/pdf" = ["org.gnome.Evince.desktop"];
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];
      "text/plain" = ["org.kde.kate.desktop"];
      "text/html" = ["zen.desktop"];
      "x-scheme-handler/http" = ["zen.desktop"];
      "x-scheme-handler/https" = ["zen.desktop"];
      "x-scheme-handler/about" = ["zen.desktop"];
      "x-scheme-handler/unknown" = ["zen.desktop"];
      "application/x-guitar-pro" = ["guitar-pro.desktop"];
      "application/x-gpx" = ["guitar-pro.desktop"];
      "audio/midi" = ["guitar-pro.desktop"];
      "audio/x-midi" = ["guitar-pro.desktop"];
      "x-scheme-handler/termius" = ["termius-app.desktop"];
    };
  };

  # The termius-app.desktop shipped by nixpkgs has neither %U nor a MimeType,
  # so nothing claims the termius:// scheme and the SSO callback
  # (termius://app/continue-sso?...) lands in KIO as "Could not read file".
  # ~/.local/share/applications wins over the profile entry, so this shadows it.
  xdg.desktopEntries."termius-app" = {
    name = "Termius";
    genericName = "Cross-platform SSH client";
    comment = "The SSH client that works on Desktop and Mobile";
    exec = "termius-app %U";
    icon = "termius-app";
    categories = ["Network"];
    mimeType = ["x-scheme-handler/termius"];
  };

  xdg.dataFile."mime/packages/guitar-pro.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-guitar-pro">
        <comment>Guitar Pro file</comment>
        <icon name="guitar-pro"/>
        <glob pattern="*.gpx"/>
        <glob pattern="*.gp5"/>
        <glob pattern="*.gp4"/>
        <glob pattern="*.gp3"/>
        <glob pattern="*.gp"/>
      </mime-type>
    </mime-info>
  '';

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    extraConfig = {
      PROJECTS = "/mnt/projects";
      DATA = "/mnt/data";
    };
  };

  home.file.".local/share/user-places.xbel" = {
    force = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE xbel>
      <xbel xmlns:bookmark="http://www.freedesktop.org/standards/bookmark" xmlns:kdepriv="http://www.kde.org/kdepriv">
        <bookmark href="file:///mnt/projects">
          <title>Projects</title>
          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-development"/>
            </metadata>
          </info>
        </bookmark>
      <bookmark href="file:///etc/nixos">
          <title>NixOS Config</title>
          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="nix-snowflake-white"/>
            </metadata>
          </info>
        </bookmark>
        <bookmark href="file:///mnt/data">
          <title>Data</title>
          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-database"/>
            </metadata>
          </info>
        </bookmark>
        <bookmark href="file:///mnt/data/01%20Hobby/Gitarre/Gitarrenst%C3%BCcke/Selbst%20probieren">
          <title>Gitarre</title>
          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-music"/>
            </metadata>
          </info>
        </bookmark>
      </xbel>
    '';
  };

  home.activation.fixNixosBookmark = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PLACES="$HOME/.local/share/user-places.xbel"

    # Home Manager creates a read-only symlink. We must replace it with a
    # writable file, otherwise KDE will delete/reset the file on reboot.
    if [ -L "$PLACES" ]; then
      temp=$(${pkgs.coreutils}/bin/mktemp)
      ${pkgs.coreutils}/bin/cat "$PLACES" > "$temp"
      ${pkgs.coreutils}/bin/rm "$PLACES"
      ${pkgs.coreutils}/bin/mv "$temp" "$PLACES"
    fi
    ${pkgs.coreutils}/bin/chmod 644 "$PLACES"

    real=$(${pkgs.coreutils}/bin/readlink -f /etc/nixos 2>/dev/null || echo /etc/nixos)
    ${pkgs.gnused}/bin/sed -i "s|file:///etc/nixos|file://$real|g" "$PLACES"
  '';

  imports = [
    ./packages.nix
    ./widgets.nix
    ./theme.nix
    ./shell.nix
    ./cheatsheet.nix
    ./nwg-dock.nix
    ./ai.nix
    ./plasma-settings.nix
    ./hyprland.nix
    ./cosmic.nix
    ./caelestia.nix
    ./vscode.nix
    ./vscode-forks.nix
    ./ghostty.nix
    ./zen.nix
    ./neovim.nix
    ./git.nix
    ./gimp.nix
    ./obsidian.nix
    ./espanso.nix
    ./steam.nix
    ./weather-patch.nix
  ];

  home.sessionVariables = {
    EDITOR = lib.mkForce "${lib.getExe pkgs.neovim}";
    GTK_USE_PORTAL = "1";
    SAL_USE_VCLPLUGIN = "qt6";

    # HiDPI / fractional scaling.
    #
    # QT_AUTO_SCREEN_SCALE_FACTOR used to be set here. It is a Qt5 variable
    # that makes the *toolkit* apply a DPI-derived scale — which, on Wayland,
    # stacks on top of the scale the compositor already applies, so Qt5 apps
    # came out oversized on any non-1x output. Qt6 replaces it with
    # QT_ENABLE_HIGHDPI_SCALING (on by default; set explicitly so it survives
    # a stray override) and takes the scale from the compositor.
    QT_ENABLE_HIGHDPI_SCALING = "1";

    # Electron/Chromium under XWayland renders at 1x and gets bitmap-upscaled
    # by the compositor, which is exactly the blur people blame on fractional
    # scaling. This was already set for the Hyprland session only; the Plasma
    # session runs the same apps (VSCode, Antigravity, Discord, Obsidian), so
    # it belongs at session scope rather than per-compositor.
    NIXOS_OZONE_WL = "1";
  };

  # Per-output scale deliberately lives outside git: it is hardware state, not
  # configuration, and hardcoding an output name here would break the moment a
  # different monitor is plugged in. Set it once per display and KScreen
  # remembers it in ~/.local/share/kscreen (persisted):
  #
  #   kscreen-doctor -o                       # list outputs
  #   kscreen-doctor output.eDP-1.scale.1.25  # apply
  #
  # Under Hyprland the equivalent is `hyprctl monitors`, with the monitor line
  # in hyprland.nix already set to auto-scale.

  # Refresh KDE application cache on rebuild to prevent apps from disappearing from launchers
  #
  # The DBus guard must use :- (or [[ -v ]], as home-manager's own generated
  # activate script does): the activation script runs under `set -eu`, so with
  # no session bus the bare "$DBUS_SESSION_BUS_ADDRESS" aborted on expansion
  # before -n could ever test it — taking every later activation step with it.
  home.activation.refreshKdeAppCache = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
    fi
  '';

  programs.home-manager.enable = true;
}
