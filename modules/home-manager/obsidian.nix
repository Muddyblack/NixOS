# Obsidian — Midnight Marina theme (by Muddyblack)
# https://github.com/Muddyblack/midnight-marina-obsidian
{pkgs, ...}: {
  xdg.configFile."obsidian/themes/Midnight Marina/theme.css" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Muddyblack/midnight-marina-obsidian/master/midnight-marina.css";
      hash = "sha256-b8w82GT7JbV0WuxscmgksTzHsutD/eelLYyQi2mgr/E=";
    };
  };

  xdg.configFile."obsidian/themes/Midnight Marina/manifest.json".text = builtins.toJSON {
    name = "Midnight Marina";
    version = "1.0.0";
    minAppVersion = "1.0.0";
    author = "Muddyblack";
    authorUrl = "https://github.com/Muddyblack/midnight-marina-obsidian";
  };
}
