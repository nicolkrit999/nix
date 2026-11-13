#!/usr/bin/env bash
# Clone installer: reinstall nixos-desktop / nixos-laptop on new hardware (or next to it as <host>-2).
# Runs from the NixOS live ISO. Everything outside the live ISO is refused except --dry-run.
#
# Usage: install.sh [--dry-run] [--host nixos-desktop|nixos-laptop] [--variant 2|same]
#   (a promoted host has no -2 clone any more: the installer then installs the original name itself)
#                   [--disk /dev/X] [--mode whole|free] [--bundle FILE]
#
# Source: always the latest `main`, cloned shallow (git clone --depth 1 --branch main) into a
# temporary directory; nixos-install uses that clone as the flake. After the install the clone is
# placed at ~/nix of the target user and unshallowed (full history on the new machine).
#
# Environment (all optional):
#   INSTALLER_LIVE=1      declare "I am the live installer" (the wrappers set it)
#   INSTALLER_REPO_URL    repository to clone and to leave as `origin` (default: repo-url.txt next to
#                         this script, the public https URL). Tests point it at a local repository.
#   INSTALLER_SRC         an existing git checkout to use instead of cloning (clone-install passes the
#                         clone it just made). A path without .git (flake store path) is ignored.
#   INSTALLER_TEST=1      test mode: regular-file disks only, needs INSTALLER_BIN_DIR with fakes
#   INSTALLER_BIN_DIR     directory prepended to PATH (fake tools for tests)
#   INSTALLER_ROOT        target mount root (default /mnt)
#   INSTALLER_WORK_DIR    tmpfs work dir for secrets (test mode only; otherwise /run is used)
#   INSTALLER_BUNDLE_DIRS extra directories searched for *.age bundles (space separated)
#   INSTALLER_EFIVARS_DIR efivars dir (default /sys/firmware/efi/efivars)
#   INSTALLER_SBCTL_ENROLL_ARGS  default "--microsoft"
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

DRY_RUN=0
OPT_HOST=""
OPT_VARIANT=""
OPT_DISK=""
OPT_MODE=""
OPT_BUNDLE=""

# shellcheck source=disk-plan.sh
source "$SCRIPT_DIR/disk-plan.sh"

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}
step() { printf '\n== %s ==\n' "$*"; }

usage() {
  awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
}

parse_args() {
  while (($#)); do
    case $1 in
      --dry-run) DRY_RUN=1 ;;
      --host) OPT_HOST=${2:?--host needs a value}; shift ;;
      --variant) OPT_VARIANT=${2:?--variant needs a value}; shift ;;
      --disk) OPT_DISK=${2:?--disk needs a value}; shift ;;
      --mode) OPT_MODE=${2:?--mode needs a value}; shift ;;
      --bundle) OPT_BUNDLE=${2:?--bundle needs a value}; shift ;;
      -h | --help) usage; exit 0 ;;
      *) die "unknown argument: $1 (see --help)" ;;
    esac
    shift
  done
  export DRY_RUN
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

is_live_installer() {
  [[ ${INSTALLER_LIVE:-0} == 1 ]] && return 0
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  (. /etc/os-release && [[ ${VARIANT_ID:-} == installer ]])
}

# Tools that can destroy or change the real machine: in test mode each of them must
# resolve into INSTALLER_BIN_DIR (a fake), never to the real binary.
DANGEROUS_TOOLS=(wipefs mkfs.vfat mkfs.btrfs cryptsetup mount umount btrfs partprobe udevadm
  nixos-install efibootmgr sbctl tailscale tailscaled chown)

guard_environment() {
  if [[ -n ${INSTALLER_BIN_DIR:-} ]]; then
    [[ -d $INSTALLER_BIN_DIR ]] || die "INSTALLER_BIN_DIR is not a directory: $INSTALLER_BIN_DIR"
    PATH="$INSTALLER_BIN_DIR:$PATH"
    export PATH
  fi
  if [[ ${INSTALLER_TEST:-0} == 1 ]]; then
    [[ -n ${INSTALLER_BIN_DIR:-} ]] || die "INSTALLER_TEST=1 needs INSTALLER_BIN_DIR with fake tools"
    local t resolved
    for t in "${DANGEROUS_TOOLS[@]}"; do
      resolved=$(command -v "$t" || true)
      [[ $resolved == "$INSTALLER_BIN_DIR/"* ]] \
        || die "INSTALLER_TEST=1: '$t' does not resolve to a fake in INSTALLER_BIN_DIR (got '${resolved:-nothing}')"
    done
    return 0
  fi
  if ((!DRY_RUN)); then
    is_live_installer || die "not running in the live installer (no VARIANT_ID=installer, INSTALLER_LIVE unset). Only --dry-run is allowed here."
    ((EUID == 0)) || die "must run as root (sudo) in the live installer"
  fi
}

