{pkgs, ...}: {
  home.packages = with pkgs; [
    # Media & Desktop
    freetube

    # Development & API tools
    # bruno

    # Wine/compatibility
    (pkgs.bottles.override {removeWarningPopup = true;})
    pkgs.guitar-pro

    # File sync
    syncthing

    # Monitoring
    vnstat

    # Terminal & CLI (daily use)
    navi
    glow
    htop
    gping
    xh
    tailspin
    lazygit

    # Dev tools
    gh
    gource
    devenv

    # AI coding agents (CLI) — the GUI counterparts live under Editors & IDEs
    aider-chat
    amp-cli
    auggie
    claude-code
    cline
    codex
    crush
    cursor-cli
    droid
    github-copilot-cli
    goose-cli
    google-antigravity-cli
    grok-build
    junie
    kimi-code
    kiro-cli
    mistral-vibe
    muse
    opencode
    openhands-cli
    pi-coding-agent
    qwen-code

    # File management
    czkawka
    metadata-cleaner
    bleachbit
    peazip

    # Communication
    # discord — now installed sandboxed via Flatpak (features/flatpak.nix)
    google-chrome
    thunderbird
    whatsapp
    termius

    # Documents
    libreoffice-qt6
    onlyoffice-desktopeditors
    obsidian
    portfolio
    stirling-pdf-ui
    firefly-iii-app
    paperless-ngx-ui

    # Networking
    motrix
    rustscan
    speedtest-cli
    whois

    # Security
    vulnix

    # Containers
    distrobox
    boxbuddy
    podman-desktop
    podman-compose
    kubectl

    # Backup & monitoring
    luckybackup
    pika-backup
    powertop
    mpv
    playerctl

    # System tools
    lynis
    ttyper
    dos2unix

    # Media players & apps
    vlc
    clock-rs
    termdown
    keepassxc
    veracrypt

    # Audio & music
    # easyeffects
    # calf
    # lsp-plugins
    # zam-plugins
    # deepfilternet
    # rnnoise

    # Media & conversion
    ffmpeg-full
    imagemagick
    upscayl
    gnome-frog
    curtail
    davinci-resolve
    mediainfo

    # Editors & IDEs
    google-antigravity
    kiro
    zed-editor

    # Recording & streaming
    obs-studio
    audacity
    soundconverter

    # Gaming & Simulation
    ckan

    # Photography & RAW
    rawtherapee
    digikam

    # Design & creative
    # krita
    blender
    inkscape
    # lunacy
    eyedropper
    displaycal
    # f3d

    (gimp-with-plugins.override {
      plugins = with gimpPlugins; [
        resynthesizer
        gmic
      ];
    })
  ];
}
