# Source: https://github.com/Muddyblack/kde-gitpulse
{
  lib,
  stdenv,
  gitpulseSrc,
  bash,
  cmake,
  coreutils,
  makeDesktopItem,
  ninja,
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
    pname = "gitpulse-hyprland";
    version = "1.0.0";
    src = gitpulseSrc;

    nativeBuildInputs = [cmake ninja qt6.wrapQtAppsHook];
    buildInputs = [qt6.qtbase qt6.qtsvg];
    cmakeDir = "../hyprland/tray";

    postInstall = ''
      mkdir -p "$out/share/gitpulse"
      cp -r ../hyprland ../package ../shell.qml "$out/share/gitpulse/"

      install -Dm644 ${quickshellDesktop}/share/applications/org.quickshell.desktop \
        "$out/share/applications/org.quickshell.desktop"

      cat > "$out/bin/gitpulse-hyprland" <<'EOF'
      #!${bash}/bin/bash
      set -eu
      export PATH=${lib.makeBinPath [bash coreutils]}:"$PATH"
      root=${placeholder "out"}/share/gitpulse
      desktop_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"
      mkdir -p "$desktop_dir"
      install -m 0644 ${quickshellDesktop}/share/applications/org.quickshell.desktop "$desktop_dir/org.quickshell.desktop"
      ${placeholder "out"}/bin/gitpulse-tray ${quickshell}/bin/qs "$root/shell.qml" &
      tray_pid=$!
      trap 'kill "$tray_pid" 2>/dev/null || true' EXIT INT TERM
      ${quickshell}/bin/qs -p "$root/shell.qml"
      EOF
      chmod +x "$out/bin/gitpulse-hyprland"
    '';

    meta = {
      description = "Hyprland/Quickshell frontend of GitPulse";
      homepage = "https://github.com/Muddyblack/kde-gitpulse";
      mainProgram = "gitpulse-hyprland";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
