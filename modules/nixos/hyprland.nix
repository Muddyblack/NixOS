{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config.hyprland.default = ["kde" "hyprland" "gtk"];
  };

  security.pam.services.hyprlock = {};

  environment.systemPackages = with pkgs; [
    hyprpicker
    hyprshot
    satty
    hyprlock
    hypridle
    wl-clipboard
    cliphist
    grim
    slurp
    brightnessctl
    playerctl
    pavucontrol
    libnotify
    networkmanagerapplet
    # Hyprland's own polkit agent, replacing polkit_gnome: Qt/Wayland-native,
    # so authentication dialogs match the rest of the session instead of
    # rendering as an unthemed GTK window. Started from exec-once in
    # modules/home-manager/hyprland.nix.
    hyprpolkitagent
  ];

  services.gnome.gnome-keyring.enable = true;
}
