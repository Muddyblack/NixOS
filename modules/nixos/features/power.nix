{
  lib,
  config,
  ...
}: {
  options.features.power.enable = lib.mkEnableOption "power management";

  config = lib.mkIf config.features.power.enable {
    services.power-profiles-daemon.enable = false;

    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    services.upower.enable = true;
  };
}
