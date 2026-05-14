# GIMP — PhotoGIMP Configuration
# Transforms GIMP 3.0 to look and behave like Adobe Photoshop:
#   - Photoshop keyboard shortcuts (Ctrl+T, Ctrl+Shift+N, etc.)
#   - Single-window mode with Photoshop-style panel layout
#   - Dark theme, compact tool options
#   - Photoshop-like tool defaults
{
  lib,
  config,
  ...
}: {
  options.programs.gimp-photogim.enable = lib.mkEnableOption "PhotoGIMP config (Photoshop-style GIMP layout)";

  config = lib.mkIf config.programs.gimp-photogim.enable {
    # ─────────────────────────────────────────────────────────────────────────
    # GIMP 3.0 — Photoshop-style keyboard shortcuts
    # ─────────────────────────────────────────────────────────────────────────
    xdg.configFile."GIMP/3.0/shortcutsrc".text = ''
      # PhotoGIMP-style Photoshop keyboard shortcuts for GIMP 3.0
      # Mapped to match Adobe Photoshop behavior as closely as possible

      (action "file-new" "<Primary>n")
      (action "file-open" "<Primary>o")
      (action "file-save" "<Primary>s")
      (action "file-save-as" "<Primary><Shift>s")
      (action "file-export-as" "<Primary><Shift><Alt>s")
      (action "file-quit" "<Primary>q")
      (action "file-close" "<Primary>w")
      (action "file-print" "<Primary>p")
      (action "file-revert" "F12")

      (action "edit-undo" "<Primary>z")
      (action "edit-redo" "<Primary><Shift>z")
      (action "edit-cut" "<Primary>x")
      (action "edit-copy" "<Primary>c")
      (action "edit-paste" "<Primary>v")
      (action "edit-paste-in-place" "<Primary><Shift>v")
      (action "edit-fill-fg" "<Alt>BackSpace")
      (action "edit-fill-bg" "<Primary>BackSpace")
      (action "edit-clear" "Delete")

      (action "select-all" "<Primary>a")
      (action "select-none" "<Primary>d")
      (action "select-invert" "<Primary><Shift>i")
      (action "select-float" "<Primary><Shift>l")
      (action "select-feather" "<Primary><Alt>d")
      (action "select-by-color" "")

      (action "image-flatten" "<Primary><Shift>e")
      (action "image-merge-visible-layers" "<Primary>e")
      (action "image-canvas-size" "<Primary><Alt>c")
      (action "image-scale" "<Primary><Alt>i")
      (action "image-crop-to-selection" "")

      (action "layers-new" "<Primary><Shift>n")
      (action "layers-new-group" "")
      (action "layers-duplicate" "<Primary>j")
      (action "layers-delete" "")
      (action "layers-merge-down" "<Primary>e")
      (action "layers-flatten-image" "<Primary><Shift>e")
      (action "layers-raise" "<Primary>bracketright")
      (action "layers-lower" "<Primary>bracketleft")
      (action "layers-raise-to-top" "<Primary><Shift>bracketright")
      (action "layers-lower-to-bottom" "<Primary><Shift>bracketleft")

      (action "view-zoom-in" "<Primary>equal")
      (action "view-zoom-out" "<Primary>minus")
      (action "view-zoom-fit-in-window" "<Primary>0")
      (action "view-zoom-1-1" "<Primary>1")
      (action "view-show-all" "")
      (action "view-zoom-fit-image" "<Primary><Shift>j")
      (action "view-show-grid" "<Primary>apostrophe")
      (action "view-show-guides" "<Primary>semicolon")
      (action "view-snap-to-guides" "<Primary><Shift>semicolon")

      (action "filters-repeat" "<Primary>f")
      (action "filters-re-show" "<Primary><Alt>f")

      (action "dialogs-action-search" "slash")

      (action "tools-free-select" "l")
      (action "tools-rect-select" "m")
      (action "tools-ellipse-select" "m")
      (action "tools-fuzzy-select" "w")
      (action "tools-by-color-select" "")
      (action "tools-crop" "c")
      (action "tools-transform" "")
      (action "tools-move" "v")
      (action "tools-scale" "<Primary>t")
      (action "tools-rotate" "r")
      (action "tools-perspective" "")
      (action "tools-flip" "")
      (action "tools-text" "t")
      (action "tools-bucket-fill" "g")
      (action "tools-gradient" "g")
      (action "tools-pencil" "b")
      (action "tools-paintbrush" "b")
      (action "tools-eraser" "e")
      (action "tools-clone" "s")
      (action "tools-heal" "j")
      (action "tools-dodge-burn" "o")
      (action "tools-smudge" "")
      (action "tools-blur-sharpen" "")
      (action "tools-measure" "i")
      (action "tools-color-picker" "i")
      (action "tools-foreground-select" "")
      (action "tools-path" "p")
      (action "tools-zoom" "z")

      (action "context-colors-swap" "x")
      (action "context-colors-default" "d")

      (action "windows-show-dock" "Tab")
    '';

    # ─────────────────────────────────────────────────────────────────────────
    # GIMP 3.0 — Photoshop-like preferences
    # ─────────────────────────────────────────────────────────────────────────
    xdg.configFile."GIMP/3.0/gimprc".text = ''
      # PhotoGIMP-style preferences

      # Single-window mode (like Photoshop)
      (single-window-mode yes)

      # Dark theme for modern look
      (theme "Dark")

      # Use symbolic icons (modern, flat look)
      (icon-theme "Symbolic")

      # Large canvas, compact UI
      (toolbox-group-menu-type small-icon)

      # Default image size (Photoshop-like)
      (default-image-width 1920)
      (default-image-height 1080)
      (default-image-xresolution 300)
      (default-image-yresolution 300)

      # Maximize usable space
      (show-menubar yes)
      (show-statusbar yes)
      (show-rulers yes)

      # Photoshop-like zoom behavior
      (zoom-quality high)

      # Use OpenCL for GPU acceleration when available
      (use-opencl yes)

      # Number of undo levels (Photoshop default is 50)
      (undo-levels 60)

      # Canvas padding color (dark like Photoshop)
      (canvas-padding-mode custom)
      (canvas-padding-color (color-rgb 0.18 0.18 0.18))

      # Snap to canvas edges (like Photoshop)
      (snap-to-canvas yes)

      # Default to bicubic interpolation (like Photoshop)
      (interpolation-type cubic)

      # Save/export behavior — always confirm
      (export-file-type ask)

      # Thumbnail size in file dialogs
      (thumbnail-size large)
    '';

    # ─────────────────────────────────────────────────────────────────────────
    # GIMP 3.0 — Tool presets (Photoshop-like defaults)
    # ─────────────────────────────────────────────────────────────────────────
    xdg.configFile."GIMP/3.0/toolrc".text = ''
      # PhotoGIMP tool configuration
      # Brush tool defaults similar to Photoshop

      (GimpPaintbrushOptions "Paintbrush"
        (opacity 1.0)
        (size 20.0)
        (hardness 0.5)
        (dynamics "Pressure Size")
      )

      (GimpEraserOptions "Eraser"
        (opacity 1.0)
        (size 25.0)
        (hardness 0.5)
      )

      (GimpCloneOptions "Clone Stamp"
        (opacity 1.0)
        (size 20.0)
        (sample-merged yes)
      )

      (GimpHealOptions "Healing"
        (opacity 1.0)
        (size 20.0)
        (sample-merged yes)
      )
    '';
  };
}
