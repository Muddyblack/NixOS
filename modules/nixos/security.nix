{pkgs, ...}: {
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

  # ...and gate fail2ban on the *same* condition. Its only jail is sshd, so on
  # bare metal it sat on a logfile nothing ever writes to — 110 MB resident to
  # guard a port with no listener. This has to be a systemd condition rather
  # than `lib.mkIf config.services.openssh.enable`: that option is true here,
  # and whether this is a VM is only knowable at unit start, not at eval time.
  # If sshd ever gets its own toggle, both lines should read from it.
  systemd.services.fail2ban.unitConfig.ConditionVirtualization = "vm";

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

  # ClamAV is deliberately NOT a service here: no clamd, no scan timer, no
  # freshclam updater — nothing starts on its own. `services.clamav` is left
  # unset entirely, which is what removes the clamav system user and the
  # /etc/clamav/*.conf that the daemons would need.
  #
  # Why: the scheduled home scan kept a core saturated for hours (a single
  # run once went 19h) and cost roughly 10 °C of thermal headroom on this
  # laptop's already-degraded cooler, while the desktop threat model is
  # covered far better by the Flatpak sandboxing in the desktop module.
  # On-demand scanning of a specific download is the actual use case, and
  # that is a GUI action.
  #
  # clamtk keeps its own signature DB in ~/.clamtk/db and updates it only
  # when asked — set "Signature updates: manual" in its preferences, since
  # there is no system freshclam for it to defer to.
  environment.systemPackages = with pkgs; [
    clamav # clamscan/freshclam on $PATH for one-off CLI scans
    clamtk # GTK front-end; scan and DB update are both user-initiated
  ];

  # Nix security settings
  nix.settings.trusted-users = ["root" "@wheel"];

  # Sudo tweaks
  security.sudo.wheelNeedsPassword = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
    Defaults passwd_timeout=1
  '';
}
