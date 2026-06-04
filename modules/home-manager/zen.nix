{
  inputs,
  pkgs,
  ...
}: let
  zen = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default.override {
    waylandSupport = true;
  };

  policies = builtins.toJSON {
    policies = {
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisableAppUpdate = false;
      NoDefaultBookmarks = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      UserMessaging = {
        WhatsNew = false;
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        SkipOnboarding = true;
      };
    };
  };
in {
  home.packages = [zen];

  home.file.".mozilla/zen/distribution/policies.json".text = policies;
}
