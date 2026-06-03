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
    Install.WantedBy = lib.mkForce ["hyprland-session.target"];
  };

  xdg.configFile."autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  home.packages = with pkgs; [
    material-symbols
    nerd-fonts.caskaydia-cove
    libqalculate
    aubio
    lm_sensors
    ddcutil
    app2unit
    swappy
    blueman
  ];
}
