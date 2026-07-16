{...}: {
  services.atd.enable = true;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

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

  # Steam needs a stable machine-id
  systemd.tmpfiles.rules = [
    "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
  ];
}
