{
  lib,
  config,
  username,
  ...
}: {
  options.features.impermanence.enable = lib.mkEnableOption "impermanence";

  config = lib.mkIf config.features.impermanence.enable {
    fileSystems."/".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/home".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;

    # This is a basic setup for impermanence.
    # You can add more files and directories here as needed.
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        # systemd stamps the last-run time of Persistent=true timers here.
        # Without it every persistent timer (btrbk, fstrim, fwupd-refresh)
        # believes it has never run and fires once on every boot.
        "/var/lib/systemd/timers"
        "/etc/NetworkManager/system-connections"
        "/var/lib/upower"
        "/var/lib/sops-nix"
        "/var/lib/sddm"
        "/var/lib/AccountsService"
        "/var/lib/private/ollama"
        "/var/lib/open-webui"
        "/var/lib/firefly-iii"
        "/var/lib/portmaster"
        "/var/lib/docker"
        "/var/lib/containers"
        # Node identity + auth state. Without this the machine drops out of the
        # tailnet and needs a fresh `tailscale up` login after every boot.
        "/var/lib/tailscale"
        # VM definitions, NVRAM and storage pools for libvirtd.
        "/var/lib/libvirt"
        # services.vnstat's traffic database — the whole point of the service is
        # a long-running history, which a wipe on every boot makes impossible.
        "/var/lib/vnstat"
        # Configured printers/queues.
        "/var/lib/cups"
        # Stirling-PDF's settings and per-user data. Under /var/lib/private
        # because the service runs with DynamicUser, so systemd puts the
        # StateDirectory there and symlinks /var/lib/stirling-pdf at it.
        "/var/lib/private/stirling-pdf"
        # Device firmware cache and per-device update history.
        "/var/lib/fwupd"
        # Remembers the profile (performance/balanced/power-saver) per power state.
        "/var/lib/power-profiles-daemon"
        # Ban database — a reboot otherwise clears every active ban.
        "/var/lib/fail2ban"
        # btrbk's transaction log; keeps its view of snapshot lineage consistent.
        "/var/lib/btrbk"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=rx";
        }
      ];
      files = [
        # systemd's local credential key. libvirt's secrets-encryption-key under
        # /var/lib/libvirt is persisted and encrypted against this key, so wiping
        # it on boot leaves a blob nothing can decrypt and libvirtd.service dies
        # at step CREDENTIALS (status=243).
        "/var/lib/systemd/credential.secret"
        "/etc/machine-id"
        "/etc/adjtime"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        {
          file = "/etc/nix/id_rsa";
          parentDirectory = {mode = "u=rwx,g=rx,o=rx";};
        }
      ];
      users.${username} = {
        directories = [
          "Desktop"
          "Downloads"
          "Documents"
          "Pictures"
          ".config"
          ".local/share"
          ".ssh"
          ".gnupg"
          ".cache"
          ".vscode"
          ".docker"
          ".gemini"
          ".pki"
          ".steam"
          ".vmware"
          ".wine"
          ".zen"
          "thunderbird"
          ".claude"
          ".vibe"
          ".codex"
          ".opencode"
        ];
        files = [
          ".bash_history"
          ".zsh_history"
          ".zhistory"
        ];
      };
    };

    environment.etc."nixos".source = "/mnt/projects/nixos-config";

    # Required for impermanence to work correctly with sudo
    security.sudo.extraConfig = "Defaults lecture=never";

    boot.initrd.systemd.services.impermanence-rollback = {
      description = "Roll back btrfs root subvolume";
      wantedBy = ["initrd.target"];
      after = ["cryptsetup.target"];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir /btrfs_tmp
        mount /dev/mapper/crypted /btrfs_tmp
        if [[ -e /btrfs_tmp/@root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@root)" "+%Y-%m-%d_%H:%M:%S")
            mv /btrfs_tmp/@root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/@root
        umount /btrfs_tmp
      '';
    };
  };
}
