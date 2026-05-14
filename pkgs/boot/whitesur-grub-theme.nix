# Source: https://github.com/vinceliuice/grub2-themes
# Modified: glassmorphism card behind boot menu
{
  stdenvNoCC,
  fetchFromGitHub,
  imagemagick,
  customBackground ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "whitesur-grub-theme";
  version = "2024";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "grub2-themes";
    rev = "80dd04ddf3ba7b284a7b1a5df2b1e95ee2aad606";
    sha256 = "044b4l2l1wj40whkyj5623yki41zc1kys0vc0fzpna7qmnz3x9dl";
  };

  nativeBuildInputs = [imagemagick];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/icons

        # Fonts
        cp common/*.pf2 $out/

        # Icons
        cp -r assets/assets-whitesur/icons-1080p/* $out/icons/

        # Selection indicator
        cp -r assets/assets-select/select-1080p/* $out/

        # Info image
        cp assets/info-1080p.png $out/info.png

        # Background (theme.txt expects background.jpg)
        ${
      if customBackground != null
      then ''
        cp ${customBackground} $out/background.jpg
        BG="$out/background.jpg"
      ''
      else ''
        cp backgrounds/1080p/background-whitesur.jpg $out/background.jpg
        BG="$out/background.jpg"
      ''
    }

        # --- Glassmorphism card ---
        # Card size matches boot_menu region (40% of 1920x1080 = 768x432),
        # with generous padding so it visually wraps the menu.
        CARD_W=640
        CARD_H=400
        RADIUS=24

        # 1. Crop + blur the wallpaper region that sits behind the menu
        #    (menu is centered: left=30% top=30% → x=576 y=324)
        CROP_X=$(( (1920 - CARD_W) / 2 ))
        CROP_Y=$(( (1080 - CARD_H) / 2 + 60 ))

        magick "$BG" \
          -gravity Center \
          -crop ''${CARD_W}x''${CARD_H}+0+0 +repage \
          -blur 0x8 \
          -fill "rgba(10,10,20,0.25)" \
          -draw "rectangle 0,0 ''${CARD_W},''${CARD_H}" \
          \( -size ''${CARD_W}x''${CARD_H} xc:black -fill white -draw "roundrectangle 0,0 $((CARD_W-1)),$((CARD_H-1)) $RADIUS,$RADIUS" \) \
          -alpha off -compose CopyOpacity -composite \
          PNG32:$out/glass_card.png

        # 2. Thin glowing border on top of card (white, 55% opacity, rounded)
        magick -size ''${CARD_W}x''${CARD_H} xc:none \
          -fill none \
          -stroke "rgba(255,255,255,0.45)" \
          -strokewidth 1 \
          -draw "roundrectangle 1,1 $((CARD_W-2)),$((CARD_H-2)) $RADIUS,$RADIUS" \
          PNG32:$out/glass_border.png

        # --- Custom theme.txt with glass card ---
        cat > $out/theme.txt << 'EOF'
    # GRUB2 theme — glassmorphism card
    title-text: ""
    desktop-image: "background.jpg"
    desktop-color: "#000000"
    terminal-font: "Terminus Regular 14"
    terminal-box: "terminal_box_*.png"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    # Boot menu — sits inside the card
    + boot_menu {
      left   = 50%-280
      top    = 50%-90
      width  = 560
      height = 300
      id     = "__menu__"
      item_font             = "Unifont Regular 16"
      item_color            = "#ffffff"
      selected_item_color   = "#ffffff"
      icon_width  = 32
      icon_height = 32
      icon_dir    = "icons"
      item_icon_space = 20
      item_height   = 40
      item_padding  = 10
      item_spacing  = 8
      selected_item_pixmap_style = "select_*.png"
    }

    # Frosted glass card (background blur layer)
    + image {
      left = 50%-320
      top  = 50%-140
      width  = 640
      height = 400
      file = "glass_card.png"
    }

    # Glowing border on top of card
    + image {
      left = 50%-320
      top  = 50%-140
      width  = 640
      height = 400
      file = "glass_border.png"
    }

    # Bottom info bar
    + image {
      top  = 100%-54
      left = 50%-240
      width  = 480
      height = 42
      file = "info.png"
    }

    # Countdown label
    + label {
      top   = 50%+220
      left  = 50%-280
      width = 560
      align = "center"
      id    = "__timeout__"
      text  = "Booting in %d seconds"
      color = "#b0c8e8"
      font  = "Unifont Regular 16"
    }
    EOF

        runHook postInstall
  '';

  meta = {
    description = "WhiteSur GRUB2 theme with glassmorphism card (macOS style)";
    homepage = "https://github.com/vinceliuice/grub2-themes";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