need_tools() {
  local missing=() t
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  if ((${#missing[@]})); then
    if ((DRY_RUN)); then
      warn "tools missing (fine for --dry-run): ${missing[*]}"
    else
      die "required tools missing: ${missing[*]}"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Prompts (stdin, so tests can pipe answers)
# ---------------------------------------------------------------------------

ask() { # ask <prompt> -> REPLY
  printf '%s ' "$1" >&2
  IFS= read -r REPLY || die "no input (stdin closed)"
}

ask_secret() { # ask_secret <prompt> -> REPLY
  printf '%s ' "$1" >&2
  if [[ -t 0 ]]; then
    IFS= read -rs REPLY || die "no input"
    printf '\n' >&2
  else
    IFS= read -r REPLY || die "no input"
  fi
}

choose() { # choose <prompt> <opt>... -> CHOICE (the option text)
  local prompt=$1 i
  shift
  local opts=("$@")
  while :; do
    for i in "${!opts[@]}"; do printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}" >&2; done
    ask "$prompt [1-${#opts[@]}]:"
    if [[ $REPLY =~ ^[0-9]+$ ]] && ((REPLY >= 1 && REPLY <= ${#opts[@]})); then
      CHOICE=${opts[$((REPLY - 1))]}
      return 0
    fi
    warn "invalid choice"
  done
}

confirm_typed() { # confirm_typed <expected> <prompt>
  ask "$2"
  [[ $REPLY == "$1" ]] || die "confirmation mismatch (expected '$1'), nothing was changed"
}

# ---------------------------------------------------------------------------
# Work dir (tmpfs only: keys must never touch a disk unencrypted)
# ---------------------------------------------------------------------------

WORK=""
CLONE_ROOT=""
MOUNTED_BUNDLE_SRCS=()

cleanup() {
  local m
  if [[ -n ${TAILSCALED_PID:-} ]]; then kill "$TAILSCALED_PID" 2>/dev/null || true; fi
  for m in "${MOUNTED_BUNDLE_SRCS[@]+"${MOUNTED_BUNDLE_SRCS[@]}"}"; do
    umount "$m" 2>/dev/null || true
  done
  if [[ -n $WORK && -d $WORK ]]; then
    find "$WORK" -type f -exec shred -u {} + 2>/dev/null || true
    rm -rf "$WORK"
  fi
  if [[ -n $CLONE_ROOT && -d $CLONE_ROOT ]]; then
    rm -rf "$CLONE_ROOT"
  fi
}

init_workdir() {
  if [[ ${INSTALLER_TEST:-0} == 1 && -n ${INSTALLER_WORK_DIR:-} ]]; then
    mkdir -p "$INSTALLER_WORK_DIR"
    WORK=$(mktemp -d "$INSTALLER_WORK_DIR/installer.XXXXXX")
  else
    WORK=$(mktemp -d /run/clone-installer.XXXXXX)
    local fstype
    fstype=$(findmnt -no FSTYPE -T "$WORK" 2>/dev/null || true)
    case $fstype in
      tmpfs | ramfs) ;;
      *)
        rm -rf "$WORK"
        die "work dir is not on tmpfs (found '${fstype:-unknown}'); refusing to handle keys here"
        ;;
    esac
  fi
  chmod 700 "$WORK"
  trap cleanup EXIT
}

# ---------------------------------------------------------------------------
# Source tree, flake ref, facts
# ---------------------------------------------------------------------------

SRC=""
FLAKE=""
SOPS_COMMON=""
REPO_URL=""
REPO_BRANCH=main

# A writable scratch base: the test work dir, /run (tmpfs on the live ISO), else $TMPDIR.
scratch_base() {
  if [[ ${INSTALLER_TEST:-0} == 1 && -n ${INSTALLER_WORK_DIR:-} ]]; then
    mkdir -p "$INSTALLER_WORK_DIR"
    printf '%s\n' "$INSTALLER_WORK_DIR"
  elif [[ -d /run && -w /run ]]; then
    printf '/run\n'
  else
    printf '%s\n' "${TMPDIR:-/tmp}"
  fi
}

# prepare_source: SRC = a git checkout of `main`. Either the one handed in (INSTALLER_SRC with a
# .git, e.g. from clone-install) or a fresh shallow clone. FLAKE = SRC.
prepare_source() {
  local url_file=$SCRIPT_DIR/repo-url.txt
  REPO_URL=${INSTALLER_REPO_URL:-}
  if [[ -z $REPO_URL && -r $url_file ]]; then REPO_URL=$(head -n1 "$url_file"); fi
  [[ -n $REPO_URL ]] || die "no repository URL: set INSTALLER_REPO_URL (repo-url.txt is missing next to install.sh)"
  if [[ -n ${INSTALLER_SRC:-} && -e ${INSTALLER_SRC}/.git ]]; then
    SRC=$INSTALLER_SRC
    say "Using the checkout $SRC as source."
  else
    CLONE_ROOT=$(mktemp -d "$(scratch_base)/clone-installer-src.XXXXXX")
    say "Cloning $REPO_URL (branch $REPO_BRANCH, shallow) ..."
    GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --branch "$REPO_BRANCH" -- "$REPO_URL" "$CLONE_ROOT/nix" \
      || die "could not clone $REPO_URL (network?)"
    SRC=$CLONE_ROOT/nix
  fi
  [[ -r $SRC/templates/installer/layout.nix ]] || die "layout.nix not found under $SRC"
  SOPS_COMMON=$SRC/users/krit/common/sops/krit-common-secrets-sops.yaml
  [[ -r $SOPS_COMMON ]] || die "common sops file not found: $SOPS_COMMON"
  dp_layout_load "$SRC/templates/installer/layout.nix" || die "$DP_REASON"
  FLAKE=$SRC
}

# shellcheck disable=SC2016  # Nix expression, not shell
FACTS_APPLY='c: let u = c.myconfig.constants.user; uc = c.users.users.${u}; in {
  hostName = c.networking.hostName;
  user = u;
  uid = uc.uid;
  gid = c.users.groups.${uc.group}.gid;
  home = uc.home;
  luks = c.boot.initrd.luks.devices != {};
  lanzaboote = c.myconfig.services.lanzaboote.enable;
  pkiBundle = c.myconfig.services.lanzaboote.pkiBundle;
  bootDevice = c.fileSystems."/boot".device;
  atticServer = c.myconfig.attic.serverUrl;
  atticCache = c.myconfig.attic.cacheName;
  atticKey = c.myconfig.attic.publicKey;
}'

# load_facts <clone>: evaluates the clone config once; sets F_* variables.
load_facts() {
  local clone=$1 json
  json=$(nix eval --json "$FLAKE#nixosConfigurations.$clone.config" --apply "$FACTS_APPLY") \
    || die "could not evaluate nixosConfigurations.$clone from $FLAKE"
  F_HOSTNAME=$(jq -er .hostName <<<"$json")
  F_USER=$(jq -er .user <<<"$json")
  F_UID=$(jq -er .uid <<<"$json")
  F_GID=$(jq -er .gid <<<"$json")
  F_LUKS=$(jq -er 'if .luks then 1 else 0 end' <<<"$json")
  F_LANZABOOTE=$(jq -er 'if .lanzaboote then 1 else 0 end' <<<"$json")
  F_PKI=$(jq -er .pkiBundle <<<"$json")
  F_BOOT_DEVICE=$(jq -er .bootDevice <<<"$json")
  F_ATTIC_SERVER=$(jq -er .atticServer <<<"$json")
  F_ATTIC_CACHE=$(jq -er .atticCache <<<"$json")
  F_ATTIC_KEY=$(jq -er .atticKey <<<"$json")
}

# ---------------------------------------------------------------------------
# Selection steps
# ---------------------------------------------------------------------------

HOST=""
CLONE=""
DISK=""
MODE=""
ACK=""

choose_host() {
  case $OPT_HOST in
    nixos-desktop | nixos-laptop) HOST=$OPT_HOST ;;
    "")
      choose "Which host do you want to install?" nixos-desktop nixos-laptop
      HOST=$CHOICE
      ;;
    *) die "--host must be nixos-desktop or nixos-laptop" ;;
  esac
}

