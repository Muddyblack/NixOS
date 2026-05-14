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

  programs.firefox = {
    enable = true;
    package = null;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      search.default = "google";
      search.force = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        darkreader
        sponsorblock
        return-youtube-dislikes
      ];

      settings = {
        "browser.startup.homepage" = "about:home";
        "browser.search.region" = "US";
        "browser.search.isUS" = true;
        "distribution.searchplugins.defaultLocale" = "en-US";
        "general.useragent.locale" = "en-US";
        "browser.newtabpage.enabled" = true;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.uitour.enabled" = false;
      };
    };
  };
}
