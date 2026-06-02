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
      "application/pdf" = ["zen.desktop"];
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];
      "text/html" = ["zen.desktop"];
      "x-scheme-handler/http" = ["zen.desktop"];
      "x-scheme-handler/https" = ["zen.desktop"];
      "x-scheme-handler/about" = ["zen.desktop"];
      "x-scheme-handler/unknown" = ["zen.desktop"];
      "application/x-guitar-pro" = ["guitar-pro.desktop"];
      "application/x-gpx" = ["guitar-pro.desktop"];
      "audio/midi" = ["guitar-pro.desktop"];
      "audio/x-midi" = ["guitar-pro.desktop"];
    };
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
    extraConfig = {
      XDG_PROJECTS_DIR = "/mnt/projects";
      XDG_DATA_DIR = "/mnt/data";
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

  # Styling for nwg-dock-hyprland to match the translucent KDE look
  home.file.".config/nwg-dock-hyprland/style.css".text = ''
    window {
      background-color: rgba(26, 27, 38, 0.55);
      border-radius: 16px;
      border: 1px solid rgba(137, 180, 250, 0.4);
      box-shadow: 0px 8px 15px rgba(0, 0, 0, 0.6);
      margin-bottom: 8px;
    }
    #box {
      padding: 5px;
      margin: 2px;
      border-radius: 10px;
    }
    button {
      background: transparent;
      border: none;
      border-radius: 10px;
      padding: 4px;
      margin: 0 5px;
      transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    }
    button:hover {
      background-color: rgba(203, 166, 247, 0.2);
    }
  '';

  home.packages = with pkgs; [
    (writeShellScriptBin "caelestia-monitor" ''
      if [[ "''${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] && command -v plasma-systemmonitor &>/dev/null; then
          exec plasma-systemmonitor
      else
          exec ghostty -e btop
      fi
    '')
  ];

  xdg.dataFile."applications/caelestia-monitor.desktop".text = ''
    [Desktop Entry]
    Name=System Monitor
    Exec=caelestia-monitor
    Type=Application
    NoDisplay=true
  '';

  imports = [
    ./packages.nix
    ./widgets.nix
    ./theme.nix
    ./shell.nix
    ./ai.nix
    ./plasma-settings.nix
    ./hyprland.nix
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
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    SAL_USE_VCLPLUGIN = "qt6";
  };

  # Refresh KDE application cache on rebuild to prevent apps from disappearing from launchers
  home.activation.refreshKdeAppCache = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
      $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental || true
    fi
  '';

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
        cfg=/home/${username}/.config
        cache=/home/${username}/.cache/plasmashell
        pm=/home/${username}/.local/share/plasma-manager
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

  programs.home-manager.enable = true;
}
