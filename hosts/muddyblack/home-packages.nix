{pkgs, ...}: {
  imports = [../../modules/home-manager/resolve.nix];

  ai.agents = [
    "claude-code"
    "cline"
    "codex"
    "cursor-cli"
    "github-copilot-cli"
    "google-antigravity-cli"
    "grok-build"
    # "grok-bot"
    "junie"
    "kiro-cli"
    # "mistral-vibe" # vibe-rs test build segfaults rustc
    "opencode"
  ];

  home.packages = with pkgs; [
    # Media & Desktop
    freetube
    localsend
    kdePackages.kdenlive

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
    glab
    gh-dash
    serie
    gource
    devenv

    # File management
    czkawka
    metadata-cleaner
    bleachbit
    peazip
    exiftool

    # Communication
    # discord — now installed sandboxed via Flatpak (features/flatpak.nix)
    google-chrome
    thunderbird
    bulwark-mail
    whatsapp
    termius

    # Documents
    onlyoffice-desktopeditors
    obsidian
    portfolio
    firefly-iii-app
    paperless-ngx-ui
    # stirling-pdf-ui # sunsetting
    craftApps.pdfcraft
    craftApps.photocraft
    craftApps.vectorcraft
    craftApps.filmcraft
    craftApps.lightcraft
    craftApps.effectcraft
    craftApps.wordcraft
    craftApps.deckcraft
    craftApps.gridcraft
    craftApps.soundcraft

    # Networking
    motrix
    rustscan
    speedtest-cli
    whois
    termshark
    bluetui

    # Security
    vulnix
    osv-scanner

    # Containers
    distrobox
    boxbuddy
    podman-desktop
    podman-compose
    podman-tui
    dive
    lazydocker
    kubectl

    # Backup & monitoring
    luckybackup
    pika-backup
    powertop
    mpv
    playerctl

    # System tools
    lynis
    systemctl-tui
    lazyjournal
    ttyper
    dos2unix

    # Media players & apps
    vlc
    clock-rs
    termdown
    keepassxc
    # bitwarden-desktop
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
    curtail
    davinci-resolve
    drwrap
    mediainfo

    # Editors & IDEs
    google-antigravity
    google-antigravity-ide
    zed-editor

    # Recording & streaming
    obs-studio
    audacity
    soundconverter

    # Gaming & Simulation
    ckan
    scrcpy
    android-tools

    # Photography & RAW
    rapidraw

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
