{
  lib,
  config,
  ...
}: {
  options.features.stirling-pdf.enable = lib.mkEnableOption "Stirling-PDF (Docker fat image)";

  config = lib.mkIf config.features.stirling-pdf.enable {
    virtualisation.oci-containers.containers.stirling-pdf = {
      image = "stirlingtools/stirling-pdf:latest-fat";
      ports = ["127.0.0.1:8080:8080"];
      volumes = [
        "/var/lib/stirling-pdf/configs:/configs"
        "/var/lib/stirling-pdf/logs:/logs"
        "/var/lib/stirling-pdf/customFiles:/customFiles"
        "/var/lib/stirling-pdf/trainingData:/usr/share/tessdata"
      ];
      environment = {
        DOCKER_ENABLE_SECURITY = "false";
        SECURITY_ENABLELOGIN = "false";
        SECURITY_CSRFDISABLED = "true";
        INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "false";
        LANGS = "de_DE,en_GB";
      };
    };

    systemd.services.podman-stirling-pdf = {
      wantedBy = lib.mkForce [];
      serviceConfig.TimeoutStartSec = lib.mkForce "10min";
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.isInGroup("wheel")) {
          var unit = action.lookup("unit");
          if (unit == "podman-stirling-pdf.service") {
            return polkit.Result.YES;
          }
        }
      });
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/stirling-pdf/configs 0755 root root -"
      "d /var/lib/stirling-pdf/logs 0755 root root -"
      "d /var/lib/stirling-pdf/customFiles 0755 root root -"
      "d /var/lib/stirling-pdf/trainingData 0755 root root -"
    ];
  };
}
