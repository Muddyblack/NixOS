# NixOS Config Guidelines for AI Assistants

When working with this NixOS configuration, follow these rules strictly.
Follow the rules in AI_GUIDELINES.md in this repo. Do not add verbose comments, duplicate packages, or break the established structure.


## Structure

```
nixos-config/
├── flake.nix                    # Main flake - keep minimal
├── deploy.sh                    # Installation & deployment script
├── assets/                      # All images/media/sounds here
│   ├── profile.png
│   ├── grub-background.png
│   ├── wallpapers/
│   └── sounds/
│       ├── success.wav          # Played on successful upnix
│       └── error.wav            # Played on failed upnix
├── hosts/
│   ├── <hostname>/
│   │   ├── configuration.nix    # System config only
│   │   ├── hardware-configuration.nix
│   │   └── packages.nix         # System packages only
│   └── common.nix               # Shared system config
├── modules/home-manager/
│   ├── home.nix                 # Imports only, minimal logic
│   ├── packages.nix             # User packages only
│   ├── theme.nix                # GTK/Kvantum/icon symlinks
│   ├── shell.nix                # Zsh/direnv/terminal tools
│   ├── plasma-settings.nix      # KDE Plasma config
│   ├── caelestia.nix            # Caelestia Shell config
│   ├── aliases.nix              # Shell aliases
│   └── functions.nix            # Shell functions
├── pkgs/                        # Custom packages & overlays
│   ├── default.nix              # Overlay definition
│   ├── widgets/                 # Custom UI widgets (AGS/QML)
│   └── <package>.nix            # One file per package
└── dev-shells/                  # Development environment templates
```

## Rules

### Packages
- System packages → `hosts/<hostname>/packages.nix`
- User packages → `modules/home-manager/packages.nix`
- NEVER duplicate packages between system and user
- `git`, `vim`, `curl`, `wget` → system only
- `fastfetch`, `btop`, `yazi`, `bat` → user only
- KDE/Plasma stuff → user packages

### Comments
- Only `# Source: <url>` for custom packages
- NO verbose section headers like `# ==================== SECTION ====================`
- NO AI explanation comments
- NO "The Clean Way" or similar branding

### Assets
- Profile pictures → `assets/profile.png`
- Wallpapers → `assets/wallpapers/`
- Reference as `../../assets/` from modules

### Flake
- Keep outputs block compact, no excessive comments

### Custom Packages (pkgs/*.nix)
```nix
# Source: https://github.com/owner/repo
{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "package-name";
  version = "1.0.0";
  # ... rest of derivation
}
```
- First line: `# Source:` URL only
- No multi-line header comments
- No inline explanatory comments unless truly necessary

### Overlay (pkgs/default.nix)
```nix
final: prev: {
  package-name = final.callPackage ./package-name.nix { };
}
```
- One line per package
- No comments in overlay file

### Home Manager Modules
- Each module is single-purpose
- Imports go at top of `home.nix`
- No inline package lists in `home.nix` - use `packages.nix`

### Plasma Global Shortcuts (two traps)

1. **Changes don't apply until relogin.** Under Wayland, KWin — not
   `plasma-kglobalaccel.service` (which exits immediately) — owns the
   `org.kde.kglobalaccel` D-Bus service, and it reads `~/.config/kglobalshortcutsrc`
   only at startup. After a rebuild the file is correct but the running KWin still
   holds the old binding, so the shortcut appears broken. Verify what is *actually*
   live, never trust the file:
   ```bash
   busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
     shortcut as 4 kwin "<ActionName>" "" ""      # returns Qt keycode int
   ```
   Apply without relogin (`u` flag 6 = SetPresent|NoAutoloading; KWin persists it back):
   ```bash
   busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
     setShortcutKeys "asa(ai)u" 4 kwin "<ActionName>" "" "" 1 4 <keycode> 0 0 0 6
   ```
   Qt keycode = `0x10000000` Meta | `0x04000000` Ctrl | `0x08000000` Alt | `0x02000000` Shift | keysym.

2. **`Shift+<digit>` must be written as the produced character.** KWin removes Shift
   from the modifier mask when xkb marks it consumed producing the keysym, so
   `Meta+Shift+1` arrives as `Meta+!` and a literal `"Meta+Shift+1"` entry never
   matches. `Meta+Shift+<letter>` is unaffected. Layout is **German** (`de`, set in
   `hosts/common.nix` `console.keyMap` + `modules/nixos/desktop.nix` `xkb.layout`),
   so the shifted number row is `! " § $ % & / ( ) =` — NOT the US `! @ # $ % ^ & * ( )`.


## Tool Replacements & Aliases

These are active shell aliases/overrides. Always use the right-hand side when suggesting commands to the user.

