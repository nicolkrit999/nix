#!/usr/bin/env bash
# Own-checking harness for the clone installer (NOT a registered repo test).
#
# Everything runs on sparse image files under $WORK_BASE (default ~/momentary/clone-installer/work).
# sgdisk/sfdisk touch only those regular files. Every other mutating tool (mkfs, cryptsetup, mount,
# nixos-install, efibootmgr, sbctl, tailscale, chown, ...) is a recording fake in a bin dir.
#
#   ./test-harness.sh            run everything
#   ./test-harness.sh -k NAME    only sections whose name contains NAME
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
WORK_BASE=${WORK_BASE:-$HOME/momentary/clone-installer/work}

# Re-exec with the needed tools when they are missing (sgdisk is not part of the base system).
if ! command -v sgdisk >/dev/null 2>&1 || ! command -v ssh-to-age >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  exec nix shell nixpkgs#gptfdisk nixpkgs#ssh-to-age nixpkgs#jq nixpkgs#util-linux nixpkgs#shellcheck \
    nixpkgs#age nixpkgs#sops --command "$0" "$@"
fi

FILTER=""
if [[ ${1:-} == -k ]]; then FILTER=${2:-}; fi

PASS=0
FAIL=0
section_on() { [[ -z $FILTER || $1 == *"$FILTER"* ]]; }
ok() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }
assert_eq() { # name got want
  if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi
}
assert_contains() { # name haystack needle
  if [[ $2 == *"$3"* ]]; then ok "$1"; else bad "$1 (missing '$3')"; fi
}
assert_not_contains() {
  if [[ $2 != *"$3"* ]]; then ok "$1"; else bad "$1 (unexpected '$3')"; fi
}
assert_rc() { # name rc want
  if [[ $2 == "$3" ]]; then ok "$1"; else bad "$1 (rc $2, want $3)"; fi
}

T=$WORK_BASE/harness
rm -rf "$T"
mkdir -p "$T/img" "$T/bin" "$T/root"

# ---------------------------------------------------------------------------
# Image builders (plain files only)
# ---------------------------------------------------------------------------
mk_windows() { # name size_gib data_end_arg  -> Windows layout, rest free
  local f=$T/img/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+200M -t1:ef00 -c1:"EFI system partition" \
    -n2:0:+16M -t2:0c01 -c2:"Microsoft reserved partition" \
    -n3:0:"$3" -t3:0700 -c3:"Basic data partition" \
    -n4:0:+1G -t4:2700 -c4:"Windows RE" "$f" >/dev/null
  printf '%s\n' "$f"
}
mk_empty() { truncate -s "${2}G" "$T/img/$1"; printf '%s\n' "$T/img/$1"; }
mk_ubuntu() {
  local f=$T/img/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+512M -t1:ef00 -c1:"EFI" -n2:0:0 -t2:8300 -c2:"ubuntu" "$f" >/dev/null
  printf '%s\n' "$f"
}
mk_bare_esp() {
  local f=$T/img/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+512M -t1:ef00 -c1:"EFI" "$f" >/dev/null
  printf '%s\n' "$f"
}
mk_dos_ntfs() {
  local f=$T/img/$1
  truncate -s "${2}G" "$f"
  printf 'label: dos\n,100G,7\n' | sfdisk -q "$f" >/dev/null
  printf '%s\n' "$f"
}
# Cheap image signature (images are sparse and huge: never hash their content).
img_sig() { { sfdisk -d "$1" 2>/dev/null; stat -c '%Y %s' "$1"; } | sha256sum | cut -d' ' -f1; }
table_of() { sfdisk --json "$1" | jq -S -c '.partitiontable.partitions'; }
existing_identity() { # partition identity lines for partitions 1..4
  sfdisk --json "$1" | jq -r '.partitiontable.partitions[] | select((.node|capture("(?<n>[0-9]+)$").n|tonumber) <= 4) | [.start,.size,.type,.uuid,.name]|@tsv'
}

# ---------------------------------------------------------------------------
# Fake tools
# ---------------------------------------------------------------------------
setup_fakes() {
  local bin=$T/bin t
  rm -rf "$bin"
  mkdir -p "$bin"
  export FAKE_CALLS=$T/calls.log
  : >"$FAKE_CALLS"
  for t in wipefs mkfs.vfat mkfs.btrfs cryptsetup mount umount btrfs partprobe udevadm chown \
    nixos-install sbctl tailscaled; do
    cat >"$bin/$t" <<EOF
#!/usr/bin/env bash
printf '%s' "$t" >>"\$FAKE_CALLS"; printf ' %q' "\$@" >>"\$FAKE_CALLS"; printf '\n' >>"\$FAKE_CALLS"
cat >/dev/null </dev/null 2>&1 || true
exit 0
EOF
  done
  # nixos-install: logs, and leaves the boot files a real install would
  cat >"$bin/nixos-install" <<'EOF2'
#!/usr/bin/env bash
printf 'nixos-install' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
root=""; while (($#)); do [[ $1 == --root ]] && root=$2; shift; done
mkdir -p "$root/boot/EFI/systemd" "$root/boot/EFI/BOOT"
: >"$root/boot/EFI/systemd/systemd-bootx64.efi"; : >"$root/boot/EFI/BOOT/BOOTX64.EFI"
exit 0
EOF2
  # git: the real one (local file:// repositories only), except that the unshallow fetch can be made to fail
  local realgit
  realgit=$(command -v git)
  cat >"$bin/git" <<GITEOF
#!/usr/bin/env bash
if [[ \${FAKE_GIT_FAIL_UNSHALLOW:-0} == 1 && " \$* " == *" --unshallow "* ]]; then
  printf 'git fetch --unshallow (forced failure)\\n' >>"\$FAKE_CALLS"
  exit 1
fi
exec "$realgit" "\$@"
GITEOF
  # tailscale: log and succeed
  cat >"$bin/tailscale" <<'EOF'
#!/usr/bin/env bash
printf 'tailscale' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
exit 0
EOF
  # efibootmgr with state
  cat >"$bin/efibootmgr" <<'EOF'
#!/usr/bin/env bash
state=${FAKE_EFI_STATE:?}
printf 'efibootmgr' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
[[ -f $state ]] || printf 'BootOrder: 0000\nBoot0000* Windows Boot Manager\n' >"$state"
if (($# == 0)); then cat "$state"; exit 0; fi
case $1 in
  --create)
    label=""; while (($#)); do [[ $1 == --label ]] && label=$2; shift; done
    new=$(printf '%04X' "$(($(grep -c '^Boot[0-9A-F]' "$state")))")
    { sed -n 's/^BootOrder: //p' "$state" | sed "s/^/BootOrder: $new,/"; grep '^Boot[0-9A-F]' "$state"; echo "Boot$new* $label"; } >"$state.new"
    mv "$state.new" "$state" ;;
  --bootorder)
    { echo "BootOrder: $2"; grep '^Boot[0-9A-F]' "$state"; } >"$state.new"; mv "$state.new" "$state" ;;
  -B | --delete-bootnum) echo "DELETE CALLED" >>"$FAKE_CALLS" ;;
esac
exit 0
EOF
  # age: -d -o OUT FILE -> copy (bundle is a plain tar in the test); never prompts; counted in the calls log
  cat >"$bin/age" <<'EOF'
#!/usr/bin/env bash
printf 'age' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
if [[ $1 == -d && $2 == -o ]]; then
  [[ ${FAKE_AGE_FAIL:-0} == 1 ]] && { echo "age: error: incorrect passphrase" >&2; exit 1; }
  cat "$4" >"$3"; exit 0
fi
exit 1
EOF
  cat >"$bin/sops" <<'EOF'
#!/usr/bin/env bash
printf 'sops' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
case "$*" in
  *tailscale_key*) printf 'tskey-auth-FAKE' ;;
  *attic-push-token*) printf 'attic-token-FAKE' ;;
esac
EOF
  cat >"$bin/ssh-to-age" <<'EOF'
#!/usr/bin/env bash
echo AGE-SECRET-KEY-FAKEFROMSSH
EOF
  cat >"$bin/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl' >>"$FAKE_CALLS"; printf ' %q' "$@" >>"$FAKE_CALLS"; printf '\n' >>"$FAKE_CALLS"
exit "${FAKE_CURL_RC:-0}"
EOF
  # nix: canned facts for --apply, real nix otherwise
  local realnix
  realnix=$(command -v nix)
  cat >"$bin/nix" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do
  if [[ \$a == --apply ]]; then
    case "\$*" in
      *laptop*) cat "$T/facts-laptop.json" ;;
      *) cat "$T/facts-desktop.json" ;;
    esac
    exit 0
  fi
