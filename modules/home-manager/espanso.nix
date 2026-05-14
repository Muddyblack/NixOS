{
  pkgs,
  lib,
  ...
}: {
  services.espanso = {
    enable = true;
    package = pkgs.espanso-wayland;
    configs.default = {
      show_notifications = false;
      editor = "${lib.getExe pkgs.neovim}";
    };
    matches = {
      base = {
        matches = [
          # Date / time
          {
            trigger = ":date";
            replace = "{{date}}";
          }
          {
            trigger = ":time";
            replace = "{{time}}";
          }
          {
            trigger = ":datetime";
            replace = "{{datetime}}";
          }

          # Symbols
          {
            trigger = ":arrow";
            replace = "→";
          }
          {
            trigger = ":darrow";
            replace = "⇒";
          }
          {
            trigger = ":check";
            replace = "✓";
          }
          {
            trigger = ":cross";
            replace = "✗";
          }
          {
            trigger = ":shrug";
            replace = "¯\\_(ツ)_/¯";
          }

          # Common snippets
          # :mail reads an email from a SOPS-managed secret at runtime.
          # Falls back to empty string if features.sops is disabled or the
          # secret is missing — safe for forks without an age key.
          # See README "Secrets (SOPS)" for setup.
          {
            trigger = ":mail";
            replace = "{{email}}";
            vars = [
              {
                name = "email";
                type = "shell";
                params.cmd = "cat /run/secrets/espanso-email 2>/dev/null || true";
              }
            ];
          }

          # Typo corrections
          {
            trigger = "teh";
            replace = "the";
            propagate_case = true;
            word = true;
          }
          {
            trigger = "adn";
            replace = "and";
            propagate_case = true;
            word = true;
          }
          {
            trigger = "taht";
            replace = "that";
            propagate_case = true;
            word = true;
          }
          {
            trigger = "wiht";
            replace = "with";
            propagate_case = true;
            word = true;
          }
        ];

        global_vars = [
          {
            name = "date";
            type = "date";
            params = {format = "%Y-%m-%d";};
          }
          {
            name = "time";
            type = "date";
            params = {format = "%H:%M";};
          }
          {
            name = "datetime";
            type = "date";
            params = {format = "%Y-%m-%d %H:%M";};
          }
        ];
      };
    };
  };
}
