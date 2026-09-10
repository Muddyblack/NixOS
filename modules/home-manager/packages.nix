{pkgs, ...}: {
  home.packages = with pkgs; [
    # Terminal & CLI
    btop
    fastfetch
    dysk
    dust
    procs
    sd
    ncdu
    delta
    ssh-to-age
    trash-cli
    tty-clock
    timg
    tealdeer
    jq
    yq-go
    tokei
    hyperfine
    grex
    trippy
    ouch # universal (de)compressor — backs the extract() function
    doggo # modern dig; aliased over `dig`
    television # fuzzy-finder TUI over pluggable "channels"
    zellij # terminal multiplexer
    typst
    typstyle
    tinymist

    # Nix tools
    nixd
    nix-du
    nix-prefetch-github
    nix-tree
    nix-search-tv
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
    protonvpn-gui
  ];
}
