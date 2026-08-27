{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "ghostty";
      paths = [pkgs.ghostty];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm $out/bin/ghostty
        makeWrapper ${pkgs.ghostty}/bin/ghostty $out/bin/ghostty \
          --run '
            case "''${XDG_CURRENT_DESKTOP:-}" in
              *GNOME*|*COSMIC*|*cosmic*)
                set -- --background-opacity=0.85 --background-blur=0 "$@"
                ;;
            esac
          '
      '';
    };

    settings = {
      background = "#1b1e2b";
      foreground = "#a9b1d6";
      cursor-color = "#c0caf5";
      cursor-text = "#1b1e2b";
      selection-background = "#364a82";
      selection-foreground = "#a9b1d6";

      palette = [
        "0=#1b1e2b"
        "1=#f7768e"
        "2=#9ece6a"
        "3=#e0af68"
        "4=#7aa2f7"
        "5=#bb9af7"
        "6=#7dcfff"
        "7=#a9b1d6"
        "8=#414868"
        "9=#f7768e"
        "10=#9ece6a"
        "11=#e0af68"
        "12=#7aa2f7"
        "13=#bb9af7"
        "14=#7dcfff"
        "15=#c0caf5"
      ];

      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;

      window-theme = "dark";
      window-decoration = "server";

      # Default: Milky / Frosted Glass (Plasma & Hyprland)
      background-opacity = 0.5;
      background-blur = 20;

      window-padding-x = 16;
      window-padding-y = 10;
      window-padding-balance = true;

      cursor-style = "bar";
      cursor-style-blink = true;

      adjust-cell-height = "20%";
      shell-integration = "zsh";
    };
  };
}
