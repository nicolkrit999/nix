#!/usr/bin/env bash
# NixOS emergency recovery: rebuild the system and reinstall the bootloader
# (GRUB or lanzaboote / systemd-boot) from a live USB. Meant for the "the
# bootloader doesn't come up at all" case - if the boot menu (GRUB, or the
# systemd-boot menu of a lanzaboote host) still shows, just pick an older
# generation there instead.
#
# Everything is detected from the disk itself, so it works for any host:
# encrypted or not, tmpfs root (impermanence) or not, dual boot or not,
# GRUB or lanzaboote (Secure Boot).
#
#   1. checks the live USB has internet (offers nmtui if not)
#   2. unlocks LUKS partitions, if there are any (passphrase typed by you)
#   3. finds the NixOS install by looking for a Nix store on every disk, and
#      reads its fstab + hostname from the newest generation on that disk
#   4. mounts it under /mnt exactly like that fstab says
#   5. on-disk flake repo: stashes uncommitted changes, checks out the branch
#      and fast-forwards it from the clone this script was run from
#   6. decides the target bootloader (grub | lanzaboote | other): from the
#      flake being built (nix eval in the chroot), else from the files on the
#      disk. lanzaboote only: checks the Secure Boot signing keys are there
#      (never creates or writes keys without your typed confirmation)
#   7. chroots in and runs `nixos-rebuild boot --install-bootloader`
#   8. GRUB: replaces stale GRUB copies on the boot partition that the
#      firmware may still start (old GRUB + new modules = "symbol ... not
#      found"). lanzaboote: runs `sbctl verify`, and offers the exact
#      `efibootmgr -c` command if the firmware has lost its NixOS entry
#   9. unmounts, closes LUKS, offers to reboot
#
# lanzaboote hosts: switch Secure Boot OFF in the firmware setup before
# booting the live USB (a stock ISO is not signed with your keys) and turn it
# back ON afterwards. The keys stay enrolled in the firmware, the script
# touches neither firmware keys nor the Secure Boot setting.
#
# Full walkthrough (making the USB, every prompt, what to do after):
#   Documentation/troubleshooting/README.md
#
# Usage, on the live USB:
#   nix-shell -p git                      # if git is missing
#   git clone https://github.com/nicolkrit999/nix && cd nix
#   ./Documentation/troubleshooting/recover.sh [HOSTNAME] [options]
#
# HOSTNAME defaults to the hostname of the system found on disk.
#
# Options:
#   -y, --yes        accept every default answer (LUKS passphrases are still
#                    asked; a missing lanzaboote signing key always stops)
#   --keep-changes   build WITH the on-disk repo's uncommitted changes (git add -A)
#                    instead of stashing them; skips the branch update
#   --branch NAME    branch to build (default: main)
#   --flake PATH     flake dir as seen from the installed system, e.g. /home/krit/nix
#                    (default: auto-detected)
#   --skip-mount     you already mounted everything under /mnt by hand
#   --shell          mount everything, then open a shell in the chroot instead
#                    of rebuilding
#   --grub-only      GRUB hosts only: do just the stale-GRUB-copy fix (no
#                    internet, git or rebuild needed), for "symbol ... not
#                    found" right after a rebuild that worked. On a lanzaboote
#                    host it prints that it does not apply and exits
#   -h, --help       show this help

MNT=${MNT:-/mnt}
BRANCH=main
HOST=""
ASSUME_YES=0
KEEP_CHANGES=0
SKIP_MOUNT=0
SHELL_ONLY=0
GRUB_ONLY=0
FLAKE_IN_TARGET=""
ORIG_ARGS=()
SCRIPT_PATH=""
WORK=""
SCAN=""
OPENED_LUKS=()
UNLOCKED_DEVS=()
ACTIVATED_LVM=0
BOUND_FLAKE=0
STASHED=0
SCRIPT_REPO=""

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

on_exit() {
  umount "$SCAN" 2>/dev/null || true
  # --one-file-system: never descend into something that is still mounted
  rm -rf --one-file-system "$WORK" 2>/dev/null || true
}

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
    UNLOCKED_DEVS+=("$dev")
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

# ------------------------------------------------------ stale GRUB copies ---

