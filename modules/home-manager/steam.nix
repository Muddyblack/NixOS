{
  home.file.".local/share/Steam/steam_dev.cfg".text = ''
    @nClientDownloadEnableHTTP2PlatformLinux 0
    @fDownloadRateImprovementToAddAnotherConnection 1.0
  '';

  home.sessionVariables = {
    STEAM_RUNTIME_PREFER_HOST_LIBRARIES = "0";
    STEAM_RUNTIME_HEAVY = "1";
  };
}
