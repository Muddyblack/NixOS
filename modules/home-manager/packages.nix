{pkgs, ...}: {
  home.packages = with pkgs; [
    # Terminal & CLI
    btop
    fastfetch
    duf
    dust
    procs
    sd
    ncdu
    delta
    ssh-to-age
    trash-cli
    tty-clock
    tealdeer
    jq
    yq-go
    just
    tokei
    hyperfine
    grex
    trippy
    typst
    typstyle
    tinymist

    # Nix tools
    nixd
    nix-du
    nix-prefetch-github
    nix-tree
    alejandra
    pre-commit
    nh
    comma
    nix-output-monitor
    nvd
    disko
    deadnix
    sops
    age
  ];
}
