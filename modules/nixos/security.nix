{
  lib,
  pkgs,
  username,
  ...
}: let
  # Reusable systemd sandbox baseline. Applied to the custom background
  # services below (clamav). Deliberately conservative so it does not break
  # a JIT/bytecode scanner or a DBus notifier; per-service overrides tighten
  # or relax individual keys. Does NOT set ProtectHome (clamav-scan must read
  # $HOME) or MemoryDenyWriteExecute (clamav bytecode / GTK may need W+X).
  hardenBase = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    # Runs as an unprivileged user; no capabilities are needed at all.
    CapabilityBoundingSet = "";
    # AF_UNIX only: NSS lookups, syslog and the user DBus session socket.
    # No AF_INET — these services do not touch the network.
    RestrictAddressFamilies = ["AF_UNIX"];
    SystemCallArchitectures = "native";
    SystemCallFilter = ["@system-service"];
    SystemCallErrorNumber = "EPERM";
    UMask = "0077";
  };
in {
  # AppArmor stays enabled, but we deliberately do NOT pull in the upstream
  # profile bundle (pkgs.apparmor-profiles): those profiles attach by absolute
  # path (/usr/bin/*, /opt/*) and so don't bind to this host's /nix/store
  # binaries — they'd be non-functional clutter that misrepresents the actual
  # confinement. Real desktop-app isolation is done via Flatpak/bubblewrap.
  security.apparmor.enable = true;
  security.rtkit.enable = true;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    # "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  networking.firewall = {
    enable = true;
    logReversePathDrops = true;
  };

  # LLMNR is a legacy fallback name-resolution protocol, spoofable on hostile networks
  services.resolved.settings.Resolve.LLMNR = false;

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Only start SSH if running in a VM
  systemd.services.sshd.unitConfig.ConditionVirtualization = "vm";

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "10m";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
    };
    jails = {
      sshd.settings = {
        enabled = true;
        port = "ssh";
        filter = "sshd";
        maxretry = 4;
        bantime = "1h";
      };
    };
  };

  # No daemon: clamscan loads its own DB; clamd would only waste ~1GB RAM
  services.clamav = {
    updater.enable = true;
    updater.frequency = 12;
  };

  systemd.timers.clamav-scan = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Runs as ${username}: the clamav user cannot read a 0700 home dir,
  # and a parser exploit should never gain more privileges than the user has anyway.
  systemd.services.clamav-scan = {
    description = "ClamAV daily home scan";
    onFailure = ["clamav-alert.service"];
    # ProtectSystem=strict is safe here: clamscan only READS $HOME, never writes.
    serviceConfig =
      hardenBase
      // {
        Type = "oneshot";
        RuntimeMaxSec = "2h";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.clamav}/bin/clamscan"
          "--recursive"
          "--infected"
          "--max-scantime=30000"
          # Nix — immutable, content-addressed
          "--exclude-dir=^\\.nix-profile$"
          # VCS and editor caches
          "--exclude-dir=\\.git$"
          "--exclude-dir=\\.cache$"
          # Package manager caches
          "--exclude-dir=^node_modules$"
          "--exclude-dir=^\\.npm$"
          "--exclude-dir=^\\.cargo$"
          "--exclude-dir=^\\.gradle$"
          "--exclude-dir=^\\.m2$"
          "--exclude-dir=^__pycache__$"
          "--exclude-dir=^\\.venv$"
          # Build outputs
          "--exclude-dir=^target$"
          "--exclude-dir=^dist$"
          "--exclude-dir=^build$"
          "--exclude-dir=^\\.next$"
          # Large binary stores
          "--exclude-dir=^Steam$"
          "--exclude-dir=^containers$"
          "--exclude-dir=^\\.docker$"
          "/home/${username}"
        ];
        User = username;
        Nice = 19;
        IOSchedulingClass = "idle";
      };
  };

  # clamscan exits 1 on findings, 2 on errors — both trigger this alert
  systemd.services.clamav-alert = {
    description = "Desktop notification for ClamAV findings";
    # AF_UNIX in the baseline keeps the user DBus session socket reachable.
    serviceConfig =
      hardenBase
      // {
        Type = "oneshot";
        User = username;
        Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
        ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical 'ClamAV' 'Scan failed or found infected files. Check: journalctl -u clamav-scan'";
      };
  };

  # Nix security settings
  nix.settings.trusted-users = ["root" "@wheel"];

  # Sudo tweaks
  security.sudo.wheelNeedsPassword = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
    Defaults passwd_timeout=1
  '';
}
