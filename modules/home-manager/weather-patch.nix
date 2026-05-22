{pkgs, ...}: let
  qdbus = "${pkgs.kdePackages.qttools}/bin/qdbus";

  patchScript = pkgs.writeShellScript "patch-weather-location" ''
    lat=$(cat /run/secrets/weather-latitude  2>/dev/null || echo "48.1351")
    lon=$(cat /run/secrets/weather-longitude 2>/dev/null || echo "11.5820")

    city=$(${pkgs.curl}/bin/curl -sf --max-time 5 \
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en" \
      | ${pkgs.jq}/bin/jq -r '
          (.address.town // .address.city // .address.village // .address.municipality)
          + ", " + .address.country' 2>/dev/null \
      || echo "''${lat}, ''${lon}")

    script="
      var found = 0;
      panels().concat(desktops()).forEach(function(c) {
        c.widgets().forEach(function(w) {
          if (w.type === 'org.kde.plasma.advanced-weather-widget') {
            w.currentConfigGroup = ['General'];
            w.writeConfig('latitude',          '$lat');
            w.writeConfig('longitude',         '$lon');
            w.writeConfig('locationName',      '$city');
            w.writeConfig('autoDetectLocation','false');
            w.reloadConfig();
            found += 1;
          }
        });
      });
      print(found);
    "

    # Run in background so the service exits instantly (no HM activation timeout).
    # Path unit re-fires on appletsrc changes but uses PathModified with a MakeDirectory
    # guard so kwriteconfig writes don't re-trigger it.
    (
      for i in $(seq 1 120); do
        ${qdbus} org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
        sleep 0.5
      done
      for i in $(seq 1 30); do
        out=$(${qdbus} org.kde.plasmashell /PlasmaShell \
          org.kde.PlasmaShell.evaluateScript "$script" 2>/dev/null || true)
        case "$out" in
          [1-9]*) echo "weather-patch: applied to $out widget(s) -> $city"; exit 0 ;;
        esac
        sleep 2
      done
      echo "weather-patch: widget not found after 60s" >&2
    ) &
    disown
  '';
in {
  systemd.user.services.weather-location-patch = {
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

  # Re-run when the user adds the widget. Use PathExists so it only fires once
  # when the file appears, not on every write (avoids feedback loop).
  systemd.user.paths.weather-location-patch = {
    Unit = {
      Description = "Watch appletsrc and re-apply weather location";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Path = {
      PathExists = "%h/.config/plasma-org.kde.plasma.desktop-appletsrc";
      Unit = "weather-location-patch.service";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
