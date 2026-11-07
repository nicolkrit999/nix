#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
source "$REPO_ROOT/templates/tests/lib/evidence.sh"
INST="${CLONE_INSTALLER_DIR:-$REPO_ROOT/templates/installer}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

pass() { printf "  %-66s ${GREEN}PASS${NC}\n" "$1"; ((PASS++)) || true; }
fail() { printf "  %-66s ${RED}FAIL${NC}\n" "$1"; ((FAIL++)) || true; FAILURES+=("$1: $2"); }
check() { if [[ $2 == "$3" ]]; then pass "$1"; else fail "$1" "expected [$3] got [$2]"; fi; }
differs() { if [[ $2 != "$3" ]]; then pass "$1"; else fail "$1" "both sides are [$2]"; fi; }
contains() { if [[ $2 == *"$3"* ]]; then pass "$1"; else fail "$1" "missing [$3] in [$2]"; fi; }

WORK=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/clone-installer-test.XXXXXXXX")
trap 'rm -rf "$WORK"' EXIT
NIX_ERR=$WORK/nix.err

echo -e "\n${BOLD}=== clone hosts, installer outputs (one scenario eval) ===${NC}"
tool_paths=$(nix build --no-link --print-out-paths --inputs-from "$REPO_ROOT" \
  nixpkgs#gptfdisk nixpkgs#jq nixpkgs#util-linux 2>"$NIX_ERR") || {
  cat "$NIX_ERR" >&2
  echo "FAIL: could not realise gptfdisk / jq / util-linux"
  exit 1
}
while IFS= read -r p; do [[ -d $p/bin ]] && PATH="$p/bin:$PATH"; done <<<"$tool_paths"
export PATH
for t in sgdisk sfdisk blkid jq; do
  command -v "$t" >/dev/null 2>&1 || { echo "FAIL: $t not found after realising the tools"; exit 1; }
done

if scenario=$(FLAKE_ROOT="$REPO_ROOT" nix eval --json --impure --file "$DIR/01-scenario-clone-installer.nix" 2>"$NIX_ERR"); then
  if [[ $(jq 'length' <<<"$scenario") -lt 40 ]]; then
    fail "scenario eval" "fewer checks than expected: $(jq -c 'keys' <<<"$scenario")"
  fi
  while IFS=$'\t' read -r name value; do
    if [[ $value == ok ]]; then pass "$name"; else fail "$name" "$value"; fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$scenario")
else
  fail "scenario eval" "$(grep -E 'error:' "$NIX_ERR" | head -3 | tr '\n' ' ')"
fi

echo -e "\n${BOLD}=== layout contract: no literal copy in the scripts ===${NC}"
export INSTALLER_TEST=1
# shellcheck source=/dev/null
source "$INST/disk-plan.sh"
if ! dp_layout_load "$INST/layout.nix"; then
  fail "layout.nix loads" "$DP_REASON"
  exit 1
fi
pass "layout.nix loads through dp_layout_load"

layout_literals() {
  grep -nHF -e "$DP_ESP_LABEL" -e "$DP_LUKS_PARTLABEL" -e "$DP_LUKS_MAPPER" \
    -e "$DP_SV_PERSIST" -e "$DP_SV_HOME" -e "$DP_SV_NIX" -e "$DP_SV_LOG" -- "$@" 2>/dev/null |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true
}
hits=$(cd "$INST" && layout_literals disk-plan.sh install.sh make-bundle.sh packages.nix iso.nix hardware-select.nix generic-hardware.nix)
check "no layout value hardcoded in the installer scripts or nix files" "$hits" ""
printf 'mkfs.vfat -n %s "$dev"\n' "$DP_ESP_LABEL" >"$WORK/leak.sh"
differs "control: a script that hardcodes the ESP label is flagged" "$(layout_literals "$WORK/leak.sh")" ""
printf '# comment only: %s\n' "$DP_LUKS_MAPPER" >"$WORK/comment.sh"
check "control: a comment line is not flagged" "$(layout_literals "$WORK/comment.sh")" ""
if grep -q 'layout.nix' "$INST/generic-hardware.nix"; then
  pass "generic-hardware.nix imports layout.nix"
