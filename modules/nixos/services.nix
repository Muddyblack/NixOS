{...}: {
  services.atd.enable = true;

  # dbus-broker over the reference implementation: same API, noticeably lower
  # per-call latency, and it is what systemd upstream targets. Plasma and the
  # portal stack both do a lot of D-Bus traffic at session start.
  services.dbus.implementation = "broker";

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

  services.systembus-notify.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';
  services.udisks2.enable = true;
  services.udisks2.mountOnMedia = true;
  services.gvfs.enable = true;

  environment.etc."udisks2/mount_options.conf".text = ''
    [defaults]
    ntfs_defaults=uid=$UID,gid=$GID
    ntfs_drivers=ntfs-3g
  '';

  # Printing
  services.printing.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Disk health: warns before the drive dies. autodetect covers every
  # SMART-capable device without naming disks that differ per host.
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -W 4,85,95";
  };

  # Network Discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.vnstat.enable = true;

  # PipeWire Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Don't pin apps to the last device they used; otherwise switching the
    # default sink (e.g. to Bluetooth buds) leaves those apps on old outputs.
    wireplumber.extraConfig."51-no-restore-target"."wireplumber.settings" = {
      "node.stream.restore-target" = false;
    };
    # Larger minimum buffer: an app requesting a tiny quantum (32 samples) forces
    # the whole graph onto a ~1ms deadline, which a busy CPU misses -> crackling
    # on Bluetooth. 256 samples = ~5ms is still low latency for desktop use.
    extraConfig.pipewire."51-min-quantum"."context.properties" = {
      "default.clock.min-quantum" = 256;
    };
    # Bluetooth audio quality: best codec each device offers (LDAC/aptX-HD/AAC,
    # SBC-XQ as the floor instead of plain SBC), HFP with wideband codecs, and
    # hardware volume so the headset's own volume stays in sync.
    wireplumber.extraConfig."52-bluez-quality"."monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      "bluez5.codecs" = ["ldac" "aptx_hd" "aptx" "aac" "sbc_xq" "sbc"];
      "bluez5.hfphsp-backend" = "native";
    };
  };

  systemd.mounts = [
    {
      where = "/mnt/data";
      what = "/dev/mapper/crypted";
      type = "btrfs";
      options = "compress=zstd,noatime,subvol=/@data";
      wantedBy = [];
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/data";
      wantedBy = ["multi-user.target"];
    }
  ];

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.udisks2.") === 0 ||
          action.id == "org.freedesktop.systemd1.manage-units") {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  services.logind = {
    settings = {
      Login = {
        KillUserProcesses = true;
        HandleLidSwitch = "suspend";
      };
    };
  };

  systemd.user.extraConfig = "DefaultTimeoutStopSec=5s";
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  # Steam needs a stable machine-id
  systemd.tmpfiles.rules = [
    "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
  ];
}
