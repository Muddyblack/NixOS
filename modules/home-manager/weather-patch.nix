{pkgs, ...}: let
  patchScript = pkgs.writeShellScript "patch-weather-location" ''
    lat=$(cat /run/secrets/weather-latitude  2>/dev/null || echo "48.1351")
    lon=$(cat /run/secrets/weather-longitude 2>/dev/null || echo "11.5820")

    city=$(${pkgs.curl}/bin/curl -sf --max-time 5 \
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en" \
      | ${pkgs.jq}/bin/jq -r '
          (.address.town // .address.city // .address.village // .address.municipality)
          + ", " + .address.country' 2>/dev/null \
      || echo "''${lat}, ''${lon}")

    cfg="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    kw=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6

    # Walk the file and pair every weather-widget applet with its parent containment
    ${pkgs.gawk}/bin/awk '
      match($0, /^\[Containments\]\[([0-9]+)\]$/, m)                              { c = m[1]; a = "" }
      match($0, /^\[Containments\]\[([0-9]+)\]\[Applets\]\[([0-9]+)\]$/, m)       { c = m[1]; a = m[2] }
      /^plugin=org\.kde\.plasma\.advanced-weather-widget$/ && a != ""             { print c, a; a = "" }
    ' "$cfg" | while read -r cont app; do
      for kv in "latitude=$lat" "longitude=$lon" "locationName=$city" "autoDetectLocation=false"; do
        key="''${kv%%=*}"; val="''${kv#*=}"
        "$kw" --file "$cfg" \
          --group "Containments" --group "$cont" \
          --group "Applets" --group "$app" \
          --group "Configuration" --group "General" \
          --key "$key" "$val"
      done
    done

    # Also push to the live session if plasmashell is running
    ${pkgs.kdePackages.qttools}/bin/qdbus6 \
      org.kde.plasmashell /PlasmaShell \
      org.kde.PlasmaShell.evaluateScript "
        panels().concat(desktops()).forEach(function(c) {
          c.widgets().forEach(function(w) {
            if (w.type === 'org.kde.plasma.advanced-weather-widget') {
              w.currentConfigGroup = ['General'];
              w.writeConfig('latitude',          '$lat');
              w.writeConfig('longitude',         '$lon');
              w.writeConfig('locationName',      '$city');
              w.writeConfig('autoDetectLocation','false');
              w.reloadConfig();
            }
          });
        });
      " 2>/dev/null || true
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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 6";
      ExecStart = "${patchScript}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
