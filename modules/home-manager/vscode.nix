{...}: {
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
      };
    };
  };
}