# grub-install writes the GRUB program twice: <boot>/grub/x86_64-efi/core.efi,
# next to the modules it has to match, and a copy under EFI/ for the firmware
# to start. A firmware entry left over from an earlier install can keep
# starting a different, OLD copy (nixos-laptop: Boot0000 "NixOS-boot" ->
# EFI/NixOS-boot/grubx64.efi, while efiInstallAsRemovable only refreshes
# EFI/BOOT/BOOTX64.EFI). Nothing updates that copy, so on the next GRUB update
# old program + new modules = "symbol ... not found" before the menu shows -
# even though the rebuild itself succeeded. Make NixOS' GRUB images (EFI/BOOT
# and EFI/NixOS*; another distro's GRUB on a shared ESP is left alone)
# identical to core.efi. boot.nix does the same on every normal rebuild.
sync_grub_copies() {
  local fresh=$MNT/boot/grub/x86_64-efi/core.efi esp f rel stale=0
  if [[ ! -f $fresh ]]; then
    ok "No EFI GRUB in /boot/grub - nothing to check"
    return 0
  fi
  info "Checking every GRUB copy the firmware could start"
  for esp in "$MNT/boot" "$MNT/boot/efi" "$MNT/efi"; do
    [[ -d $esp/EFI ]] || continue
    while IFS= read -r -d '' f; do
      # GRUB images only - never Windows' boot manager or systemd-boot
      grep -qaE 'grub_mod_init|grub rescue>' "$f" || continue
      rel=${f#"$MNT"}
      if [[ -n $(find "${f%/*}" -maxdepth 1 -iname 'shim*.efi' -print -quit) ]]; then
        warn "$rel is started through shim (Secure Boot) - not touching it"
        continue
      fi
      if cmp -s "$fresh" "$f"; then
        ok "$rel is current"
      else
        cp "$f" "$f.old"
        cp "$fresh" "$f"
        ok "$rel was an OLD GRUB - replaced (backup next to it: ${f##*/}.old)"
        stale=1
      fi
    done < <(find "$esp/EFI" -mindepth 2 -maxdepth 2 -type f -iname '*.efi' \
      \( -ipath "$esp/EFI/BOOT/*" -o -ipath "$esp/EFI/NixOS*/*" \) -print0 2>/dev/null)
  done
  sync
  if ((stale)); then
    warn "A stale GRUB copy is what makes GRUB fail with 'symbol ... not found'."
  fi
  show_boot_order
}

show_boot_order() {
  local order line
  command -v efibootmgr >/dev/null || return 0
  order=$(efibootmgr 2>/dev/null | sed -n 's/^BootOrder: //p')
  [[ -n $order ]] || return 0
  line=$(efibootmgr -v 2>/dev/null | grep "^Boot${order%%,*}" || true)
  ok "Firmware starts first: ${line:0:150}"
}

# ------------------------------------------------------------- bootloader ---

# Decision about the TARGET bootloader: grub | lanzaboote | other.
# DISK_BL is read from the files on the disk, FLAKE_BL from `nix eval` of the
# flake being built. The flake wins: it is what the rebuild will install.
DISK_BL=""
DISK_BL_WHY=""
FLAKE_BL=""
FLAKE_PKI=""
TARGET_BL=""
TARGET_BL_SRC=""
TARGET_GEN=""
KEYDIR=""
GUIDFILE=""
KEY_SRC=""
KEYS_OK=0
NEW_KEYS_CREATED=0
VERIFY_BAD=()
VERIFY_EXPECTED=()
VERIFY_SIGNED=0
EFIVARS_DIR=${EFIVARS_DIR:-/sys/firmware/efi/efivars}
SYSFS_BLOCK=${SYSFS_BLOCK:-/sys/class/block}
# shellcheck disable=SC2016 # expanded inside the chroot
CHROOT_PATH_PRELUDE='export PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$PATH'

# Runs inside the chroot: FLAKE, HOST and APPLY are prepended by flake_eval_bootloader.
# shellcheck disable=SC2016
EVAL_SCRIPT='
set -e
export PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$PATH
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="*"
nix --extra-experimental-features "nix-command flakes" eval --raw "$FLAKE#nixosConfigurations.\"$HOST\".config.boot" --apply "$APPLY"
'

# Newest generation of the installed system that has a readable fstab (the
# same rule inspect uses). Sets TARGET_GEN.
find_target_gen() {
  local g gens=()
  TARGET_GEN=""
  mapfile -t gens < <(
    shopt -s nullglob
    for g in "$MNT"/nix/var/nix/profiles/system-*-link; do echo "${g##*/}"; done | sort -t- -k2,2nr
  )
  for g in "${gens[@]}"; do
    if read_gen_file "$MNT/nix" "$g" etc/fstab >/dev/null 2>&1; then
      TARGET_GEN=$g
      return 0
    fi
  done
  return 1
}

# installed_gen_file REL: prints REL from the newest generation, fails if absent
installed_gen_file() {
  [[ -n $TARGET_GEN ]] || find_target_gen || return 1
  read_gen_file "$MNT/nix" "$TARGET_GEN" "$1" 2>/dev/null
}

# Mounted boot partitions that hold an EFI directory
esp_dirs() {
  local esp
  for esp in "$MNT/boot" "$MNT/boot/efi" "$MNT/efi"; do
    if [[ -d $esp/EFI ]]; then printf '%s\n' "$esp"; fi
  done
  return 0
}

# The boot partition lanzaboote writes to (first one with stubs or a fallback loader)
main_esp() {
  local esp
  for esp in "$MNT/boot" "$MNT/boot/efi" "$MNT/efi"; do
    if [[ -d $esp/EFI/Linux || -f $esp/EFI/BOOT/BOOTX64.EFI ]]; then
      printf '%s\n' "$esp"
      return 0
    fi
  done
  return 1
}

is_systemd_boot() { [[ -f $1 ]] && grep -qa 'LoaderInfo: systemd-boot' "$1"; }

count_stubs() { (
  shopt -s nullglob
  set -- "$1"/EFI/Linux/nixos-*.efi
  echo $#
); }

# Sets DISK_BL + DISK_BL_WHY from the files on the disk. A hybrid ESP (GRUB
# leftovers next to lanzaboote, before the cleanup phase) counts as lanzaboote:
# only the generation's sbctl.conf or the signed stubs + systemd-boot decide it.
detect_bootloader_disk() {
  local esp stubs=0 sdboot=0 core=0
  DISK_BL=other DISK_BL_WHY="no GRUB and no lanzaboote files found"
  if installed_gen_file etc/sbctl/sbctl.conf >/dev/null; then
    DISK_BL=lanzaboote DISK_BL_WHY="$TARGET_GEN has /etc/sbctl/sbctl.conf"
    return 0
  fi
  while IFS= read -r esp; do
    if compgen -G "$esp/EFI/Linux/nixos-*.efi" >/dev/null; then stubs=1; fi
    if is_systemd_boot "$esp/EFI/BOOT/BOOTX64.EFI"; then sdboot=1; fi
    if [[ -f $esp/grub/x86_64-efi/core.efi ]]; then core=1; fi
  done < <(esp_dirs)
  if [[ -f $MNT/boot/grub/x86_64-efi/core.efi ]]; then core=1; fi
  if ((stubs && sdboot)); then
    DISK_BL=lanzaboote DISK_BL_WHY="signed stubs in EFI/Linux and systemd-boot as EFI/BOOT/BOOTX64.EFI"
  elif ((core)); then
    DISK_BL=grub DISK_BL_WHY="GRUB modules in /boot/grub, no lanzaboote files"
  fi
  return 0
}

# Prints the raw "RECOVER-BL:<lanzaboote|grub|other>:<pkiBundle>" line the
# flake evaluates to; fails soft (the caller falls back to the disk).
flake_eval_bootloader() {
  local apply out
  # shellcheck disable=SC2016 # nix code
  apply='b: "RECOVER-BL:" + (if (b.lanzaboote.enable or false) then "lanzaboote" else if (b.loader.grub.enable or false) then "grub" else "other") + ":" + builtins.toString (b.lanzaboote.pkiBundle or "")'
  if ! out=$(nixos-enter --root "$MNT" -c "FLAKE=$(printf %q "$FLAKE_IN_TARGET"); HOST=$(printf %q "$HOST"); APPLY=$(printf %q "$apply")
$EVAL_SCRIPT" </dev/null 2>"$WORK/bl-eval.err"); then
    tail -n 8 "$WORK/bl-eval.err" >&2 || true
    return 1
  fi
  printf '%s\n' "$out" | grep -o 'RECOVER-BL:[^[:space:]]*' | tail -n 1
}

# parse_bl_line "RECOVER-BL:x:y" -> FLAKE_BL, FLAKE_PKI
parse_bl_line() {
  local line=$1 rest
  [[ $line == RECOVER-BL:* ]] || return 1
  rest=${line#RECOVER-BL:}
  FLAKE_BL=${rest%%:*}
  FLAKE_PKI=${rest#*:}
  case $FLAKE_BL in lanzaboote | grub | other) ;; *) return 1 ;; esac
}

resolve_target_bootloader() {
  local line=""
  FLAKE_BL="" FLAKE_PKI=""
  info "Asking the flake which bootloader it builds (nix eval in the chroot; can take a minute)"
  if line=$(flake_eval_bootloader) && parse_bl_line "$line"; then
    TARGET_BL=$FLAKE_BL TARGET_BL_SRC="the flake ($HOST)"
    if [[ -n $DISK_BL && $DISK_BL != "$TARGET_BL" ]]; then
      warn "The flake builds '$TARGET_BL', the files on the disk look like '$DISK_BL' - following the flake."
    fi
  else
    FLAKE_BL="" FLAKE_PKI=""
    warn "Could not evaluate the flake - falling back to what the disk looks like."
    TARGET_BL=${DISK_BL:-other} TARGET_BL_SRC="the disk (${DISK_BL_WHY:-no evidence})"
  fi
  ok "Target bootloader: $TARGET_BL (from $TARGET_BL_SRC)"
}

# ----------------------------------------------------- lanzaboote: pre-flight ---

# sbctl.conf is two lines of YAML: "keydir: <dir>" and "guid: <file>"
sbctl_conf_value() { sed -n "/^[[:space:]]*$1:/{s/^[[:space:]]*$1:[[:space:]]*//;p;q}" | tr -d "\"'\r" | sed 's/[[:space:]]*$//'; }

# Sets KEYDIR, GUIDFILE (paths as seen from the installed system) and KEY_SRC:
# flake pkiBundle, else the generation's sbctl.conf, else the module default.
resolve_key_paths() {
  local conf kd gf def
  KEYDIR="" GUIDFILE="" KEY_SRC=""
  [[ -n $TARGET_GEN ]] || find_target_gen || true
  if [[ -n $FLAKE_PKI ]]; then
    KEYDIR=$FLAKE_PKI/keys GUIDFILE=$FLAKE_PKI/GUID KEY_SRC="the flake (boot.lanzaboote.pkiBundle)"
    return 0
  fi
  if conf=$(installed_gen_file etc/sbctl/sbctl.conf) &&
    kd=$(printf '%s\n' "$conf" | sbctl_conf_value keydir) && [[ -n $kd ]]; then
    gf=$(printf '%s\n' "$conf" | sbctl_conf_value guid)
    KEYDIR=$kd GUIDFILE=${gf:-${kd%/*}/GUID} KEY_SRC="/etc/sbctl/sbctl.conf of $TARGET_GEN"
    return 0
  fi
  if [[ -d $MNT/persist ]]; then def=/persist/var/lib/sbctl; else def=/var/lib/sbctl; fi
  KEYDIR=$def/keys GUIDFILE=$def/GUID KEY_SRC="default location (the flake and sbctl.conf gave no answer)"
}

# The db key + certificate are what lanzaboote signs with
keys_dir_ok() { compgen -G "$1/db/*.key" >/dev/null && compgen -G "$1/db/*.pem" >/dev/null; }

# Reports on $MNT$KEYDIR; sets KEYS_OK. Creates nothing. If the keys are only
# in /persist (a bind-mounted path such as /var/lib/sbctl on an impermanence
# host) the persisted copy is bind-mounted into place, as the system does at boot.
check_signing_keys() {
  local d sub
  d=$MNT$KEYDIR
  if ! keys_dir_ok "$d" && [[ $KEYDIR != /persist/* ]] && keys_dir_ok "$MNT/persist$KEYDIR"; then
    mkdir -p "$d"
    mount --bind "$MNT/persist$KEYDIR" "$d"
    ok "Keys found in /persist$KEYDIR - bound to $KEYDIR (what impermanence does at boot)"
  fi
  KEYS_OK=0
  if keys_dir_ok "$d"; then KEYS_OK=1; fi
  for sub in db KEK PK; do
    if compgen -G "$d/$sub/*.key" >/dev/null; then
      ok "$KEYDIR/$sub: key present"
    elif [[ $sub == db ]]; then
      warn "$KEYDIR/$sub: MISSING (needed: lanzaboote signs everything with the db key)"
    else
      warn "$KEYDIR/$sub: missing (not needed to build, only to enroll the keys again)"
    fi
  done
  if [[ -f $MNT$GUIDFILE ]]; then
    ok "$GUIDFILE present"
  else
    warn "$GUIDFILE missing (not needed to build)"
  fi
}

esp_free_mb() { df -Pm "$1" 2>/dev/null | awk 'NR == 2 { print $4 }'; }

# 1 = the running (live) system has Secure Boot enforcing, 0 = off, unknown
live_secure_boot() {
  local f=$EFIVARS_DIR/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c v
  [[ -r $f ]] || {
    echo unknown
    return 0
  }
  v=$(od -An -tu1 -j4 -N1 "$f" 2>/dev/null | tr -d ' ')
  if [[ $v == 1 ]]; then echo 1; else echo 0; fi
}

# Runs sbctl in the chroot against the resolved key directory
chroot_sbctl() { # sbctl args...
  local args
  args=$(printf '%q ' "$@")
  nixos-enter --root "$MNT" -c "$CHROOT_PATH_PRELUDE
printf 'keydir: %s\nguid: %s\n' $(printf %q "$KEYDIR") $(printf %q "$GUIDFILE") >/dev/shm/recover-sbctl.conf
sbctl --config /dev/shm/recover-sbctl.conf $args"
}

# choose_def DEFAULT "prompt" item... - like choose, but Enter (and --yes)
# picks the DEFAULT item (1-based); prints the 0-based index
choose_def() {
  local def=$1 prompt=$2 i reply
  shift 2
  if ((ASSUME_YES)); then
    echo $((def - 1))
    return
  fi
  for ((i = 1; i <= $#; i++)); do printf '     %d) %s\n' "$i" "${!i}" >&2; done
  while :; do
    read -r -p "    $prompt [1-$#, Enter = $def]: " reply </dev/tty || reply=""
    reply=${reply:-$def}
    if [[ $reply =~ ^[0-9]+$ ]] && ((reply >= 1 && reply <= $#)); then
      echo $((reply - 1))
      return
    fi
  done
}

# Only when the target is lanzaboote. Never creates or writes keys on its own.
lanza_preflight() {
  local esp free sb typed choice
  info "lanzaboote pre-flight: Secure Boot signing keys"
  resolve_key_paths
  echo "      key directory: $KEYDIR  (from $KEY_SRC)"
  if esp=$(main_esp); then
    free=$(esp_free_mb "$esp")
    if [[ $free =~ ^[0-9]+$ ]] && ((free < 150)); then
      warn "Only ${free} MB free on the boot partition ($esp). One kernel+initrd set needs about 160 MB: free space first (old EFI/Linux/nixos-*.efi, GRUB leftovers) or the install fails half way."
    else
      ok "Boot partition has ${free:-?} MB free"
    fi
  fi
  sb=$(live_secure_boot)
  if [[ $sb == 1 ]]; then
    warn "This live system runs with Secure Boot ENFORCING. It booted, so the ISO is accepted by your firmware keys, but anything you do with the firmware keys from here can lock you out: change nothing in the firmware setup you do not understand."
  fi

  while :; do
    check_signing_keys
    if ((KEYS_OK)); then
      ok "Signing keys found: the lanzaboote install can sign the boot files"
      return 0
    fi
    echo
    warn "The Secure Boot signing key is NOT in $KEYDIR on the installed system."
    warn "Without it the lanzaboote install stops at the first key read, before writing anything to the boot partition (safe, but the rebuild fails)."
    warn "Restore your key archive (password manager) into place, do NOT generate new keys unless you have lost the old ones."
    choice=$(choose_def 1 "What now?" \
      "stop here, everything stays mounted (default; restore the keys, then run the script again)" \
      "open a shell on the live system to restore the key archive into $MNT$KEYDIR, then check again" \
      "continue anyway (the rebuild will fail at the key read)" \
      "create NEW keys with sbctl in the chroot (asks for a typed confirmation)")
    case $choice in
    0)
      info "Stopped. Everything is still mounted at $MNT - re-run the script or: umount -R $MNT"
      exit 1
      ;;
    1)
      if [[ ! -d $MNT${KEYDIR%/*} ]]; then
        mkdir -p "$MNT${KEYDIR%/*}"
        chmod 0700 "$MNT${KEYDIR%/*}"
      fi
      info "Shell on the LIVE system. Put the keys at $MNT$KEYDIR (db/ KEK/ PK/ with .key and .pem files, root only), e.g.: tar -xpf <archive> -C $MNT${KEYDIR%/*}. Type 'exit' to continue."
      (cd "$MNT${KEYDIR%/*}" && bash </dev/tty >/dev/tty 2>&1) || true
      ;;
    2)
      warn "Continuing without keys, as requested."
      return 0
      ;;
    3)
      echo
      warn "NEW KEYS DO NOT MATCH THE KEYS ENROLLED IN THE FIRMWARE."
      warn "The firmware db holds the OLD public key, so what you sign now is rejected with Secure Boot ON."
      warn "You must turn Secure Boot OFF, boot, delete the old keys/enroll the new ones (Phase 2 and 3 of Documentation/usage/secure-boot/lanzaboote.md) and re-seal the TPM."
      warn "Only do this if the old key is really lost. Archive the new directory in the password manager right away."
      read -r -p "    Type CREATE NEW KEYS to confirm (anything else goes back): " typed </dev/tty || typed=""
      if [[ $typed == "CREATE NEW KEYS" ]]; then
        if chroot_sbctl create-keys; then
          NEW_KEYS_CREATED=1
        else
          warn "sbctl create-keys failed - see the output above."
        fi
      fi
      ;;
    esac
  done
}

# ---------------------------------------------------- lanzaboote: after build ---

# summarize_sbctl_verify FILE -> VERIFY_BAD (unsigned but must be signed),
# VERIFY_EXPECTED (unsigned, fine), VERIFY_SIGNED (count)
summarize_sbctl_verify() {
  local line p lp
  VERIFY_BAD=() VERIFY_EXPECTED=() VERIFY_SIGNED=0
  while IFS= read -r line; do
    line=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
    case $line in
    *"is not signed"*)
      p=/${line#*/}
      p=${p%" is not signed"*}
      lp=${p,,}
      case $lp in
      */efi/linux/nixos-*.efi | */efi/boot/boot*.efi | */efi/systemd/systemd-boot*.efi) VERIFY_BAD+=("$p") ;;
      *) VERIFY_EXPECTED+=("$p") ;;
      esac
      ;;
    *"is signed"*) VERIFY_SIGNED=$((VERIFY_SIGNED + 1)) ;;
    esac
  done <"$1"
}

