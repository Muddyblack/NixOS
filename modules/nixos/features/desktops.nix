{lib, ...}: {
  options.features.desktops = {
    hyprland.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hyprland session";
    };
    plasma.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "KDE Plasma 6 session";
    };
    cosmic.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "COSMIC session";
    };
    gnome.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "GNOME session";
    };
  };
}
