# Source: https://github.com/Muddyblack/kde-ai-usage
{
  lib,
  stdenv,
  ai-usage-widget,
  aiUsageSrc,
  bash,
  cmake,
  coreutils,
  makeDesktopItem,
  ninja,
  python3,
  qt6,
  quickshell,
}: let
  quickshellDesktop = makeDesktopItem {
    name = "org.quickshell";
    desktopName = "Quickshell";
    comment = "QtQuick desktop shell runtime";
    exec = "${quickshell}/bin/qs";
    terminal = false;
    noDisplay = true;
    categories = ["Utility"];
  };
in
  stdenv.mkDerivation {
    pname = "ai-usage-hyprland";
    inherit (ai-usage-widget) version;
    src = aiUsageSrc;

    nativeBuildInputs = [cmake ninja qt6.wrapQtAppsHook];
    buildInputs = [qt6.qtbase qt6.qtwayland];
    cmakeDir = "../hyprland/tray";

    postInstall = ''
      mkdir -p "$out/share/ai-usage-widget"
      cp -r ../hyprland ../package "$out/share/ai-usage-widget/"

      install -Dm644 ${quickshellDesktop}/share/applications/org.quickshell.desktop \
        "$out/share/applications/org.quickshell.desktop"

      cat > "$out/bin/ai-usage-hyprland" <<'EOF'
      #!${bash}/bin/bash
      set -eu
      export PATH=${lib.makeBinPath [bash coreutils python3]}:"$PATH"
      root=${placeholder "out"}/share/ai-usage-widget
      ${placeholder "out"}/bin/ai-usage-tray ${quickshell}/bin/qs \
        "$root/hyprland/shell.qml" "$root/package/contents/tools/sh/get-ai-usage" &
      tray_pid=$!
      trap 'kill "$tray_pid" 2>/dev/null || true' EXIT INT TERM
      ${quickshell}/bin/qs -p "$root/hyprland/shell.qml"
      EOF
      chmod +x "$out/bin/ai-usage-hyprland"
    '';

    meta = {
      description = "Hyprland/Quickshell frontend of the AI usage widget";
      homepage = "https://github.com/Muddyblack/kde-ai-usage";
      mainProgram = "ai-usage-hyprland";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
