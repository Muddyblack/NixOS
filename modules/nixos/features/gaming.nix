{
  pkgs,
  lib,
  config,
  ...
}: {
  options.features.gaming.enable = lib.mkEnableOption "gaming";

  config = lib.mkIf config.features.gaming.enable {
    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraPackages = with pkgs; [
        mangohud
        protontricks
        steamtinkerlaunch
      ];
    };

    environment.systemPackages = with pkgs; [
      mangohud
      gperftools
    ];

    boot.kernel.sysctl = {
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_fastopen" = 3;
    };
  };
}
