# Flatpak feature module.
#
# Provides real, working sandboxing for high-risk desktop apps (untrusted-file
# parsers, chat clients) — the isolation native AppArmor profiles can't deliver
# on NixOS because of /nix/store path mismatch.
#
# Apps are installed *declaratively* via nix-flatpak (services.flatpak.packages);
# their per-app data lives in the bubblewrap sandbox under ~/.var/app/<id>/.
# Audit/tighten each app's permissions with Flatseal.
#
# NOTE: the browser (Zen) is deliberately NOT here — it stays native so its
# declarative user.js, default-handler wiring and impermanence entry keep
# working. Flatpak only earns its keep for apps with no native integration to
# break and untrusted input to contain.
{
  lib,
  config,
  username,
  ...
}: {
  options.features.flatpak.enable =
    lib.mkEnableOption "Flatpak app sandboxing (declarative via nix-flatpak)";

  config = lib.mkIf config.features.flatpak.enable {
    services.flatpak = {
      enable = true;

      # Declaratively installed sandboxed apps. nix-flatpak reconciles this
      # list on activation; uninstallUnmanaged stays false so apps you install
      # by hand (e.g. to try something out) are left alone.
      uninstallUnmanaged = false;
      packages = [
        "com.github.tchx84.Flatseal" # per-app permission editor
        "org.gnome.Evince" # sandboxed PDF/document viewer
        "com.discordapp.Discord" # chat client (replaces the native pkg)
      ];
      # nix-flatpak defaults the Flathub remote already; listed explicitly so
      # the source of these appIDs is obvious.
      remotes = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
      ];
    };

    # Flatpak relies on xdg-desktop-portal for sandboxed file/device access.
    # The Hyprland/KDE portals are wired up in hyprland.nix; just ensure the
    # portal service itself is on (mkDefault so it never clashes).
    xdg.portal.enable = lib.mkDefault true;

    # Under impermanence, root and un-persisted $HOME paths are wiped on boot.
    # Persist both the system-wide Flatpak store (remote + `--system` apps and
    # runtimes) and each app's sandboxed home data (~/.var/app), or installs
    # and app settings/logins would vanish every reboot.
    environment.persistence = lib.mkIf config.features.impermanence.enable {
      "/persist" = {
        directories = ["/var/lib/flatpak"];
        users.${username}.directories = [".var/app"];
      };
    };
  };
}
