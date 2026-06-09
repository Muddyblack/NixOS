{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop.widgets;
  qdbus = "${pkgs.kdePackages.qttools}/bin/qdbus";
  kwrite = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";

  patchScript = pkgs.writeShellScript "patch-weather-location" ''
    set -uo pipefail

    lat=$(cat /run/secrets/weather-latitude  2>/dev/null || echo "48.1351")
    lon=$(cat /run/secrets/weather-longitude 2>/dev/null || echo "11.5820")

    city=$(${pkgs.curl}/bin/curl -sf --max-time 5 \
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en" \
      | ${pkgs.jq}/bin/jq -r '
          (.address.town // .address.city // .address.village // .address.municipality)
          + ", " + .address.country' 2>/dev/null \
      || echo "''${lat}, ''${lon}")

    active_loc=$(${pkgs.jq}/bin/jq -cn \
      --arg  name "''${city}" \
      --argjson lat  "''${lat}" \
      --argjson lon  "''${lon}" \
      '{name:$name,lat:$lat,lon:$lon,altitude:0,timezone:"",countryCode:""}')

    saved_locs=$(${pkgs.jq}/bin/jq -cn \
      --arg  name "''${city}" \
      --argjson lat  "''${lat}" \
      --argjson lon  "''${lon}" \
      '[{name:$name,lat:$lat,lon:$lon,altitude:0,timezone:"",countryCode:"",starred:true}]')

    appletsrc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

    # Plasma Manager can delete and recreate appletsrc during a layout rebuild.
    # Wait briefly for the weather widget stanza to exist before giving up.
    for _ in $(seq 1 60); do
      if [ -f "$appletsrc" ] && ${pkgs.gnugrep}/bin/grep -q 'plugin=org\.kde\.plasma\.advanced-weather-widget' "$appletsrc" 2>/dev/null; then
        break
      fi
      sleep 1
    done

    # Find every weather widget section header in appletsrc, e.g.
    #   [Containments][30][Applets][36]
    mapfile -t sections < <(
      ${pkgs.gawk}/bin/awk '
        /^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/ { hdr=$0 }
        /plugin=org\.kde\.plasma\.advanced-weather-widget/  { print hdr }
      ' "$appletsrc" 2>/dev/null
    )

    if [[ ''${#sections[@]} -eq 0 ]]; then
      echo "weather-patch: no weather widgets found in appletsrc" >&2
      exit 1
    fi

    for section in "''${sections[@]}"; do
      # Extract the two numeric IDs from e.g. [Containments][30][Applets][36]
      cid=$(echo "$section" | grep -o '\[Containments\]\[[0-9]*\]' | grep -o '[0-9]*')
      aid=$(echo "$section" | grep -o '\[Applets\]\[[0-9]*\]'      | grep -o '[0-9]*')

      for key_val in \
        "autoDetectLocation|false" \
        "latitude|''${lat}" \
        "longitude|''${lon}" \
        "locationName|''${city}" \
        "activeLocation|''${active_loc}" \
        "savedLocations|''${saved_locs}"
      do
        key="''${key_val%%|*}"
        val="''${key_val##*|}"
        ${kwrite} --file "$appletsrc" \
          --group Containments --group "$cid" \
          --group Applets      --group "$aid" \
          --group Configuration --group General \
          --key "$key" "$val"
      done

      echo "weather-patch: wrote config for Containments/$cid/Applets/$aid -> $city"
    done

    # Best-effort live reload — run in background so the service exits quickly.
    # Writing is already done above via kwriteconfig6, so if the reload fails
    # the config will be picked up on next plasmashell restart.
    (
      for i in $(seq 1 120); do
        ${qdbus} org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
        sleep 0.5
      done
      ${qdbus} org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript '
          panels().concat(desktops()).forEach(function(c) {
            c.widgets().forEach(function(w) {
              if (w.type && w.type.indexOf("advanced-weather-widget") !== -1)
                w.reloadConfig();
            });
          });
          print("reloaded");
        ' 2>/dev/null && echo "weather-patch: reloaded widgets" || true
    ) &
    disown
  '';
  networkWatchScript = pkgs.writeShellScript "weather-network-watch" ''
    # Already online — main service handles it
    ${pkgs.curl}/bin/curl -sf --max-time 3 https://nominatim.openstreetmap.org/ -o /dev/null 2>/dev/null && exit 0
    # Poll until internet arrives (max 10 min) then re-run the patch
    for i in $(seq 1 120); do
      sleep 5
      if ${pkgs.curl}/bin/curl -sf --max-time 5 https://nominatim.openstreetmap.org/ -o /dev/null 2>/dev/null; then
        systemctl --user start weather-location-patch.service
        exit 0
      fi
    done
  '';
in {
  systemd.user.services.weather-location-patch = lib.mkIf cfg.weather.enable {
    Unit = {
      Description = "Set weather widget location from SOPS secrets";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${patchScript}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  systemd.user.paths.weather-location-patch = lib.mkIf cfg.weather.enable {
    Unit = {
      Description = "Watch appletsrc and re-apply weather location";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Path = {
      PathExists = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      PathModified = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      PathChanged = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      Unit = "weather-location-patch.service";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  systemd.user.services.weather-location-network-watch = lib.mkIf cfg.weather.enable {
    Unit = {
      Description = "Re-apply weather location once internet is reachable";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${networkWatchScript}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
