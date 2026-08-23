{lib, ...}: {
  # Electron's utility/node subprocesses inherit --render-node-override and
  # crash (SIGSEGV/SIGTRAP) in the Intel UHD DRI driver under Wayland. The
  # no-fhs build's launcher.sh doesn't read *-flags.conf; the desktop entry
  # override is the only reliable injection point.
  xdg.desktopEntries.antigravity-ide = {
    name = "Google Antigravity IDE";
    comment = "Next-generation agentic IDE";
    icon = "antigravity-ide";
    exec = "antigravity-ide --disable-gpu --ozone-platform-hint=auto %U";
    categories = ["Development" "IDE"];
    startupNotify = true;
    mimeType = ["x-scheme-handler/antigravity"];
    settings.StartupWMClass = "Antigravity IDE";
  };
  home.activation.syncVscodeForkSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    code_user_dir="$HOME/.config/Code/User"
    mkdir -p "$code_user_dir"

    for f in settings.json keybindings.json; do
      src="$code_user_dir/$f"
      real_src=$(readlink -f "$src" 2>/dev/null || echo "$src")

      if [ -f "$real_src" ]; then
        rm -f "$src"
        cp "$real_src" "$src"
        chmod u+w "$src"
      fi

      if [ ! -f "$src" ]; then
        continue
      fi

      for fork_dir in "$HOME/.config/Antigravity/User" "$HOME/.config/Windsurf/User"; do
        mkdir -p "$fork_dir"
        rm -f "$fork_dir/$f"
        cp "$src" "$fork_dir/$f"
        chmod u+w "$fork_dir/$f"
      done
    done
  '';
}
