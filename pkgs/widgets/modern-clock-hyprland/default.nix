# Quickshell twin of kde-modern-clock for the Hyprland session. Reuses the
# plasmoid's own fonts so the two cannot drift apart.
{
  lib,
  writeShellScriptBin,
  kde-modern-clock,
  quickshell,
  # Caelestia's wallpaper palette instead of the plasmoid's plain white.
  wallpaperColors ? true,
}: let
  fonts = "${kde-modern-clock}/share/plasma/plasmoids/com.github.prayag2.modernclock/contents/fonts";
in
  (writeShellScriptBin "modern-clock-hyprland" ''
    export MODERN_CLOCK_FONTS=${fonts}
    export MODERN_CLOCK_WALLPAPER_COLORS=${
      if wallpaperColors
      then "1"
      else "0"
    }
    exec ${quickshell}/bin/qs -p ${./shell.qml} "$@"
  '')
  .overrideAttrs {
    meta = {
      description = "Modern Clock desktop clock for Hyprland/Quickshell";
      mainProgram = "modern-clock-hyprland";
      platforms = lib.platforms.linux;
    };
  }
