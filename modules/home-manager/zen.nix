{
  inputs,
  pkgs,
  ...
}: let
  zen = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default.override {
    waylandSupport = true;
  };

  performancePrefs = ''
    user_pref("gfx.webrender.all", true);
    user_pref("gfx.webrender.enabled", true);
    user_pref("gfx.canvas.accelerated", true);
    user_pref("media.hardware-video-decoding.force-enabled", true);
    user_pref("media.ffmpeg.vaapi.enabled", true);
    user_pref("layers.acceleration.force-enabled", true);
    user_pref("gfx.x11-egl.force-enabled", true);
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
