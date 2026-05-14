# Source: https://github.com/dfaust/plasma-applet-netspeed-widget
{
  stdenvNoCC,
  fetchFromGitHub,
  jq,
}:
stdenvNoCC.mkDerivation rec {
  pname = "plasma-applet-netspeed-widget";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "dfaust";
    repo = "plasma-applet-netspeed-widget";
    rev = "5f54d7515c8770a7e81f1edd6bab429ff0f5db21";
    hash = "sha256-lP2wenbrghMwrRl13trTidZDz+PllyQXQT3n9n3hzrg=";
  };

  nativeBuildInputs = [ jq ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.kde.netspeedWidget
    cp -r package/* $out/share/plasma/plasmoids/org.kde.netspeedWidget/
    meta=$out/share/plasma/plasmoids/org.kde.netspeedWidget/metadata.json
    jq '.KPackageStructure = "Plasma/Applet" | del(.KPlugin.KPackageStructure)' "$meta" > "$meta.tmp" && mv "$meta.tmp" "$meta"
    runHook postInstall
  '';

  meta = {
    description = "Plasma 6 applet that shows network speed";
    homepage = "https://github.com/dfaust/plasma-applet-netspeed-widget";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
