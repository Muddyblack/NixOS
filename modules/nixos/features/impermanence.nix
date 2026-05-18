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
        "/etc/NetworkManager/system-connections"
        "/var/lib/upower"
        "/var/lib/sops-nix"
        "/var/lib/sddm"
        "/var/lib/AccountsService"
        "/var/lib/private/ollama"
        "/var/lib/open-webui"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=rx";
        }
      ];
      files = [
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
          ".antigravity"
          ".antigravity-server"
          ".docker"
          ".gemini"
          ".local/share/keyrings"
          ".local/share/Steam"
          ".pki"
          ".oh-my-zsh"
          ".steam"
          ".vmware"
          ".wine"
          ".zen"
          ".mozilla"
          "Thunderbird"
          ".claude"
          ".claude-code-router"
          ".codex"
          ".opencode"
          ".windsurf"
        ];
        files = [
          ".bash_history"
          ".zsh_history"
          ".zhistory"
        ];
      };
    };

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