# fw_has_entry PARTUUID: does a firmware boot entry start from that partition?
fw_has_entry() { efibootmgr -v 2>/dev/null | grep -qi "GPT,$1"; }

# Looks for a firmware entry that starts from the NixOS boot partition and, if
# there is none (NVRAM lost), prints and offers the exact efibootmgr command.
fw_entry_check() {
  local esp src puuid disk part cmd
  command -v efibootmgr >/dev/null || {
    warn "efibootmgr is not available - can't check the firmware boot entries"
    return 0
  }
  if [[ ! -d $EFIVARS_DIR ]]; then
    warn "The live system was not booted in UEFI mode - the firmware entries can't be checked or written from here."
    return 0
  fi
  esp=$(main_esp) || return 0
  src=$(findmnt -rno SOURCE -M "$esp" 2>/dev/null || true)
  puuid=""
  [[ -n $src ]] && puuid=$(blkid -s PARTUUID -o value "$src" 2>/dev/null || true)
  if [[ -z $puuid ]]; then
    warn "Can't read the partition UUID of the boot partition ($esp) - firmware entry check skipped"
    return 0
  fi
  if fw_has_entry "$puuid"; then
    ok "The firmware has a boot entry that starts from the NixOS boot partition ($src)"
    return 0
  fi
  warn "No firmware boot entry points at the NixOS boot partition ($src). The NVRAM was probably reset."
  warn "Many firmwares still list the fallback loader EFI/BOOT/BOOTX64.EFI as 'UEFI <disk>' in the F12 menu; if yours doesn't, create the entry:"
  disk=$(lsblk -dno PKNAME "$src" 2>/dev/null || true)
  part=$(cat "$SYSFS_BLOCK/${src##*/}/partition" 2>/dev/null || true)
  if [[ -z $disk || -z $part ]]; then
    warn "Could not work out disk and partition number of $src - create it by hand with efibootmgr -c -d <disk> -p <partition number> -l '\\EFI\\BOOT\\BOOTX64.EFI' -L 'NixOS lanzaboote'"
    return 0
  fi
  cmd=(efibootmgr -c -d "/dev/$disk" -p "$part" -l '\EFI\BOOT\BOOTX64.EFI' -L 'NixOS lanzaboote')
  echo "      efibootmgr -c -d /dev/$disk -p $part -l '\\EFI\\BOOT\\BOOTX64.EFI' -L 'NixOS lanzaboote'"
  if ask "Create this firmware entry now?" n; then
    if "${cmd[@]}"; then ok "Entry created"; else warn "efibootmgr failed"; fi
  fi
}

