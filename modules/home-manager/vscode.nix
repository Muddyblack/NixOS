{pkgs, ...}: {
  programs.vscode = {
    enable = true;

    profiles.default = {
      # Keybindings (keybindings.json)
      keybindings = [
        {
          key = "ctrl+ö";
          command = "workbench.action.terminal.toggleTerminal";
        }
        {
          key = "ctrl+shift+c";
          command = "-workbench.action.terminal.openNativeConsole";
        }
      ];

      # Settings (settings.json)
      userSettings = {
        "keyboard.dispatch" = "keyCode";
        "workbench.colorTheme" = "Midnight Marina";
        "workbench.iconTheme" = "material-icon-theme";
        "editor.fontFamily" = "'Fira Code', monospace";
        "editor.fontSize" = 14;
        "terminal.integrated.fontFamily" = "'MesloLGS NF', monospace";
        "window.menuBarVisibility" = "classic";
        "editor.formatOnSave" = true;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "[nix]" = {
          "editor.defaultFormatter" = "kamadorueda.alejandra";
        };
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.python";
          "editor.formatOnType" = true;
        };
        "git.confirmSync" = false;
        "editor.copySelection" = false;
        "remote.SSH.path" = "/run/current-system/sw/bin/ssh";
        "workbench.editorAssociations" = {
          "*.qrc" = "qt-core.qrcEditor";
        };
      };
    };
  };

  xdg.dataFile."applications/dolphin-open-vscode.desktop".text = ''
    [Desktop Entry]
    Name=Open Current Folder in VS Code
    Comment=Open the current Dolphin folder or terminal directory in VS Code
    Exec=dolphin-open-vscode
    Type=Application
    NoDisplay=true
    Icon=vscode
  '';

  home.packages = [
    (pkgs.writeShellScriptBin "dolphin-open-vscode" ''
      if command -v code >/dev/null 2>&1; then
        CODE_BIN="code"
      elif command -v codium >/dev/null 2>&1; then
        CODE_BIN="codium"
      elif flatpak info com.visualstudio.code >/dev/null 2>&1; then
        CODE_BIN="flatpak run com.visualstudio.code"
      else
        exit 0
      fi

      target_dir=""

      if [ -n "$1" ]; then
        if [ -d "$1" ]; then
          target_dir="$1"
        elif [ -f "$1" ]; then
          target_dir="$(dirname "$1")"
        fi
      fi

      get_terminal_cwd() {
        local term_pid="$1"
        local term_title="$2"
        [ -z "$term_pid" ] && return 1

        local best_cand=""
        local best_time=0

        for cp in $(pgrep -P "$term_pid" 2>/dev/null); do
          local tpgid
          tpgid=$(awk '{print $8}' "/proc/$cp/stat" 2>/dev/null)
          local target_p="''${tpgid:-$cp}"
          local cand=""
          if [ -n "$tpgid" ] && [ -d "/proc/$tpgid/cwd" ]; then
            cand=$(readlink "/proc/$tpgid/cwd" 2>/dev/null)
          fi
          if [ -z "$cand" ] || [ ! -d "$cand" ]; then
            cand=$(readlink "/proc/$cp/cwd" 2>/dev/null)
          fi
          [ -z "$cand" ] || [ ! -d "$cand" ] && continue

          if [ -n "$term_title" ]; then
            local bname="$(basename "$cand" 2>/dev/null)"
            local fg_comm="$(cat "/proc/$target_p/comm" 2>/dev/null)"
            if [ -n "$bname" ] && [[ "$term_title" == *"$bname"* ]]; then
              echo "$cand"
              return 0
            fi
            if [ -n "$fg_comm" ] && [[ "$term_title" == *"$fg_comm"* ]]; then
              echo "$cand"
              return 0
            fi
          fi

          local tty
          tty=$(ps -o tty= -p "$cp" 2>/dev/null | tr -d ' ')
          if [ -n "$tty" ] && [ -e "/dev/$tty" ]; then
            local atime
            atime=$(stat -c "%X" "/dev/$tty" 2>/dev/null || echo 0)
            if [ "$atime" -ge "$best_time" ]; then
              best_time="$atime"
              best_cand="$cand"
            fi
          elif [ -z "$best_cand" ]; then
            best_cand="$cand"
          fi
        done

        if [ -n "$best_cand" ] && [ -d "$best_cand" ]; then
          echo "$best_cand"
          return 0
        fi

        local direct
        direct=$(readlink "/proc/$term_pid/cwd" 2>/dev/null)
        if [ -n "$direct" ] && [ -d "$direct" ] && [ "$direct" != "$HOME" ]; then
          echo "$direct"
          return 0
        fi
        return 1
      }

      get_dolphin_dir() {
        local instance="$1"
        [ -z "$instance" ] && return 1

        local title
        title=$($QDBUS "$instance" /dolphin/Dolphin_1 org.qtproject.Qt.QWidget.windowTitle 2>/dev/null || true)
        for suffix in " — Dolphin" " - Dolphin" " [Administrator]"; do
          title="''${title%"$suffix"}"
        done
        title="''${title/#\~/$HOME}"
        if [ -d "$title" ]; then
          echo "$title"
          return 0
        elif [ -f "$title" ]; then
          dirname "$title"
          return 0
        fi

        if command -v wl-paste >/dev/null 2>&1; then
          local prev_clip
          prev_clip=$(wl-paste 2>/dev/null || true)
          $QDBUS "$instance" /dolphin/Dolphin_1/actions/copy_location trigger 2>/dev/null || true
          sleep 0.05
          local loc
          loc=$(wl-paste 2>/dev/null || true)
          if [ -n "$prev_clip" ]; then
            echo -n "$prev_clip" | wl-copy 2>/dev/null || true
          fi
          loc="''${loc#file://}"
          if [ -d "$loc" ]; then
            echo "$loc"
            return 0
          elif [ -f "$loc" ]; then
            dirname "$loc"
            return 0
          fi
        fi
        return 1
      }

      QDBUS="${pkgs.kdePackages.qttools}/bin/qdbus"

      if [ -z "$target_dir" ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
        active_win=$(hyprctl activewindow -j 2>/dev/null)
        w_class=$(echo "$active_win" | ${pkgs.jq}/bin/jq -r '.class // empty' 2>/dev/null)
        w_title=$(echo "$active_win" | ${pkgs.jq}/bin/jq -r '.title // empty' 2>/dev/null)
        w_pid=$(echo "$active_win" | ${pkgs.jq}/bin/jq -r '.pid // empty' 2>/dev/null)

        case "$w_class" in
          *ghostty*|*Ghostty*|*konsole*|*Konsole*|*kitty*|*Kitty*|*foot*|*alacritty*|*Alacritty*|*wezterm*|*WezTerm*|*terminal*|*Terminal*)
            target_dir=$(get_terminal_cwd "$w_pid" "$w_title")
            ;;
          *dolphin*|*Dolphin*)
            active_instance=""
            for s in $($QDBUS 2>/dev/null | awk '/org.kde.dolphin-/{print $1}'); do
              if [ "$($QDBUS "$s" /dolphin/Dolphin_1 org.qtproject.Qt.QWidget.isActiveWindow 2>/dev/null)" = "true" ]; then
                active_instance="$s"
                break
              fi
            done
            [ -z "$active_instance" ] && active_instance=$($QDBUS 2>/dev/null | awk '/org.kde.dolphin-/{print $1; exit}')
            target_dir=$(get_dolphin_dir "$active_instance")
            ;;
          *)
            if [ -n "$w_pid" ] && pgrep -P "$w_pid" -f "zsh|bash|fish|sh" >/dev/null 2>&1; then
              target_dir=$(get_terminal_cwd "$w_pid" "$w_title")
            fi
            ;;
        esac
      fi

      if [ -z "$target_dir" ]; then
        active_instance=""
        for s in $($QDBUS 2>/dev/null | awk '/org.kde.dolphin-/{print $1}'); do
          if [ "$($QDBUS "$s" /dolphin/Dolphin_1 org.qtproject.Qt.QWidget.isActiveWindow 2>/dev/null)" = "true" ]; then
            active_instance="$s"
            break
          fi
        done
        if [ -n "$active_instance" ]; then
          target_dir=$(get_dolphin_dir "$active_instance")
        fi

        if [ -z "$target_dir" ]; then
          active_konsole=""
          for s in $($QDBUS 2>/dev/null | awk '/org.kde.konsole-/{print $1}'); do
            if [ "$($QDBUS "$s" /konsole/MainWindow_1 org.qtproject.Qt.QWidget.isActiveWindow 2>/dev/null)" = "true" ]; then
              active_konsole="$s"
              break
            fi
          done
          if [ -n "$active_konsole" ]; then
            sess=$($QDBUS "$active_konsole" /Windows/1 org.kde.konsole.Window.activeSession 2>/dev/null)
            if [ -n "$sess" ]; then
              kdir=$($QDBUS "$active_konsole" "/Sessions/$sess" org.kde.konsole.Session.currentDir 2>/dev/null)
              [ -d "$kdir" ] && target_dir="$kdir"
            fi
          fi
        fi

        if [ -z "$target_dir" ]; then
          for tname in ghostty kitty alacritty foot; do
            for tpid in $(pgrep -x "$tname" 2>/dev/null); do
              cdir=$(get_terminal_cwd "$tpid" "")
              if [ -n "$cdir" ] && [ -d "$cdir" ]; then
                target_dir="$cdir"
                break 2
              fi
            done
          done
        fi
      fi

      if [ -z "$target_dir" ]; then
        bg_dolphin=$($QDBUS 2>/dev/null | awk '/org.kde.dolphin-/{print $1; exit}')
        if [ -n "$bg_dolphin" ]; then
          target_dir=$(get_dolphin_dir "$bg_dolphin")
        fi
      fi

      if [ -z "$target_dir" ] && [ -n "$XDG_RUNTIME_DIR" ] && [ -f "$XDG_RUNTIME_DIR/last-terminal-cwd" ]; then
        recorded=$(cat "$XDG_RUNTIME_DIR/last-terminal-cwd" 2>/dev/null)
        [ -d "$recorded" ] && target_dir="$recorded"
      fi

      if [ -z "$target_dir" ] && [ -d "$PWD" ] && [ "$PWD" != "$HOME" ]; then
        target_dir="$PWD"
      fi

      if [ -n "$target_dir" ]; then
        exec $CODE_BIN "$target_dir"
      fi
    '')
    (pkgs.writeShellScriptBin "open-vscode" ''
      exec dolphin-open-vscode "$@"
    '')
  ];
}
