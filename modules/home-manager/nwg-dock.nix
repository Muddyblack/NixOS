{...}: {
  # Styling for nwg-dock-hyprland to match the translucent KDE look.
  # Launched from the Hyprland exec-once block in hyprland.nix.
  home.file.".config/nwg-dock-hyprland/style.css".text = ''
    window {
      background-color: rgba(26, 27, 38, 0.55);
      border-radius: 16px;
      border: 1px solid rgba(137, 180, 250, 0.4);
      box-shadow: 0px 8px 15px rgba(0, 0, 0, 0.6);
      margin-bottom: 8px;
    }
    #box {
      padding: 5px;
      margin: 2px;
      border-radius: 10px;
    }
    button {
      background: transparent;
      border: none;
      border-radius: 10px;
      padding: 4px;
      margin: 0 5px;
      transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    }
    button:hover {
      background-color: rgba(203, 166, 247, 0.2);
    }
  '';
}
