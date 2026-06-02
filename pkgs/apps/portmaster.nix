# Source: https://github.com/safing/portmaster
# Portmaster is an application firewall by Safing (https://safing.io).
#
# Because Portmaster downloads its own sub-components at runtime it cannot be
# packaged in the traditional sense.  This derivation packages only the two
# static pieces that never change between runs:
#   • portmaster-start  – the launcher / control binary (statically linked)
#   • installer-assets  – icons and .desktop files
#
# Mutable runtime data (updates/, databases/, config.json …) live in
# /var/lib/portmaster which is managed by the companion NixOS module at
# modules/nixos/features/portmaster.nix.
{
  lib,
  stdenvNoCC,
  fetchurl,
  copyDesktopItems,
  makeDesktopItem,
}: let
  version = "2.1.19"; # portmaster-start binary date: 2025-02-03

  portmaster-start = fetchurl {
    url = "https://updates.safing.io/latest/linux_amd64/start/portmaster-start";
    sha256 = "0n1g4qvb8aqsbb294kzwb9c91dlgs5irish4z4jqssmdkxbqqxy6";
  };

  assets = fetchurl {
    url = "https://updates.safing.io/latest/linux_all/packages/installer-assets.tar.gz";
    sha256 = "00srwhin6ays0xpi75ycv58fppjgim2br1sbi4zkcw109ichs57k";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "portmaster";
    inherit version;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [copyDesktopItems];

    # Portmaster's upstream .desktop file hard-codes /opt/safing/portmaster.
    # We override it to point at /var/lib/portmaster (the mutable state dir).
    # Exec calls `portmaster-fhs` – the buildFHSEnv wrapper installed by the
    # NixOS module – so the Electron-based portmaster-app binary can find its
    # shared libraries (libgobject-2.0 etc.) at standard /usr/lib paths.
    desktopItems = [
      (makeDesktopItem {
        name = "portmaster";
        desktopName = "Portmaster";
        genericName = "Application Firewall";
        comment = "Block mass surveillance. Take back control of your network connections.";
        exec = "portmaster-fhs --data=/var/lib/portmaster app";
        icon = "portmaster";
        terminal = false;
        categories = ["System" "Security" "Network"];
        startupNotify = false;
      })
      (makeDesktopItem {
        name = "portmaster-notifier";
        desktopName = "Portmaster Notifier";
        genericName = "Application Firewall Notifier";
        exec = "portmaster-fhs --data=/var/lib/portmaster notifier";
        icon = "portmaster";
        terminal = false;
        categories = ["System" "Security"];
        noDisplay = true;
      })
    ];

    installPhase = ''
      runHook preInstall

      # ── Binary ────────────────────────────────────────────────────────────
      install -Dm755 ${portmaster-start} $out/bin/portmaster-start

      # ── Assets (icons, service template, etc.) ───────────────────────────
      local assets_dir=$(mktemp -d)
      tar -xzf ${assets} -C "$assets_dir"

      # Icons (all resolutions provided by upstream)
      for res_dir in "$assets_dir"/icons/*/; do
        local res
        res=$(basename "$res_dir")
        install -Dm644 "$res_dir/portmaster.png" \
          "$out/share/icons/hicolor/$res/apps/portmaster.png"
      done

      # Store the raw systemd service as a reference; the NixOS module wires
      # it up properly rather than relying on a static file path.
      install -Dm644 "$assets_dir/portmaster.service" \
        "$out/lib/systemd/system/portmaster.service.upstream"

      runHook postInstall
    '';

    meta = {
      description = "Portmaster – open-source application firewall by Safing";
      longDescription = ''
        Portmaster is a free and open-source application firewall that lets you
        monitor and control all network connections on your device.  It runs as
        a privileged system service and intercepts traffic at the kernel level
        via nfqueue / kmod.

        NOTE: Portmaster downloads its own core/ui modules at first launch into
        /var/lib/portmaster.  An internet connection is required on first boot.
      '';
      homepage = "https://safing.io";
      license = lib.licenses.agpl3Only;
      platforms = ["x86_64-linux"];
      maintainers = [];
      mainProgram = "portmaster-start";
    };
  }
