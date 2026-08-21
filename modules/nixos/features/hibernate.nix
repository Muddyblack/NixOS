# Hibernate (suspend-to-disk).
#
# Why this module exists: the session menu had a "Hibernate" entry wired to
# `systemctl suspend`, because real hibernation was impossible on this host —
# zram is the only swap device, and the kernel cannot write a hibernation image
# into compressed RAM that disappears when power is cut. Hibernation needs a
# real, on-disk swap area at least as large as the resident set to be saved.
#
# ENABLING THIS IS A TWO-STEP PROCESS, because the resume offset is a physical
# block number that only exists once the swapfile has been written:
#
#   1. Set features.hibernate.enable = true, leave resumeOffset = null,
#      and rebuild. This creates /persist/swap/swapfile and activates it as
#      swap. Hibernation is still refused at this point (the assertion below
#      keeps you from booting a half-configured resume path).
#   2. Read the offset and pin it:
#        sudo btrfs inspect-internal map-swapfile -r /persist/swap/swapfile
#      Put that number in features.hibernate.resumeOffset and rebuild again.
#
# Step 2 has to be repeated if the swapfile is ever recreated (size change,
# filesystem restore) — the offset is not stable across recreation.
#
# The swapfile lives under /persist deliberately: / is a fresh subvolume on
# every boot (features/impermanence.nix), so anything written to /swap would be
# discarded before the resume ever happened.
{
  lib,
  config,
  ...
}: let
  cfg = config.features.hibernate;
  swapfile = "/persist/swap/swapfile";
in {
  options.features.hibernate = {
    enable = lib.mkEnableOption "hibernation via an on-disk btrfs swapfile";

    sizeMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 20480;
      description = ''
        Swapfile size in MiB. Must be >= physical RAM for a reliable
        hibernation image; the default assumes 16 GB with headroom.
      '';
    };

    resumeOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = ''
        Physical offset of the first block of the swapfile, from
        `btrfs inspect-internal map-swapfile -r ${swapfile}`.
        Until this is set, the swapfile is created but hibernation stays off.
      '';
    };

    sessionButtonAction = lib.mkOption {
      type = lib.types.enum ["sleep" "hibernate"];
      default = "sleep";
      description = ''
        What the Caelestia session menu's hibernate-labeled button actually
        runs. Independent of `enable`/`resumeOffset` above, so you can flip
        this back to "sleep" any time even after hibernation is fully wired
        up — e.g. because resume-from-hibernate is slower or you just prefer
        sleep day-to-day.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    swapDevices = [
      {
        device = swapfile;
        size = cfg.sizeMiB;
        # Above zram's default priority (5) so the hibernation image and the
        # resume path both refer to this device rather than compressed RAM.
        priority = 10;
      }
    ];

    systemd.tmpfiles.rules = [
      "d /persist/swap 0700 root root -"
    ];

    # resume= names the *backing block device*; resume_offset locates the
    # swapfile within it. The LUKS mapping is already open in initrd, so the
    # kernel can read the image before any filesystem is mounted.
    boot.resumeDevice = lib.mkIf (cfg.resumeOffset != null) "/dev/mapper/crypted";
    boot.kernelParams =
      lib.optional (cfg.resumeOffset != null)
      "resume_offset=${toString cfg.resumeOffset}";

    assertions = [
      {
        assertion = cfg.resumeOffset != null;
        message = ''
          features.hibernate is enabled but resumeOffset is unset, so the system
          could suspend to disk and then fail to resume. Rebuild once to create
          ${swapfile}, then run:
            sudo btrfs inspect-internal map-swapfile -r ${swapfile}
          and set features.hibernate.resumeOffset to the reported offset.
        '';
      }
    ];
  };
}
