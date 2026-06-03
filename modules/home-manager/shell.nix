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
      export FLAKE_DIR="/etc/nixos"

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

  systemd.user.services.zsh-history-backup = {
    Unit.Description = "Back up zsh history";
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "zsh-history-backup" ''
        set -euo pipefail
        src="$HOME/.zsh_history"
        dir="$HOME/.local/share/zsh-history-backups"
        [ -f "$src" ] || exit 0
        ${pkgs.coreutils}/bin/mkdir -p "$dir"
        ${pkgs.coreutils}/bin/cp "$src" "$dir/zsh_history-$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
        ${pkgs.coreutils}/bin/ls -1t "$dir"/zsh_history-* | ${pkgs.coreutils}/bin/tail -n +31 | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm --
      '');
    };
  };

  systemd.user.timers.zsh-history-backup = {
    Unit.Description = "Hourly zsh history backup";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "24h";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
