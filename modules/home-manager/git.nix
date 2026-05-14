{pkgs, ...}: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      user.name = "Muddyblack";
      user.email = "70057554+Muddyblack@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      credential.helper = "libsecret";
    };

    # Ignore common junk
    ignores = [
      "*.swp"
      "*.swo"
      ".DS_Store"
      "result"
      ".direnv"
      "node_modules"
    ];
  };

  programs.difftastic.enable = true;
}