# Returns 1 (after printing why, loudly) when a file that MUST be signed is not
lanza_post() {
  local out=$WORK/sbctl-verify.txt esp stubs=0 rc=0 p failed=0 n
  info "Checking the signatures on the boot partition (sbctl verify)"
  chroot_sbctl verify >"$out" 2>&1 || rc=$?
  summarize_sbctl_verify "$out"
  if esp=$(main_esp); then stubs=$(count_stubs "$esp"); fi
  if ((VERIFY_SIGNED + ${#VERIFY_BAD[@]} + ${#VERIFY_EXPECTED[@]} == 0)); then
    warn "sbctl verify gave no verdict (sbctl missing in the system, or it could not find the boot partition): exit code $rc."
    tail -n 5 "$out" | sed 's/^/        /' >&2 || true
    warn "Check by hand later: sudo sbctl verify  (EFI/Linux/nixos-*.efi, EFI/BOOT/BOOTX64.EFI and EFI/systemd/systemd-bootx64.efi must be signed)."
  else
    ok "$VERIFY_SIGNED file(s) signed"
    for p in "${VERIFY_BAD[@]}"; do
      printf '\033[1;31m  ✗ NOT SIGNED: %s\033[0m\n' "$p" >&2
      failed=1
    done
    n=${#VERIFY_EXPECTED[@]}
    if ((n)); then
      ok "$n unsigned file(s) are expected and NOT an error (EFI/nixos/kernel-* and initrd-* are checked by hash from the signed stub; GRUB leftovers like EFI/NixOS-boot, /boot/grub, /boot/kernels are unused):"
      printf '        %s\n' "${VERIFY_EXPECTED[@]:0:8}"
      if ((n > 8)); then echo "        ... and $((n - 8)) more"; fi
    fi
  fi
  if [[ -n ${esp:-} ]] && ((stubs == 0)); then
    printf '\033[1;31m  ✗ No EFI/Linux/nixos-*.efi stub on the boot partition (%s) - nothing to boot.\033[0m\n' "$esp" >&2
    failed=1
  elif [[ -n ${esp:-} ]]; then
    ok "$stubs signed boot stub(s) in EFI/Linux"
  fi
  if ((failed)); then
    printf '\033[1;31m  ✗ At least one file the firmware must verify is unsigned: with Secure Boot ON this machine will NOT boot from it.\033[0m\n' >&2
    printf '\033[1;31m    Check the key at %s, re-run the script, or boot an older generation with Secure Boot OFF.\033[0m\n' "$KEYDIR" >&2
  fi
  show_boot_order
  fw_entry_check
  return "$failed"
}

lanza_final_notes() {
  local d
  echo
  info "Next steps (lanzaboote / Secure Boot)"
  echo "      1. Turn Secure Boot back ON in the firmware setup (you switched it off to boot the live USB)."
  echo "         The enrolled keys normally stay in the firmware; the boot files written now are signed with them."
  if ((NEW_KEYS_CREATED)); then
    echo "         YOU CREATED NEW KEYS: they are NOT enrolled. Leave Secure Boot OFF, boot NixOS, and repeat Phase 2 and 3 of"
    echo "         Documentation/usage/secure-boot/lanzaboote.md (the firmware db still holds the OLD public key). Archive the new keys."
  fi
  if ((${#UNLOCKED_DEVS[@]})); then
    echo "      2. LUKS + TPM: the TPM keeps unlocking only if PCR 7 is unchanged (same keys, Secure Boot state as before)."
    echo "         If the passphrase is asked at boot, log in and re-seal:"
    for d in "${UNLOCKED_DEVS[@]}"; do
      echo "           sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 $d"
    done
  fi
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

main() {
  local idx=0 FSTAB extra=() lanza_failed=0

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
    --grub-only) GRUB_ONLY=1 ;;
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
  trap on_exit EXIT
  trap 'warn "Failed at line $LINENO: $BASH_COMMAND"; warn "Anything already mounted is left at $MNT - just run the script again to start over."' ERR

  if ((!GRUB_ONLY)); then
    ensure_network
    ensure_git
    SCRIPT_REPO=$(git -c safe.directory='*' -C "$(dirname "$SCRIPT_PATH")" rev-parse --show-toplevel 2>/dev/null || true)
  fi

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

  TARGET_GEN=""
  detect_bootloader_disk || true

  if ((GRUB_ONLY)); then
    if [[ $DISK_BL == lanzaboote ]]; then
      warn "--grub-only does not apply: this system boots through lanzaboote ($DISK_BL_WHY), there are no GRUB copies to fix."
      echo "      Boot problem on a lanzaboote host: run the full  $(basename "$0")  (rebuilds and reinstalls the signed boot files,"
      echo "      checks the signing keys first), or  $(basename "$0") --shell  to look around in the installed system."
      cleanup
      exit 0
    fi
    sync_grub_copies
    cleanup
    echo
    info "Done. The USB stick can stay in; if the live system comes up again, remove it and reboot."
    if ask "Reboot now?" y; then systemctl reboot; fi
    exit 0
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
  echo "      boot:    $DISK_BL on the disk ($DISK_BL_WHY); the flake is asked again after the update below and decides"
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

  resolve_target_bootloader
  if [[ $TARGET_BL == lanzaboote ]]; then lanza_preflight; fi

  info "Rebuilding inside the chroot (errors from 'setting up /etc', sops or systemd while entering are normal)"
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
  case $TARGET_BL in
  lanzaboote)
    ok "System rebuilt and the signed boot files (lanzaboote) reinstalled"
    lanza_post || lanza_failed=1
    ;;
  grub)
    ok "System rebuilt and GRUB reinstalled"
    sync_grub_copies
    ;;
  *)
    ok "System rebuilt and the bootloader reinstalled"
    sync_grub_copies
    ;;
  esac
  if ((STASHED)); then warn "Your uncommitted changes are in 'git stash list' in $FLAKE_IN_TARGET"; fi
  if ((lanza_failed)); then
    ask "A boot file is unsigned (see above). Unmount and finish anyway?" n || {
      warn "Everything is still mounted at $MNT (chroot: nixos-enter --root $MNT)."
      exit 1
    }
  fi

  cleanup
  if [[ $TARGET_BL == lanzaboote ]]; then lanza_final_notes; fi
  echo
  info "Done. The USB stick can stay in; if the live system comes up again, remove it and reboot."
  if ask "Reboot now?" y; then systemctl reboot; fi
}

# Sourcing the file (tests) only defines functions and defaults
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  set -Eeuo pipefail
  main "$@"
fi
