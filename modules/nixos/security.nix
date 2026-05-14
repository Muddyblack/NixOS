{pkgs, ...}: {
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

  services.clamav = {
    daemon.enable = true;
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

  systemd.services.clamav-scan = {
    description = "ClamAV daily home scan";
    after = ["clamav-daemon.service"];
    requires = ["clamav-daemon.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.clamav}/bin/clamscan --recursive --infected --log=/var/log/clamav/scan.log /home";
      User = "clamav";
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
