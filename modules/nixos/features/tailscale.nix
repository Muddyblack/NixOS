{
  lib,
  config,
  ...
}: {
  options.features.tailscale.enable = lib.mkEnableOption "Tailscale mesh VPN";

  config = lib.mkIf config.features.tailscale.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    networking.firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };
  };
}
