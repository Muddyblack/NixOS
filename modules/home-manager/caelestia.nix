{
  pkgs,
  lib,
  ...
}: {
  programs.caelestia = {
    enable = true;
    systemd.enable = true;
    cli.enable = true;
    settings = {
      bar.status = {
        showAudio = true;
        showMicrophone = true;
        showBattery = true;
        showNetwork = true;
        showBluetooth = true;
      };
      background = {
        enabled = true;
        wallpaperEnabled = true;
        desktopClock = {
          enabled = true;
          position = "middle-center";
        };
      };
      dashboard = {
        enabled = true;
        showWeather = true;
        showPerformance = true;
        performance = {
          showCpu = true;
          showMemory = true;
          showNetwork = true;
          showBattery = true;
        };
      };
      paths = {
        wallpaperDir = "${../../assets/wallpapers}";
      };
      services = {
        useFahrenheit = false;
        weatherLocation = "";
      };
      session = {
        commands = {
          logout = ["hyprctl" "dispatch" "exit"];
        };
      };
    };
  };

  systemd.user.services.caelestia = {
    Unit = {
      After = lib.mkForce ["hyprland-session.target"];
      PartOf = lib.mkForce ["hyprland-session.target"];
    };
    Service.Environment = [
      "NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
    ];
    Install.WantedBy = lib.mkForce ["hyprland-session.target"];
  };

  home.packages = with pkgs; [
    material-symbols
    nerd-fonts.caskaydia-cove
    libqalculate
    aubio
    lm_sensors
    ddcutil
    app2unit
    swappy
  ];
}