# has_config <name>: is nixosConfigurations.<name> defined in the flake? Only the attribute names
# are evaluated (no host config), so this is cheap. A promoted host has no "<host>-2" any more.
has_config() {
  local names
  [[ -n ${FLAKE_CONFIG_NAMES:-} ]] || {
    FLAKE_CONFIG_NAMES=$(nix eval --json "$FLAKE#nixosConfigurations" --apply builtins.attrNames) \
      || die "could not list nixosConfigurations of $FLAKE"
  }
  jq -e 'type == "array"' <<<"$FLAKE_CONFIG_NAMES" >/dev/null \
    || die "could not read the nixosConfigurations names of $FLAKE"
  names=$FLAKE_CONFIG_NAMES
  jq -e --arg n "$1" 'index($n) != null' <<<"$names" >/dev/null
}

choose_variant() {
  local v=$OPT_VARIANT
  if ! has_config "$HOST-2"; then
    # Promoted host: the original name is the only one left, so there is nothing to choose.
    if [[ $v == 2 ]]; then
      warn "'$HOST-2' no longer exists in this flake (the host was promoted): installing '$HOST' instead of the -2 variant."
    else
      say "'$HOST-2' no longer exists in this flake (the host was promoted): installing '$HOST'."
    fi
    CLONE=$HOST
    return 0
  fi
  if [[ -z $v ]]; then
    say ""
    say "Variant:"
    say "  2    install as '$HOST-2' next to the original (default, safe; the original is never modified)"
    say "  same install as '$HOST' itself. Only valid AFTER the original was promoted to the generic"
    say "       hardware layer (the promotion removes the old machine's by-UUID disk config); before that"
    say "       the original config points at the old machine's disks and will not boot here."
    choose "Variant?" "2 (alongside)" "same name (only after promotion)"
    case $CHOICE in
      2*) v=2 ;;
      *) v=same ;;
    esac
  fi
  case $v in
    2) CLONE=$HOST-2 ;;
    same) CLONE=$HOST ;;
    *) die "--variant must be 2 or same" ;;
  esac
}

check_same_name_promoted() {
  [[ $CLONE == "$HOST" ]] || return 0
  if [[ $F_BOOT_DEVICE != "/dev/disk/by-label/$DP_ESP_LABEL" ]]; then
    if has_config "$HOST-2"; then
      die "'$HOST' is not promoted yet: its /boot is '$F_BOOT_DEVICE', not the generic by-label layer. Use the '-2' variant, or promote first (see Documentation/installation/)."
    fi
    die "'$HOST' has no '$HOST-2' clone any more, but its /boot is '$F_BOOT_DEVICE', not the generic by-label layer: the repository is half-promoted. Finish the promotion (Documentation/installation/clone-retire-and-promote.md) or restore the clone entry."
  fi
}

require_uefi() {
  [[ -d /sys/firmware/efi ]] || {
    if [[ ${INSTALLER_TEST:-0} == 1 || $DRY_RUN == 1 ]]; then
      warn "not booted in UEFI mode (ignored in test/dry-run)"
    else
      die "not booted in UEFI mode: lanzaboote/systemd-boot needs UEFI. Boot the USB stick in UEFI mode."
    fi
  }
}

show_disk_table() {
  local d size model status
  say ""
  printf '%-22s %10s  %-26s %s\n' DISK SIZE MODEL STATUS
  while IFS= read -r d; do
    [[ -n $d ]] || continue
    size=$(($(dp_disk_bytes "$d" 2>/dev/null || echo 0) / 1073741824))
    if [[ -f $d ]]; then model=$(basename "$d"); else model=$(lsblk -dno MODEL "$d" 2>/dev/null | head -n1 || true); fi
    status=$(dp_status_line "$d" 2>/dev/null || echo unreadable)
    if dp_disk_in_use "$d"; then status="$status [IN USE by this system: not selectable]"; fi
    printf '%-22s %7s GiB  %-26s %s\n' "$d" "$size" "${model:-?}" "$status"
  done < <(dp_list_disks)
}

choose_disk() {
  local disks=() d
  show_disk_table
  if [[ -n $OPT_DISK ]]; then
    DISK=$OPT_DISK
  else
    while IFS= read -r d; do [[ -n $d ]] && disks+=("$d"); done < <(dp_list_disks)
    ((${#disks[@]})) || die "no disks found"
    choose "Install onto which disk?" "${disks[@]}"
    DISK=$CHOICE
  fi
  dp_assert_disk_allowed "$DISK" || die "$DP_REASON"
  if dp_disk_in_use "$DISK"; then
    die "$DISK holds mounts of the running system (is it the USB stick?). Refusing."
  fi
}

choose_mode() {
  local class
  class=$(dp_classify "$DISK")
  say ""
  say "Disk $DISK is classified: $class ($(dp_status_line "$DISK"))"
  if [[ -z $OPT_MODE ]]; then
    choose "Mode?" \
      "free-space: new partitions in the free block next to Windows (never touches existing partitions)" \
      "whole disk: NO Windows, wipe everything on $DISK"
    case $CHOICE in
      free-space*) MODE=free ;;
      *) MODE=whole ;;
    esac
  else
    case $OPT_MODE in whole | free) MODE=$OPT_MODE ;; *) die "--mode must be whole or free" ;; esac
  fi
  if [[ $MODE == whole ]]; then
    case $class in
      windows | other-os | unknown)
        say ""
        say "$DISK contains '$class' data. Wiping it destroys that installation."
        confirm_typed "no windows, wipe" "Type exactly 'no windows, wipe' to accept (anything else aborts): "
        ACK=no-windows-wipe
        ;;
    esac
    dp_wipe_allowed "$DISK" "$ACK" || die "$DP_REASON"
  else
    dp_free_space_check "$DISK" || {
      printf '%s\n' "$DP_REASON" >&2
      die "free-space mode not possible, nothing was changed"
    }
  fi
}

