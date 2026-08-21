# Stirling-PDF: local PDF manipulation toolbox.
#
# Native nixpkgs service, not the upstream container: services.stirling-pdf
# runs the same 2.14.3 release straight from the store, with its helper tools
# (libreoffice, ocrmypdf, qpdf, ghostscript, tesseract…) supplied as a systemd
# `path` instead of baked into a 2 GB "fat" image. That removes the podman
# dependency, the image pull, and the hand-rolled volume directories.
#
# On demand, like Paperless-ngx and Open WebUI — nothing autostarts at boot.
# The launcher entry (pkgs/apps/stirling-pdf.nix) starts the unit and shows its
# journal while it comes up.
{
  lib,
  config,
  ...
}: {
  options.features.stirling-pdf.enable = lib.mkEnableOption "Stirling-PDF";

  config = lib.mkIf config.features.stirling-pdf.enable {
    services.stirling-pdf = {
      enable = true;
      environment = {
        # Spring relaxed binding: server.address / server.port. Keeps the
        # listener on loopback, matching what the container's port mapping did.
        SERVER_ADDRESS = "127.0.0.1";
        SERVER_PORT = 8080;
        SECURITY_ENABLELOGIN = false;
        SECURITY_CSRFDISABLED = true;
        LANGS = "de_DE,en_GB";
      };
    };

    # On demand: nothing autostarts at boot.
    systemd.services.stirling-pdf = {
      wantedBy = lib.mkForce [];
      # LibreOffice and the OCR pipeline make the first start slow.
      serviceConfig.TimeoutStartSec = lib.mkForce "5min";
    };

    # Clean up the pre-native layout. The podman version kept its volumes in a
    # real /var/lib/stirling-pdf; the native service runs with DynamicUser, so
    # systemd needs that path to be a symlink into /var/lib/private and aborts
    # with 238/STATE_DIRECTORY ("File exists") while the old directory sits
    # there. rmdir only ever removes empty directories, so a tree that somehow
    # still holds data is left alone and the failure stays visible.
    system.activationScripts.stirling-pdf-legacy-statedir = ''
      if [ -d /var/lib/stirling-pdf ] && [ ! -L /var/lib/stirling-pdf ]; then
        rmdir /var/lib/stirling-pdf/configs \
              /var/lib/stirling-pdf/customFiles \
              /var/lib/stirling-pdf/logs \
              /var/lib/stirling-pdf/trainingData \
              /var/lib/stirling-pdf 2>/dev/null || true
      fi
      rmdir /persist/var/lib/stirling-pdf 2>/dev/null || true
    '';

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.isInGroup("wheel")) {
          var unit = action.lookup("unit");
          if (unit == "stirling-pdf.service") {
            return polkit.Result.YES;
          }
        }
      });
    '';
  };
}
