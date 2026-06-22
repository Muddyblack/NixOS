{
  lib,
  pkgs,
  config,
  ...
}: let
  # Served on loopback only, matching the localhost:PORT convention used by
  # the other self-hosted services (Stirling 8080, Homepage 8082, …).
  port = 8083;
in {
  options.features.firefly-iii.enable =
    lib.mkEnableOption "Firefly III personal finance manager";

  config = lib.mkIf config.features.firefly-iii.enable {
    services.firefly-iii = {
      enable = true;
      enableNginx = true;
      virtualHost = "localhost";

      settings = {
        # SQLite keeps it a single-user, zero-extra-daemon setup. The DB lives
        # under dataDir (/var/lib/firefly-iii) which impermanence persists.
        DB_CONNECTION = "sqlite";

        APP_ENV = "production";
        APP_URL = "http://localhost:${toString port}";
        TRUSTED_PROXIES = "*";
        TZ = "Europe/Berlin";
        SITE_OWNER = "muddyblack.original@gmail.com";

        # 32-byte app key (encrypts stored secrets); provisioned via sops.
        APP_KEY_FILE = config.sops.secrets.firefly-app-key.path;
      };
    };

    # The firefly module attaches its vhost to "localhost"; pin it to loopback
    # on a dedicated port instead of the default :80.
    services.nginx.virtualHosts.localhost.listen = [
      {
        addr = "127.0.0.1";
        inherit port;
      }
    ];

    # Impermanence bind-mounts dataDir *after* the global systemd-tmpfiles pass,
    # so the storage tree gets created on the ephemeral root and is then hidden
    # by the mount, leaving an empty dir. firefly-iii-setup already orders after
    # the mount, so re-run tmpfiles scoped to dataDir (reusing the module's own
    # rules) right before it. The "+" prefix runs as root, outside the sandbox.
    systemd.services.firefly-iii-setup.serviceConfig.ExecStartPre = [
      "+${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=${config.services.firefly-iii.dataDir}"
    ];
  };
}
