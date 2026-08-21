{lib, ...}: {
  # Electron's utility/node subprocesses inherit --render-node-override and
  # crash (SIGSEGV/SIGTRAP) in the Intel UHD DRI driver under Wayland. The
  # argv.json "disable-hardware-acceleration" only affects the main window;
  # these flags propagate to every subprocess.
  home.file.".config/antigravity-ide-flags.conf".text = ''
    --disable-gpu
    --ozone-platform-hint=auto
  '';
  home.file.".config/code-flags.conf".text = ''
    --disable-gpu
    --ozone-platform-hint=auto
  '';
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
