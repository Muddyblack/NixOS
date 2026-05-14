# Source: https://www.opencode.net/phob1an/sonomatic
{
  stdenvNoCC,
  fetchurl,
  lib,
  customBackground ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sonomatic-sddm";
  version = "3.1";

  src = fetchurl {
    url = "https://www.opencode.net/phob1an/sonomatic/-/archive/master/sonomatic-master.tar.gz";
    sha256 = "sha256-xZhbBwspqgjhrHPa/VAEldvpjpdQKCCjI9JxLNJOPmg=";
  };

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sddm/themes
    cp -r sonomatic-master/sddm/themes/Sonomatic $out/share/sddm/themes/

    substituteInPlace $out/share/sddm/themes/Sonomatic/Main.qml \
      --replace-fail \
        'nameinput.focus = true' \
        'password.forceActiveFocus()'

    ${lib.optionalString (customBackground != null) ''
      cp ${customBackground} $out/share/sddm/themes/Sonomatic/assets/custom-bg.png
      echo '[General]' > $out/share/sddm/themes/Sonomatic/theme.conf
      echo 'background=assets/custom-bg.png' >> $out/share/sddm/themes/Sonomatic/theme.conf
      echo '[General]' > $out/share/sddm/themes/Sonomatic/theme.conf.user
      echo 'background=assets/custom-bg.png' >> $out/share/sddm/themes/Sonomatic/theme.conf.user
      echo 'type=image' >> $out/share/sddm/themes/Sonomatic/theme.conf.user
    ''}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Sonomatic - macOS-style SDDM theme";
    homepage = "https://www.opencode.net/phob1an/sonomatic";
    license = licenses.gpl3;
    platforms = platforms.all;
  };
}
