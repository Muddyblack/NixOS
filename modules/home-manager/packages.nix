{pkgs, ...}: {
  home.packages = with pkgs; [
    # Plasma widgets
    ai-usage-widget
    kde-powerchart
    advanced-weather-widget
    kde-nixdatifier

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