| Instead of | Use | Notes |
|---|---|---|
| `ls` / `ls -l` | `eza` / `ll` | Icons, git status, group-dirs-first |
| `cat <file>.log` | `tspin` (auto via `cat`) | auto-triggered for `.log` files and `/var/log/*` |
| `find` | `fd` | Aliased: `find` → `fd` |
| `grep` / `rg` | `rg` | Aliased: `grep` → `rg` |
| `df` | `duf` | Aliased: `duf --theme ansi --hide binds` |
| `du` | `dust` | Aliased: `du` → `dust` |
| `ps` | `procs` | Aliased: `ps --tree` |
| `top` / `htop` | `btop` | Aliased: `top` → `btop` |
| `ping` | `gping` | Aliased: `ping` → `gping` (graphical) |
| `curl` | `xh` | Aliased: `curl` → `xh` |
| `cat` (logs) | `tspin` | Shell function: auto for `.log`/`/var/log/*` |
| `git diff` | `difftastic` | Via git integration (`programs.difftastic`) |
| `git log` | `gl` | Alias: `git log --oneline --graph --decorate` |
| `git status` | `gs` | Alias |
| `git add` | `ga` | Alias |
| `git commit` | `gc` | Alias |
| `git push` | `gp` | Alias |
| `lazygit` | `lg` | Alias |
| `cd` | `zoxide` | Auto-aliased with `--cmd cd`; learns frecency |
| `neofetch` | `fastfetch` | |
| `nixos-rebuild switch` | `rebuild` / `upnix` | Plays success/error sound; runs `deploy.sh` if present |
| `nix flake update` | `update` | |
| `nh os list` | `gen` | List NixOS generations |
| `nh clean all` | `clean` / `gcnix` | Garbage collection wrapper |
| `history \| grep` | `hs "term"` / `Ctrl+R` | Alias: `atuin search`; Ctrl+R is atuin's TUI. Up/Down stay on zsh-history-substring-search |
| `tar`/`unzip`/`7z` | `ouch` | Backs `extract` / `pack`; RAR still goes through `unrar` |
| `dig` | `doggo` | Aliased: `dig` → `doggo` |
| `tmux` | `zellij` | No tmux installed |
| `git` (advanced) | `jj` | jujutsu, git-compatible; the git CLI still works on the same repos |
| `mkdir foo && cd foo` | `mkcd foo` | Shell function |
| `sops` | `secrets` | SOPS wrapper with configured keys |
| `termdown` | `timer` | |
| `clock-rs -s` | `stopwatch` | |
| `startplasma-wayland` | `kde-plasma` | Start Plasma (Wayland) from TTY, like `Hyprland` |
| `claude` | `cc-gemini` | Claude Code with Gemini backend |
| `claude` (models) | `cc-models` | List available models on OpenRouter |

## Available Shell Functions

- `upnix` — rebuild NixOS (calls `deploy.sh switch` if present)
- `devnew <template>` — init a dev shell from `dev-shells/` templates (tab-completable)
- `extract <archive>` — universal archive extractor (ouch; unrar for `.rar`)
- `pack <archive.ext> <files...>` — inverse of `extract`
- `mkcd <dir>` — mkdir + cd in one
- `cat <file>.log` — auto-uses `tspin` for log files
- `cht <query>` — interactive cheat sheet (`cht.sh`)
- `dashboard` — start and open Homepage (localhost:8082)
- `paperless` / `paperless-stop` — start/stop the on-demand Paperless-ngx stack (localhost:28981)
- `ai-webui` / `ai-webui-stop` — start/stop the on-demand Open WebUI (localhost:8765)
- `gcnix <keep>` — clean nix garbage (default: keep 5 generations)
- `rollback <N>` — switch to generation N (`gen` to list)
- `cc-gemini`, `cc-kimi`, `cc-openrouter`, `cc-ollama` — Claude Code backends
- `update-claude` — update the Claude Code derivation to latest version

Any function that calls `curl` must write `command curl`: `curl` is aliased to
`xh`, and zsh expands aliases when the function body is *parsed*.

Local models must stay small — this host has an Intel iGPU and no dedicated
VRAM, so ~4B (`gemma4:e4b`) is the practical ceiling. `OLLAMA_DEFAULT_MODEL`
(functions.nix) and `localModel` (modules/home-manager/ai.nix) are the two
places to keep in sync. Frontier models are reached over an API, never locally:
Kimi K3 is 2.8T parameters (104B active) and ships no small variant, so
`cc-kimi` is an API wrapper by necessity, not by preference.

## Security Hardening — Known Tradeoffs

When suggesting kernel sysctl hardening for `modules/nixos/security.nix`, be aware of these conflicts with this system's use case:

| Sysctl | Risk | Reason |
|--------|------|--------|
| `kernel.yama.ptrace_scope = 1` | **Breaks Proton/Steam games & debugger attach** | Proton uses ptrace internally; attaching gdb/strace to running processes also breaks. Do NOT add this — gaming is enabled on this host. |
| `kernel.unprivileged_bpf_disabled = 1` | Monitoring tools need sudo | Tools like `bpftrace`, some `btop` features, `bandwhich` require elevated privileges. Acceptable tradeoff but warn the user. |
| `net.core.bpf_jit_harden = 2` | Pairs with BPF above | Low daily impact, fine to keep. |

Default safe set (already in security.nix): `kptr_restrict`, `dmesg_restrict`, `rp_filter`, `tcp_syncookies`, redirect/accept blocks, `bpf_jit_harden`. Skip `ptrace_scope` and be cautious with `unprivileged_bpf_disabled`.

## DO NOT

- Add packages to both system and user config
- Create verbose section comments
- Put assets in random locations
- Hardcode backup extension versions
- Add explanatory AI comments
- Touch `dev-shells/` or `archiv/`
- Create new files without following the structure
- Duplicate theme/icon definitions
