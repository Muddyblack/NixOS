# Source: https://www.guitar-pro.com
{
  lib,
  stdenvNoCC,
  copyDesktopItems,
  makeDesktopItem,
  fd,
  writeShellScript,
}: let
  icon = ../../assets/icons/guitar-pro.png;

  launcher = writeShellScript "guitar-pro" ''
    bottle="Guitar Pro 8"
    exe=$(${fd}/bin/fd -I -g "GuitarPro.exe" "$HOME/.local/share/bottles/bottles" 2>/dev/null | head -1)
    if [ -n "$exe" ]; then
      exec bottles-cli run -b "$bottle" -e "$exe" -- "$@"
    fi
    exe=$(${fd}/bin/fd -I -g "GuitarPro.exe" "$HOME/.local/share/Steam/steamapps/compatdata" 2>/dev/null | head -1)
    if [ -n "$exe" ]; then
      exec steam "steam://run/$(basename "$(dirname "$(dirname "$(dirname "$(dirname "$exe")")")")")"
    fi
    echo "Guitar Pro executable not found" >&2
    exit 1
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "guitar-pro";
    version = "8";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "guitar-pro";
        desktopName = "Guitar Pro 8";
        genericName = "Guitar Tablature Editor";
        exec = "guitar-pro %f";
        icon = "guitar-pro";
        categories = ["AudioVideo" "Audio"];
        mimeTypes = [
          "application/x-guitar-pro"
          "application/x-gpx"
          "audio/midi"
          "audio/x-midi"
        ];
        startupWMClass = "guitar-pro";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp ${launcher} $out/bin/guitar-pro
      chmod +x $out/bin/guitar-pro

      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${icon} $out/share/icons/hicolor/256x256/apps/guitar-pro.png

      runHook postInstall
    '';

    meta = {
      description = "Guitar Pro 8 – launcher via Bottles/Steam Wine prefix";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "guitar-pro";
    };
  }
