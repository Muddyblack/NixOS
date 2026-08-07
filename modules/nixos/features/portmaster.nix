# Portmaster NixOS feature module
# https://safing.io / https://github.com/safing/portmaster
#
# Enables Portmaster as a proper NixOS service.  Key design decisions:
#
#  • The binary lives in the Nix store (pkgs.portmaster).
#  • Mutable data (updates/, databases/, config.json) live in
#    /var/lib/portmaster and persists across reboots.
#  • A symlink /opt/safing/portmaster → /var/lib/portmaster is created so
#    Portmaster's self-update logic (which hard-codes that path) still works.
#  • The systemd core service calls portmaster-start directly (no bubblewrap)
#    because RestrictNamespaces/NoNewPrivileges would block bwrap.  The core
#    is a native Go binary that does not need FHS compatibility.
#  • A buildFHSEnv wrapper (portmaster-fhs) is provided for user-facing
#    invocations (shell alias, .desktop) so the Electron-based portmaster-app
#    binary – downloaded at runtime – can find libgobject-2.0 etc.
#  • iptables/ip6tables are added to the service PATH so Portmaster's nfqueue
#    interception module can call them at startup.
#  • networking.firewall is NOT disabled here; Portmaster manages its own
#    netfilter rules via kmod and coexists fine with nixos firewall.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features.portmaster;
  dataDir = "/var/lib/portmaster";
  # Compatibility symlink expected by Portmaster's hard-coded paths
  compatLink = "/opt/safing/portmaster";

  # Libraries for the Electron-based portmaster-app binary downloaded at runtime.
  # We cannot patchelf a pre-built upstream artifact, so we expose these via an
  # FHS-compatible environment.  Not used by the systemd service — bubblewrap is
  # blocked there by RestrictNamespaces + NoNewPrivileges.
  fhsLibs = p:
    with p; [
      # GLib / GObject (libgobject-2.0, libglib-2.0, libgio-2.0)
      glib
      # GTK3 – used by Electron's tray/notification code
      gtk3
      # NSS / NSPR – TLS in Chromium/Electron
      nss
      nspr
      # ATK accessibility
      atk
      at-spi2-atk
      at-spi2-core
      # CUPS (Electron print support)
      cups
      # Mesa / DRM / GBM / GL / EGL
      libdrm
      mesa
      libgbm
      libGL
      libglvnd
      # Pango / Cairo / text rendering
      pango
      cairo
      # Xorg
      libX11
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libxscrnsaver
      libXtst
      libxcb
      libxshmfence
      # Wayland
      wayland
      libxkbcommon
      # Audio
      alsa-lib
      # D-Bus / udev
      dbus
      udev
      # Fonts / encoding
      expat
      fontconfig
      freetype
      # libuuid
      util-linux
    ];

  # FHS wrapper for user-facing launches (shell alias, .desktop).
  # portmaster-start passes "--data /path" but Electron wants "--data=/path",
  # so app launches go through this shim.
  portmasterFHSLauncher = pkgs.writeShellScript "portmaster-fhs-launcher" ''
    set -euo pipefail

    data_dir="''${PORTMASTER_DATA:-${dataDir}}"
    passthrough=()
    command=""

    consume_data_flag() {
      case "$1" in
        --data)
          if [ "$#" -lt 2 ]; then
            echo "portmaster-fhs: --data requires a path" >&2
            exit 2
          fi
          data_dir="$2"
          return 2
          ;;
        --data=*)
          data_dir="''${1#--data=}"
          return 1
          ;;
      esac
      return 0
    }

    while [ "$#" -gt 0 ]; do
      consume_data_flag "$@" || consumed="$?"
      if [ "''${consumed:-0}" != 0 ]; then
        shift "$consumed"
        consumed=0
        continue
      fi

      case "$1" in
        app|clean-structure|core|hub|notifier|purge|recover-iptables|show|update|verify|version)
          command="$1"
          shift
          break
          ;;
        *)
          passthrough+=("$1")
          shift
          ;;
      esac
    done

    command_args=()
    while [ "$#" -gt 0 ]; do
      consume_data_flag "$@" || consumed="$?"
      if [ "''${consumed:-0}" != 0 ]; then
        shift "$consumed"
        consumed=0
        continue
      fi
      command_args+=("$1")
      shift
    done

    start_bin="$data_dir/portmaster-start"
    if [ ! -f "$start_bin" ]; then
      start_bin="${pkgs.portmaster}/bin/portmaster-start"
    fi

    if [ -z "$command" ]; then
      exec "$start_bin" --data "$data_dir" "''${passthrough[@]}" "''${command_args[@]}"
    fi

    if [ "$command" != app ]; then
      exec "$start_bin" --data "$data_dir" "''${passthrough[@]}" "$command" "''${command_args[@]}"
    fi

    if ! ${pkgs.systemd}/bin/systemctl --quiet is-active portmaster.service; then
      ${pkgs.systemd}/bin/systemctl start portmaster.service >/dev/null 2>&1 || true
    fi

    app_bin="$(
      ${pkgs.findutils}/bin/find "$data_dir/updates/linux_amd64/app" \
        -mindepth 2 -maxdepth 2 -type f -executable -name 'portmaster-app_v*' 2>/dev/null \
        | ${pkgs.coreutils}/bin/sort -V \
        | ${pkgs.coreutils}/bin/tail -n 1
    )"

    if [ -z "$app_bin" ]; then
      "$start_bin" --data "$data_dir" update
      app_bin="$(
        ${pkgs.findutils}/bin/find "$data_dir/updates/linux_amd64/app" \
          -mindepth 2 -maxdepth 2 -type f -executable -name 'portmaster-app_v*' 2>/dev/null \
          | ${pkgs.coreutils}/bin/sort -V \
          | ${pkgs.coreutils}/bin/tail -n 1
      )"
    fi

    if [ -z "$app_bin" ]; then
      echo "portmaster-fhs: Portmaster app binary was not found in $data_dir/updates" >&2
      exit 1
    fi

    electron_flags=(--no-sandbox)

    # Clean up stale Chromium lock to prevent startup failures
    rm -f "''${XDG_CONFIG_HOME:-$HOME/.config}/Portmaster/SingletonLock"

    exec "$app_bin" "--data=$data_dir" "''${electron_flags[@]}" "''${command_args[@]}"
  '';

  portmasterFHS = pkgs.buildFHSEnv {
    name = "portmaster-fhs";
    targetPkgs = fhsLibs;
    runScript = portmasterFHSLauncher;
  };
