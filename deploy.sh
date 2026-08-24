#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
NIXOS_USER="${NIXOS_USER:-muddyblack}"

STATE_FILE="${FLAKE_DIR}/.deploy-state"
SUCCESS_SOUND="${FLAKE_DIR}/assets/sounds/success.wav"
ERROR_SOUND="${FLAKE_DIR}/assets/sounds/error.wav"

_play_sound() {
  local file="$1"
  if [[ -f "$file" && -s "$file" ]]; then
    if command -v pw-play &>/dev/null; then
      pw-play "$file" &>/dev/null &
    elif command -v paplay &>/dev/null; then
      paplay "$file" &>/dev/null &
    elif command -v aplay &>/dev/null; then
      aplay "$file" &>/dev/null &
    fi
  fi
}

load_saved_profile() {
  if [[ -f "$STATE_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$STATE_FILE"
  fi
}

save_profile() {
  echo "FLAKE_TARGET=${1}" > "$STATE_FILE"
}

load_saved_profile
FLAKE_TARGET="${FLAKE_TARGET:-muddyblack}"

ensure_symlink() {
  local target="$1"
  if [[ "$(readlink /etc/nixos 2>/dev/null)" == "$target" ]]; then
    return 0
  fi
  if [[ -e /etc/nixos && ! -L /etc/nixos ]]; then
    echo "/etc/nixos exists as a directory — removing to replace with symlink"
    sudo rm -rf /etc/nixos
  fi
  sudo ln -sfn "$target" /etc/nixos
  echo "Symlink updated: /etc/nixos -> $target"
}

usage() {
  cat <<EOF
NixOS deployment helper

Usage: $0 <command> [options]

Commands:
  fresh             Partition disk (disko) + install NixOS on LOCAL machine
                    (Run this while booted from a Live ISO)
  fresh --remote <host>
                    Partition + install on a REMOTE machine via nixos-anywhere
                    (Builds locally, pushes over SSH)
  install           Run nixos-install on LOCAL machine (disk already partitioned)
  switch            Rebuild & switch config on the RUNNING system (day-to-day)
  switch --offline  Rebuild without fetching anything from the network
  switch --remote <host>
                    Rebuild & switch on a REMOTE running NixOS machine
  sops-setup        First-time SOPS setup: generate age key, update .sops.yaml, create secrets
  secrets-edit      Edit encrypted secrets
  secrets-rotate    Re-encrypt after adding new age keys to .sops.yaml

Options:
  --profile <name>     Host profile: muddyblack (default), muddyblack-lite
  --remote <host>      Target host (e.g. root@192.168.1.100)
  --nh                 Use 'nh' wrapper instead of 'nixos-rebuild' directly
  --device <dev>       Target disk (e.g. /dev/sda, /dev/nvme0n1) — prompted interactively if omitted
  --bootloader <bl>    Bootloader: grub or refind — prompted interactively if omitted
  --dual-boot          Enable dual-boot Windows partitions — prompted interactively if omitted
  --no-dual-boot       Disable dual-boot Windows partitions
  --plymouth-theme <t> Plymouth boot theme (dotted, flower, icy, matrix) — prompted interactively if omitted
  --desktops <list>    Comma-separated desktop sessions to enable: hyprland,plasma,cosmic,gnome
                        — prompted interactively if omitted
  --keyboard <layout>  xkb keyboard layout for every session (de, us, fr, ...)
                        — prompted interactively if omitted

Examples:
  $0 fresh                                             # interactive setup
  $0 fresh --device /dev/nvme0n1                       # skip device prompt only
  $0 fresh --device /dev/sda --bootloader grub --no-dual-boot  # fully non-interactive
  $0 fresh --remote root@192.168.1.100                 # remote install (interactive)
  $0 install                                           # local, after manual disko
  $0 switch                                            # rebuild current system
  $0 switch --remote root@192.168.1.100
EOF
  exit 1
}


# Best x86-64 psABI level this CPU can run. v4 is deliberately not a possible
# answer: the kernel builds with -mno-avx, so no AVX-512 reaches kernel code and
# a v4 build is a v3 build with a narrower CPU requirement. Read from
# /proc/cpuinfo rather than `ld.so --help` because the loader on PATH is nix-ld's
# shim here, and cpuinfo answers the same CPUID bits over SSH just as well.
detect_march() {
  local host="${1:-}"
  local cpuinfo flags vendor f

  if [[ -n "$host" ]]; then
    cpuinfo="$(ssh -o StrictHostKeyChecking=no "$host" 'cat /proc/cpuinfo' 2>/dev/null)" || return 1
  else
    cpuinfo="$(cat /proc/cpuinfo 2>/dev/null)" || return 1
  fi

  flags=" $(printf '%s\n' "$cpuinfo" | sed -n 's/^flags[[:space:]]*: //p' | head -1) "
  vendor="$(printf '%s\n' "$cpuinfo" | sed -n 's/^vendor_id[[:space:]]*: //p' | head -1)"
  [[ -n "${flags// /}" ]] || return 1

  for f in avx avx2 bmi1 bmi2 f16c fma movbe xsave popcnt sse4_1 sse4_2 ssse3 cx16 lahf_lm; do
    [[ "$flags" == *" $f "* ]] || { echo "generic"; return 0; }
  done

  # Zen 4/5 are the AMD parts with AVX-512, and the one cached variant tuned for
  # a microarchitecture instead of a psABI level.
  if [[ "$vendor" == "AuthenticAMD" && "$flags" == *" avx512f "* ]]; then
    echo "zen4"
    return 0
  fi

  echo "x86_64-v3"
}

# Keep the detected level in deploy-config.nix. Nix cannot probe the CPU itself:
# flake evaluation is pure, so reading /proc/cpuinfo at eval time would need
# --impure and would break `nix flake check` and every remote build. Detecting
# once at deploy time and writing the answer down keeps evaluation reproducible.
sync_deploy_march() {
  local host="${1:-}"
  local out="$FLAKE_DIR/hosts/deploy-config.nix"
  local march

  [[ -f "$out" ]] || return 0

  if ! march="$(detect_march "$host")"; then
    echo "CPU detection failed — leaving features.kernel.cachyos.march unchanged."
    return 0
  fi

  if grep -q 'features\.kernel\.cachyos\.march' "$out"; then
    grep -q "features\.kernel\.cachyos\.march = \"${march}\";" "$out" && return 0
    sed -i "s|features\.kernel\.cachyos\.march = \".*\";|features.kernel.cachyos.march = \"${march}\";|" "$out"
  else
    sed -i "\$i\\  features.kernel.cachyos.march = \"${march}\";" "$out"
  fi
  echo "Detected CPU level: ${march} (hosts/deploy-config.nix updated)"
}

write_deploy_config() {
  local device="$1"
  local bl="$2"
  local dual_boot="$3"
  local theme="$4"
  local march="${5:-generic}"
  local desktops="${6:-hyprland,plasma,cosmic}"
  local kb_layout="${7:-de}"
  local out="$FLAKE_DIR/hosts/deploy-config.nix"

  if [[ ! "$device" =~ ^/dev/ ]]; then
    echo "Error: device must be a path like /dev/sda or /dev/nvme0n1"
    exit 1
  fi

  if [[ ! "$bl" =~ ^(grub|refind|systemd-boot)$ ]]; then
    echo "Error: bootloader must be grub, refind, or systemd-boot"
    exit 1
  fi
  if [[ ! "$dual_boot" =~ ^(true|false)$ ]]; then
    echo "Error: dual_boot must be true or false"
    exit 1
  fi
  if ! compgen -G "$FLAKE_DIR/assets/plymouth/$theme/*.mp4" > /dev/null; then
    echo "Error: Plymouth theme '$theme' not found in assets/plymouth/"
    exit 1
  fi

  if [[ ! "$kb_layout" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    echo "Error: keyboard layout must be an xkb layout name like de, us, fr"
    exit 1
  fi

  local all_desktops=(hyprland plasma cosmic gnome)
  local desktop_lines=""
  IFS=',' read -ra chosen_desktops <<< "$desktops"
  for d in "${chosen_desktops[@]}"; do
    if [[ ! " ${all_desktops[*]} " =~ " ${d} " ]]; then
      echo "Error: unknown desktop session '${d}' (known: ${all_desktops[*]})"
      exit 1
    fi
  done
  for d in "${all_desktops[@]}"; do
    if [[ " ${chosen_desktops[*]} " =~ " ${d} " ]]; then
      desktop_lines+="  features.desktops.${d}.enable = true;"$'\n'
    else
      desktop_lines+="  features.desktops.${d}.enable = false;"$'\n'
    fi
  done

  cat > "$out" <<EOF
# Auto-generated by deploy.sh — do not edit manually.
{
  diskLayout.device = "${device}";
  diskLayout.withDualBoot = ${dual_boot};
  bootloader = "${bl}";
  plymouthTheme = "${theme}";
  keyboardLayout = "${kb_layout}";
  features.kernel.cachyos.march = "${march}";
${desktop_lines}}
EOF
  echo "Wrote deploy config: hosts/deploy-config.nix (device=${device}, bootloader=${bl}, dualBoot=${dual_boot}, plymouth=${theme}, march=${march}, desktops=${desktops}, keyboard=${kb_layout})"
}

prompt_interactive_setup() {
  local bootloader_ref="$1"  # nameref
  local dual_boot_ref="$2"   # nameref
  local device_ref="$3"      # nameref
  local plymouth_theme_ref="$4"  # nameref
  local desktops_ref="$5"    # nameref
  local kb_layout_ref="$6"   # nameref
  local -n _bootloader="$bootloader_ref"
  local -n _dual_boot="$dual_boot_ref"
  local -n _device="$device_ref"
  local -n _plymouth_theme="$plymouth_theme_ref"
  local -n _desktops="$desktops_ref"
  local -n _kb_layout="$kb_layout_ref"

  echo ""
  echo "=== Interactive setup ==="

  # Device
  if [[ -z "$_device" ]]; then
    echo "Available block devices:"
    lsblk -d -o NAME,SIZE,MODEL 2>/dev/null | grep -v "^loop" || true
    echo ""
    local disks=()
    while IFS= read -r name; do
      disks+=("/dev/$name")
    done < <(lsblk -d -o NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}' | grep -v "^loop")
    local default_device=""
    if [[ ${#disks[@]} -eq 1 ]]; then
      default_device="${disks[0]}"
    fi
    if [[ -n "$default_device" ]]; then
      read -rp "Target disk device [default: ${default_device}]: " _device
      _device="${_device:-$default_device}"
    else
      read -rp "Target disk device [e.g. /dev/sda, /dev/nvme0n1]: " _device
      if [[ -z "$_device" ]]; then
        echo "Error: device is required"
        exit 1
      fi
    fi
  fi

  # Bootloader
  if [[ -z "$_bootloader" ]]; then
    local uefi_supported=false
    if [[ -d /sys/firmware/efi ]]; then
      uefi_supported=true
    fi
    echo ""
    echo "Available bootloaders:"
    if $uefi_supported; then
      echo "  1) refind  (UEFI — recommended)"
      echo "  2) grub"
      read -rp "Select bootloader [1-2, default: 1]: " bl_choice
      bl_choice="${bl_choice:-1}"
      case "$bl_choice" in
        1) _bootloader="refind" ;;
        2) _bootloader="grub" ;;
        *) echo "Invalid choice, using refind"; _bootloader="refind" ;;
      esac
    else
      echo "  1) grub  (legacy BIOS — only option)"
      echo "  Note: rEFInd requires UEFI, not available on this system."
      read -rp "Select bootloader [1, default: 1]: " bl_choice
      _bootloader="grub"
    fi
  fi

  # Dual boot
  if [[ -z "$_dual_boot" ]]; then
    read -rp "Enable dual-boot Windows partitions? [y/N]: " db_answer
    if [[ "$db_answer" =~ ^[Yy]$ ]]; then
      _dual_boot="true"
    else
      _dual_boot="false"
    fi
  fi

  # Plymouth theme
  if [[ -z "$_plymouth_theme" ]]; then
    echo ""
    echo "Available Plymouth boot themes:"
    local themes=()
    local i=1
    for theme_dir in "$FLAKE_DIR"/assets/plymouth/*/; do
      if [[ -d "$theme_dir" ]]; then
        theme_name=$(basename "$theme_dir")
        if compgen -G "$theme_dir/*.mp4" > /dev/null; then
          themes+=("$theme_name")
          echo "  $i) $theme_name"
          ((i++))
        fi
      fi
    done
    echo ""
    read -rp "Select Plymouth theme [1-${#themes[@]}, default: 1]: " theme_choice
    theme_choice="${theme_choice:-1}"
    if [[ "$theme_choice" =~ ^[0-9]+$ ]] && [[ "$theme_choice" -ge 1 ]] && [[ "$theme_choice" -le "${#themes[@]}" ]]; then
      _plymouth_theme="${themes[$((theme_choice-1))]}"
    else
      echo "Invalid choice, using first theme: ${themes[0]}"
      _plymouth_theme="${themes[0]}"
    fi
  fi

  # Desktop sessions
  if [[ -z "$_desktops" ]]; then
    echo ""
    echo "Which desktop sessions do you want enabled? (switchable at the login screen)"
    local all_desktops=(hyprland plasma cosmic gnome)
    local defaults=(y y y n)
    local chosen=()
    for i in "${!all_desktops[@]}"; do
      local name="${all_desktops[$i]}"
      local def="${defaults[$i]}"
      local prompt_suffix="[y/N]"
      [[ "$def" == "y" ]] && prompt_suffix="[Y/n]"
      read -rp "  Enable ${name}? ${prompt_suffix}: " answer
      answer="${answer:-$def}"
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        chosen+=("$name")
      fi
    done
    if [[ ${#chosen[@]} -eq 0 ]]; then
      echo "Error: at least one desktop session must be enabled"
      exit 1
    fi
    _desktops="$(IFS=,; echo "${chosen[*]}")"
  fi

  # Keyboard layout — one xkb layout name for console, greeter, Hyprland,
  # Plasma and fcitx5 alike (keyboardLayout in hosts/deploy-config.nix).
  if [[ -z "$_kb_layout" ]]; then
    echo ""
    echo "Keyboard layout:"
    local kb_names=(de us gb fr es it ch)
    local kb_labels=("German" "US English" "UK English" "French (AZERTY)" "Spanish" "Italian" "Swiss")
    for i in "${!kb_names[@]}"; do
      echo "  $((i+1))) ${kb_names[$i]}  — ${kb_labels[$i]}"
    done
    echo "  $(( ${#kb_names[@]} + 1 ))) other  — type any xkb layout name"
    read -rp "Select keyboard layout [1-$(( ${#kb_names[@]} + 1 )), default: 1]: " kb_choice
    kb_choice="${kb_choice:-1}"
    if [[ "$kb_choice" =~ ^[0-9]+$ ]] && [[ "$kb_choice" -ge 1 ]] && [[ "$kb_choice" -le "${#kb_names[@]}" ]]; then
      _kb_layout="${kb_names[$((kb_choice-1))]}"
    elif [[ "$kb_choice" == "$(( ${#kb_names[@]} + 1 ))" ]]; then
      read -rp "  xkb layout name (see 'localectl list-x11-keymap-layouts'): " _kb_layout
      if [[ ! "$_kb_layout" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "Invalid layout name, using de"
        _kb_layout="de"
      fi
    else
      echo "Invalid choice, using de"
      _kb_layout="de"
    fi
    # console.keyMap reuses this string; a handful of layouts spell their
    # console keymap differently. Warn rather than silently install a console
    # with no keymap.
    case "$_kb_layout" in
      gb) echo "  Note: xkb 'gb' has no console keymap of that name — set console.keyMap = \"uk\" in hosts/common.nix." ;;
    esac
  fi

  echo ""
  echo "  Profile:        $FLAKE_TARGET"
  echo "  Device:         $_device"
  echo "  Bootloader:     $_bootloader"
  echo "  Dual boot:      $_dual_boot"
  echo "  Plymouth theme: $_plymouth_theme"
  echo "  Desktops:       $_desktops"
  echo "  Keyboard:       $_kb_layout"
  echo ""
  read -rp "Proceed with these settings? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}

prompt_luks_password() {
  local pw pw2
  while true; do
    read -rsp "Enter LUKS disk encryption password: " pw; echo
    read -rsp "Confirm LUKS password: " pw2; echo
    if [[ "$pw" == "$pw2" ]]; then
      break
    fi
    echo "Passwords do not match, try again."
  done
  LUKS_PASSWORD="$pw"
}

cmd_fresh() {
  local host=""
  local bootloader=""
  local dual_boot=""
  local device=""
  local plymouth_theme=""
  local desktops=""
  local kb_layout=""
  local pw_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote)
        host="$2"
        shift 2
        ;;
      --profile)
        FLAKE_TARGET="$2"
        shift 2
        ;;
      --bootloader)
        bootloader="$2"
        shift 2
        ;;
      --dual-boot)
        dual_boot="true"
        shift
        ;;
      --no-dual-boot)
        dual_boot="false"
        shift
        ;;
      --device)
        device="$2"
        shift 2
        ;;
      --plymouth-theme)
        plymouth_theme="$2"
        shift 2
        ;;
      --desktops)
        desktops="$2"
        shift 2
        ;;
      --keyboard)
        kb_layout="$2"
        shift 2
        ;;
      *)
        if [[ ! "$1" =~ ^-- ]]; then
          host="$1"
          shift
        else
          echo "Unknown option: $1"
          exit 1
        fi
        ;;
    esac
  done

  prompt_interactive_setup bootloader dual_boot device plymouth_theme desktops kb_layout
  write_deploy_config "$device" "$bootloader" "$dual_boot" "$plymouth_theme" \
    "$(detect_march "$host" || echo generic)" "$desktops" "$kb_layout"

  if [[ -z "$host" ]]; then
    # LOCAL: booted from live ISO
    echo "WARNING: This will WIPE the local disk and install NixOS!"
    read -rp "Are you absolutely sure? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

    prompt_luks_password
    pw_file="/tmp/luks.key"
    echo -n "$LUKS_PASSWORD" > "$pw_file"
    chmod 600 "$pw_file"
    trap 'rm -f "$pw_file"' EXIT

    echo "Running Disko (partitioning)..."
    sudo --preserve-env=pw_file \
      nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
      --mode disko --flake "${FLAKE_DIR}#${FLAKE_TARGET}"

    echo "Disko done. Running install..."
    cmd_install --skip-setup
  else
    # REMOTE: build locally, deploy via nixos-anywhere
    echo "Fresh install to ${host} via nixos-anywhere (will WIPE disk!)..."
    read -rp "Are you sure? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

    prompt_luks_password
    pw_file="$(mktemp)"
    echo -n "$LUKS_PASSWORD" > "$pw_file"
    trap 'rm -f "$pw_file"' EXIT

    nix --extra-experimental-features "nix-command flakes" run github:nix-community/nixos-anywhere -- \
      --flake "${FLAKE_DIR}#${FLAKE_TARGET}" \
      --target-host "$host" \
      --disk-encryption-keys /tmp/luks.key "$pw_file" \
      --generate-hardware-config nixos-generate-config \
        "${FLAKE_DIR}/hosts/${FLAKE_TARGET}/hardware-configuration.nix"
  fi
}

cmd_install() {
  local bootloader=""
  local dual_boot=""
  local device=""
  local plymouth_theme=""
  local desktops=""
  local kb_layout=""
  local skip_setup=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        FLAKE_TARGET="$2"
        shift 2
        ;;
      --bootloader)
        bootloader="$2"
        shift 2
        ;;
      --dual-boot)
        dual_boot="true"
        shift
        ;;
      --no-dual-boot)
        dual_boot="false"
        shift
        ;;
      --device)
        device="$2"
        shift 2
        ;;
      --plymouth-theme)
        plymouth_theme="$2"
        shift 2
        ;;
      --desktops)
        desktops="$2"
        shift 2
        ;;
      --keyboard)
        kb_layout="$2"
        shift 2
        ;;
      --skip-setup)
        skip_setup="1"
        shift
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "$skip_setup" ]]; then
    prompt_interactive_setup bootloader dual_boot device plymouth_theme desktops kb_layout
    write_deploy_config "$device" "$bootloader" "$dual_boot" "$plymouth_theme" \
      "$(detect_march || echo generic)" "$desktops" "$kb_layout"
  fi

  echo "Running nixos-install (disk must already be partitioned/mounted)..."
  sudo nixos-install --flake "${FLAKE_DIR}#${FLAKE_TARGET}"

  save_profile "$FLAKE_TARGET"

  echo "Copying config repo to installed system..."
  if ! mountpoint -q /mnt; then
    sudo mount -o subvol=@root /dev/mapper/crypted /mnt
  fi
  if ! mountpoint -q /mnt/home; then
    sudo mount -o subvol=@home /dev/mapper/crypted /mnt/home
  fi
  sudo mkdir -p "/mnt/home/${NIXOS_USER}"
  sudo cp -r "${FLAKE_DIR}" "/mnt/home/${NIXOS_USER}/nixos-config"
  sudo chown -R 1000:100 "/mnt/home/${NIXOS_USER}/nixos-config"
  sudo ln -sfn "/home/${NIXOS_USER}/nixos-config" /mnt/etc/nixos

  echo "Done! You can now reboot."
}

cmd_switch() {
  local host=""
  local offline=""
  local profile_explicit=""
  local use_nh=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote)
        host="$2"
        shift 2
        ;;
      --profile)
        FLAKE_TARGET="$2"
        profile_explicit="1"
        shift 2
        ;;
      --offline)
        offline="--offline"
        shift
        ;;
      --nh)
        use_nh="1"
        shift
        ;;
      *)
        if [[ ! "$1" =~ ^-- ]]; then
          host="$1"
          shift
        else
          echo "Unknown option: $1"
          exit 1
        fi
        ;;
    esac
  done

  [[ -n "$profile_explicit" ]] && save_profile "$FLAKE_TARGET"

  sync_deploy_march "$host"

  if [[ -z "$host" ]]; then
    ensure_symlink "$FLAKE_DIR"


    echo "Rebuilding & switching local config (profile: ${FLAKE_TARGET})..."
    sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null || true
    local success=false
    if [[ -n "$use_nh" ]] && command -v nh &>/dev/null; then
        if NIX_CONFIG="experimental-features = nix-command flakes" \
          nh os switch "${FLAKE_DIR}" --hostname "${FLAKE_TARGET}" $offline; then
          success=true
        else
          success=false
        fi
    else
        if sudo -E HOME=/root NIX_CONFIG="experimental-features = nix-command flakes" \
          nixos-rebuild switch --install-bootloader --flake "${FLAKE_DIR}#${FLAKE_TARGET}" $offline; then
          success=true
        else
          success=false
        fi
    fi

    if [[ "$success" == "true" ]]; then
      echo "Build successful!"
      _play_sound "$SUCCESS_SOUND"
    else
      echo "Build failed!"
      _play_sound "$ERROR_SOUND"
      exit 1
    fi
  else
    echo "Rebuilding & switching config on ${host} (profile: ${FLAKE_TARGET})..."
    if NIX_SSHOPTS="-o StrictHostKeyChecking=no" \
    NIX_CONFIG="experimental-features = nix-command flakes" \
      nixos-rebuild switch --flake "${FLAKE_DIR}#${FLAKE_TARGET}" \
      --target-host "$host" \
      --use-remote-sudo \
      --show-trace $offline; then
      echo "Build successful!"
      _play_sound "$SUCCESS_SOUND"
    else
      echo "Build failed!"
      _play_sound "$ERROR_SOUND"
      exit 1
    fi
  fi
}

cmd_secrets_edit() {
  SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}" \
    sops "${FLAKE_DIR}/secrets/secrets.yaml"
}

cmd_secrets_rotate() {
  SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}" \
    sops updatekeys "${FLAKE_DIR}/secrets/secrets.yaml"
}

cmd_sops_setup() {
  local key_file="$HOME/.config/sops/age/keys.txt"
  local secrets_file="$FLAKE_DIR/secrets/secrets.yaml"
  local sops_yaml="$FLAKE_DIR/.sops.yaml"

  echo "=== SOPS Setup ==="

  # 1. Generate user age key if missing
  if [[ -f "$key_file" ]]; then
    echo "Age key already exists: $key_file"
  else
    echo "Generating age key..."
    mkdir -p "$(dirname "$key_file")"
    age-keygen -o "$key_file"
    chmod 600 "$key_file"
  fi

  # 2. Read user public key
  local user_pub
  user_pub=$(age-keygen -y "$key_file")
  echo "User public key : $user_pub"

  # 3. Get host public key from SSH host key
  local host_pub=""
  if [[ -f /etc/ssh/ssh_host_ed25519_key.pub ]]; then
    host_pub=$(ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub)
    echo "Host public key : $host_pub"
  else
    echo "Warning: /etc/ssh/ssh_host_ed25519_key.pub not found — host key skipped"
  fi

  # 4. Write .sops.yaml
  if [[ -n "$host_pub" ]]; then
    cat > "$sops_yaml" <<EOF
keys:
  - &user ${user_pub}
  - &host ${host_pub}
creation_rules:
  - path_regex: secrets/.*\\.yaml\$
    key_groups:
      - age:
          - *user
          - *host
EOF
  else
    cat > "$sops_yaml" <<EOF
keys:
  - &user ${user_pub}
creation_rules:
  - path_regex: secrets/.*\\.yaml\$
    key_groups:
      - age:
          - *user
EOF
  fi
  echo "Updated .sops.yaml"

  # 5. Handle secrets.yaml
  if [[ -f "$secrets_file" ]]; then
    if SOPS_AGE_KEY_FILE="$key_file" sops -d "$secrets_file" &>/dev/null; then
      echo "Existing secrets.yaml is valid — opening editor..."
    else
      echo "Cannot decrypt existing secrets.yaml (old keys) — recreating..."
      rm -f "$secrets_file"
    fi
  fi

  if [[ ! -f "$secrets_file" ]]; then
    echo "Creating secrets.yaml — add your secrets in the editor that opens."
    echo "See secrets/secrets.yaml.example for available keys."
    echo ""
  fi

  SOPS_AGE_KEY_FILE="$key_file" sops "$secrets_file"

  echo ""
  echo "Done. Run 'upnix' to apply."
}

[[ $# -lt 1 ]] && usage

case "$1" in
  fresh)
    shift
    cmd_fresh "$@"
    ;;
  install)
    shift
    cmd_install "$@"
    ;;
  switch|rebuild)
    shift
    cmd_switch "$@"
    ;;
  secrets-edit)
    cmd_secrets_edit
    ;;
  secrets-rotate)
    cmd_secrets_rotate
    ;;
  sops-setup)
    cmd_sops_setup
    ;;
  *)
    usage
    ;;
esac
