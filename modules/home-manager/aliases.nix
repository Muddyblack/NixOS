{...}: {
  programs.zsh.shellAliases = {
    ll = "ls -l";
    nix-check = "nix flake update --dry-run";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    cls = "clear";
    copy = "cp";
    grep = "rg";
    find = "fd";
    ping = "gping";
    curl = "xh";
    lg = "lazygit";
    duf = "duf --theme ansi --hide binds";
    top = "btop";
    du = "dust";
    ps = "procs --tree";
    h = "history 1 -1";
    # atuin owns history search now (Ctrl+R interactive, `hs <term>` one-shot)
    hs = "atuin search";
    hstats = "atuin stats";
    vim = "nvim";
    vi = "nvim";
    clock = "tty-clock -scC 4";
    blender-vm = "LIBGL_ALWAYS_SOFTWARE=1 blender";
    py = "python";
    rebuild = "upnix";
    gen = "nh os list";
    clean = "nh clean all";
    update = "nix flake update";
    secrets = "SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops";
    oc = "opencode";

    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gpl = "git pull";
    gst = "git stash";
    gstp = "git stash pop";
    gb = "git branch";
    gco = "git checkout";
    gd = "git diff";
    gl = "git log --oneline --graph --decorate";

    dig = "doggo";
  };
}
