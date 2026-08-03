{
  pkgs,
  username,
  ...
}: {
  # Display & Desktop
  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.excludePackages = [pkgs.xterm];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "Sonomatic";
    autoLogin.relogin = false;
    settings.General.InputMethod = "";
  };

  services.displayManager.autoLogin = {
    enable = false;
    user = null;
  };
  services.desktopManager.plasma6.enable = true;
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "kde-plasma" ''
      exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
        ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland "$@"
    '')
  ];
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "kde";
    config.gtk.default = "gtk";
  };

  # User avatar for SDDM
  services.accounts-daemon.enable = true;
  system.activationScripts.sddm-avatar = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${../../assets/profile.png} /var/lib/AccountsService/icons/${username}
    chmod 644 /var/lib/AccountsService/icons/${username}
  '';

  # Keyboard
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Touchpad
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      clickMethod = "buttonareas";
    };
    mouse = {
      naturalScrolling = true;
    };
  };

  environment.sessionVariables = {
    GTK_THEME = "Sweet-Dark-v40";
    GTK2_RC_FILES = "${pkgs.sweet-theme}/share/themes/Sweet-Dark-v40/gtk-2.0/gtkrc";
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  fonts.fontconfig.defaultFonts = {
    serif = ["Noto Serif"];
    sansSerif = ["Noto Sans"];
    monospace = ["JetBrainsMono Nerd Font"];
    emoji = ["Noto Color Emoji"];
  };
}
