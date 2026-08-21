{pkgs, ...}: {
  imports = [
    ./aliases.nix
    ./functions.nix
  ];

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.bat.enable = true;

  programs.cava = {
    enable = true;
    settings = {
      general = {
        framerate = 60;
        bars = 0;
        bar_width = 2;
        bar_spacing = 1;
        sensitivity = 150;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
      };
      input.method = "pipewire";
      output = {
        method = "noncurses";
        channels = "stereo";
        orientation = "bottom";
        show_idle_bar_heads = 1;
      };
      color = {
        background = "'#0d0d0d'";
        foreground = "'#c792ea'";
        gradient = 1;
        gradient_color_1 = "'#ff007c'";
        gradient_color_2 = "'#c792ea'";
        gradient_color_3 = "'#82aaff'";
        gradient_color_4 = "'#7fdbca'";
        gradient_color_5 = "'#addb67'";
        gradient_color_6 = "'#ffcb6b'";
        gradient_color_7 = "'#f78c6c'";
        gradient_color_8 = "'#ff5370'";
      };
      smoothing = {
        noise_reduction = 66;
        monstercat = 1;
        waves = 0;
      };
    };
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
    ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };

  # Force zsh in nix develop shells
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ -n "$IN_NIX_SHELL" && -z "$DIRENV_IN_ENVRC" ]]; then
        exec zsh
      fi
    '';
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Replaces the hand-rolled hourly zsh-history-backup timer: atuin keeps every
  # command in a SQLite database at ~/.local/share/atuin (already covered by the
  # .local/share persistence entry) together with its exit code, duration, cwd
  # and session, and never truncates.
  #
  # --disable-up-arrow is deliberate: Up/Down stay bound to
  # zsh-history-substring-search (see initContent below), so only Ctrl+R changes
  # behaviour. Sync is off — enabling it would mean shipping shell history to a
  # server, which is an explicit decision, not a default. Turn it on with
  # `atuin register` + `atuin sync` if ever wanted.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
      inline_height = 20;
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";
      show_preview = true;
      enter_accept = false;
      # Never record secrets typed on a command line.
      secrets_filter =
        # television's binary is already `tv`; no alias needed for it.
        true;
      history_filter = [
        "^ "
        "^curl .*(api[_-]?key|token|password)"
      ];
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.zsh";
      }
    ];

    initContent = ''
      for candidate in "$HOME/nixos-config" "/mnt/projects/nixos-config" "/etc/nixos"; do
        if [[ -d "$candidate/dev-shells" ]]; then
          export FLAKE_DIR="$candidate"
          break
        fi
      done

      [[ $SHLVL -gt 1 ]] && typeset -gi _ghostty_state=1

      [[ ! -f ${./p10k.zsh} ]] || source ${./p10k.zsh}

      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      setopt CORRECT
      setopt CORRECT_ALL
      export SPROMPT="Correct %F{red}%R%f to %F{green}%r%f? [nyae] "

      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

      # fzf-tab styling
      source ${./fzf-tab.zsh}



      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey "$terminfo[kcuu1]" history-substring-search-up
      bindkey "$terminfo[kcud1]" history-substring-search-down

      chpwd() { eza --icons=auto --group-directories-first; }

      [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
    '';
  };
}