done
exec "$realnix" "\$@"
EOF
  chmod +x "$bin"/*
  cat >"$T/facts-laptop.json" <<'EOF'
{"hostName":"nixos-laptop-2","user":"krit","uid":1000,"gid":100,"home":"/home/krit","luks":true,"lanzaboote":true,"pkiBundle":"/persist/var/lib/sbctl","bootDevice":"/dev/disk/by-label/NIXOS-BOOT","atticServer":"http://nicol-nas.tail9b9ae8.ts.net:8081","atticCache":"krit-nix","atticKey":"krit-nix:KEY"}
EOF
  sed 's/nixos-laptop-2/nixos-desktop-2/; s/"luks":true/"luks":false/' "$T/facts-laptop.json" >"$T/facts-desktop.json"
  export FAKE_EFI_STATE=$T/efi-state
  rm -f "$FAKE_EFI_STATE"
}

make_bundle_tar() { # out.tar host
  local d=$T/bundle-src
  rm -rf "$d"
  mkdir -p "$d/host" "$d/user"
  printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nFAKE\n-----END OPENSSH PRIVATE KEY-----\n' >"$d/host/ssh_host_ed25519_key"
  echo 'ssh-ed25519 AAAAFAKE root@fake' >"$d/host/ssh_host_ed25519_key.pub"
  echo 'AGE-SECRET-KEY-FAKEUSER' >"$d/user/keys.txt"
  printf 'format=1\nhost=%s\n' "$2" >"$d/meta.txt"
  tar -C "$d" -cf "$1" host user meta.txt
}

# ---------------------------------------------------------------------------
echo "# shellcheck"
if section_on shellcheck; then
  if shellcheck -x -s bash "$HERE/disk-plan.sh" "$HERE/install.sh" "$HERE/make-bundle.sh" "$HERE/test-harness.sh"; then
    ok "shellcheck clean"
  else
    bad "shellcheck findings"
  fi
fi

# ---------------------------------------------------------------------------
export INSTALLER_TEST=1
export INSTALLER_BIN_DIR=$T/bin
# shellcheck source=disk-plan.sh
source "$HERE/disk-plan.sh"
dp_layout_load "$HERE/layout.nix" || { echo "layout load failed: $DP_REASON"; exit 1; }

WIN=$(mk_windows win.img 500 +300G)
FULL=$(mk_windows full.img 120 -1025M)
SMALL=$(mk_windows small.img 120 +60G)
EMPTY=$(mk_empty empty.img 200)
UBU=$(mk_ubuntu ubuntu.img 200)
BARE=$(mk_bare_esp bare.img 200)
DOS=$(mk_dos_ntfs dos.img 200)

if section_on layout; then
  echo "# layout.nix is the single source"
  assert_eq "esp label" "$DP_ESP_LABEL" "$(nix eval --raw -f "$HERE/layout.nix" espLabel)"
  assert_eq "luks partlabel" "$DP_LUKS_PARTLABEL" "$(nix eval --raw -f "$HERE/layout.nix" luksPartLabel)"
  assert_eq "subvolume log" "$DP_SV_LOG" "@log"
  hard=$(grep -nE 'NIXOS-BOOT|nixos-luks|cryptroot|@persist|@home|@nix|@log' "$HERE/disk-plan.sh" "$HERE/install.sh" | grep -v '^[^:]*:[0-9]*:\s*#' || true)
  assert_eq "no layout values duplicated in scripts" "$hard" ""
fi

if section_on classify; then
  echo "# classification"
  assert_eq "windows disk" "$(dp_classify "$WIN")" windows
  assert_eq "full windows disk" "$(dp_classify "$FULL")" windows
  assert_eq "empty file" "$(dp_classify "$EMPTY")" empty
  assert_eq "ubuntu disk" "$(dp_classify "$UBU")" other-os
  assert_eq "bare ESP + big free" "$(dp_classify "$BARE")" free-space
  assert_eq "dos ntfs" "$(dp_classify "$DOS")" windows
  zero=$T/img/zero.img
  truncate -s 10G "$zero"
  sgdisk -o "$zero" >/dev/null
  assert_eq "empty GPT without partitions" "$(dp_classify "$zero")" empty
  tinyesp=$T/img/tiny.img
  truncate -s 20G "$tinyesp"
  sgdisk -n1:0:+512M -t1:ef00 "$tinyesp" >/dev/null
  assert_eq "bare ESP without room" "$(dp_classify "$tinyesp")" unknown
fi

if section_on free; then
  echo "# free block"
  read -r s z ss <<<"$(dp_largest_free "$WIN")"
  assert_eq "win: sector size" "$ss" 512
  gib=$((z * ss / 1073741824))
  # 500 GiB - (200M+16M+300G+1G) ~ 198.8 GiB
  if ((gib >= 197 && gib <= 199)); then ok "win free block ~198 GiB ($gib)"; else bad "win free block $gib GiB"; fi
  assert_eq "free block start 1MiB aligned" "$((s % 2048))" 0
  assert_eq "full disk has (almost) no free space" "$(($(dp_free_bytes "$FULL") < 1048576 ? 1 : 0))" 1
  assert_eq "empty disk free ~ whole disk" "$(($(dp_free_bytes "$EMPTY") > 199 * 1073741824 ? 1 : 0))" 1
  # Free block is the largest gap, not the first: leave a gap in the middle too.
  gap=$T/img/gap.img
  truncate -s 300G "$gap"
  sgdisk -n1:0:+200M -t1:ef00 -n2:0:+16M -t2:0c01 -n3:0:+10G -t3:0700 \
    -n4:+5G:+10G -t4:0700 -n5:0:+1G -t5:2700 "$gap" >/dev/null
  assert_eq "gap disk: largest gap is the tail (~270G)" "$(($(dp_free_bytes "$gap") > 250 * 1073741824 ? 1 : 0))" 1
fi

if section_on guards; then
  echo "# guards"
  INSTALLER_FAKE_INUSE="$WIN"
  export INSTALLER_FAKE_INUSE
  if dp_disk_in_use "$WIN"; then ok "in-use disk detected"; else bad "in-use disk not detected"; fi
  dp_wipe_allowed "$WIN" no-windows-wipe
  assert_rc "wipe refused when disk is in use" $? 1
  assert_contains "reason says mounts" "$DP_REASON" "mounts of the running system"
  dp_free_space_check "$WIN"
  assert_rc "free-space refused when in use" $? 1
  unset INSTALLER_FAKE_INUSE

  dp_wipe_allowed "$WIN" ""
  assert_rc "wipe of windows disk refused without ack" $? 1
  assert_contains "reason names the explicit choice" "$DP_REASON" "no Windows, wipe"
  dp_wipe_allowed "$WIN" no-windows-wipe
  assert_rc "wipe of windows disk allowed with ack" $? 0
  dp_wipe_allowed "$UBU" ""
  assert_rc "wipe of ubuntu disk refused without ack" $? 1
  dp_wipe_allowed "$EMPTY" ""
  assert_rc "wipe of empty disk allowed" $? 0

  dp_free_space_check "$FULL"
  assert_rc "free-space on full disk refused" $? 1
  assert_contains "full disk: tells to shrink in Windows" "$DP_REASON" "Shrink the Windows partition in Windows"
  dp_free_space_check "$SMALL"
  assert_rc "free-space with ~58G free refused (needs 68)" $? 1
  assert_contains "small: names the 68 GiB need" "$DP_REASON" "at least 68 GiB"
  dp_free_space_check "$UBU"
  assert_rc "free-space on ubuntu disk refused (no Windows ESP)" $? 1
  assert_contains "ubuntu: no windows esp" "$DP_REASON" "no Windows ESP"
  dp_free_space_check "$DOS"
  assert_rc "free-space on dos disk refused" $? 1
  dp_free_space_check "$EMPTY"
  assert_rc "free-space on empty disk refused (nothing to sit next to)" $? 1
  dp_free_space_check "$WIN"
  assert_rc "free-space on windows disk with room allowed" $? 0

  blk=$(find /dev -maxdepth 1 -type b 2>/dev/null | head -n1)
  if [[ -n $blk ]]; then
    dp_assert_disk_allowed "$blk"
    assert_rc "test mode refuses a block device (stat only)" $? 1
  else
    ok "test mode block-device refusal skipped (no block device visible)"
  fi
  (INSTALLER_TEST=0; dp_assert_disk_allowed "$WIN")
  assert_rc "non-test mode refuses a regular file" $? 1
  dp_assert_disk_allowed "$T/img/does-not-exist"
  assert_rc "missing file refused" $? 1
fi

if section_on apply; then
  echo "# apply_partition on image files"
  # --- free-space on a copy of the windows disk
  cp --sparse=always "$WIN" "$T/img/win-free.img"
  D=$T/img/win-free.img
  before=$(existing_identity "$D")
  tbefore=$(table_of "$D")
  dp_plan "$D" free 1 || { bad "plan free luks: $DP_REASON"; }
  assert_eq "plan: esp number follows highest (5)" "$DP_PLAN_ESP_NUM" 5
  assert_eq "plan: root number 6" "$DP_PLAN_ROOT_NUM" 6
  assert_eq "plan: luks type" "$DP_PLAN_ROOT_TYPE" 8309
  assert_eq "plan: luks partlabel" "$DP_PLAN_ROOT_NAME" "$DP_LUKS_PARTLABEL"
  DP_CMDLOG=$T/apply.cmds
  : >"$DP_CMDLOG"
  export DP_CMDLOG
  DRY_RUN=1 apply_partition >/dev/null
  assert_eq "dry-run changed nothing" "$(table_of "$D")" "$tbefore"
  apply_partition >/dev/null
  assert_rc "apply_partition (free, luks) ok" $? 0
  after=$(existing_identity "$D")
  assert_eq "existing partitions 1-4 byte-identical" "$after" "$before"
  newp=$(sfdisk --json "$D" | jq -r '.partitiontable.partitions[] | select((.node|capture("(?<n>[0-9]+)$").n|tonumber) > 4) | [(.node|capture("(?<n>[0-9]+)$").n),.type,.name,.start,.size]|@tsv')
  assert_contains "new ESP: type EFI, label from layout" "$newp" "5	C12A7328-F81F-11D2-BA4B-00A0C93EC93B	$DP_ESP_LABEL"
  assert_contains "new root: LUKS type + partlabel from layout" "$newp" "6	CA7D7CCB-63ED-4C53-861C-1742536059CC	$DP_LUKS_PARTLABEL"
  read -r es ez < <(printf '%s\n' "$newp" | awk -F'\t' '$1==5{print $4, $5}')
  assert_eq "ESP is 4 GiB" "$((ez * 512))" "$((4 * 1073741824))"
  read -r rs rz < <(printf '%s\n' "$newp" | awk -F'\t' '$1==6{print $4, $5}')
  tlast=$(sfdisk --json "$D" | jq '.partitiontable.lastlba')
  assert_eq "root ends 1MiB-aligned" "$(((rs + rz) % 2048))" 0
  assert_eq "root reaches the end of the free block (within 1 MiB)" "$((tlast - (rs + rz - 1) < 2048 ? 1 : 0))" 1
  assert_eq "root starts right after ESP" "$rs" "$((es + ez))"
  # Windows ESP (partition 1) specifically
  assert_eq "windows ESP identical" "$(existing_identity "$D" | sed -n 1p)" "$(echo "$before" | sed -n 1p)"
  assert_not_contains "partitioning stage ran no mkfs/wipefs" "$(cat "$DP_CMDLOG")" mkfs
  unset DP_CMDLOG

  # --- free-space, btrfs (no luks)
  cp --sparse=always "$WIN" "$T/img/win-free2.img"
  D2=$T/img/win-free2.img
  dp_plan "$D2" free 0 && apply_partition >/dev/null
  assert_rc "apply_partition (free, no luks)" $? 0
  assert_contains "no-luks root partition named after btrfs label" \
    "$(sfdisk --json "$D2" | jq -r '.partitiontable.partitions[5].name')" "$DP_BTRFS_LABEL"

  # --- refusal paths leave the image bit-identical
  h1=$(img_sig "$WIN")
  dp_plan "$FULL" free 1
  assert_rc "plan free on full disk fails" $? 1
  INSTALLER_FAKE_INUSE="$WIN" dp_plan "$WIN" free 1
  assert_rc "plan free on in-use disk fails" $? 1
  assert_eq "original windows image untouched" "$(img_sig "$WIN")" "$h1"

  # --- whole disk wipe on an empty image
  cp --sparse=always "$EMPTY" "$T/img/e1.img"
  dp_plan "$T/img/e1.img" whole 0 && apply_partition >/dev/null
  assert_rc "apply_partition (whole, empty)" $? 0
  assert_eq "whole: 2 partitions" "$(sfdisk --json "$T/img/e1.img" | jq '.partitiontable.partitions|length')" 2
  assert_eq "whole: first partition starts at 1MiB" "$(sfdisk --json "$T/img/e1.img" | jq '.partitiontable.partitions[0].start')" 2048

  # --- whole-disk over a windows image (explicit ack path), on a copy
  cp --sparse=always "$WIN" "$T/img/w2.img"
  dp_wipe_allowed "$T/img/w2.img" no-windows-wipe && dp_plan "$T/img/w2.img" whole 0 && apply_partition >/dev/null
  assert_eq "whole over windows: only our 2 partitions remain" \
    "$(sfdisk --json "$T/img/w2.img" | jq -r '[.partitiontable.partitions[].name]|join(",")')" "$DP_ESP_LABEL,$DP_BTRFS_LABEL"

  echo "# format/mount recorded commands (dry-run)"
  dp_plan "$WIN" free 1 >/dev/null
  out=$(DRY_RUN=1 apply_format_mount /mnt/testroot "") # luks + dry-run: empty passphrase tolerated
  assert_contains "wipefs on new partitions only" "$out" "wipefs --all"
  assert_contains "esp formatted with layout label" "$out" "mkfs.vfat -F 32 -n $DP_ESP_LABEL"
  assert_contains "luksFormat on root partition" "$out" "cryptsetup luksFormat --type luks2"
  assert_contains "mapper name from layout" "$out" "$DP_LUKS_MAPPER"
  assert_contains "btrfs label" "$out" "mkfs.btrfs -f -L $DP_BTRFS_LABEL /dev/mapper/$DP_LUKS_MAPPER"
  for sv in "$DP_SV_PERSIST" "$DP_SV_HOME" "$DP_SV_NIX" "$DP_SV_LOG"; do
    assert_contains "subvolume $sv created" "$out" "btrfs subvolume create /mnt/testroot.btrfs-top/$sv"
  done
  assert_contains "tmpfs root size from layout" "$out" "size=$DP_TMPFS_SIZE"
  assert_not_contains "passphrase never printed" "$out" "hunter2"
  assert_not_contains "no operation on the windows ESP partition 1" "$out" "${WIN}1 "
  dp_plan "$WIN" free 0 >/dev/null
  out=$(DRY_RUN=1 apply_format_mount /mnt/testroot "")
  assert_not_contains "no-luks host: no cryptsetup" "$out" cryptsetup
  assert_contains "no-luks host: btrfs directly on partition" "$out" "mkfs.btrfs -f -L $DP_BTRFS_LABEL ${WIN}6"
fi

# ---------------------------------------------------------------------------
# Local origin repositories (branch main, two commits so that a shallow clone really is shallow).
git_t() { GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t git "$@"; }
mk_origin() { # mk_origin <dir> mini|full
  local d=$1 f
  rm -rf "$d"
  mkdir -p "$d"
  if [[ $2 == full ]]; then
    # snapshot of the working tree (tracked + staged new files), so uncommitted work is tested
    while IFS= read -r -d '' f; do
      [[ -e $REPO/$f ]] && (cd "$REPO" && cp --parents -P -- "$f" "$d/") 2>/dev/null
    done < <(git -C "$REPO" ls-files -z --cached --others --exclude-standard)
  else
    mkdir -p "$d/templates/installer" "$d/users/krit/common/sops"
    cp "$HERE/layout.nix" "$d/templates/installer/"
    cp "$REPO/users/krit/common/sops/krit-common-secrets-sops.yaml" "$d/users/krit/common/sops/"
  fi
  git_t -C "$d" init -q -b main
  git_t -C "$d" add -A
  git_t -C "$d" commit -q -m first
  echo second >"$d/second.txt"
  git_t -C "$d" add -A
  git_t -C "$d" commit -q -m second
}

ORIGIN_MINI=$T/origin-mini
ORIGIN_URL=file://$ORIGIN_MINI
mk_origin "$ORIGIN_MINI" mini

run_install() { # run_install <stdin-text> args...  (uses fakes, writes $T/out.txt)
  local input=$1
  shift
  : >"$FAKE_CALLS"
  printf '%s' "$input" | INSTALLER_ROOT=$T/root/target INSTALLER_REPO_URL=$ORIGIN_URL INSTALLER_WORK_DIR=$T/wd \
    "$HERE/install.sh" "$@" >"$T/out.txt" 2>&1
  return $?
}

if section_on install; then
  echo "# install.sh end-to-end with fakes (free-space, laptop, Setup Mode)"
  setup_fakes
  rm -rf "$T/root/target" "$T/wd"
  make_bundle_tar "$T/bundle.tar" nixos-laptop
  cp --sparse=always "$WIN" "$T/img/inst.img"
  D=$T/img/inst.img
  export INSTALLER_TEST_DISKS="$D"
  before=$(existing_identity "$D")
  mkdir -p "$T/efivars"
  printf '\x07\x00\x00\x00\x01' >"$T/efivars/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c"
  export INSTALLER_EFIVARS_DIR=$T/efivars
  run_install "$D
secretpw
secretpw
" --host nixos-laptop --variant 2 --disk "$D" --mode free --bundle "$T/bundle.tar"
  rc=$?
  out=$(cat "$T/out.txt")
  calls=$(cat "$FAKE_CALLS")
  assert_rc "installer exit code" "$rc" 0
  [[ $rc -eq 0 ]] || { echo "$out" | tail -n 30; }
  assert_eq "existing partitions untouched by the full flow" "$(existing_identity "$D")" "$before"
  if [[ $calls =~ nixos-install\ --root\ $T/root/target\ --flake\ $T/wd/clone-installer-src\.[A-Za-z0-9]+/nix\#nixos-laptop-2\ --no-root-passwd ]]; then
    ok "nixos-install uses the local clone as flake + clone name"
  else
    bad "nixos-install flake ref (not the local clone): $(grep '^nixos-install' "$FAKE_CALLS")"
  fi
  assert_not_contains "no github: flake anywhere" "$calls" "github:"
  assert_contains "installer cloned the origin shallow" "$out" "Cloning $ORIGIN_URL (branch main, shallow)"
  assert_contains "no gate prompt in Setup Mode" "$out" "Firmware is in Secure Boot Setup Mode"
  assert_not_contains "no gate prompt when in Setup Mode" "$out" "[r]etry"
  rp=$T/root/target/home/krit/nix
  assert_eq "repo placed at ~/nix of the target user" "$([[ -d $rp/.git ]] && echo yes)" yes
  assert_eq "origin is the repo URL" "$(git -C "$rp" remote get-url origin)" "$ORIGIN_URL"
  assert_eq "clone is on branch main" "$(git -C "$rp" rev-parse --abbrev-ref HEAD)" main
  assert_eq "history was unshallowed (2 commits)" "$(git -C "$rp" rev-list --count HEAD)" 2
  assert_eq "repo no longer shallow" "$(git -C "$rp" rev-parse --is-shallow-repository)" false
  assert_contains "repo chowned recursively to the user" "$calls" "chown -R 1000:100 $rp"
  assert_eq "temporary clone removed from the work dir" "$(find "$T/wd" -maxdepth 1 -name 'clone-installer-src.*' | wc -l)" 0
  assert_contains "attic substituter added" "$calls" "extra-substituters http://nicol-nas.tail9b9ae8.ts.net:8081/krit-nix"
  assert_contains "attic public key added" "$calls" "extra-trusted-public-keys krit-nix:KEY"
  assert_contains "netrc passed" "$calls" "netrc-file"
  assert_contains "sbctl create-keys uses target pkiBundle config" "$calls" "sbctl --config"
  assert_contains "sbctl create-keys" "$calls" "create-keys"
  assert_contains "sbctl enroll-keys --microsoft (Setup Mode)" "$calls" "enroll-keys --microsoft"
  cr=$(grep -n 'create-keys' "$FAKE_CALLS" | head -1 | cut -d: -f1)
  ni=$(grep -n '^nixos-install' "$FAKE_CALLS" | head -1 | cut -d: -f1)
  en=$(grep -n 'enroll-keys' "$FAKE_CALLS" | head -1 | cut -d: -f1)
  if [[ -n $cr && -n $ni && -n $en ]] && ((cr < ni && ni < en)); then ok "order: create-keys < nixos-install < enroll-keys"; else bad "order create/install/enroll ($cr/$ni/$en)"; fi
  assert_contains "luksFormat executed (laptop)" "$calls" "cryptsetup luksFormat"
  assert_contains "tailscale up with clone hostname" "$calls" "--hostname=nixos-laptop-2"
  assert_contains "tailscale key passed as file" "$calls" "--auth-key=file:"
  assert_not_contains "no tailscale key on a command line" "$calls" "tskey-auth-FAKE"
  assert_contains "efibootmgr create with our label" "$calls" "--label NixOS\\ \\(nixos-laptop-2\\)"
  assert_contains "efibootmgr loader path systemd-boot" "$calls" '\\EFI\\systemd\\systemd-bootx64.efi'
  assert_not_contains "Windows Boot Manager never deleted" "$calls" "DELETE CALLED"
  efi=$(cat "$FAKE_EFI_STATE")
  assert_contains "Windows entry still present" "$efi" "Windows Boot Manager"
  assert_contains "our entry is first in BootOrder" "$efi" "BootOrder: 0001,0000"
  hk=$T/root/target/persist/etc/ssh/ssh_host_ed25519_key
  assert_eq "host key mode 600" "$(stat -c %a "$hk")" 600
  assert_eq "host pub key mode 644" "$(stat -c %a "$hk.pub")" 644
  uk=$T/root/target/home/krit/.config/sops/age/keys.txt
  assert_eq "user age key mode 600" "$(stat -c %a "$uk")" 600
  assert_contains "age dir chowned to 1000:100" "$calls" "chown 1000:100 $T/root/target/home/krit/.config/sops/age/keys.txt"
  assert_contains "host key chowned root" "$calls" "chown 0:0 $hk"
  assert_eq "bundle keys are not left in the work dir" "$(find "$T/wd" -type f 2>/dev/null | wc -l)" 0
  assert_eq "bundle decrypted exactly once (one passphrase prompt)" "$(grep -c '^age ' <<<"$calls")" 1
  assert_contains "decrypt goes to a file in the work dir" "$calls" "age -d -o $T/wd/installer."
  assert_eq "no plaintext tar left in the work dir" "$(find "$T/wd" -name 'bundle.tar' 2>/dev/null | wc -l)" 0
  assert_contains "final checklist: secure boot on" "$out" "Turn Secure Boot ON"
  assert_contains "final checklist: TPM step (luks)" "$out" "TPM"
  assert_contains "final checklist docs pointer" "$out" "Documentation/installation/"
  assert_not_contains "no secret in installer output" "$out" "secretpw"
  assert_not_contains "no key in installer output" "$out" "tskey-auth-FAKE"
fi

if section_on notsetup; then
  echo "# install.sh: firmware not in Setup Mode (gate), desktop (no LUKS)"
  setup_fakes
  rm -rf "$T/root/target" "$T/wd"
  make_bundle_tar "$T/bundle.tar" nixos-desktop
  cp --sparse=always "$WIN" "$T/img/inst2.img"
  D=$T/img/inst2.img
  export INSTALLER_TEST_DISKS="$D"
  SM=SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c
  mkdir -p "$T/efivars2" "$T/efivars-on"
  printf '\x07\x00\x00\x00\x00' >"$T/efivars2/$SM"
  printf '\x07\x00\x00\x00\x01' >"$T/efivars-on/$SM"
  export INSTALLER_EFIVARS_DIR=$T/efivars2

  # gate: quit before anything happens
  sig=$(img_sig "$D")
  run_install "q
" --host nixos-desktop --variant 2 --disk "$D" --mode free --bundle "$T/bundle.tar"
  assert_rc "gate: [q]uit exits non-zero" $? 1
  out=$(cat "$T/out.txt")
  assert_contains "gate: BIOS steps printed" "$out" "Reset to Setup Mode"
  assert_contains "gate: Microsoft keys kept (--microsoft)" "$out" "enroll-keys --microsoft"
  assert_contains "gate: offers retry/continue/quit" "$out" "[r]etry"
  assert_contains "gate: quit says nothing was modified" "$out" "Nothing was modified"
  assert_eq "gate quit: image untouched" "$(img_sig "$D")" "$sig"
  assert_eq "gate quit: no tool of any kind ran" "$(grep -cE '^(mkfs|cryptsetup|nixos-install|wipefs|sbctl|efibootmgr|tailscale|chown)' "$FAKE_CALLS")" 0
  assert_eq "gate quit: clone dir removed" "$(find "$T/wd" -maxdepth 1 -name 'clone-installer-src.*' 2>/dev/null | wc -l)" 0

  # gate: invalid answer, then retry (still not in Setup Mode), then continue
  rm -rf "$T/root/target" "$T/wd"
  cp --sparse=always "$WIN" "$D"
  run_install "x
r
c
$D
" --host nixos-desktop --variant 2 --disk "$D" --mode free --bundle "$T/bundle.tar"
  rc=$?
  out=$(cat "$T/out.txt")
  calls=$(cat "$FAKE_CALLS")
  assert_rc "gate: invalid, retry, continue -> install ok" "$rc" 0
  assert_contains "gate: invalid answer rejected" "$out" "please answer r, c or q"
  assert_contains "gate: retry re-reads and stays" "$out" "still not in Setup Mode"
  assert_contains "gate: continue warns" "$out" "continuing without enrollment"
  assert_contains "keys still created (lanzaboote needs them)" "$calls" "create-keys"
  assert_not_contains "no enroll-keys outside Setup Mode" "$calls" "enroll-keys"
  assert_not_contains "no cryptsetup on desktop" "$calls" "cryptsetup"
  assert_contains "manual steps printed" "$out" "sudo sbctl enroll-keys --microsoft"
  gc=$(grep -n 'Secure Boot gate' "$T/out.txt" | head -1 | cut -d: -f1)
  pt=$(grep -n 'Partition, format, mount' "$T/out.txt" | head -1 | cut -d: -f1)
  if [[ -n $gc && -n $pt ]] && ((gc < pt)); then ok "gate comes before the partition step"; else bad "gate order ($gc/$pt)"; fi

  # gate: firmware flips to Setup Mode while the prompt waits, then [r]etry succeeds -> enroll
  rm -rf "$T/root/target" "$T/wd"
  cp --sparse=always "$WIN" "$D"
  mkdir -p "$T/efivars-flip"
  printf '\x07\x00\x00\x00\x00' >"$T/efivars-flip/$SM"
  : >"$FAKE_CALLS"
  : >"$T/out.txt"
  # shellcheck disable=SC2094  # the writer polls its own output file on purpose
  {
    for _ in $(seq 1 100); do grep -q '\[r\]etry' "$T/out.txt" 2>/dev/null && break; sleep 0.2; done
    printf '\x07\x00\x00\x00\x01' >"$T/efivars-flip/$SM"
    printf 'r\n%s\n' "$D"
  } | INSTALLER_EFIVARS_DIR=$T/efivars-flip INSTALLER_ROOT=$T/root/target INSTALLER_REPO_URL=$ORIGIN_URL \
    INSTALLER_WORK_DIR=$T/wd "$HERE/install.sh" --host nixos-desktop --variant 2 --disk "$D" --mode free \
    --bundle "$T/bundle.tar" >"$T/out.txt" 2>&1
  rc=$?
  out=$(cat "$T/out.txt")
  calls=$(cat "$FAKE_CALLS")
  assert_rc "gate: retry after firmware change -> install ok" "$rc" 0
  [[ $rc -eq 0 ]] || echo "$out" | tail -n 15
  assert_contains "gate: retry sees Setup Mode" "$out" "Firmware is now in Setup Mode"
  assert_contains "gate: enroll happens after retry succeeded" "$calls" "enroll-keys --microsoft"

  echo "# install.sh: source = clone of main"
  rm -rf "$T/root/target" "$T/wd"
  export INSTALLER_EFIVARS_DIR=$T/efivars-on
  cp --sparse=always "$WIN" "$D"
  : >"$FAKE_CALLS"
  # unshallow failure: warn only, install still succeeds
  FAKE_GIT_FAIL_UNSHALLOW=1 run_install "$D
" --host nixos-desktop --variant 2 --disk "$D" --mode free --bundle "$T/bundle.tar"
  rc=$?
  out=$(cat "$T/out.txt")
  assert_rc "unshallow failure does not fail the install" "$rc" 0
  [[ $rc -eq 0 ]] || echo "$out" | tail -n 15
  assert_contains "unshallow failure is a warning" "$out" "git fetch --unshallow failed"
  assert_eq "failed unshallow leaves a shallow clone" "$(git -C "$T/root/target/home/krit/nix" rev-parse --is-shallow-repository)" true
  assert_eq "origin still the repo URL" "$(git -C "$T/root/target/home/krit/nix" remote get-url origin)" "$ORIGIN_URL"
  # clone failure: abort before anything
  sig=$(img_sig "$D")
  rm -rf "$T/root/target" "$T/wd"
  printf '' | INSTALLER_ROOT=$T/root/target INSTALLER_REPO_URL=file://$T/does-not-exist INSTALLER_WORK_DIR=$T/wd \
    "$HERE/install.sh" --host nixos-desktop --variant 2 --disk "$D" --mode free --bundle "$T/bundle.tar" >"$T/out.txt" 2>&1
  assert_rc "unclonable repo aborts" $? 1
  assert_contains "says could not clone" "$(cat "$T/out.txt")" "could not clone"
  assert_eq "unclonable repo: image untouched" "$(img_sig "$D")" "$sig"
  # INSTALLER_SRC: a git checkout is used as is, a plain directory is ignored
  rm -rf "$T/root/target" "$T/wd"
  git clone -q "$ORIGIN_URL" "$T/given-checkout"
  cp --sparse=always "$WIN" "$D"
  printf '' | INSTALLER_ROOT=$T/root/target INSTALLER_SRC=$T/given-checkout INSTALLER_REPO_URL=$ORIGIN_URL \
    INSTALLER_WORK_DIR=$T/wd "$HERE/install.sh" --dry-run --host nixos-desktop --variant 2 --disk "$D" --mode free \
    --bundle "$T/bundle.tar" >"$T/out.txt" 2>&1
  rc=$?
  assert_rc "dry-run with INSTALLER_SRC checkout" "$rc" 0
  [[ $rc -eq 0 ]] || tail -n 12 "$T/out.txt"
  assert_contains "INSTALLER_SRC checkout used, not cloned" "$(cat "$T/out.txt")" "Using the checkout $T/given-checkout"
  mkdir -p "$T/plain-dir"
  printf '' | INSTALLER_ROOT=$T/root/target INSTALLER_SRC=$T/plain-dir INSTALLER_REPO_URL=$ORIGIN_URL \
    INSTALLER_WORK_DIR=$T/wd "$HERE/install.sh" --dry-run --host nixos-desktop --variant 2 --disk "$D" --mode free \
    --bundle "$T/bundle.tar" >"$T/out.txt" 2>&1
  assert_rc "dry-run with INSTALLER_SRC without .git" $? 0
  assert_contains "INSTALLER_SRC without .git ignored: cloned" "$(cat "$T/out.txt")" "Cloning $ORIGIN_URL"
  printf '' | INSTALLER_EFIVARS_DIR=$T/efivars2 INSTALLER_ROOT=$T/root/target INSTALLER_REPO_URL=$ORIGIN_URL \
    INSTALLER_WORK_DIR=$T/wd "$HERE/install.sh" --dry-run --host nixos-desktop --variant 2 --disk "$D" --mode free \
    --bundle "$T/bundle.tar" >"$T/out.txt" 2>&1
  assert_rc "dry-run outside Setup Mode does not prompt" $? 0
  assert_contains "dry-run: gate only warns" "$(cat "$T/out.txt")" "would stop here"

  # the default URL is the public https URL, and the scripts have no github: flake / --ref
  assert_eq "repo-url.txt is a public https URL" "$(head -n1 "$HERE/repo-url.txt" | grep -cE '^https://github\.com/[^/]+/[^/]+\.git$')" 1
  assert_eq "install.sh has no github: flake ref or --ref option" "$(grep -cE 'github:|--ref' "$HERE/install.sh")" 0
  export INSTALLER_EFIVARS_DIR=$T/efivars2

  echo "# install.sh: refusals"
  export INSTALLER_EFIVARS_DIR=$T/efivars-on
  h=$(img_sig "$WIN")
  export INSTALLER_TEST_DISKS="$WIN"
  run_install "$WIN
" --host nixos-desktop --variant 2 --disk "$WIN" --mode whole --bundle "$T/bundle.tar"
  assert_rc "whole-disk on Windows without the phrase: abort" $? 1
  assert_contains "mentions the phrase" "$(cat "$T/out.txt")" "no windows, wipe"
  assert_eq "no destructive call made" "$(grep -cE '^(mkfs|cryptsetup|nixos-install|wipefs)' "$FAKE_CALLS")" 0
  run_install "no windows, wipe
wrongname
" --host nixos-desktop --variant 2 --disk "$WIN" --mode whole --bundle "$T/bundle.tar"
  assert_rc "phrase ok but wrong disk name typed: abort" $? 1
  assert_eq "image untouched" "$(img_sig "$WIN")" "$h"
  rm -rf "$T/wd"
  FAKE_AGE_FAIL=1 run_install "$WIN
" --host nixos-desktop --variant 2 --disk "$WIN" --mode free --bundle "$T/bundle.tar"
  assert_rc "wrong bundle passphrase: abort" $? 1
  assert_contains "says decrypt failed" "$(cat "$T/out.txt")" "could not decrypt the bundle"
  assert_eq "failed decrypt leaves no file in the work dir" "$(find "$T/wd" -type f 2>/dev/null | wc -l)" 0
  assert_eq "image untouched after failed decrypt" "$(img_sig "$WIN")" "$h"
  export INSTALLER_FAKE_INUSE="$WIN"
  run_install "x
" --host nixos-desktop --variant 2 --disk "$WIN" --mode free --bundle "$T/bundle.tar"
  assert_rc "in-use disk refused" $? 1
  assert_contains "says mounts" "$(cat "$T/out.txt")" "mounts of the running system"
  unset INSTALLER_FAKE_INUSE
  export INSTALLER_TEST_DISKS="$FULL"
  run_install "x
" --host nixos-desktop --variant 2 --disk "$FULL" --mode free --bundle "$T/bundle.tar"
  assert_rc "full disk free-space refused" $? 1
  assert_contains "tells to shrink in Windows" "$(cat "$T/out.txt")" "Shrink the Windows partition"
  export INSTALLER_TEST_DISKS="$UBU"
  run_install "x
" --host nixos-desktop --variant 2 --disk "$UBU" --mode free --bundle "$T/bundle.tar"
  assert_rc "ubuntu free-space refused" $? 1
  run_install "x
" --host nixos-desktop --variant same --disk "$EMPTY" --mode whole --bundle "$T/bundle.tar"
  assert_rc "dry unpromoted same-name variant" $? 1
  # same name before promotion: facts say bootDevice by-uuid
  sed -i 's#/dev/disk/by-label/NIXOS-BOOT#/dev/disk/by-uuid/abcd#' "$T/facts-desktop.json"
  run_install "x
" --host nixos-desktop --variant same --disk "$EMPTY" --mode whole --bundle "$T/bundle.tar"
  assert_rc "same-name before promotion refused" $? 1
  assert_contains "explains promotion" "$(cat "$T/out.txt")" "not promoted yet"

  echo "# install.sh: guards"
  : >"$FAKE_CALLS"
  (unset INSTALLER_TEST INSTALLER_BIN_DIR; INSTALLER_SRC=$REPO "$HERE/install.sh" --host nixos-desktop --variant 2 --disk "$WIN" </dev/null >"$T/out.txt" 2>&1)
  assert_rc "outside live installer (non-dry) refused" $? 1
  assert_contains "says not live" "$(cat "$T/out.txt")" "not running in the live installer"
  bd=$T/bin-incomplete
  mkdir -p "$bd"
  (INSTALLER_BIN_DIR=$bd INSTALLER_SRC=$REPO "$HERE/install.sh" --host nixos-desktop --variant 2 --disk "$WIN" </dev/null >"$T/out.txt" 2>&1)
  assert_rc "test mode without fakes refused" $? 1
  assert_contains "names the unfaked tool" "$(cat "$T/out.txt")" "does not resolve to a fake"
  (unset INSTALLER_BIN_DIR; "$HERE/install.sh" --dry-run --host nixos-desktop </dev/null >"$T/out.txt" 2>&1)
  assert_rc "test mode without INSTALLER_BIN_DIR refused" $? 1
fi

if section_on bundle; then
  echo "# bundle discovery and make-bundle.sh"
  setup_fakes
  stick=$T/stick
  mkdir -p "$stick/sub"
  make_bundle_tar "$stick/sub/nixos-desktop-clone-bundle.tar.age" nixos-desktop
  make_bundle_tar "$stick/other.age" nixos-laptop
  rm -rf "$T/root/target" "$T/wd"
  cp --sparse=always "$EMPTY" "$T/img/b1.img"
  export INSTALLER_TEST_DISKS="$T/img/b1.img" INSTALLER_BUNDLE_DIRS="$stick"
  run_install "x
" --host nixos-desktop --variant 2 --disk "$T/img/b1.img" --mode whole
  # bad answer at the confirmation -> abort, but discovery text only after confirm; just check plan reached
  assert_contains "plan printed before confirmation" "$(cat "$T/out.txt")" "WHOLE DISK"
  run_install "$T/img/b1.img
" --host nixos-desktop --variant 2 --disk "$T/img/b1.img" --mode whole
  assert_rc "bundle found without --bundle (host-named preferred)" $? 0
  assert_contains "host-named bundle chosen" "$(cat "$T/out.txt")" "nixos-desktop-clone-bundle.tar.age"
  unset INSTALLER_BUNDLE_DIRS

  # wrong host in the bundle meta
  make_bundle_tar "$T/wrong.tar" nixos-laptop
  rm -rf "$T/root/target" "$T/wd"
  cp --sparse=always "$EMPTY" "$T/img/b2.img"
  export INSTALLER_TEST_DISKS="$T/img/b2.img"
  run_install "$T/img/b2.img
" --host nixos-desktop --variant 2 --disk "$T/img/b2.img" --mode whole --bundle "$T/wrong.tar"
  assert_rc "bundle for another host refused" $? 1
  assert_contains "says which" "$(cat "$T/out.txt")" "is for 'nixos-laptop'"
  assert_eq "image not partitioned after bundle failure" "$(sfdisk --json "$T/img/b2.img" 2>/dev/null | wc -c)" 0

  # make-bundle.sh with a fake age that records stdin: proves keys are piped, output encrypted marker only
  mb=$T/mb
  rm -rf "$mb"
  mkdir -p "$mb/bin" "$mb/out"
  ssh-keygen -q -t ed25519 -N '' -C fake -f "$mb/hostkey" >/dev/null
  echo 'AGE-SECRET-KEY-1THROWAWAYFAKEKEYFORTESTSONLY' >"$mb/keys.txt"
  cat >"$mb/bin/age" <<'EOF'
#!/usr/bin/env bash
# fake age -p -o OUT: stores the (fake-)encrypted stream: header + base64
[[ $1 == -p && $2 == -o ]] || exit 2
{ printf 'age-encryption.org/v1\n'; base64; } >"$3"
EOF
  chmod +x "$mb/bin/age"
  PATH="$mb/bin:$PATH" "$HERE/make-bundle.sh" --host nixos-desktop --host-key "$mb/hostkey" --user-key "$mb/keys.txt" --out-dir "$mb/out" >"$T/mb.out" 2>&1
  assert_rc "make-bundle ok" $? 0
  f=$mb/out/nixos-desktop-clone-bundle.tar.age
  assert_eq "output file name" "$(basename "$f")" "nixos-desktop-clone-bundle.tar.age"
  assert_eq "output mode 600" "$(stat -c %a "$f")" 600
  assert_eq "age header" "$(head -n1 "$f")" "age-encryption.org/v1"
  assert_eq "no stray files in out dir" "$(find "$mb/out" -type f | wc -l)" 1
  members=$(tail -n +2 "$f" | base64 -d | tar -tf - | sort | tr '\n' ' ')
  assert_eq "bundle members" "$members" "host/ host/ssh_host_ed25519_key host/ssh_host_ed25519_key.pub meta.txt user/ user/keys.txt "
  assert_not_contains "plain key text not in the output file" "$(cat "$f")" "AGE-SECRET-KEY"
  PATH="$mb/bin:$PATH" "$HERE/make-bundle.sh" --host nixos-desktop --host-key "$mb/hostkey" --user-key "$mb/keys.txt" --out-dir "$mb/out" >"$T/mb.out" 2>&1
  assert_rc "refuses to overwrite" $? 1
  PATH="$mb/bin:$PATH" "$HERE/make-bundle.sh" --host nixos-desktop --host-key "$mb/hostkey" --user-key "$mb/keys.txt" --out-dir "$mb/out" --force >"$T/mb.out" 2>&1
  assert_rc "--force overwrites" $? 0
  echo 'junk' >"$mb/bad.txt"
  PATH="$mb/bin:$PATH" "$HERE/make-bundle.sh" --host nixos-desktop --host-key "$mb/bad.txt" --user-key "$mb/keys.txt" --out-dir "$mb/out" --force >"$T/mb.out" 2>&1
  assert_rc "non-key host file refused" $? 1
  assert_eq "stage dirs cleaned" "$(find /dev/shm -maxdepth 1 -name 'clone-bundle.*' -user "$(id -un)" 2>/dev/null | wc -l)" 0

  if command -v python3 >/dev/null 2>&1 && command -v age >/dev/null 2>&1 && [[ ${REAL_AGE:-1} == 1 ]]; then
    echo "# real age -p / -d round trip through a pty (throwaway keys)"
    cat >"$T/pty-age.py" <<'EOF'
import os, pty, sys, time, select
mode, passphrase = sys.argv[1], sys.argv[2]
argv = sys.argv[3:]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(argv[0], argv)
buf = b""
sent = 0
while True:
    r, _, _ = select.select([fd], [], [], 20)
    if not r:
        break
    try:
        d = os.read(fd, 4096)
    except OSError:
        break
    if not d:
        break
    buf += d
    if b"passphrase" in buf.lower() and sent < (2 if mode == "enc" else 1):
        time.sleep(0.2)
        os.write(fd, passphrase.encode() + b"\n")
        sent += 1
        buf = b""
_, status = os.waitpid(pid, 0)
sys.exit(os.waitstatus_to_exitcode(status))
EOF
    rm -rf "$mb/out2"
    mkdir -p "$mb/out2"
    python3 -I "$T/pty-age.py" enc harness-pass "$HERE/make-bundle.sh" --host nixos-laptop \
      --host-key "$mb/hostkey" --user-key "$mb/keys.txt" --out-dir "$mb/out2" >/dev/null 2>&1
    assert_rc "real age encryption via pty" $? 0
    rf=$mb/out2/nixos-laptop-clone-bundle.tar.age
    assert_eq "real age file header" "$(head -c 21 "$rf" 2>/dev/null)" "age-encryption.org/v1"
    python3 -I "$T/pty-age.py" dec harness-pass age -d -o "$mb/out2/dec.tar" "$rf" >/dev/null 2>&1
    assert_rc "real age decrypt with the same passphrase" $? 0
    assert_contains "decrypted tar has the user key" "$(tar -xOf "$mb/out2/dec.tar" user/keys.txt 2>/dev/null)" "AGE-SECRET-KEY-1THROWAWAY"
    rm -f "$mb/out2/dec.tar"
  fi
fi

if section_on realnix; then
  echo "# dry-run with the real facts evaluation (no fakes for nix)"
  setup_fakes
  rm -f "$T/bin/nix"
  make_bundle_tar "$T/bundle.tar" nixos-laptop
  export INSTALLER_TEST_DISKS="$WIN"
  mk_origin "$T/origin-full" full
  out=$(printf '' | INSTALLER_ROOT=$T/root/dry INSTALLER_REPO_URL=file://$T/origin-full INSTALLER_WORK_DIR=$T/wd "$HERE/install.sh" --dry-run \
    --host nixos-laptop --variant 2 --disk "$WIN" --mode free --bundle "$T/bundle.tar" 2>&1)
  rc=$?
  assert_rc "dry-run exit" "$rc" 0
  assert_contains "real facts: luks laptop" "$out" "LUKS: yes"
  assert_contains "real facts: uid" "$out" "uid 1000"
  assert_contains "real facts: hostname" "$out" "nixos-laptop-2"
  assert_contains "dry-run prints sgdisk, runs nothing" "$out" "[dry-run] sgdisk"
  assert_contains "dry-run nixos-install line" "$out" "[dry-run] nixos-install"
  assert_contains "dry-run attic from the evaluated config" "$out" "extra-trusted-public-keys krit-nix:"
  assert_eq "dry-run changed no partition" "$(existing_identity "$WIN" | wc -l)" 4
  assert_eq "dry-run left no partitions beyond 4" "$(sfdisk --json "$WIN" | jq '.partitiontable.partitions|length')" 4
fi

echo
echo "passed: $PASS  failed: $FAIL"
((FAIL == 0))
