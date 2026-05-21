#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(grep -oE '"Version":[[:space:]]*"[^"]+"' "$HERE/metadata.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
OUT="$HERE/claude-usage-widget-${VERSION}.plasmoid"

rm -f "$OUT"
(cd "$HERE" && zip -r "$OUT" metadata.json contents -x '*.swp' '*~')
echo "wrote $OUT"