in {
  options.features.portmaster = {
    enable = lib.mkEnableOption "Portmaster application firewall by Safing";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to open ports 717/tcp and 717/udp used by Portmaster's DNS
        resolver for local SPN connections.  Usually not needed for personal
        workstations.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Packages ────────────────────────────────────────────────────────────
    environment.systemPackages = [
      pkgs.portmaster
      portmasterFHS
    ];

    # Convenience wrapper: `portmaster` → FHS-wrapped portmaster-start with
    # the data dir pre-set.  Works for `portmaster app`, `portmaster core`, …
    # The FHS env is fine in user sessions where bubblewrap can create namespaces.
    environment.shellAliases = {
      portmaster = "${portmasterFHS}/bin/portmaster-fhs --data ${dataDir}";
    };

    # ── Kernel modules required by Portmaster's packet interception ─────────
    boot.kernelModules = [
      "nf_conntrack"
      "nfnetlink_queue"
      "nfnetlink_log"
      "xt_mark"
    ];

    # ── Mutable state directory and compat symlink ──────────────────────────
    systemd.tmpfiles.rules = [
      # The desktop app/notifier run as the logged-in user, while the core runs
      # as root. Keep sensitive subdirectories under Portmaster's own control,
      # but let user-facing components traverse updates and write UI state/logs.
      "d  ${dataDir}               0755 root root - -"
      "d  ${dataDir}/updates       0755 root root - -"
      "d  ${dataDir}/exec          1777 root root - -"
      "d  ${dataDir}/logs          1777 root root - -"
      "d  ${dataDir}/logs/app      1777 root root - -"
      "d  ${dataDir}/logs/notifier 1777 root root - -"
      "d  ${dataDir}/logs/start    1777 root root - -"
      # Compatibility symlink so Portmaster's hard-coded /opt/safing/portmaster
      # still resolves correctly (e.g. for self-updates and module downloads).
      "d  /opt/safing        0755 root root - -"
      "L+ ${compatLink}      -    -    -    - ${dataDir}"
    ];

    # ── systemd service ──────────────────────────────────────────────────────
    systemd.services.portmaster = {
      description = "Portmaster by Safing";
      documentation = [
        "https://safing.io"
        "https://docs.safing.io"
      ];

      # Must start before the network is considered up so it can intercept
      # connections from boot.
      before = [
        "nss-lookup.target"
        "network.target"
        "shutdown.target"
      ];
      after = ["systemd-networkd.service"];
      wants = ["nss-lookup.target"];
      conflicts = [
        "shutdown.target"
        "firewalld.service"
      ];
      wantedBy = ["multi-user.target"];

      # Portmaster's nfqueue/interception module calls iptables/ip6tables at
      # runtime.  `path` merges with NixOS's default service PATH.
      path = [
        pkgs.iptables
        pkgs.iproute2
        pkgs.kmod
      ];

      environment = {
        LOGLEVEL = "info";
        PORTMASTER_ARGS = "";
      };

      preStart = ''
        if [ ! -f ${dataDir}/portmaster-start ]; then
          cp ${pkgs.portmaster}/bin/portmaster-start ${dataDir}/portmaster-start
          chmod 755 ${dataDir}/portmaster-start
        fi
      '';

      # If the core crash-loops, stop retrying after a few attempts rather than
      # flapping the nfqueue rules (which would cut connectivity on every
      # down-cycle).  ExecStopPost still runs the iptables recovery, so giving
      # up leaves the network in a clean, fully-routable state.
      startLimitIntervalSec = 120;
      startLimitBurst = 3;

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
        PIDFile = "${dataDir}/core-lock.pid";

        # Portmaster's core ignores SIGTERM on shutdown, so systemd waits the
        # full default timeout (90s) before SIGKILL. Kill it fast instead —
        # ExecStopPost still recovers iptables, so the network stays clean.
        TimeoutStopSec = 10;
        SendSIGKILL = true;

        # Use the mutable launcher, ensuring it can self-update properly without
        # "Unsupported Launcher" warnings in the UI.
        ExecStart = "${dataDir}/portmaster-start --data ${dataDir} core";
        ExecStopPost = [
          "-${dataDir}/portmaster-start --data ${dataDir} recover-iptables"
          "-${pkgs.systemd}/bin/systemctl reload firewall"
        ];

        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = "read-only";
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = "AF_UNIX AF_NETLINK AF_INET AF_INET6";
        RestrictNamespaces = true;
        LimitMEMLOCK = "infinity";

        AmbientCapabilities = lib.concatStringsSep " " [
          "CAP_CHOWN"
          "CAP_KILL"
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_BROADCAST"
          "CAP_NET_RAW"
          "CAP_SYS_MODULE"
          "CAP_SYS_PTRACE"
          "CAP_DAC_OVERRIDE"
          "CAP_FOWNER"
          "CAP_FSETID"
        ];
        CapabilityBoundingSet = lib.concatStringsSep " " [
          "CAP_CHOWN"
          "CAP_KILL"
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_BROADCAST"
          "CAP_NET_RAW"
          "CAP_SYS_MODULE"
          "CAP_SYS_PTRACE"
          "CAP_DAC_OVERRIDE"
          "CAP_FOWNER"
          "CAP_FSETID"
        ];
      };
    };

    # ── Optional firewall openings ───────────────────────────────────────────
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [717];
      allowedUDPPorts = [717];
    };

    # ── Captive portal workaround ────────────────────────────────────────────
    # Portmaster routes all DNS through its own resolver (DNS-over-TLS), which
    # is unreachable from behind an unauthenticated captive portal — the login
    # page's hostname never resolves, so the portal looks "blocked".  Known
    # upstream limitation (safing/portmaster#1765) with no settings-level fix;
    # the only reliable remedy is stopping Portmaster until the portal is
    # passed.  NetworkManager can automate that: Portmaster exempts a fixed set
    # of connectivity-check domains from its resolver and sends them as plain
    # DNS to the network-assigned one (netenv.ConnectivityDomains).  That list
    # includes nmcheck.gnome.org — the URI configured in hosts/common.nix — so
    # NM's portal detection keeps working even while Portmaster is running.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "portmaster-captive-portal" ''
          set -euo pipefail

          # Set by NetworkManager for connectivity-change events only.
          # Values: UNKNOWN, NONE, PORTAL, LIMITED, FULL.
          [ -n "''${CONNECTIVITY_STATE:-}" ] || exit 0

          # Records that *we* paused Portmaster, so one stopped by hand is never
          # silently resurrected.  /run is cleared on reboot, which is the right
          # lifetime for a pause.
          marker=/run/portmaster-captive-portal.paused

          systemctl=${pkgs.systemd}/bin/systemctl

          case "$CONNECTIVITY_STATE" in
            PORTAL)
              # --no-block: dispatcher scripts are killed if they run too long,
              # and stopping Portmaster costs up to TimeoutStopSec plus the
              # iptables recovery in ExecStopPost.  Queue it and return.
              if "$systemctl" is-active --quiet portmaster.service; then
                touch "$marker"
                "$systemctl" stop --no-block portmaster.service
              fi
              ;;
            FULL)
              # Resume only what we paused.  NM re-emits FULL on every periodic
              # re-check, and the unit's StartLimitBurst counts manual starts
              # too — starting unconditionally would eventually wedge the unit
              # in a failed state, leaving the firewall silently off.
              if [ -e "$marker" ]; then
                rm -f "$marker"
                "$systemctl" reset-failed portmaster.service || true
                "$systemctl" start --no-block portmaster.service
              fi
              ;;
          esac
        '';
      }
    ];
  };
}