else
  fail "generic-hardware.nix imports layout.nix" "no reference"
fi

echo -e "\n${BOLD}=== disk-plan.sh on sparse image files ===${NC}"
IMG=$WORK/img
mkdir -p "$IMG"

mk_windows() { # name size_gib data_end
  local f=$IMG/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+200M -t1:ef00 -c1:"EFI system partition" \
    -n2:0:+16M -t2:0c01 -c2:"Microsoft reserved partition" \
    -n3:0:"$3" -t3:0700 -c3:"Basic data partition" \
    -n4:0:+1G -t4:2700 -c4:"Windows RE" "$f" >/dev/null
  printf '%s\n' "$f"
}
mk_empty() { truncate -s "${2}G" "$IMG/$1"; printf '%s\n' "$IMG/$1"; }
mk_ubuntu() {
  local f=$IMG/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+512M -t1:ef00 -c1:EFI -n2:0:0 -t2:8300 -c2:ubuntu "$f" >/dev/null
  printf '%s\n' "$f"
}
mk_bare_esp() {
  local f=$IMG/$1
  truncate -s "${2}G" "$f"
  sgdisk -n1:0:+512M -t1:ef00 -c1:EFI "$f" >/dev/null
  printf '%s\n' "$f"
}
img_sig() { { sfdisk -d "$1" 2>/dev/null; stat -c '%Y %s' "$1"; } | sha256sum | cut -d' ' -f1; }
table_of() { sfdisk --json "$1" | jq -S -c '.partitiontable.partitions'; }
old_parts() { # identity of partitions 1..4
  sfdisk --json "$1" | jq -r '.partitiontable.partitions[]
    | select((.node | capture("(?<n>[0-9]+)$").n | tonumber) <= 4)
    | [.start, .size, .type, .uuid, .name] | @tsv'
}
gib() { echo $(($1 / 1073741824)); }

WIN=$(mk_windows win.img 200 +100G)
FULL=$(mk_windows full.img 120 -1025M)
SMALL=$(mk_windows small.img 120 +60G)
EMPTY=$(mk_empty empty.img 200)
UBU=$(mk_ubuntu ubuntu.img 200)
BARE=$(mk_bare_esp bare.img 200)
TINY=$(mk_bare_esp tiny.img 20)

check "classify: Windows disk" "$(dp_classify "$WIN")" windows
check "classify: full Windows disk" "$(dp_classify "$FULL")" windows
check "classify: Ubuntu disk" "$(dp_classify "$UBU")" other-os
check "classify: empty file" "$(dp_classify "$EMPTY")" empty
check "classify: bare ESP with room" "$(dp_classify "$BARE")" free-space
check "classify: bare ESP without room" "$(dp_classify "$TINY")" unknown
differs "control: Windows and Ubuntu disks are told apart" "$(dp_classify "$WIN")" "$(dp_classify "$UBU")"

dp_wipe_allowed "$WIN" ""; check "wipe: Windows disk refused without the ack" $? 1
contains "wipe: refusal names the explicit choice" "$DP_REASON" "no Windows, wipe"
dp_wipe_allowed "$UBU" ""; check "wipe: Ubuntu disk refused without the ack" $? 1
dp_wipe_allowed "$WIN" no-windows-wipe; check "control: Windows disk wipe allowed with the ack" $? 0
dp_wipe_allowed "$EMPTY" ""; check "wipe: empty disk allowed" $? 0
INSTALLER_FAKE_INUSE="$EMPTY" dp_wipe_allowed "$EMPTY" no-windows-wipe
check "wipe: in-use disk refused even with the ack" $? 1

dp_free_space_check "$WIN"; check "free-space: Windows disk with room accepted" $? 0
dp_free_space_check "$FULL"; check "free-space: full Windows disk refused" $? 1
contains "free-space: full disk is told to shrink in Windows" "$DP_REASON" "Shrink the Windows partition in Windows"
dp_free_space_check "$SMALL"; check "free-space: Windows disk below the minimum refused" $? 1
dp_free_space_check "$UBU"; check "free-space: Ubuntu disk refused (no Windows ESP)" $? 1
dp_free_space_check "$EMPTY"; check "free-space: empty disk refused (nothing to sit next to)" $? 1

