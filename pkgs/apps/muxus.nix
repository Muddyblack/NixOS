# Source: https://github.com/FloSch62/muxus
{
  lib,
  fetchurl,
  appimageTools,
}: let
  pname = "muxus";
  version = "0.13.0";
  src = fetchurl {
    url = "https://github.com/FloSch62/muxus/releases/download/v${version}/muxus-${version}-linux-x86_64.AppImage";
    hash = "sha256-3FPZss8XspEOXMEAG/R17Uq+FwCgXi8eC0h/8O3kqL4=";
  };
  extracted = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm644 ${extracted}/muxus.desktop $out/share/applications/muxus.desktop
      substituteInPlace $out/share/applications/muxus.desktop --replace-fail "Exec=AppRun" "Exec=muxus"
      cp -r ${extracted}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "SSH, Telnet, serial, RDP and VNC client with network device workbench";
      homepage = "https://github.com/FloSch62/muxus";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "muxus";
    };
  }
