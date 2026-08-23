{
  pkgs,
  lib,
  config,
  username,
  ...
}: let
  cfg = config.features.desktops;
in {
  # Display & Desktop
  #
  # The greeter runs as a Wayland compositor now (wayland.enable), not on Xorg.
  # That is what fixes cursor size and fractional scaling on the login screen,
  # and it means no X server is started at boot — both sessions (Plasma 6 and
  # Hyprland) have been Wayland all along, so Xorg only ever existed to paint
  # the greeter.
  #
  # services.xserver.enable stays TRUE on purpose, and is not the same thing as
  # "run an X server". It is NixOS's plumbing switch: it generates
  # /etc/X11/xorg.conf.d/00-keyboard.conf from services.xserver.xkb, which is
  # what systemd-localed — and therefore the kwin_wayland greeter and XWayland
  # clients — read the German layout from. Turning it off silently drops the
  # layout back to us, which you would discover while typing your password at
  # a login screen. The X server binary is simply never launched.
  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.excludePackages = [pkgs.xterm];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # No `package` here on purpose: the Wayland greeter needs the Qt6 build,
    # and services.desktopManager.plasma6 now defines sddm.package as
    # kdePackages.sddm itself. Setting it again — even to that same
    # derivation — breaks eval, because the option takes a unique definition.
    theme = "Sonomatic";
    autoLogin.relogin = false;
    settings.General.InputMethod = "";
  };

  services.displayManager.autoLogin = {
    enable = false;
    user = null;
  };
  services.desktopManager.plasma6.enable = cfg.plasma.enable;
  environment.systemPackages = lib.optional cfg.plasma.enable (
    pkgs.writeShellScriptBin "kde-plasma" ''
      exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
        ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland "$@"
    ''
  );
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default =
      if cfg.plasma.enable
      then "kde"
      else "gtk";
    config.gtk.default = "gtk";
  };

  # NIX_XDG_DESKTOP_PORTAL_DIR gates which portal backends the frontend can
  # even see; it was defaulting to the per-user profile (hyprland.portal
  # only), so cosmic/gnome/kde sessions got PortalNotFound for Screenshot and
  # Settings. Point it at the system profile, which has every backend.
  systemd.user.services.xdg-desktop-portal.environment.NIX_XDG_DESKTOP_PORTAL_DIR =
    lib.mkForce "/run/current-system/sw/share/xdg-desktop-portal/portals";

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

  # Fcitx5's built-in Unicode/emoji typing goes through the actual IME input
  # channel (not clipboard+paste), so selecting an emoji types it directly
  # into whatever field has focus — in any toolkit, on any desktop session.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # Wayland input-method frontend (text-input-v3) instead of the
    # GTK_IM_MODULE/QT_IM_MODULE shims — every session here is Wayland, and
    # KWin only feeds fcitx5 through the Wayland frontend.
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [fcitx5-gtk kdePackages.fcitx5-qt kdePackages.fcitx5-configtool];
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
