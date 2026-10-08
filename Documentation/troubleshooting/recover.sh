#!/usr/bin/env bash
# NixOS emergency recovery: rebuild the system and reinstall the bootloader
# from a live USB. Meant for the "GRUB doesn't come up at all" case - if GRUB
# still shows its menu, just pick an older generation there instead.
#
# Everything is detected from the disk itself, so it works for any host:
# encrypted or not, tmpfs root (impermanence) or not, dual boot or not.
#
#   1. checks the live USB has internet (offers nmtui if not)
#   2. unlocks LUKS partitions, if there are any (passphrase typed by you)
#   3. finds the NixOS install by looking for a Nix store on every disk, and
#      reads its fstab + hostname from the newest generation on that disk
#   4. mounts it under /mnt exactly like that fstab says
#   5. on-disk flake repo: stashes uncommitted changes, checks out the branch
#      and fast-forwards it from the clone this script was run from
#   6. chroots in and runs `nixos-rebuild boot --install-bootloader`
#   7. unmounts, closes LUKS, offers to reboot
#
# Usage, on the live USB:
#   nix-shell -p git                      # if git is missing
#   git clone https://github.com/nicolkrit999/nix && cd nix
#   ./Documentation/troubleshooting/recover.sh [HOSTNAME] [options]
#
# HOSTNAME defaults to the hostname of the system found on disk.
#
# Options:
#   -y, --yes        accept every default answer (LUKS passphrases are still asked)
#   --keep-changes   build WITH the on-disk repo's uncommitted changes (git add -A)
#                    instead of stashing them; skips the branch update
#   --branch NAME    branch to build (default: main)
#   --flake PATH     flake dir as seen from the installed system, e.g. /home/krit/nix
#                    (default: auto-detected)
#   --skip-mount     you already mounted everything under /mnt by hand
#   --shell          mount everything, then open a shell in the chroot instead
#                    of rebuilding
#   -h, --help       show this help

set -Eeuo pipefail

MNT=${MNT:-/mnt}
BRANCH=main
HOST=""
ASSUME_YES=0
KEEP_CHANGES=0
SKIP_MOUNT=0
SHELL_ONLY=0
FLAKE_IN_TARGET=""

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2
  exit 1
}

# ask "question" [y|n] - the second argument is the default (Enter / --yes)
ask() {
  local q=$1 def=${2:-y} reply hint="[Y/n]"
  [[ $def == n ]] && hint="[y/N]"
  if ((ASSUME_YES)); then
    [[ $def == y ]]
    return
  fi
  read -r -p "    $q $hint " reply </dev/tty || reply=""
  reply=${reply:-$def}
  [[ $reply == [yY]* ]]
}

# choose "prompt" item... - prints the 0-based index of the picked item
choose() {
  local prompt=$1 i reply
  shift
  for ((i = 1; i <= $#; i++)); do printf '     %d) %s\n' "$i" "${!i}" >&2; done
  while :; do
    read -r -p "    $prompt [1-$#]: " reply </dev/tty
    if [[ $reply =~ ^[0-9]+$ ]] && ((reply >= 1 && reply <= $#)); then
      echo $((reply - 1))
      return
    fi
  done
}

ORIG_ARGS=("$@")
while (($#)); do
  case $1 in
  -y | --yes) ASSUME_YES=1 ;;
  --keep-changes) KEEP_CHANGES=1 ;;
  --branch)
    BRANCH=${2:?--branch needs a value}
    shift
    ;;
  --flake)
    FLAKE_IN_TARGET=${2:?--flake needs a value}
    shift
    ;;
  --skip-mount) SKIP_MOUNT=1 ;;
  --shell) SHELL_ONLY=1 ;;
  -h | --help)
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
    exit 0
    ;;
  -*) die "Unknown option: $1 (see --help)" ;;
  *)
    [[ -z $HOST ]] || die "Only one hostname can be given"
    HOST=$1
    ;;
  esac
  shift
done

SCRIPT_PATH=$(realpath "$0")

if ((EUID != 0)); then
  exec sudo env "PATH=$PATH" ${NIX_PATH:+"NIX_PATH=$NIX_PATH"} "$SCRIPT_PATH" "${ORIG_ARGS[@]}"
