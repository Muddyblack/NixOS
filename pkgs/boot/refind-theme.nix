# Source: https://github.com/evanpurkhiser/rEFInd-minimal (modified)
{
  stdenvNoCC,
  fetchFromGitHub,
  imagemagick,
  dejavu_fonts,
  makeFontsConf,
  customBackground ? null,
}:
stdenvNoCC.mkDerivation {
  pname = "refind-theme-minimal-custom";
  version = "2026-03-02";

  src = fetchFromGitHub {
    owner = "evanpurkhiser";
    repo = "rEFInd-minimal";
    rev = "2c7a4aa67707a669e5a38e8bd4456c09a5477f38";
    sha256 = "sha256-8FxOFSI54H5SnxoDNllofc8bJ0TiOnjbtQp/GWNQf6w=";
  };

  nativeBuildInputs = [imagemagick];

  # Provide fonts so ImageMagick can render text icons in the Nix sandbox
  FONTCONFIG_FILE = makeFontsConf {fontDirectories = [dejavu_fonts];};

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r ./* $out/

    ${
      if customBackground != null
      then ''cp ${customBackground} $out/background.png''
      else ""
    }

    # Generate selection highlight boxes.
    # rEFInd does NOT support true alpha transparency — use solid colors only.
    # A dark rounded rectangle with a bright border works well on dark backgrounds.
    if command -v magick >/dev/null; then
      IMG_CMD="magick"
    else
      IMG_CMD="convert"
    fi

    $IMG_CMD -size 144x144 xc:"#00000000" \
      -fill "#1a1a2e" \
      -stroke "#a0c4ff" \
      -strokewidth 2 \
      -draw "roundrectangle 2,2,141,141,10,10" \
      -alpha off \
      PNG32:$out/selection_big.png
    $IMG_CMD -size 64x64 xc:"#00000000" \
      -fill "#1a1a2e" \
      -stroke "#a0c4ff" \
      -strokewidth 2 \
      -draw "roundrectangle 2,2,61,61,8,8" \
      -alpha off \
      PNG32:$out/selection_small.png

    # Invert icons to white so they're visible on dark backgrounds
    for icon in $out/icons/*.png; do
      $IMG_CMD "$icon" -channel RGB -negate "$icon"
    done

    # Generate missing tool icons — white-on-transparent so rEFInd doesn't
    # fall back to the yellow striped placeholder.

    # tool_shell: ">_" terminal prompt
    $IMG_CMD -size 48x48 xc:none \
      -fill white -font DejaVu-Sans-Bold -pointsize 22 \
      -gravity Center -annotate 0 ">_" \
      PNG32:$out/icons/tool_shell.png

    # tool_firmware & func_firmware: drawn gear shape (no unicode needed)
    # tool_firmware is for the shell tool, func_firmware is for "Reboot to Computer Setup"
    $IMG_CMD -size 48x48 xc:none \
      -fill white \
      -draw "circle 24,24 24,10" \
      -fill none -stroke none \
      -fill black -draw "circle 24,24 24,17" \
      -fill white \
      -draw "rectangle 20,2 28,8" \
      -draw "rectangle 20,40 28,46" \
      -draw "rectangle 2,20 8,28" \
      -draw "rectangle 40,20 46,28" \
      -draw "rectangle 7,7 13,13" \
      -draw "rectangle 35,7 41,13" \
      -draw "rectangle 7,35 13,41" \
      -draw "rectangle 35,35 41,41" \
      PNG32:$out/icons/tool_firmware.png

    # Copy for firmware/BIOS setup utility
    cp $out/icons/tool_firmware.png $out/icons/func_firmware.png

    # func_about: "i" info icon — circle with dot and stem
    $IMG_CMD -size 48x48 xc:none \
      -fill white -stroke none \
      -draw "circle 24,24 24,2" \
      -fill black \
      -draw "circle 24,24 24,4" \
      -fill white \
      -draw "circle 24,13 24,10" \
      -draw "rectangle 21,19 27,36" \
      -draw "rectangle 18,33 30,37" \
      PNG32:$out/icons/func_about.png

    # NixOS boot entry icon — use our custom nix_icon.png
    # big_icon_size is 128 in refind.conf, so render at 128x128
    $IMG_CMD ${../../assets/nix_icon.png} \
      -resize 128x128 \
      -background none \
      -gravity Center \
      -extent 128x128 \
      PNG32:$out/icons/os_nixos.png

    runHook postInstall
  '';

  meta = {
    description = "Custom rEFInd minimal theme";
    homepage = "https://github.com/evanpurkhiser/rEFInd-minimal";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
