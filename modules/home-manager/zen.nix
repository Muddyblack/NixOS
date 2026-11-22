{
  inputs,
  pkgs,
  ...
}: let
  zenBase = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default.override {
    waylandSupport = true;
  };

  # Drop any inherited LD_LIBRARY_PATH before Zen's own wrapper adds its libs.
  # The nixpkgs-unstable claude-code wrapper exports an alsa-lib built against
  # glibc 2.44; Zen opened from it (login links, xdg-open) loaded that and died
  # with "GLIBC_2.43 not found ... Couldn't load XPCOM" (seen 2026-11-20/21).
  zen = pkgs.symlinkJoin {
    name = "zen-browser-clean-env";
    paths = [zenBase];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/zen --unset LD_LIBRARY_PATH
    '';
  };

  performancePrefs = ''
    user_pref("gfx.webrender.all", true);
    user_pref("gfx.webrender.enabled", true);
    user_pref("gfx.canvas.accelerated", true);
    user_pref("media.ffmpeg.vaapi.enabled", true);
    user_pref("widget.wayland.opaque-region.enabled", true);
    user_pref("browser.cache.disk.enable", true);
    user_pref("browser.cache.memory.enable", true);
    user_pref("browser.cache.memory.capacity", 524288);
    user_pref("network.http.max-connections", 1800);
    user_pref("network.http.max-persistent-connections-per-server", 10);
    user_pref("content.notify.interval", 100000);
    user_pref("nglayout.initialpaint.delay", 0);
  '';
in {
  home.packages = [zen];

  home.file.".zen/default/user.js".text = performancePrefs;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
  };
}
