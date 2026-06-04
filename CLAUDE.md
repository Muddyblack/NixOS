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
| `history \| grep` | `hs "term"` | Alias: `history 1 -1 \| rg` |
| `mkdir foo && cd foo` | `mkcd foo` | Shell function |
| `sops` | `secrets` | SOPS wrapper with configured keys |
| `termdown` | `timer` | |
| `clock-rs -s` | `stopwatch` | |
| `claude` | `cc-gemini` | Claude Code with Gemini backend |
| `claude` (models) | `cc-models` | List available models on OpenRouter |

## Available Shell Functions

- `upnix` — rebuild NixOS (calls `deploy.sh switch` if present)
- `devnew <template>` — init a dev shell from `dev-shells/` templates (tab-completable)
- `extract <archive>` — universal archive extractor
- `mkcd <dir>` — mkdir + cd in one
- `cat <file>.log` — auto-uses `tspin` for log files
- `cht <query>` — interactive cheat sheet (`cht.sh`)
- `dashboard` — start and open Homepage (localhost:8082)
- `gcnix <keep>` — clean nix garbage (default: keep 5 generations)
- `rollback <N>` — switch to generation N (`gen` to list)
- `cc-gemini`, `cc-openrouter`, `cc-ollama` — Claude Code integrations
- `update-claude` — update the Claude Code derivation to latest version

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
