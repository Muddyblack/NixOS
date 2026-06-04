{
  pkgs,
  lib,
  config,
  ...
}: {
  options.bootloader = lib.mkOption {
    type = lib.types.enum ["grub" "refind" "systemd-boot"];
    # Bare safety-net fallback only (used when no deploy-config.nix exists).
    # The real per-machine value lives in hosts/deploy-config.nix.
    default = "systemd-boot";
    description = "Bootloader to use: grub (BIOS+UEFI), refind (UEFI), or systemd-boot (UEFI).";
  };

  options.plymouthTheme = lib.mkOption {
    type = lib.types.enum ["dotted" "flower" "icy" "matrix"];
    default = "dotted";
    description = "Plymouth boot splash theme.";
  };

  config = let
    useRefind = config.bootloader == "refind";
    useGrub = config.bootloader == "grub";
    useSystemdBoot = config.bootloader == "systemd-boot";
  in {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.initrd.availableKernelModules = ["ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "ahci" "sd_mod" "sr_mod" "i915" "i2c_designware_platform" "i2c_designware_core" "i2c_hid_acpi" "hid_multitouch"];
    boot.kernelModules = ["kvm-intel" "kvm-amd" "elan_i2c" "i2c-hid-acpi"];

    # Always allow touching EFI variables — all UEFI loaders need this.
    boot.loader.timeout = 0;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # rEFInd (UEFI only, opt-in via bootloader = "refind")
    boot.loader.refind = lib.mkIf useRefind {
      enable = true;
      # ESP is 1G and rEFInd copies each generation's kernel+initrd onto it;
      # keep this capped so a kernel bump can't fill the partition mid-install.
      maxGenerations = 8;
      # scanfor manual: show only our themed NixOS entries (keeps the systemd-boot
      # backup from showing up as a duplicate); graphics mode + theme assets follow.
      extraConfig = ''
        timeout 0
        textonly false
        scanfor manual
        screensaver 300
        extra_kernel_version_strings linux-nixos

        hideui singleuser,hints,arrows,badges
        icons_dir /EFI/refind/themes/refind-minimal/icons
        big_icon_size 128
        small_icon_size 48
        banner /EFI/refind/themes/refind-minimal/background.png
        banner_scale fillscreen
        selection_big /EFI/refind/themes/refind-minimal/selection_big.png
        selection_small /EFI/refind/themes/refind-minimal/selection_small.png
        showtools shell,firmware,reboot,shutdown
      '';
    };

    # The installer wipes anything it didn't write and runs before activation, so
    # (re)install the theme and patch refind.conf here: newest generation default,
    # plus a NixOS icon on each entry (otherwise entries fall back to a folder icon).
    system.activationScripts.refind-theme-install = lib.mkIf useRefind (
      lib.stringAfter ["specialfs"] ''
        dest="/boot/EFI/refind/themes/refind-minimal"
        mkdir -p "$dest"
        ${pkgs.rsync}/bin/rsync -a --delete ${pkgs.refind-theme-minimal}/. "$dest/"

        cfg="/boot/EFI/refind/refind.conf"
        if [ -f "$cfg" ]; then
          ${pkgs.gnused}/bin/sed -i 's/^default_selection [0-9]\+$/default_selection 1/' "$cfg"
          if ! grep -q "os_nixos.png" "$cfg"; then
            ${pkgs.gnused}/bin/sed -i \
              '/loader \/efi\/refind\/kernels\//a\  icon /EFI/refind/themes/refind-minimal/icons/os_nixos.png' \
              "$cfg"
          fi
        fi
      ''
    );

    # systemd-boot (UEFI; opt-in via bootloader = "systemd-boot")
    boot.loader.systemd-boot = lib.mkIf useSystemdBoot {
      enable = true;
      configurationLimit = 10;
      consoleMode = "auto";
    };

    # GRUB (opt-in via bootloader = "grub"); disabled for the other loaders
    boot.loader.grub = lib.mkForce (
      if useGrub
      then {
        enable = true;
        efiSupport = true;
        device = "nodev";
        theme = pkgs.whitesur-grub-theme;
        splashImage = null;
      }
      else {
        enable = false;
      }
    );

    # Plymouth: graphical boot splash — MP4 videos converted to frames at build time.
    # Only the small MP4 files live in git; PNG frames are generated during nixos-rebuild.
    #
    # HOW TO ADD A NEW VIDEO THEME:
    #   1. Drop your .mp4 into assets/plymouth/<name>/<name>.mp4
    #   2. Add a mkVideoTheme entry below.
    #   3. Set boot.plymouth.theme to the name and rebuild.
    #
    # Available themes: "dotted", "icy", "flower", "matrix"
    boot.plymouth = let
      mkVideoTheme = name: videoFile:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "plymouth-theme-${name}";
          version = "1.0";
          src = videoFile;
          dontUnpack = true;
          nativeBuildInputs = [pkgs.ffmpeg];
          buildPhase = ''
            mkdir -p frames
            ffmpeg -i ${videoFile} \
              -vf 'fps=8,scale=1920:1080' \
              frames/frame-%d.png \
              -loglevel error
          '';
          installPhase = ''
                      themedir=$out/share/plymouth/themes/${name}
                      mkdir -p "$themedir"

                      find frames -name "frame-*.png" -exec cp {} "$themedir/" \;
                      frame_count=$(find frames -name "frame-*.png" | wc -l)

                      cp ${../../assets/plymouth/plymouth-theme.script} "$themedir/${name}.script"
                      sed -i "s/FRAME_COUNT_PLACEHOLDER/$frame_count/" "$themedir/${name}.script"

                      cat > "$themedir/${name}.plymouth" << PLYDESC
            [Plymouth Theme]
            Name=${name}
            Description=Video boot splash: ${name}
            ModuleName=script

            [script]
            ImageDir=$out/share/plymouth/themes/${name}
            ScriptFile=$out/share/plymouth/themes/${name}/${name}.script
            PLYDESC
          '';
        };
      # All available themes - only the selected one will be built
      availableThemes = {
        dotted = mkVideoTheme "dotted" ../../assets/plymouth/dotted/dotted.mp4;
        flower = mkVideoTheme "flower" ../../assets/plymouth/flower/flower.mp4;
        icy = mkVideoTheme "icy" ../../assets/plymouth/icy/icy.mp4;
        matrix = mkVideoTheme "matrix" ../../assets/plymouth/matrix/matrix.mp4;
      };
      selectedTheme = config.plymouthTheme;
    in {
      enable = true;
      theme = selectedTheme;
      # Only build the selected theme to save build time and disk space
      themePackages = [availableThemes.${selectedTheme}];
    };
    boot.initrd.systemd.enable = true;
    boot.kernelParams = [
      "quiet"
      "splash"
      "loglevel=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=0"
      "udev.log_level=0"
      "acpi.debug_layer=0"
      "acpi.debug_level=0"
      "fbcon=nodefer"
      "vt.global_cursor_default=0"
      "plymouth.ignore-serial-consoles"
      "acpi_backlight=native"
    ];
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;

    hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          FastConnectable = true;
          JustWorksRepairing = "always";
          Privacy = "device";
        };
        Policy = {
          AutoEnable = true;
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,4,8,16,32,64";
        };
        LE = {
          MinConnectionInterval = 7;
          MaxConnectionInterval = 9;
          ConnectionLatency = 0;
          ConnectionSupervisionTimeout = 200;
          Autoconnect = true;
        };
      };
    };

    # udev rules: unblock IdeaPad bluetooth rfkill (boots soft-blocked) + wake BT adapter fast after suspend
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="rfkill", ATTR{type}=="bluetooth", ATTR{soft}="0"
      ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{type}=="1", ATTR{idle_timeout}="0"
      SUBSYSTEM=="powercap", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys/%p/energy_uj"
    '';

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # For Broadwell (2014) and newer
        intel-vaapi-driver # For older CPUs
        libvdpau-va-gl
        intel-compute-runtime # OpenCL (GPU compute)
      ];
    };

    services.thermald.enable = lib.mkDefault true;
    services.fstrim.enable = lib.mkDefault true;
  };
}