fi

WORK=$(mktemp -d /tmp/recover.XXXXXX)
SCAN=$WORK/scan
OPENED_LUKS=()
ACTIVATED_LVM=0
BOUND_FLAKE=0
STASHED=0
SCRIPT_REPO=""

on_exit() {
  umount "$SCAN" 2>/dev/null || true
  # --one-file-system: never descend into something that is still mounted
  rm -rf --one-file-system "$WORK" 2>/dev/null || true
}
trap on_exit EXIT
trap 'warn "Failed at line $LINENO: $BASH_COMMAND"; warn "Anything already mounted is left at $MNT - just run the script again to start over."' ERR

# ---------------------------------------------------------------- network ---

net_ok() {
  getent hosts cache.nixos.org >/dev/null 2>&1 || return 1
  if command -v curl >/dev/null; then
    curl -fsS -m 10 -o /dev/null https://cache.nixos.org/nix-cache-info 2>/dev/null || return 1
  fi
}

ensure_network() {
  info "Checking internet access"
  while ! net_ok; do
    warn "No internet - the rebuild downloads from cache.nixos.org, so it's needed."
    if command -v nmtui >/dev/null && ask "Open nmtui to connect? (Wi-Fi: 'Activate a connection')" y; then
      nmtui </dev/tty >/dev/tty || true
    else
      warn "Connect in another terminal (no NetworkManager? use wpa_cli), then press Enter."
      read -r </dev/tty || true
    fi
  done
  ok "Internet works"
}

ensure_git() {
  command -v git >/dev/null && return
  if [[ -z ${RECOVER_IN_NIX_SHELL:-} ]] && command -v nix-shell >/dev/null; then
    info "git is missing - re-running inside 'nix-shell -p git'"
    export RECOVER_IN_NIX_SHELL=1
    exec nix-shell -p git --run "$(printf '%q ' "$SCRIPT_PATH" "${ORIG_ARGS[@]}")"
  fi
  die "git is required (try: nix-shell -p git)"
}

# ----------------------------------------------------------------- unlock ---

# Every block device with its filesystem type, probed straight from the disk
# (lsblk's FSTYPE comes from udev, which can lag right after cryptsetup open)
list_devices() {
  local dev
  for dev in $(lsblk -rpno NAME); do
    printf '%s %s\n' "$dev" "$(blkid -p -s TYPE -o value "$dev" 2>/dev/null || true)"
  done
}

