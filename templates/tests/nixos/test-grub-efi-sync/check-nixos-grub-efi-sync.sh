#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
SCENARIO="$DIR/01-scenario-grub-efi-sync.nix"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
trap 'chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

pass() { printf "  %-66s ${GREEN}PASS${NC}\n" "$1"; ((PASS++)) || true; }
fail() { printf "  %-66s ${RED}FAIL${NC}\n" "$1"; ((FAIL++)) || true; FAILURES+=("$1: $2"); }

run_check() {
  local attr="$1" label="$2" result err
  err=$(mktemp)
  if result=$(nix eval --raw --impure --file "$SCENARIO" "$attr" 2>"$err"); then
    if [[ "$result" == "ok" ]]; then pass "$label"; else fail "$label" "$result"; fi
  else
    fail "$label" "eval error: $(grep -E 'error:' "$err" | head -2 | tr '\n' ' ')"
  fi
  rm -f "$err"
}

assert() { # label, condition-exit-status, detail
  if [[ "$2" == 0 ]]; then pass "$1"; else fail "$1" "$3"; fi
}

new_sandbox() {
  SB="$WORK/sb$((++N))"
  mkdir -p "$SB/boot/grub/x86_64-efi" "$SB/boot/EFI/NixOS-boot" "$SB/boot/EFI/BOOT"
}

run_hook() { # populates OUT, ERR, RC
  OUT=$(bash "$HOOK" 2>"$WORK/stderr"); RC=$?
  ERR=$(cat "$WORK/stderr")
}

N=0
echo -e "\n${BOLD}=== GRUB stale-EFI-copy sync hook ===${NC}"

for host in "${HOSTS[@]}"; do
  echo -e "\n${BOLD}${host}${NC}"
  for c in nonempty source-core target-glob no-set-e no-exit grub-efi-removable; do
    run_check "check-${host}-${c}" "${c}"
  done

  RAW="$WORK/raw-$host.sh"
  if ! nix eval --raw --impure --file "$SCENARIO" "script-${host}" >"$RAW" 2>/dev/null; then
    fail "extract script" "could not evaluate script-${host}"; continue
  fi

  bash -n "$RAW" 2>"$WORK/synerr"
  assert "bash -n parses" $? "$(cat "$WORK/synerr")"

  SB=""; HOOK="$WORK/hook-$host.sh"
  rewrite() { sed -E -e 's#/nix/store/[^/ ]+/bin/##g' -e "s#/boot/#$SB/boot/#g" "$RAW" >"$HOOK"; }

  new_sandbox; rewrite
  ! grep '/boot' "$HOOK" | grep -qvF "$SB/boot"
  assert "all /boot refs sandboxed, only cmp/cp store paths" $? "unrewritten /boot reference"
  ! grep -q '/nix/store' "$HOOK"
  assert "no store paths other than bin/ tools remain" $? "unexpected store path remains"

  # stale copy gets replaced
  new_sandbox; rewrite
  printf 'NEW-GRUB' >"$SB/boot/grub/x86_64-efi/core.efi"
  printf 'OLD-GRUB' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
  run_hook
  [[ $RC == 0 && "$(cat "$SB/boot/EFI/NixOS-boot/grubx64.efi")" == NEW-GRUB && "$OUT" == *"refreshed stale GRUB copy"* ]]
  assert "stale copy replaced, message printed, exit 0" $? "rc=$RC out=$OUT"

  # identical copy untouched, silent
  new_sandbox; rewrite
  printf 'SAME' >"$SB/boot/grub/x86_64-efi/core.efi"
  printf 'SAME' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
  run_hook
  [[ $RC == 0 && -z "$OUT" && -z "$ERR" ]]
  assert "identical copy: no message, exit 0" $? "rc=$RC out=$OUT err=$ERR"

  # multiple NixOS* dirs all refreshed; non-NixOS dirs untouched
  new_sandbox; rewrite
  mkdir -p "$SB/boot/EFI/NixOS"
  printf 'NEW' >"$SB/boot/grub/x86_64-efi/core.efi"
  printf 'OLD1' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
  printf 'OLD2' >"$SB/boot/EFI/NixOS/grubx64.efi"
  printf 'KEEP' >"$SB/boot/EFI/BOOT/grubx64.efi"
  run_hook
  [[ $RC == 0 && "$(cat "$SB/boot/EFI/NixOS-boot/grubx64.efi")" == NEW \
     && "$(cat "$SB/boot/EFI/NixOS/grubx64.efi")" == NEW \
     && "$(cat "$SB/boot/EFI/BOOT/grubx64.efi")" == KEEP ]]
  assert "all NixOS* copies refreshed, EFI/BOOT untouched" $? "rc=$RC"

  # no core.efi -> no change
  new_sandbox; rewrite
  printf 'OLD' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
  run_hook
  [[ $RC == 0 && "$(cat "$SB/boot/EFI/NixOS-boot/grubx64.efi")" == OLD && -z "$OUT" ]]
  assert "no core.efi: exit 0, target unchanged" $? "rc=$RC out=$OUT"

  # no NixOS* dir -> exit 0, nothing created
  new_sandbox; rewrite
  rmdir "$SB/boot/EFI/NixOS-boot"
  printf 'NEW' >"$SB/boot/grub/x86_64-efi/core.efi"
  run_hook
  [[ $RC == 0 && -z "$OUT" && ! -e "$SB/boot/EFI/NixOS-boot" ]]
  assert "no NixOS* dir: exit 0, nothing created" $? "rc=$RC out=$OUT"

  # unwritable target -> exit 0 + WARNING on stderr
  if [[ $(id -u) != 0 ]]; then
    new_sandbox; rewrite
    printf 'NEW' >"$SB/boot/grub/x86_64-efi/core.efi"
    printf 'OLD' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
    chmod 444 "$SB/boot/EFI/NixOS-boot/grubx64.efi"
    run_hook
    [[ $RC == 0 && "$ERR" == *"WARNING: could not refresh"* && "$(cat "$SB/boot/EFI/NixOS-boot/grubx64.efi")" == OLD ]]
    assert "read-only target: exit 0 + WARNING, unchanged" $? "rc=$RC err=$ERR"
  fi

  # control: hook run under set -e still exits 0 on failure path is covered above;
  # control that the check bites: a hook with cp removed must NOT replace the stale copy
  new_sandbox; rewrite
  printf 'NEW' >"$SB/boot/grub/x86_64-efi/core.efi"
  printf 'OLD' >"$SB/boot/EFI/NixOS-boot/grubx64.efi"
  sed -i 's/cp /true /' "$HOOK"
  run_hook
  [[ "$(cat "$SB/boot/EFI/NixOS-boot/grubx64.efi")" == OLD ]]
  assert "control: sabotaged hook leaves stale copy (checks can fail)" $? "sabotaged hook still replaced file"
done

echo -e "\n${BOLD}Summary:${NC} ${PASS} passed, ${FAIL} failed"
if (( FAIL > 0 )); then
  for f in "${FAILURES[@]}"; do echo -e "  ${RED}x${NC} $f"; done
  exit 1
fi
