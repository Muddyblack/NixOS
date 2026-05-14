#!@SHELL@
set -eu
RUN="${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget"
mkdir -p "$RUN"
exec 9>"$RUN/lock"
@FLOCK@ -n 9 || exit 0
echo "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0" > "$RUN/bars"
@CAVA@ -p @CAVA_CONF@ | while IFS= read -r line; do
  printf '%s' "$line" > "$RUN/bars.tmp" && mv -f "$RUN/bars.tmp" "$RUN/bars"
done