read -r s z ss <<<"$(dp_largest_free "$WIN")"
check "free block: Windows disk, 1 MiB aligned start" "$((s % 2048))" 0
win_free=$(gib $((z * ss)))
if ((win_free >= 97 && win_free <= 99)); then pass "free block: Windows disk leaves ~98 GiB ($win_free)"; else fail "free block: Windows disk leaves ~98 GiB" "got $win_free GiB"; fi
check "free block: empty disk is (almost) the whole disk" "$(($(dp_free_bytes "$EMPTY") > 199 * 1073741824 ? 1 : 0))" 1
GAP=$IMG/gap.img
truncate -s 300G "$GAP"
sgdisk -n1:0:+200M -t1:ef00 -n2:0:+16M -t2:0c01 -n3:0:+10G -t3:0700 \
  -n4:+5G:+10G -t4:0700 -n5:0:+1G -t5:2700 "$GAP" >/dev/null
check "free block: the largest gap wins, not the first" "$(($(dp_free_bytes "$GAP") > 250 * 1073741824 ? 1 : 0))" 1
read -r gs gz _ <<<"$(dp_largest_free "$GAP")"
last_end=$(sfdisk --json "$GAP" | jq '[.partitiontable.partitions[] | .start + .size] | max')
check "free block: starts at or after the last partition" "$((gs >= last_end ? 1 : 0))" 1

cp --sparse=always "$WIN" "$IMG/win-apply.img"
D=$IMG/win-apply.img
before=$(old_parts "$D")
tbefore=$(table_of "$D")
dp_plan "$D" free 1; check "plan: free-space + LUKS accepted" $? 0
check "plan: new ESP number follows the highest (5)" "$DP_PLAN_ESP_NUM" 5
check "plan: root number" "$DP_PLAN_ROOT_NUM" 6
check "plan: LUKS root type" "$DP_PLAN_ROOT_TYPE" 8309
DRY_RUN=1 apply_partition >/dev/null
check "apply_partition --dry-run changes nothing" "$(table_of "$D")" "$tbefore"
apply_partition >/dev/null; check "apply_partition (free-space, LUKS)" $? 0
check "Windows partitions 1-4 (incl. the Windows ESP) identical after apply" "$(old_parts "$D")" "$before"
check "Windows ESP (partition 1) identical after apply" "$(old_parts "$D" | sed -n 1p)" "$(sed -n 1p <<<"$before")"
newp=$(sfdisk --json "$D" | jq -r '.partitiontable.partitions[]
  | select((.node | capture("(?<n>[0-9]+)$").n | tonumber) > 4)
  | [(.node | capture("(?<n>[0-9]+)$").n), .type, .name, .size] | @tsv')
contains "new ESP: EFI type, label from layout.nix" "$newp" "5	C12A7328-F81F-11D2-BA4B-00A0C93EC93B	$DP_ESP_LABEL"
contains "new root: LUKS type, partlabel from layout.nix" "$newp" "6	CA7D7CCB-63ED-4C53-861C-1742536059CC	$DP_LUKS_PARTLABEL"
esp_sectors=$(awk -F'\t' '$1 == 5 { print $4 }' <<<"$newp")
check "new ESP is 4 GiB" "$((esp_sectors * 512))" "$((4 * 1073741824))"
sgdisk -c 1:renamed "$D" >/dev/null
differs "control: renaming the Windows ESP would be seen by the identity check" "$(old_parts "$D")" "$before"

h=$(img_sig "$WIN")
dp_plan "$FULL" free 1; check "plan: free-space on a full disk fails" $? 1
INSTALLER_FAKE_INUSE="$WIN" dp_plan "$WIN" free 1; check "plan: free-space on an in-use disk fails" $? 1
check "refusals leave the original Windows image untouched" "$(img_sig "$WIN")" "$h"

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if ((FAIL == 0)); then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for f in "${FAILURES[@]}"; do echo -e "  ${RED}✗${NC} $f"; done
exit 1
