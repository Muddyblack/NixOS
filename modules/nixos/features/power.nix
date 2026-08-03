{
  lib,
  config,
  ...
}: {
  options.features.power.enable = lib.mkEnableOption "power management";

  config = lib.mkIf config.features.power.enable {
    # power-profiles-daemon over auto-cpufreq: it exposes a Performance /
    # Balanced / Power Saver switch in the Plasma battery applet, and it drives
    # /sys/firmware/acpi/platform_profile -- the EC cooling mode. auto-cpufreq
    # never touched platform_profile, so the EC stayed on the "balanced" fan
    # curve and the package was thermally clamped to ~10W (vs ~19W on
    # "performance"). It also hardcoded governor=performance on AC with no way
    # for the user to opt into a quieter profile.
    #
    # Which profile is selected per power state is declared in
    # modules/home-manager/plasma-settings.nix (programs.plasma.powerdevil).
    services.power-profiles-daemon.enable = true;
    services.auto-cpufreq.enable = false;

    services.upower.enable = true;
  };
}