unlock_disks() {
  local dev name size label luks=()
  info "Looking for encrypted partitions"
  mapfile -t luks < <(list_devices | awk '$2 == "crypto_LUKS" { print $1 }')
  if ((${#luks[@]} == 0)); then
    ok "None - nothing to unlock"
  fi
  for dev in "${luks[@]}"; do
    if [[ $(lsblk -rno TYPE "$dev") == *crypt* ]]; then
      ok "$dev is already unlocked"
      continue
    fi
    size=$(lsblk -dno SIZE "$dev" | tr -d ' ')
    label=$(lsblk -dno PARTLABEL "$dev" | tr -d ' ')
    ask "Unlock $dev ($size${label:+, partition \"$label\"})?" y || continue
    # disko names the root container "cryptroot"; fix_mapper_names() renames
    # it later if the installed system's fstab expects a different name.
    name=cryptroot
    [[ -e /dev/mapper/$name ]] && name="crypt-${dev##*/}"
    until cryptsetup open "$dev" "$name" </dev/tty; do
      ask "Unlocking failed. Try again?" y || continue 2
    done
    OPENED_LUKS+=("$name")
    ok "Unlocked $dev as /dev/mapper/$name"
  done
  udevadm settle 2>/dev/null || true

  if command -v vgchange >/dev/null && [[ $(list_devices) == *LVM2_member* ]]; then
    vgchange -ay >/dev/null && ACTIVATED_LVM=1
    ok "Activated LVM volume groups"
    udevadm settle 2>/dev/null || true
  fi
  if command -v btrfs >/dev/null; then btrfs device scan >/dev/null 2>&1 || true; fi
}

# ------------------------------------------------------------------- find ---

# Reads a file out of a generation of the system profile, from a Nix store
# that sits at host path $1 (the directory that gets mounted at /nix).
# Everything in a store is an absolute /nix/store/... symlink, so we bind that
# store over /nix in a private mount namespace and resolve paths there. Only
# bash builtins run after the bind: any external binary would come from the
# live USB's store, which the bind just hid.
read_gen_file() { # nixdir generation-link relative-path
  # shellcheck disable=SC2016 # expanded by the inner bash
  unshare --mount --propagation private bash -c '
    mount --bind "$1" /nix 2>/dev/null || exit 3
    f=/nix/var/nix/profiles/$2/$3
    [[ -f $f && -r $f ]] || exit 2
    printf "%s\n" "$(< "$f")"' _ "$@"
}

# inspect nixdir -> sets INS_GEN INS_HOST INS_DATE INS_EPOCH, writes $WORK/fstab.tmp
# Uses the newest generation that has a readable fstab.
inspect() {
  local nixdir=$1 gen gens=()
  INS_GEN="" INS_HOST="" INS_DATE="" INS_EPOCH=0
  mapfile -t gens < <(
    shopt -s nullglob
    for g in "$nixdir"/var/nix/profiles/system-*-link; do echo "${g##*/}"; done | sort -t- -k2,2nr
  )
  for gen in "${gens[@]}"; do
    read_gen_file "$nixdir" "$gen" etc/fstab >"$WORK/fstab.tmp" 2>/dev/null || continue
    INS_GEN=$gen
    INS_HOST=$(read_gen_file "$nixdir" "$gen" etc/hostname 2>/dev/null || true)
    INS_DATE=$(stat -c %y "$nixdir/var/nix/profiles/$gen" | cut -d. -f1)
    INS_EPOCH=$(stat -c %Y "$nixdir/var/nix/profiles/$gen")
    return 0
  done
  return 1
}

has_generations() { compgen -G "$1/var/nix/profiles/system-*-link" >/dev/null; }

CAND_DESC=()
CAND_HOST=()
STORE_WITHOUT_FSTAB=0

find_installs() {
  local dev fstype uuid sv d seen="" svs best best_epoch best_host
  info "Looking for NixOS installations"
  mkdir -p "$SCAN"
  while read -r dev fstype; do
    case $fstype in btrfs | ext4 | ext3 | ext2 | xfs | f2fs) ;; *) continue ;; esac
    # Mounted already = in use by the live system itself
    [[ -z $(findmnt -rno TARGET -S "$dev" 2>/dev/null) ]] || continue
    # A multi-device btrfs shows up once per device
    uuid=$(lsblk -dno UUID "$dev" 2>/dev/null || true)
    if [[ -n $uuid ]]; then
      [[ " $seen " == *" $uuid "* ]] && continue
      seen+=" $uuid"
    fi

    svs=("")
    if [[ $fstype == btrfs ]]; then
      mount -o ro,subvolid=5 "$dev" "$SCAN" 2>/dev/null || continue
      mapfile -t -O 1 svs < <(btrfs subvolume list "$SCAN" 2>/dev/null | sed 's/.* path //')
    else
      mount -o ro "$dev" "$SCAN" 2>/dev/null || continue
    fi

    # Several subvolumes can hold a store (a leftover pre-impermanence root,
    # snapshots...): keep the one with the newest generation.
    best="" best_epoch=-1
    for sv in "${svs[@]}"; do
      d=$SCAN${sv:+/$sv}
      if [[ -d $d/store ]] && has_generations "$d"; then
        : # this is what gets mounted at /nix
      elif has_generations "$d/nix"; then
        d=$d/nix # a root filesystem with /nix inside it
      else
        continue
      fi
      if ! inspect "$d"; then
        STORE_WITHOUT_FSTAB=1
        continue
      fi
      if ((INS_EPOCH > best_epoch)); then
        best_epoch=$INS_EPOCH
        best="$dev${sv:+ (subvolume $sv)}: host '${INS_HOST:-unknown}', $INS_GEN built $INS_DATE"
        cp "$WORK/fstab.tmp" "$WORK/fstab.best"
        best_host=$INS_HOST
      fi
    done
    umount "$SCAN"

    if [[ -n $best ]]; then
      CAND_DESC+=("$best")
      CAND_HOST+=("$best_host")
      mv "$WORK/fstab.best" "$WORK/fstab.${#CAND_DESC[@]}"
    fi
  done < <(list_devices)
}

# ------------------------------------------------------------------ mount ---

# If the installed system expects /dev/mapper/<x> but we opened the container
# under another name, rename it so the fstab devices resolve.
fix_mapper_names() {
  local fstab=$1 dev missing=()
  while read -r dev; do
    [[ -e $dev ]] || missing+=("${dev#/dev/mapper/}")
  done < <(awk '!/^[[:space:]]*#/ && $1 ~ /^\/dev\/mapper\// { print $1 }' "$fstab" | sort -u)
  ((${#missing[@]})) || return 0
  if ((${#missing[@]} == 1 && ${#OPENED_LUKS[@]} == 1)) &&
    ! grep -q "^/dev/mapper/${OPENED_LUKS[0]}[[:space:]]" "$fstab"; then
    dmsetup rename "${OPENED_LUKS[0]}" "${missing[0]}"
    ok "Renamed /dev/mapper/${OPENED_LUKS[0]} to /dev/mapper/${missing[0]} (the name the system expects)"
    OPENED_LUKS=("${missing[0]}")
    udevadm settle 2>/dev/null || true
  else
    warn "fstab expects ${missing[*]/#//dev/mapper/}, which doesn't exist - those mounts may fail"
  fi
}

mount_from_fstab() {
  local fstab=$1 dev mp fs opts target o kept parts
  info "Mounting the system under $MNT (from its own fstab)"
  # Shallowest mount points first, so / comes before /home, /home before /home/x
  while IFS=$'\t' read -r _ dev mp fs opts; do
    dev=${dev//\\040/ } mp=${mp//\\040/ }
    [[ $fs == swap || $mp == none ]] && continue
    if [[ ,$opts, == *,noauto,* ]]; then
      ok "skipped $mp (noauto)"
      continue
    fi
    # impermanence bind mounts etc.: not needed to rebuild, and skipping them
    # keeps the chroot from writing into persisted state
    [[ ,$opts, == *,bind,* || ,$opts, == *,rbind,* ]] && continue
    case $fs in
    btrfs | ext4 | ext3 | ext2 | xfs | f2fs) ;;
    tmpfs) [[ $mp == / ]] || continue ;;
    vfat)
      if [[ $mp != /boot* && $mp != /efi* ]]; then
        ok "skipped $mp (vfat, not the boot partition)"
        continue
      fi
      ;;
    *)
      ok "skipped $mp ($fs, not needed to rebuild)"
      continue
      ;;
    esac

    # Drop options that only mean something to systemd/the desktop at boot
    kept=()
    IFS=, read -ra parts <<<"$opts"
    for o in "${parts[@]}"; do
      case $o in x-* | X-* | comment=* | nofail | auto) ;; *) kept+=("$o") ;; esac
    done
    ((${#kept[@]})) || kept=(defaults)
    opts=$(
      IFS=,
      echo "${kept[*]}"
    )

    target=$MNT${mp%/}
    mkdir -p "$target"
    if mount -t "$fs" -o "$opts" "$dev" "$target"; then
      ok "$mp  ←  $dev ($fs, $opts)"
    else
      case $mp in
      / | /nix | /boot | /boot/* | /efi) die "Could not mount $mp - can't continue" ;;
      *) warn "Could not mount $mp - continuing without it" ;;
      esac
    fi
  done < <(awk -F'[ \t]+' '!/^[[:space:]]*#/ && NF >= 3 {
             d = ($2 == "/") ? 0 : gsub("/", "/", $2)
             print d "\t" $1 "\t" $2 "\t" $3 "\t" (NF >= 4 ? $4 : "defaults")
           }' "$fstab" | sort -s -n -k1,1)

  findmnt -M "$MNT/boot" >/dev/null 2>&1 || warn "Nothing mounted at /boot - the bootloader may end up in the wrong place"
  # nixos-enter refuses a root without /etc/NIXOS, and a tmpfs root starts empty
  if [[ ! -e $MNT/etc/NIXOS ]]; then
    mkdir -p "$MNT/etc"
    touch "$MNT/etc/NIXOS"
  fi
}

# ------------------------------------------------------------------ flake ---

find_flake() {
  local c cands=() matching=() i
  if [[ -n $FLAKE_IN_TARGET ]]; then
    [[ -f $MNT$FLAKE_IN_TARGET/flake.nix ]] || die "No flake.nix at $FLAKE_IN_TARGET on the installed system"
    return
  fi
  for c in "$MNT"/home/*/{nix,nixos,nix-config,dotfiles,.dotfiles,.config/nixos} "$MNT"/etc/nixos "$MNT"/persist/etc/nixos; do
    [[ -f $c/flake.nix ]] && cands+=("${c#"$MNT"}")
  done
  # Prefer flakes that mention this host
  for c in "${cands[@]}"; do
    if [[ -d $MNT$c/hosts/$HOST ]] || grep -rqsF --include='*.nix' "\"$HOST\"" "$MNT$c"; then
      matching+=("$c")
    fi
  done
  ((${#matching[@]})) && cands=("${matching[@]}")

  case ${#cands[@]} in
  0)
    if [[ -n $SCRIPT_REPO && -f $SCRIPT_REPO/flake.nix ]]; then
      warn "No flake found on the installed system - using the live USB clone ($SCRIPT_REPO)"
      mkdir -p "$MNT/recover-flake"
      mount --bind "$SCRIPT_REPO" "$MNT/recover-flake"
      BOUND_FLAKE=1
      FLAKE_IN_TARGET=/recover-flake
    else
      die "No flake found on the installed system. Pass it with --flake /home/<user>/<dir>"
    fi
    ;;
  1) FLAKE_IN_TARGET=${cands[0]} ;;
  *)
    i=$(choose "Which flake should be built?" "${cands[@]}")
    FLAKE_IN_TARGET=${cands[i]}
    ;;
  esac
}

# Brings the on-disk repo to the latest committed $BRANCH. git runs as root
# (with safe.directory so it accepts a repo owned by someone else), then the
# repo is chowned back to its owner so nothing root-owned is left behind.
update_repo() {
  local repo=$MNT$FLAKE_IN_TARGET owner src="" ref
  ((BOUND_FLAKE)) && return 0
  if [[ ! -d $repo/.git ]]; then
    warn "$FLAKE_IN_TARGET is not a git repo - building it as it is"
    return 0
  fi
  owner=$(stat -c %u:%g "$repo")
  g() { git -c safe.directory='*' -c user.name=recover.sh -c user.email=recover@localhost -C "$repo" "$@"; }

  info "Preparing $FLAKE_IN_TARGET"
  if ((KEEP_CHANGES)); then
    g add -A
    ok "Staged all local changes so the flake sees them (--keep-changes, no update)"
  else
    if [[ -n $(g status --porcelain) ]]; then
      g stash push -u -m "recover.sh $(date '+%F %T')"
      STASHED=1
      ok "Stashed uncommitted changes (get them back later with: git stash pop)"
    fi
    if [[ $(g symbolic-ref --short -q HEAD || true) != "$BRANCH" ]]; then
      g checkout -q "$BRANCH"
      ok "Checked out $BRANCH"
    fi
    # The clone this script runs from was just made, so it's the newest
    # state - and fetching from it needs no credentials. origin is the fallback.
    if [[ -n $SCRIPT_REPO && $(realpath "$SCRIPT_REPO") != $(realpath "$repo") ]]; then
      for ref in "refs/heads/$BRANCH" "refs/remotes/origin/$BRANCH"; do
        if g fetch -q "$SCRIPT_REPO" "$ref" 2>/dev/null; then
          src="the live USB clone"
          break
        fi
      done
    fi
    if [[ -z $src ]] && g fetch -q origin "$BRANCH"; then src=origin; fi
    if [[ -z $src ]]; then
      warn "Could not fetch $BRANCH - building the on-disk $BRANCH as it is"
    elif g merge -q --ff-only FETCH_HEAD 2>/dev/null; then
      ok "$BRANCH is at $(g log -1 --format='%h %s') (up to date with $src)"
    else
      warn "On-disk $BRANCH has commits that aren't in $src - building the on-disk $BRANCH as it is"
    fi
  fi
  chown -R -h "$owner" "$repo"
}

check_host_in_flake() {
  local hosts=$MNT$FLAKE_IN_TARGET/hosts
  [[ -d $hosts ]] || return 0
  if [[ ! -d $hosts/$HOST ]]; then
    # shellcheck disable=SC2012
    die "The flake has no hosts/$HOST. Available: $(cd "$hosts" && ls -d -- */ | tr -d / | tr '\n' ' ')"
  fi
}

# ---------------------------------------------------------------- rebuild ---

# Runs inside the chroot. FLAKE, HOST and EXTRA are prepended by run_rebuild.
# shellcheck disable=SC2016
CHROOT_SCRIPT='
set -e
export PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$PATH
# The flake repo belongs to a normal user; let root-run git (and anything nix
# shells out to) accept it.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="*"

# Hosts with boot.binfmt list /run/binfmt in extra-sandbox-paths; every
# sandboxed build fails if it does not exist.
mkdir -p /run/binfmt

# nixos-enter already binds the live USB resolv.conf in, which is enough
# normally. Only if that still fails, force public DNS - via a bind mount in
# this private namespace, so nothing is written to the disk.
if command -v getent >/dev/null 2>&1 && ! getent hosts cache.nixos.org >/dev/null 2>&1; then
  echo "-> DNS does not work inside the chroot; using 1.1.1.1 / 9.9.9.9 for this run"
  printf "nameserver 1.1.1.1\nnameserver 9.9.9.9\n" >/dev/shm/recover-resolv.conf
  t=$(readlink -f /etc/resolv.conf || echo /etc/resolv.conf)
  mkdir -p "$(dirname "$t")"
  [ -e "$t" ] || : >"$t"
  mount --bind /dev/shm/recover-resolv.conf "$t"
fi

echo "-> nixos-rebuild boot --install-bootloader --flake $FLAKE#$HOST ${EXTRA[*]}"
nixos-rebuild boot --install-bootloader --flake "$FLAKE#$HOST" "${EXTRA[@]}"
'

run_rebuild() { # extra nixos-rebuild args...
  local extra=""
  (($#)) && extra=$(printf '%q ' "$@")
  nixos-enter --root "$MNT" -c "FLAKE=$(printf %q "$FLAKE_IN_TARGET"); HOST=$(printf %q "$HOST"); EXTRA=($extra)
$CHROOT_SCRIPT"
}

# ---------------------------------------------------------------- cleanup ---

cleanup() {
  local n
  info "Unmounting $MNT"
  sync
  if ((BOUND_FLAKE)); then
    umount "$MNT/recover-flake" && rmdir "$MNT/recover-flake" || true
  fi
  if ! umount -R "$MNT" 2>/dev/null; then
    warn "Something is still busy - detaching lazily"
    umount -R -l "$MNT" || true
  fi
  if ((ACTIVATED_LVM)); then vgchange -an >/dev/null 2>&1 || true; fi
  for n in "${OPENED_LUKS[@]}"; do
    cryptsetup close "$n" || warn "Could not close /dev/mapper/$n (harmless, reboot takes care of it)"
  done
  ok "Disks released"
}

# ------------------------------------------------------------------- main ---

ensure_network
ensure_git
SCRIPT_REPO=$(git -c safe.directory='*' -C "$(dirname "$SCRIPT_PATH")" rev-parse --show-toplevel 2>/dev/null || true)

DETECTED_HOST=""
if ((SKIP_MOUNT)); then
  findmnt -M "$MNT" >/dev/null || die "--skip-mount given, but nothing is mounted at $MNT"
  inspect "$MNT/nix" && DETECTED_HOST=$INS_HOST
  [[ -e $MNT/etc/NIXOS ]] || { mkdir -p "$MNT/etc" && touch "$MNT/etc/NIXOS"; }
else
  # Leftovers from an earlier run
  if findmnt -M "$MNT" >/dev/null || [[ -n $(findmnt -rno TARGET | grep "^$MNT/" || true) ]]; then
    info "Unmounting leftovers from a previous run at $MNT"
    umount -R "$MNT" 2>/dev/null || umount -R -l "$MNT"
  fi

  unlock_disks
  find_installs
  case ${#CAND_DESC[@]} in
  0)
    if ((STORE_WITHOUT_FSTAB)); then
      die "Found a Nix store but no generation with a readable fstab. Mount by hand under $MNT and re-run with --skip-mount."
    fi
    die "No NixOS installation found. Encrypted disk not unlocked? Check with: lsblk -f"
    ;;
  1) idx=0 ;;
  *)
    warn "More than one NixOS installation found."
    idx=$(choose "Which one should be repaired?" "${CAND_DESC[@]}")
    ;;
  esac
  ok "Found ${CAND_DESC[idx]}"
  DETECTED_HOST=${CAND_HOST[idx]}
  FSTAB=$WORK/fstab.$((idx + 1))
  fix_mapper_names "$FSTAB"
  mount_from_fstab "$FSTAB"
fi

if [[ -z $HOST ]]; then
  HOST=$DETECTED_HOST
  [[ -n $HOST ]] || die "Couldn't detect the hostname - pass it: $(basename "$0") <hostname>"
elif [[ -n $DETECTED_HOST && $HOST != "$DETECTED_HOST" ]]; then
  warn "You asked for '$HOST', but the system on disk calls itself '$DETECTED_HOST'."
  ask "Build '$HOST' anyway?" n || die "Stopped. Re-run without a hostname to use '$DETECTED_HOST'."
fi

find_flake

if ((SHELL_ONLY)); then
  info "Opening a shell in the chroot (flake: $FLAKE_IN_TARGET, host: $HOST). Type 'exit' when done."
  nixos-enter --root "$MNT" || true
  if ask "Unmount everything now?" y; then cleanup; fi
  exit 0
fi

# Nothing gets updated in these cases, so a wrong hostname can be caught now
if ((BOUND_FLAKE || KEEP_CHANGES)); then check_host_in_flake; fi

echo
info "Ready to repair"
echo "      host:    $HOST"
echo "      flake:   $FLAKE_IN_TARGET"
if ((BOUND_FLAKE)); then
  echo "      git:     (using the live USB clone as is)"
elif ((KEEP_CHANGES)); then
  echo "      git:     build including uncommitted changes"
else
  echo "      git:     stash uncommitted changes (if any), check out + fast-forward $BRANCH"
fi
echo "      run:     nixos-rebuild boot --install-bootloader --flake $FLAKE_IN_TARGET#$HOST"
echo "      mounted:"
findmnt -R "$MNT" -no TARGET,SOURCE,FSTYPE | sed 's/^/        /'
echo
ask "Go ahead?" y || {
  info "Stopped. Everything is still mounted at $MNT - re-run the script or: umount -R $MNT"
  exit 0
}

update_repo
check_host_in_flake

info "Rebuilding inside the chroot (errors from 'setting up /etc', sops or systemd while entering are normal)"
extra=()
until run_rebuild "${extra[@]}"; do
  warn "The rebuild failed - see the output above."
  case $(choose "What now?" \
    "retry with the Nix sandbox off (fixes sandbox/namespace errors inside a chroot)" \
    "retry as is" \
    "open a shell in the chroot to fix it by hand (exit to come back here)" \
    "stop here (everything stays mounted)") in
  0) extra=(--option sandbox false) ;;
  1) ;;
  2) nixos-enter --root "$MNT" || true ;;
  3) exit 1 ;;
  esac
done
ok "System rebuilt and GRUB reinstalled"
if ((STASHED)); then warn "Your uncommitted changes are in 'git stash list' in $FLAKE_IN_TARGET"; fi

cleanup
echo
info "Done. Remove the USB stick while the machine restarts (or it may boot the USB again)."
if ask "Reboot now?" y; then systemctl reboot; fi
