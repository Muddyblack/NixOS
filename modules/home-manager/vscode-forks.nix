{...}: {
  home.activation.syncVscodeForkSettings = {
    after = ["writeBoundary"];
    before = [];
    data = ''
      for f in settings.json keybindings.json; do
        src="$HOME/.config/Code/User/$f"
        real_src=$(readlink -f "$src" 2>/dev/null || echo "$src")
        if [ -f "$real_src" ]; then
          rm -f "$src"
          cp "$real_src" "$src"
          chmod u+w "$src"
        fi

        for fork_dir in "$HOME/.config/Antigravity/User" "$HOME/.config/Windsurf/User"; do
          mkdir -p "$fork_dir"
          if [ -f "$real_src" ]; then
            rm -f "$fork_dir/$f"
            cp "$real_src" "$fork_dir/$f"
            chmod u+w "$fork_dir/$f"
          fi
        done
      done
    '';
  };
}
