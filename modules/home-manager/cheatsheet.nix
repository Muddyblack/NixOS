{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "hypr-cheatsheet" ''
      # Colors (ANSI)
      R='\033[0m'        # reset
      B='\033[1m'        # bold
      DIM='\033[2m'      # dim
      C1='\033[38;5;111m' # blue  – mod key color
      C5='\033[38;5;243m' # gray  – separators
      HD='\033[38;5;189m' # header

      key() { printf "''${C1}''${B}%-26s''${R}''${DIM} │ ''${R}%s\n" "''$1" "''$2"; }
      hdr() { printf "\n''${HD}''${B}  %-40s''${R}\n" "''$1"; printf "''${C5}  %s''${R}\n" "────────────────────────────────────────────"; }

      clear
      printf "''${HD}''${B}"
      printf "  ╔══════════════════════════════════════════════╗\n"
      printf "  ║        HYPRLAND  KEYBINDINGS  CHEAT SHEET   ║\n"
      printf "  ║    Super = ❖ Win  │   press Q or Ctrl+C    ║\n"
      printf "  ╚══════════════════════════════════════════════╝\n"
      printf "''${R}"

      hdr "🖥  WINDOWS"
      key "Super + Q"           "Close active window"
      key "Super + V"           "Toggle floating"
      key "Super + F"           "Fullscreen"
      key "Super + Shift + F"   "Maximize (fake fullscreen)"
      key "Super + P"           "Pseudo-tile"
      key "Super + J"           "Toggle split direction"
      key "Super + Ctrl + ←↑↓→" "Move floating window"
      key "Super + Shift + ←↑↓→" "Move window in tiling"
      key "Super + ←↑↓→"        "Move focus"

      hdr "📦  GROUPS / TABS"
      key "Super + G"           "Create / join group"
      key "Super + Shift + G"   "Move window OUT of group"
      key "Super + Tab"         "Next tab in group"
      key "Super + Shift + Tab" "Previous tab in group"

      hdr "🗂  WORKSPACES"
      key "Super + 1–0"         "Switch to workspace 1–10"
      key "Super + Shift + 1–0" "Move window to workspace 1–10"
      key "Super + scroll"      "Switch workspace (mouse wheel)"
      key "3-finger swipe"      "Switch workspace (touchpad)"

      hdr "🫥  HIDE / SPECIAL WORKSPACE"
      key "Super + –"           "Toggle magic workspace (show/hide all)"
      key "Super + Shift + –"   "Hide active window → magic (silent)"
      key "Super + +"           "Unhide window → current workspace"

      hdr "🚀  LAUNCH"
      key "Super + Return / T"  "Terminal (Ghostty)"
      key "Ctrl + Alt + T"      "Terminal (Ghostty)"
      key "Super + Space"       "App launcher (Caelestia)"
      key "Super + E"           "File manager (Dolphin)"
      key "Super + I"           "Antigravity AI assistant"

      hdr "📋  CLIPBOARD"
      key "Super + Shift + V"   "Clipboard history (cliphist)"
      key "Super + Alt + V"     "Wipe clipboard history"

      hdr "🌙  CAELESTIA SHELL"
      key "Super + S"           "Toggle sidebar"
      key "Super + C"           "Toggle dashboard"
      key "Super + N"           "Toggle utilities panel"
      key "Super + M"           "Toggle session drawer"
      key "Super + L"           "Lock screen"

      hdr "📸  SCREENSHOTS"
      key "Print"               "Region screenshot"
      key "Shift + Print"       "Window screenshot"
      key "Ctrl + Print"        "Full output screenshot"
      key "Super + Shift + S"   "Region screenshot"

      hdr "🔊  MEDIA / SYSTEM"
      key "XF86AudioRaise/Lower" "Volume ±5%"
      key "XF86AudioMute"        "Mute audio"
      key "XF86AudioMicMute"     "Mute microphone"
      key "XF86Brightness±"      "Screen brightness ±10%"
      key "XF86Audio Next/Prev"  "Media next / previous"
      key "XF86AudioPlay/Pause"  "Media play / pause"
      key "Ctrl + Shift + Esc"   "System monitor"

      hdr "❓  THIS CHEAT SHEET"
      key "Super + H"           "Toggle cheat sheet (this window)"

      printf "\n''${DIM}  Press Ctrl+C or Q to close''${R}\n\n"

      read -rsn1 _key
      exit 0
    '')
  ];
}
