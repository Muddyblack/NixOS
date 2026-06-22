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
    polkit_gnome
  ];

  services.gnome.gnome-keyring.enable = true;
}
