{pkgs, ...}: {
  home.packages = with pkgs; [
    # Media & Desktop
    freetube
    nwg-dock-hyprland
    swaybg
    awww

    # Development & API tools
    bruno

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
    act
    devenv

    # AI & productivity
    gemini-cli
    opencode
    perplexity
    mistral-vibe

    # File management
    czkawka
    metadata-cleaner
    bleachbit
    peazip

    # Communication
    vesktop
    google-chrome
    thunderbird
    whatsapp
    gmaps
    termius

    # Documents
    libreoffice-qt6
    onlyoffice-desktopeditors
    qpdf
    obsidian
    portfolio
    stirling-pdf-ui

    # Networking
    motrix
    rustscan
    speedtest-cli
    whois

    # Security
    bitwarden-desktop
    vulnix
    photopea
    recraft

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
    easyeffects
    calf
    lsp-plugins
    zam-plugins
    deepfilternet
    rnnoise

    # Media & conversion
    ffmpeg-full
    imagemagick
    upscayl
    gnome-frog
    curtail
    davinci-resolve
    mediainfo

    # Editors & IDEs
    kiro
    antigravity
    zed-editor
    claude-code
    codex

    # Recording & streaming
    obs-studio
    audacity
    soundconverter

    # Gaming & Simulation
    ckan

    # Photography & RAW
    rawtherapee
    digikam
    rapid-photo-downloader

    # Design & creative
    krita
    blender
    inkscape
    lunacy
    eyedropper
    displaycal
    f3d

    (gimp-with-plugins.override {
      plugins = with gimpPlugins; [
        resynthesizer
        gmic
      ];
    })
  ];
}
