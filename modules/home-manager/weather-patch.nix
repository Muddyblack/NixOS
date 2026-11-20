{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop.widgets;
  qdbus = "${pkgs.kdePackages.qttools}/bin/qdbus";
  kwrite = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
  kread = "${pkgs.kdePackages.kconfig}/bin/kreadconfig6";

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

    notification_enabled=true
    changed=0
    for section in "''${sections[@]}"; do
      section_changed=0
      # Extract the two numeric IDs from e.g. [Containments][30][Applets][36]
      cid=$(echo "$section" | grep -o '\[Containments\]\[[0-9]*\]' | grep -o '[0-9]*')
      aid=$(echo "$section" | grep -o '\[Applets\]\[[0-9]*\]'      | grep -o '[0-9]*')

      for key_val in \
        "autoDetectLocation|false" \
        "latitude|''${lat}" \
        "longitude|''${lon}" \
        "locationName|''${city}" \
        "activeLocation|''${active_loc}" \
        "savedLocations|''${saved_locs}" \
        "alertNotificationsEnabled|''${notification_enabled}" \
        "notificationTodayEnabled|''${notification_enabled}" \
        "notificationTomorrowEnabled|''${notification_enabled}" \
        "notificationRainEnabled|''${notification_enabled}" \
        "notificationSnowEnabled|''${notification_enabled}" \
        "notificationUvEnabled|''${notification_enabled}" \
        "notificationSpaceWeatherEnabled|''${notification_enabled}"
      do
        key="''${key_val%%|*}"
        val="''${key_val##*|}"
        # Skip keys that already hold the value. This service runs whenever
        # appletsrc changes, and rewriting it (plus the reload below) changes
        # it again, which used to retrigger the service until systemd gave up.
        cur=$(${kread} --file "$appletsrc" \
          --group Containments --group "$cid" \
          --group Applets      --group "$aid" \
          --group Configuration --group General \
          --key "$key" 2>/dev/null || true)
        [ "$cur" = "$val" ] && continue
        ${kwrite} --file "$appletsrc" \
          --group Containments --group "$cid" \
          --group Applets      --group "$aid" \
          --group Configuration --group General \
          --key "$key" "$val"
        section_changed=1
        changed=1
      done

      if [ "$section_changed" = 1 ]; then
        echo "weather-patch: wrote config for Containments/$cid/Applets/$aid -> $city"
      fi
      notification_enabled=false
    done

    # Nothing changed: leave appletsrc and the running widgets alone.
    [ "$changed" = 1 ] || exit 0

    # Best-effort live reload, in the foreground: systemd kills whatever a
    # finished oneshot leaves running, so a backgrounded reload never ran.
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
      # The widget only exists in Plasma; skip this in e.g. Hyprland sessions.
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=KDE";
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
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=KDE";
    };
    Path = {
      # Not PathExists: the file always exists, so that retriggered the service
      # the moment it finished. The service itself already runs once at login.
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
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=KDE";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${networkWatchScript}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
