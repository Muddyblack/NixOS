{...}: {
  programs.zsh.initContent = ''
    cht() {
      curl -s "cht.sh/$(echo "$@" | tr ' ' '+')"
    }

    mkcd() {
      mkdir -p "$1" && cd "$1"
    }

    dashboard() {
      if ! systemctl is-active --quiet homepage-dashboard; then
        echo "Starting homepage-dashboard..."
        sudo systemctl start homepage-dashboard
      fi
      for i in $(seq 1 10); do
        if command curl -s http://localhost:8082 &>/dev/null; then
          break
        fi
        sleep 1
      done
      xdg-open http://localhost:8082
    }

    extract() {
      if [[ -f "$1" ]]; then
        case "$1" in
          *.tar.bz2)   tar xjf "$1"    ;;
          *.tar.gz)    tar xzf "$1"    ;;
          *.tar.xz)    tar xJf "$1"    ;;
          *.bz2)       bunzip2 "$1"    ;;
          *.rar)       unrar x "$1"    ;;
          *.gz)        gunzip "$1"     ;;
          *.tar)       tar xf "$1"     ;;
          *.tbz2)      tar xjf "$1"    ;;
          *.tgz)       tar xzf "$1"    ;;
          *.zip)       unzip "$1"      ;;
          *.Z)         uncompress "$1" ;;
          *.7z)        7z x "$1"       ;;
          *.zst)       unzstd "$1"     ;;
          *)           echo "Unknown archive format: $1" ;;
        esac
      else
        echo "'$1' is not a valid file"
      fi
    }

    _play_sound() {
      local file="$1"
      if [[ -f "$file" && -s "$file" ]]; then
        if command -v pw-play &>/dev/null; then
          pw-play "$file" &>/dev/null &
        elif command -v paplay &>/dev/null; then
          paplay "$file" &>/dev/null &
        elif command -v aplay &>/dev/null; then
          aplay "$file" &>/dev/null &
        fi
      fi
    }

    upnix() {
      local flake_path="."
      [[ -f "flake.nix" ]] || flake_path="''${FLAKE_DIR:-.}"

      if [[ -f "$flake_path/deploy.sh" ]]; then
        echo "Running deployment script (switch) from $flake_path..."
        # Pass all arguments to deploy.sh
        "$flake_path/deploy.sh" switch "''$@"
      else
        local success_sound="$flake_path/assets/sounds/success.wav"
        local error_sound="$flake_path/assets/sounds/error.wav"

        echo "Building NixOS configuration with nh (fallback: deploy.sh not found)..."
        if NIX_CONFIG="experimental-features = nix-command flakes" nh os switch "$flake_path" "''$@"; then
          echo "Build successful!"
          _play_sound "$success_sound"
        else
          echo "Build failed!"
          _play_sound "$error_sound"
          return 1
        fi
      fi
    }

    upall() {
      local flake_path="."
      [[ -f "flake.nix" ]] || flake_path="''${FLAKE_DIR:-.}"

      echo "Updating flake inputs..."
      (cd "$flake_path" && nix flake update)

      local old_gen
      old_gen=$(readlink -f /nix/var/nix/profiles/system)

      if upnix "''$@"; then
        local new_gen
        new_gen=$(readlink -f /nix/var/nix/profiles/system)

        if [[ "$old_gen" != "$new_gen" ]]; then
          echo "System updated. Diffing generations..."
          nvd diff "$old_gen" "$new_gen"
        else
          echo "No system changes detected."
        fi

        (cd "$flake_path" && git add . && git commit -m "feat: update system $(date '+%Y-%m-%d %H:%M:%S')")
      else
        echo "Update failed, skipping commit."
        return 1
      fi
    }

    rollback() {
      if [[ -z "''${1}" ]]; then
        echo "Usage: rollback <generation-number>"
        echo "       run 'gen' to list available generations"
        return 1
      fi
      local profile="/nix/var/nix/profiles/system-''${1}-link"
      if [[ ! -d "$profile" ]]; then
        echo "Generation ''${1} not found. Run 'gen' to list available generations."
        return 1
      fi
      echo "Rolling back to generation ''${1}..."
      sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "''${1}"
      sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    }

    gcnix() {
      local keep="''${1:-5}"
      echo "Cleaning Nix garbage (keeping $keep generations)..."
      if command -v nh &>/dev/null; then
        nh clean all --keep "$keep"
      else
        echo "nh not found, falling back to nix-collect-garbage..."
        sudo nix-collect-garbage --delete-older-than "''${keep}d"
      fi
    }

    cat() {
      if [[ $# -eq 1 && -f "$1" ]] && [[ "$1" == *.log || "$1" == /var/log/* || "$1" == /run/log/* ]]; then
        tspin "$1"
      else
        command cat "$@"
      fi
    }

    cc-gemini() {
      ANTHROPIC_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai" \
      ANTHROPIC_API_KEY="''${GEMINI_API_KEY:?Set GEMINI_API_KEY}" \
      CLAUDE_MODEL="''${1:-gemini-2.5-pro-preview-05-06}" \
      claude "''${@:2}"
    }

    cc-openrouter() {
      local model="''${1:-google/gemini-2.5-pro}"
      ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1" \
      ANTHROPIC_API_KEY="''${OPENROUTER_API_KEY:?Set OPENROUTER_API_KEY}" \
      CLAUDE_MODEL="$model" \
      claude "''${@:2}"
    }

    cc-ollama() {
      local model="''${1:-gemma4:e4b}"
      if ! systemctl is-active --quiet ollama; then
        echo "Starting Ollama..."
        sudo systemctl start ollama
        sleep 1
      fi
      ANTHROPIC_BASE_URL="http://localhost:11434" \
      ANTHROPIC_API_KEY="ollama" \
      claude --model "$model" "''${@:2}"
    }

    ai-pull() {
      local model="''${1:-gemma4:e4b}"
      if ! systemctl is-active --quiet ollama; then
        echo "Starting Ollama..."
        sudo systemctl start ollama
        sleep 2
      fi
      echo "Pulling $model..."
      if ollama pull "$model"; then
        echo "Done. Run 'cc-ollama' or 'oc' to use it."
      else
        echo "Failed to pull '$model'. Run 'ai-models' to see what's available locally, or check https://ollama.com/library for valid model names."
        return 1
      fi
    }

    ai-models() {
      ollama list
    }

    ai-webui() {
      if ! systemctl is-active --quiet ollama; then
        echo "Starting Ollama..."
        sudo systemctl start ollama
      fi
      if ! systemctl is-active --quiet open-webui; then
        echo "Starting Open WebUI (first start can take a minute)..."
        sudo systemctl start open-webui
      fi
      for i in $(seq 1 60); do
        if command curl -s http://localhost:8765 &>/dev/null; then
          break
        fi
        sleep 1
      done
      xdg-open http://localhost:8765
    }

    ai-webui-stop() {
      sudo systemctl stop open-webui
      echo "Open WebUI stopped."
    }

    cc-models() {
      curl -s https://openrouter.ai/api/v1/models \
        -H "Authorization: Bearer ''${OPENROUTER_API_KEY}" \
        | jq -r '.data[].id' | sort
    }

    _resolve_flake_dir() {
      local candidate
      for candidate in \
        "$FLAKE_DIR" \
        "$PWD" \
        "$HOME/nixos-config" \
        "/mnt/projects/nixos-config" \
        "/etc/nixos"
      do
        [[ -n "$candidate" && -d "$candidate/dev-shells" ]] || continue
        readlink -f "$candidate" 2>/dev/null || echo "$candidate"
        return 0
      done
      return 1
    }

    devnew() {
      if [ -z "$1" ]; then
        echo "Usage: devnew <template>"
        echo "Example: devnew python"
        return 1
      fi
      local _flake_path _src
      _flake_path="$(_resolve_flake_dir)"
      if [[ -z "$_flake_path" ]]; then
        echo "Could not locate a nixos-config with a dev-shells directory."
        return 1
      fi
      _src="''${_flake_path}/dev-shells/$1"
      if [[ ! -d "$_src" ]]; then
        echo "Template not found: $_src"
        return 1
      fi
      cp -rn "$_src"/. .
      command -v direnv &> /dev/null && direnv allow
    }

    _devnew() {
      local _flake_path
      local -a templates
      _flake_path="$(_resolve_flake_dir)" || return 0
      templates=($(find "$_flake_path/dev-shells" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null))
      compadd -a templates
    }
    compdef _devnew devnew

    # Timer and Stopwatch
    alias timer='termdown'
    alias stopwatch='clock-rs -s'
  '';
}
