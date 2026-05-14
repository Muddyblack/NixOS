{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    config.hyprland.default = ["hyprland" "gtk"];
  };

  security.pam.services.hyprlock = {};

  environment.systemPackages = with pkgs; [
    hyprpicker
    hyprshot
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
