# Paperless-ngx: OCR'd document archive.
#
# Slots between the two services already here — Stirling-PDF manipulates a PDF
# you hand it, Firefly III tracks what a document *cost* — by being the thing
# that keeps the document itself: drop a scan into the consumption directory and
# it comes back OCR'd, full-text searchable, tagged and dated.
#
# Started on demand, like Stirling-PDF and Open WebUI: the four units below idle
# at a few hundred MB between them, which is not something this laptop should
# spend on a service used a few times a month. `paperless` (shell function in
# modules/home-manager/functions.nix) starts the stack and opens the UI;
# `paperless-stop` puts it away again.
{
  lib,
  config,
  username,
  ...
}: {
  options.features.paperless.enable = lib.mkEnableOption "Paperless-ngx document archive";

  config = lib.mkIf config.features.paperless.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = 28981;

      # World-writable consumption dir so documents can be dropped in as the
      # normal user without sudo; everything else stays owned by paperless.
      consumptionDirIsPublic = true;

      settings = {
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_TIME_ZONE = config.time.timeZone;
        PAPERLESS_ADMIN_USER = username;
        PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
        # Skip OCR when the PDF already carries a text layer (most e-invoices),
        # which is the difference between a two-second import and a minute of
        # pegged CPU on a machine with limited thermal headroom.
        PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "with_text";
        PAPERLESS_TASK_WORKERS = 1;
        PAPERLESS_THREADS_PER_WORKER = 2;
      };
    };

    # On-demand: nothing autostarts at boot.
    systemd.services.paperless-web.wantedBy = lib.mkForce [];
    systemd.services.paperless-consumer.wantedBy = lib.mkForce [];
    systemd.services.paperless-scheduler.wantedBy = lib.mkForce [];
    systemd.services.paperless-task-queue.wantedBy = lib.mkForce [];

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.isInGroup("wheel")) {
          var unit = action.lookup("unit");
          if (unit && unit.indexOf("paperless-") === 0) {
            return polkit.Result.YES;
          }
        }
      });
    '';

    # Ownership has to be spelled out: impermanence creates the bind-mount
    # source under /persist itself, and a root-owned /var/lib/paperless leaves
    # the units failing in ExecStartPre on "Permission denied: .../log".
    environment.persistence = lib.mkIf config.features.impermanence.enable {
      "/persist".directories = [
        {
          directory = "/var/lib/paperless";
          user = "paperless";
          group = "paperless";
          mode = "u=rwx,g=rx,o=rx";
        }
      ];
    };
  };
}