confirm_plan() {
  step "Plan"
  dp_plan "$DISK" "$MODE" "$F_LUKS" || die "$DP_REASON"
  dp_plan_describe
  say ""
  say "Host:    $CLONE (tailnet/hostname $F_HOSTNAME, user $F_USER uid $F_UID, LUKS: $([[ $F_LUKS == 1 ]] && echo yes || echo no))"
  say "Flake:   $FLAKE#$CLONE"
  say "Target:  $ROOT"
  if ((DRY_RUN)); then
    say "(dry-run: no confirmation needed, nothing is executed)"
    return 0
  fi
  confirm_typed "$DISK" "Type the disk name ($DISK) to start the installation: "
}

# ---------------------------------------------------------------------------
# Bundle and secrets
# ---------------------------------------------------------------------------

BUNDLE=""

list_bundle_candidates() {
  local dir mp
  {
    for dir in ${INSTALLER_BUNDLE_DIRS:-}; do
      find "$dir" -maxdepth 2 -name '*.age' -type f 2>/dev/null || true
    done
    if [[ ${INSTALLER_TEST:-0} != 1 ]]; then
      while IFS= read -r mp; do
        [[ -n $mp && $mp != "$ROOT" && $mp != "$ROOT"/* ]] || continue
        find "$mp" -maxdepth 2 -name '*.age' -type f 2>/dev/null || true
      done < <(findmnt -rn -o TARGET 2>/dev/null | grep -E '^(/run/media|/media|/mnt|/iso|/run/ventoy|/run/initramfs)' || true)
    fi
  } | sort -u
}

# Mount unmounted removable partitions read-only so that a stick without automount is found.
mount_removable_ro() {
  [[ ${INSTALLER_TEST:-0} != 1 ]] || return 0
  ((!DRY_RUN)) || return 0
  local name fstype mp n=0
  while read -r name fstype; do
    [[ -n $fstype ]] || continue
    case $fstype in vfat | exfat | ntfs | ext4 | ext3 | ext2 | iso9660 | udf) ;; *) continue ;; esac
    findmnt -rn -S "$name" >/dev/null 2>&1 && continue
    mp=$WORK/stick-$n
    n=$((n + 1))
    mkdir -p "$mp"
    if dp_run mount -o ro "$name" "$mp" 2>/dev/null; then MOUNTED_BUNDLE_SRCS+=("$mp"); fi
  done < <(lsblk -rpno NAME,FSTYPE,RM,TYPE 2>/dev/null | awk '$3 == 1 && $4 == "part" { print $1, $2 }')
  INSTALLER_BUNDLE_DIRS="${INSTALLER_BUNDLE_DIRS:-} $WORK"
}

find_bundle() {
  local c
  if [[ -n $OPT_BUNDLE ]]; then
    [[ -r $OPT_BUNDLE ]] || die "bundle not readable: $OPT_BUNDLE"
    BUNDLE=$OPT_BUNDLE
    return 0
  fi
  mount_removable_ro
  local cands=()
  while IFS= read -r c; do [[ -n $c ]] && cands+=("$c"); done < <(list_bundle_candidates)
  if ((${#cands[@]} == 0)); then
    say "No *.age bundle found on any attached stick."
    ask "Path to the bundle file (or 'q' to abort):"
    [[ $REPLY != q && -r $REPLY ]] || die "no bundle; plug the stick that holds ${HOST}-clone-bundle.tar.age and retry"
    BUNDLE=$REPLY
  elif ((${#cands[@]} == 1)); then
    BUNDLE=${cands[0]}
    say "Found bundle: $BUNDLE"
  else
    # Prefer the one named after the host.
    for c in "${cands[@]}"; do
      if [[ $(basename "$c") == "$HOST-clone-bundle.tar.age" ]]; then BUNDLE=$c; fi
    done
    if [[ -z $BUNDLE ]]; then
      choose "Several bundles found, which one?" "${cands[@]}"
      BUNDLE=$CHOICE
    else
      say "Found bundle: $BUNDLE"
    fi
  fi
}

KEYS_DIR=""
TS_AUTHKEY_FILE=""
NETRC_FILE=""
LUKS_PASS=""

decrypt_bundle() {
  KEYS_DIR=$WORK/keys
  mkdir -p "$KEYS_DIR"
  chmod 700 "$KEYS_DIR"
  if ((DRY_RUN)); then
    say "+ [dry-run] age -d '$BUNDLE' once into tmpfs, then tar -x into ($KEYS_DIR): host/ssh_host_ed25519_key(.pub), user/keys.txt"
    return 0
  fi
  say "Decrypting $BUNDLE (bundle passphrase, asked once)..."
  # One decryption into the tmpfs work dir (0600, shredded on exit); list and extract read that file.
  local plain=$WORK/bundle.tar
  (umask 077 && : >"$plain")
  (umask 077 && age -d -o "$plain" "$BUNDLE") || die "could not decrypt the bundle (wrong passphrase?)"
  chmod 600 "$plain"
  local listing
  listing=$(tar -tf "$plain" 2>/dev/null) || die "could not read the decrypted bundle (not a tar?)"
  # Only the four expected members; anything else is refused before extraction.
  local bad
  bad=$(printf '%s\n' "$listing" | grep -vxE 'host/ssh_host_ed25519_key|host/ssh_host_ed25519_key\.pub|user/keys\.txt|meta\.txt|host/|user/' || true)
  [[ -z $bad ]] || die "bundle contains unexpected members: $bad"
  tar -xf "$plain" -C "$KEYS_DIR" --no-same-owner --no-same-permissions
  shred -u "$plain" 2>/dev/null || rm -f "$plain"
  [[ -s $KEYS_DIR/host/ssh_host_ed25519_key && -s $KEYS_DIR/host/ssh_host_ed25519_key.pub && -s $KEYS_DIR/user/keys.txt ]] \
    || die "bundle is incomplete (need host key, host pub key, user age key)"
  chmod 600 "$KEYS_DIR/host/ssh_host_ed25519_key" "$KEYS_DIR/user/keys.txt"
  if [[ -r $KEYS_DIR/meta.txt ]]; then
    local bh
    bh=$(sed -n 's/^host=//p' "$KEYS_DIR/meta.txt" | head -n1)
    [[ -z $bh || $bh == "$HOST" ]] || die "bundle is for '$bh', but you are installing '$HOST'"
  fi
}

decrypt_secrets() {
  local ident=$WORK/age-identity.txt
  if ((DRY_RUN)); then
    say "+ [dry-run] ssh-to-age -private-key -i host key -> age identity (tmpfs); sops -d tailscale_key, attic-push-token from $SOPS_COMMON"
    TS_AUTHKEY_FILE=$WORK/tailscale-authkey
    return 0
  fi
  {
    ssh-to-age -private-key -i "$KEYS_DIR/host/ssh_host_ed25519_key"
    cat "$KEYS_DIR/user/keys.txt"
  } >"$ident"
  chmod 600 "$ident"
  export SOPS_AGE_KEY_FILE=$ident
  TS_AUTHKEY_FILE=$WORK/tailscale-authkey
  (umask 077 && sops -d --extract '["tailscale_key"]' "$SOPS_COMMON" >"$TS_AUTHKEY_FILE") \
    || die "could not decrypt tailscale_key (is this host key a recipient of the common sops file?)"
  local token host
  token=$(sops -d --extract '["attic-push-token"]' "$SOPS_COMMON") || {
    warn "could not decrypt attic-push-token: no cache authentication"
    return 0
  }
  host=${F_ATTIC_SERVER#*://}
  host=${host%%/*}
  host=${host%%:*}
  NETRC_FILE=$WORK/attic-netrc
  (umask 077 && printf 'machine %s password %s\n' "$host" "$token" >"$NETRC_FILE")
}

# ---------------------------------------------------------------------------
# Tailscale on the live system
# ---------------------------------------------------------------------------

TS_STATE=/var/lib/tailscale
TS_SOCK=/run/tailscale/tailscaled.sock
TAILSCALED_PID=""
TS_JOINED=0
TS_ERR=""
TS_MAX_TRIES=3

# One `tailscale up` with the key file; stderr is kept for classification. Never puts the key on a command line.
ts_up_attempt() {
  : >"$TS_ERR"
  tailscale --socket="$TS_SOCK" up --auth-key="file:$TS_AUTHKEY_FILE" --hostname="$F_HOSTNAME" --timeout=60s 2>"$TS_ERR"
}

ts_error_kind() { # -> expired | rejected | network | other
  local e
  e=$(cat "$TS_ERR" 2>/dev/null || true)
  if grep -qiE 'expired' <<<"$e"; then
    echo expired
  elif grep -qiE 'does not exist|invalid key|revoked|not valid|already (been )?used|unauthorized|forbidden' <<<"$e"; then
    echo rejected
  elif grep -qiE 'timed? ?out|deadline|unreachable|no route|dial |resolve|connection (refused|reset)|temporary failure|network' <<<"$e"; then
    echo network
  else
    echo other
  fi
}

ts_show_error() {
  [[ -s $TS_ERR ]] || return 0
  say "tailscale said:" >&2
  # defence in depth: a key must never reach the screen or a log, even if tailscale echoed it
  sed -E 's/tskey-[A-Za-z0-9_-]+/tskey-<hidden>/g; s/^/  /' "$TS_ERR" | head -n 8 >&2
}

ts_explain() { # ts_explain <kind>
  {
    printf '\n+------------------------------------------------------------------------------+\n'
    case $1 in
      network) printf '| TAILSCALE: could not reach the Tailscale servers                             |\n' ;;
      *) printf '| TAILSCALE: the stored auth key was not accepted                              |\n' ;;
    esac
    printf '+------------------------------------------------------------------------------+\n'
    case $1 in
      expired) say "Why: the key stored in the sops file (tailscale_key) has expired." ;;
      rejected) say "Why: the key stored in the sops file (tailscale_key) was revoked, was single-use and is"
        say "     already used, or no longer exists." ;;
      network) say "Why: this looks like a network problem, not a key problem. Check the connection of"
        say "     the live system (for example: ping 1.1.1.1), then choose [r]etry below."
        say "     If the retry says the key was rejected, you get the steps for a new key." ;;
      *) say "Why: Tailscale refused the join for a reason that is not clear from its message"
        say "     (shown above). The stored key may be expired, revoked or single-use." ;;
    esac
    if [[ $1 != network ]]; then
      say ""
      say "How to create a new key (about one minute, from any device):"
      say "  1. Open  https://login.tailscale.com/admin/settings/keys"
      say "  2. Click \"Generate auth key...\""
      say "  3. Turn \"Reusable\" ON (so a retry can use it again) and leave \"Ephemeral\" OFF"
      say "     (an ephemeral machine disappears from the tailnet when it is offline)."
      say "     Expiry: 1 day is enough, this key is only for this install. No tags needed."
      say "  4. Generate it and copy the key. It starts with  tskey-auth-"
      say ""
      say "Where to put it:"
      say "  Paste it at the hidden prompt below (nothing is shown while you type). It is used"
      say "  for this install only and is NOT stored anywhere. The node identity is saved on"
      say "  the new system, so it joins the tailnet by itself after the reboot."
    fi
    say ""
    say "Skipping Tailscale: the install still works, and the Attic cache on the NAS is still used"
    say "if this network can reach it anyway (a VPN, the LAN, or a host that is on the tailnet,"
    say "for example a VM behind NAT). If not, packages come from cache.nixos.org only and anything"
    say "missing there is compiled (slower). The first boot then needs a manual join"
    say "(clone-post-install.md)."
    say ""
    say "The stored sops key is intentionally not relied on (auth keys expire after 90 days at most,"
    say "installs are years apart): a fresh key per install is the supported path, do not try to fix it."
    say ""
  } >&2
}

tailscale_join() {
  step "Tailscale (live system)"
  if [[ ${INSTALLER_TEST:-0} == 1 ]]; then
    TS_STATE=$WORK/ts-state
    TS_SOCK=$WORK/ts.sock
  fi
  if ((DRY_RUN)); then
    say "+ [dry-run] tailscaled --statedir=$TS_STATE --socket=$TS_SOCK &"
    say "+ [dry-run] tailscale up --auth-key=file:<tmpfs key> --hostname=$F_HOSTNAME"
    say "+ [dry-run] on failure: explain how to create a fresh auth key, then [p]aste / [r]etry / [s]kip / [q]uit"
    return 0
  fi
  mkdir -p "$TS_STATE" "$(dirname "$TS_SOCK")"
  TS_ERR=$WORK/tailscale-up.err
  tailscaled --statedir="$TS_STATE" --socket="$TS_SOCK" >"$WORK/tailscaled.log" 2>&1 &
  TAILSCALED_PID=$!
  [[ ${INSTALLER_TEST:-0} == 1 ]] || sleep 3
  if ts_up_attempt; then
    TS_JOINED=1
  else
    local tries=0 kind shown="" choice key
    while :; do
      ts_show_error
      kind=$(ts_error_kind)
      if [[ $kind != "$shown" ]]; then
        ts_explain "$kind"
        shown=$kind
      fi
      if ((tries >= TS_MAX_TRIES)); then
        warn "$TS_MAX_TRIES attempts failed."
        ask "Choose [s]kip Tailscale or [q]uit the installer:"
        choice=${REPLY,,}
        [[ $choice == s || $choice == q ]] || choice=invalid
      else
        ask "[p]aste a new key (default), [r]etry, [s]kip Tailscale, [q]uit:"
        choice=${REPLY,,}
        [[ -n $choice ]] || choice=p
      fi
      case $choice in
        p | paste)
          ask_secret "Tailscale auth key (hidden, not stored):"
          key=${REPLY//[[:space:]]/}
          tries=$((tries + 1))
          if [[ $key != tskey-* ]]; then
            warn "that does not look like an auth key (it should start with tskey-auth-)."
            continue
          fi
          (umask 077 && printf '%s' "$key" >"$TS_AUTHKEY_FILE")
          key=""
          ;;
        r | retry) tries=$((tries + 1)) ;;
        s | skip)
          warn "skipping Tailscale"
          break
          ;;
        q | quit)
          say "Aborted before any change. Nothing was modified."
          exit 1
          ;;
        *)
          warn "please answer p, r, s or q"
          continue
          ;;
      esac
      if ts_up_attempt; then
        TS_JOINED=1
        break
      fi
      warn "tailscale did not accept that."
    done
  fi
  shred -u "$TS_AUTHKEY_FILE" 2>/dev/null || rm -f "$TS_AUTHKEY_FILE"
  if ((TS_JOINED)); then
    say "Tailscale joined as $F_HOSTNAME."
  else
    warn "tailscale not joined: tailnet-only names and addresses may not resolve from this live system (the Attic cache is probed separately before nixos-install), the install continues"
  fi
}

tailscale_save_state() {
  step "Persist tailscale state"
  if ((DRY_RUN)); then
    say "+ [dry-run] stop tailscaled; cp -a $TS_STATE/. $ROOT/persist/var/lib/tailscale/ (only if the join worked)"
    return 0
  fi
  [[ -n $TAILSCALED_PID ]] || return 0
  kill "$TAILSCALED_PID" 2>/dev/null || true
  wait "$TAILSCALED_PID" 2>/dev/null || true
  TAILSCALED_PID=""
  if ((!TS_JOINED)); then
    say "Tailscale was not joined: no node identity to persist. Join after the first boot (clone-post-install.md, section 4)."
    return 0
  fi
  mkdir -p "$TS_STATE"
  install -d -m 0700 "$ROOT/persist/var/lib/tailscale"
  cp -a "$TS_STATE/." "$ROOT/persist/var/lib/tailscale/"
}

# ---------------------------------------------------------------------------
# Key placement
# ---------------------------------------------------------------------------

place_keys() {
  step "Place keys on the target"
  local ssh=$ROOT/persist/etc/ssh
  local ageDir=$ROOT/home/$F_USER/.config/sops/age
  dp_run install -d -m 0755 "$ssh"
  if ((DRY_RUN)); then
    say "+ [dry-run] install -m 0600 host key -> $ssh/ssh_host_ed25519_key; -m 0644 .pub (root:root)"
    say "+ [dry-run] install user age key -> $ageDir/keys.txt (0600, owner $F_UID:$F_GID)"
    return 0
  fi
  install -m 0600 "$KEYS_DIR/host/ssh_host_ed25519_key" "$ssh/ssh_host_ed25519_key"
  install -m 0644 "$KEYS_DIR/host/ssh_host_ed25519_key.pub" "$ssh/ssh_host_ed25519_key.pub"
  chown 0:0 "$ssh/ssh_host_ed25519_key" "$ssh/ssh_host_ed25519_key.pub"
  # /home is the @home subvolume (own mount), so this lands on the persistent home.
  install -d -m 0700 "$ROOT/home/$F_USER" "$ROOT/home/$F_USER/.config" "$ROOT/home/$F_USER/.config/sops" "$ageDir"
  chown "$F_UID:$F_GID" "$ROOT/home/$F_USER" "$ROOT/home/$F_USER/.config" "$ROOT/home/$F_USER/.config/sops" "$ageDir"
  install -m 0600 "$KEYS_DIR/user/keys.txt" "$ageDir/keys.txt"
  chown "$F_UID:$F_GID" "$ageDir/keys.txt"
}

# ---------------------------------------------------------------------------
# Secure Boot
# ---------------------------------------------------------------------------

SB_CONF=""
SB_SETUP_MODE=0

secure_boot_setup_mode() {
  local f
  f=${INSTALLER_EFIVARS_DIR:-/sys/firmware/efi/efivars}/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c
  [[ -r $f ]] || return 1
  # 4 attribute bytes followed by one data byte: 1 = Setup Mode.
  [[ $(od -An -tu1 -j4 -N1 "$f" | tr -d ' ') == 1 ]]
}

print_setup_mode_steps() {
  cat >&2 <<'MSG'

The firmware is NOT in Secure Boot Setup Mode, so the new Secure Boot keys cannot be enrolled by
this installer. To enroll them automatically, put the firmware into Setup Mode first:

  1. Reboot into the firmware setup (BIOS/UEFI): from this live system "systemctl reboot --firmware-setup",
     or the vendor key during power-on.
  2. Open the Secure Boot settings and clear/delete the Platform Key (PK): look for "Reset to Setup Mode",
     "Clear Secure Boot keys" or "Delete all variables" (some boards: switch the Secure Boot mode to
     "Custom" first, then delete the keys). Secure Boot itself may stay on or off; only Setup Mode matters.
  3. Save, boot this stick again and rerun clone-install. The Microsoft keys are kept: the installer
     enrolls with "sbctl enroll-keys --microsoft" (Windows and firmware option ROMs keep working).
  4. Only after the install: turn Secure Boot ON in the firmware.

If you continue without enrollment, the install itself works (the keys are created and the boot files
are signed); enrolling is then a manual step after the first boot (the final checklist prints it).
MSG
}

# secure_boot_gate: lanzaboote hosts only. Runs before anything destructive. Sets SB_SETUP_MODE.
secure_boot_gate() {
  ((F_LANZABOOTE)) || return 0
  if secure_boot_setup_mode; then
    SB_SETUP_MODE=1
    say "Firmware is in Secure Boot Setup Mode: the keys will be enrolled after the install."
    return 0
  fi
  SB_SETUP_MODE=0
  if ((DRY_RUN)); then
    warn "[dry-run] firmware is not in Setup Mode: the real run would stop here and ask [r]etry / [c]ontinue / [q]uit."
    return 0
  fi
  step "Secure Boot gate"
  print_setup_mode_steps
  while :; do
    ask "[r]etry (re-read the firmware state) / [c]ontinue without enrollment / [q]uit:"
    case $REPLY in
      r | R | retry)
        if secure_boot_setup_mode; then
          SB_SETUP_MODE=1
          say "Firmware is now in Setup Mode: the keys will be enrolled after the install."
          return 0
        fi
        warn "still not in Setup Mode (a firmware change needs a reboot: quit, change it in the firmware, boot the stick again)."
        ;;
      c | C | continue)
        warn "continuing without enrollment: keys are created, enrolling is a manual step afterwards."
        return 0
        ;;
      q | Q | quit)
        say "Aborted before any change. Nothing was modified."
        exit 1
        ;;
      *) warn "please answer r, c or q" ;;
    esac
  done
}

secure_boot_create_keys() {
  ((F_LANZABOOTE)) || {
    say "Host does not use lanzaboote: no Secure Boot keys needed."
    return 0
  }
  step "Secure Boot keys (sbctl)"
  local pki=$ROOT$F_PKI
  SB_CONF=$WORK/sbctl.conf
  # sbctl reads its key paths from a config file; point it at the target's pkiBundle.
  printf 'keydir: %s/keys\nguid: %s/GUID\n' "$pki" "$pki" >"$SB_CONF"
  dp_run install -d -m 0700 "$pki"
  # lanzaboote signs during nixos-install and needs the keys even if enrolling is not possible.
  dp_run sbctl --config "$SB_CONF" create-keys
  if ((SB_SETUP_MODE)); then
    say "Keys created; they will be enrolled after the install."
  else
    warn "keys created but not enrolled (firmware not in Setup Mode): manual steps are printed at the end."
  fi
}

secure_boot_enroll() {
  ((F_LANZABOOTE)) || return 0
  step "Secure Boot enrollment"
  if ((SB_SETUP_MODE)); then
    # shellcheck disable=SC2086
    dp_run sbctl --config "$SB_CONF" enroll-keys ${INSTALLER_SBCTL_ENROLL_ARGS:---microsoft}
  else
    say "Skipped (not in Setup Mode)."
  fi
}

# ---------------------------------------------------------------------------
# nixos-install
# ---------------------------------------------------------------------------

# Independent of the Tailscale join: the NAS may be reachable via a VPN, the LAN or a NAT through a tailnet host.
attic_probe() {
  [[ -n $F_ATTIC_SERVER && -n $F_ATTIC_CACHE ]] || return 1
  local url=$F_ATTIC_SERVER/$F_ATTIC_CACHE/nix-cache-info args=()
  [[ -n $NETRC_FILE ]] && args+=(--netrc-file "$NETRC_FILE")
  curl -fsS --max-time 8 -o /dev/null "${args[@]+"${args[@]}"}" "$url"
}

run_nixos_install() {
  step "nixos-install"
  local opts=(--root "$ROOT" --flake "$FLAKE#$CLONE" --no-root-passwd)
  if ((DRY_RUN)); then
    say "(attic probe skipped in dry-run; substituter would be added when reachable)"
    opts+=(--option extra-substituters "$F_ATTIC_SERVER/$F_ATTIC_CACHE?priority=10"
      --option extra-trusted-public-keys "$F_ATTIC_KEY")
    [[ -n $NETRC_FILE ]] && opts+=(--option netrc-file "$NETRC_FILE")
  elif attic_probe; then
    opts+=(--option extra-substituters "$F_ATTIC_SERVER/$F_ATTIC_CACHE?priority=10"
      --option extra-trusted-public-keys "$F_ATTIC_KEY")
    [[ -n $NETRC_FILE ]] && opts+=(--option netrc-file "$NETRC_FILE")
  else
    warn "Attic cache $F_ATTIC_SERVER/$F_ATTIC_CACHE is not reachable from this live system (checked independently of the Tailscale join): using cache.nixos.org only, anything missing there is built (this can take long)."
  fi
  dp_run nixos-install "${opts[@]}"
}

# ---------------------------------------------------------------------------
# Firmware boot entry (never touches 'Windows Boot Manager')
# ---------------------------------------------------------------------------

firmware_entry() {
  step "Firmware boot entry"
  local label="NixOS ($CLONE)" loader entry order new_order existing
  if ((F_LANZABOOTE)); then
    loader='\EFI\systemd\systemd-bootx64.efi'
  else
    loader='\EFI\BOOT\BOOTX64.EFI'
  fi
  local path=$ROOT/boot/${loader//\\//}
  if ((!DRY_RUN)) && [[ ! -e $path ]]; then
    warn "$path not found after install: not creating a firmware entry (boot via the firmware menu / fallback path)."
    return 0
  fi
  if ((DRY_RUN)); then
    say "+ [dry-run] efibootmgr --create --disk $DISK --part $DP_PLAN_ESP_NUM --label '$label' --loader '$loader'  (then put it first in BootOrder)"
    return 0
  fi
  existing=$(efibootmgr | sed -nE "s/^Boot([0-9A-Fa-f]{4})\*? ${label//[()]/.}.*/\1/p" | head -n1 || true)
  if [[ -n $existing ]]; then
    entry=$existing
    say "Boot entry for '$label' exists (Boot$entry), only reordering."
  else
    dp_run efibootmgr --create --disk "$DISK" --part "$DP_PLAN_ESP_NUM" --label "$label" --loader "$loader" >/dev/null
    entry=$(efibootmgr | sed -nE "s/^Boot([0-9A-Fa-f]{4})\*? ${label//[()]/.}.*/\1/p" | head -n1)
    [[ -n $entry ]] || {
      warn "could not find the new boot entry; pick the NixOS entry in the firmware menu"
      return 0
    }
  fi
  order=$(efibootmgr | sed -nE 's/^BootOrder: *//p')
  new_order=$entry
  local o
  IFS=',' read -ra _ord <<<"$order"
  for o in "${_ord[@]}"; do
    [[ -n $o && $o != "$entry" ]] && new_order+=",$o"
  done
  dp_run efibootmgr --bootorder "$new_order" >/dev/null
  say "BootOrder: $new_order (Windows Boot Manager left untouched)"
}

# ---------------------------------------------------------------------------
# Repository on the target (~/nix of the user)
# ---------------------------------------------------------------------------

place_repo() {
  step "Repository on the target"
  local dest=$ROOT/home/$F_USER/nix
  if ((DRY_RUN)); then
    say "+ [dry-run] cp -a $SRC -> $dest; origin = $REPO_URL; git fetch --unshallow; chown -R $F_UID:$F_GID"
    return 0
  fi
  if [[ -e $dest ]]; then
    warn "$dest already exists: leaving it alone (the repository is not copied)."
    return 0
  fi
  if ! cp -a "$SRC" "$dest"; then
    warn "could not copy the repository to $dest: clone it manually after the first boot."
    rm -rf "$dest"
    return 0
  fi
  # The flake lives in the user's clone from now on: its origin is the public URL.
  git -C "$dest" remote set-url origin "$REPO_URL" || warn "could not set origin to $REPO_URL"
  if [[ $(git -C "$dest" rev-parse --is-shallow-repository 2>/dev/null) == true ]]; then
    say "Fetching the full history (git fetch --unshallow) ..."
    if ! GIT_TERMINAL_PROMPT=0 timeout 900 git -C "$dest" fetch --quiet --unshallow; then
      warn "git fetch --unshallow failed; the clone stays shallow. Run 'git fetch --unshallow' in ~/nix when online."
    fi
  fi
  chown -R "$F_UID:$F_GID" "$dest"
}

# ---------------------------------------------------------------------------
# Final checklist
# ---------------------------------------------------------------------------

final_checklist() {
  step "Done: final steps"
  cat <<EOF
Installed $CLONE on $DISK.

 1. Reboot, remove the USB stick, enter the firmware setup (BIOS).
EOF
  if ((F_LANZABOOTE)); then
    if ((SB_SETUP_MODE)); then
      echo " 2. Turn Secure Boot ON in the firmware. The keys are already enrolled."
    else
      cat <<EOF
 2. The firmware was NOT in Setup Mode, so the keys are created but not enrolled. Manually:
      - in the firmware, clear/delete the Secure Boot keys (Custom mode, "Delete all vars") to enter Setup Mode,
      - boot $CLONE, run:  sudo sbctl enroll-keys ${INSTALLER_SBCTL_ENROLL_ARGS:---microsoft}
      - then turn Secure Boot ON in the firmware.
EOF
    fi
  else
    echo " 2. (No lanzaboote on this host: Secure Boot setup does not apply.)"
  fi
  cat <<EOF
 3. Check the system is on the tailnet:  tailscale status   (name: $F_HOSTNAME)
EOF
  if ((F_LUKS)); then
    echo " 4. TPM auto-unlock (laptop): after Secure Boot is ON, enroll the TPM, see Documentation/installation/."
  else
    echo " 4. (No LUKS on this host: no TPM step.)"
  fi
  cat <<EOF
 5. The Windows boot entry was not changed; select it in the firmware boot menu if needed.
 6. Retiring the old machine or promoting this clone to the original name:
    see Documentation/installation/ (install, Secure Boot, retire/sell, promote).
EOF
}

# ---------------------------------------------------------------------------

ROOT=${INSTALLER_ROOT:-/mnt}

main() {
  parse_args "$@"
  guard_environment
  need_tools nix jq git sfdisk sgdisk blkid lsblk findmnt age tar sops ssh-to-age tailscale tailscaled \
    sbctl efibootmgr nixos-install mkfs.vfat mkfs.btrfs btrfs cryptsetup curl
  init_workdir
  step "Source"
  prepare_source
  step "Selection"
  choose_host
  choose_variant
  say "Evaluating $CLONE from $FLAKE ..."
  load_facts "$CLONE"
  check_same_name_promoted
  require_uefi
  secure_boot_gate
  choose_disk
  choose_mode
  confirm_plan
  step "Bundle and secrets"
  find_bundle
  decrypt_bundle
  decrypt_secrets
  tailscale_join
  if ((F_LUKS)) && ((!DRY_RUN)); then
    while :; do
      ask_secret "New LUKS passphrase for the disk:"
      LUKS_PASS=$REPLY
      ask_secret "Repeat LUKS passphrase:"
      [[ $REPLY == "$LUKS_PASS" && -n $LUKS_PASS ]] && break
      warn "passphrases differ or are empty"
    done
  fi
  step "Partition, format, mount"
  apply_partition || die "partitioning failed: $DP_REASON"
  apply_format_mount "$ROOT" "$LUKS_PASS" || die "format/mount failed: $DP_REASON"
  LUKS_PASS=""
  place_keys
  secure_boot_create_keys
  run_nixos_install
  secure_boot_enroll
  tailscale_save_state
  firmware_entry
  place_repo
  final_checklist
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
