#!/usr/bin/env bash
# Usage:
#   bash check-nixos-reboot-to-windows.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-reboot-to-windows.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ok() { printf "  %-100s ${GREEN}PASS${NC}\n" "$1"; PASS=$((PASS + 1)); }
bad() {
  printf "  %-100s ${RED}FAIL${NC}\n" "$1"; FAIL=$((FAIL + 1))
  FAILURES+=("$1|$2")
}
verdict() { if [[ "$1" == "yes" ]]; then ok "$2"; else bad "$2" "$3"; fi; }
is() { [[ "$1" == "$2" ]] && echo yes || echo no; }
isnt() { [[ "$1" != "$2" ]] && echo yes || echo no; }
both() { [[ "$1" == yes && "$2" == yes ]] && echo yes || echo no; }

TAB=$'\t'
GUID="00000000-0000-0000-0000-000000000001"
header() { printf 'BootCurrent: 0001\nTimeout: 1 seconds\nBootOrder: 0001,0000\n'; }
trap_lines() {
  printf 'BootCurrent: 0001 Windows Boot Manager\n'
  printf 'BootNext: 0001 HD(1,GPT,%s,0x800,0x32000)/File(\\EFI\\Microsoft\\Boot\\bootmgfw.efi)\n' "$GUID"
  printf 'BootOrder: 0001,0000 (Windows Boot Manager)\n'
}
linux_entries() {
  printf 'Boot0001* Linux Boot Manager%sHD(1,GPT,%s,0x800,0x32000)/File(\\EFI\\systemd\\systemd-bootx64.efi)\n' "$TAB" "$GUID"
  printf 'Boot0002* UEFI: Built-in EFI Shell%sFvVol(%s)/FvFile(%s)\n' "$TAB" "$GUID" "$GUID"
  printf 'Boot0003* ubuntu%sHD(1,GPT,%s,0x800,0x32000)/File(\\EFI\\ubuntu\\shimx64.efi)\n' "$TAB" "$GUID"
}
win_entry() { # id marker label path
  printf 'Boot%s%s %s%sHD(1,GPT,%s,0x800,0x32000)/File(%s)WINDOWS.........x...B.C.D.O.B.J.E.C.T.=.\n' "$1" "$2" "$3" "$TAB" "$GUID" "$4"
}
fx_windows() { header; win_entry 0000 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'; linux_entries; }
fx_linux_only() { header; linux_entries; }
fx_two() {
  header; win_entry 0000 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'; linux_entries
  win_entry 0007 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'
}
fx_two_rev() {
  header; win_entry 0007 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'; linux_entries
  win_entry 0000 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'
}
fx_renamed_path() { header; linux_entries; win_entry 000a '*' 'Gaming Partition' '\EFI\MICROSOFT\Boot\BootMgFw.EFI'; }
fx_renamed_slash() { header; linux_entries; win_entry 00B1 ' ' 'Dual boot disk' '/EFI/Microsoft/Boot/bootmgfw.efi'; }
fx_lower_label() { header; linux_entries; win_entry 0003 '*' 'windows boot manager' '\EFI\Boot\other.efi'; }
fx_trap_only() { header; trap_lines; linux_entries; }
fx_trap_plus_windows() { header; trap_lines; linux_entries; win_entry 0000 '*' 'Windows Boot Manager' '\EFI\Microsoft\Boot\bootmgfw.efi'; }

SHIMS="$WORK/shims"
mkdir -p "$SHIMS"
printf '#!%s\nprintf "%%s\\n" "$*" >>"$CASE_DIR/efi.log"\ncase "${1:-}" in\n  -v) [ -z "${SHIM_V_RC:-}" ] || exit "$SHIM_V_RC"; cat "$CASE_DIR/listing" ;;\n  --bootnext) exit "${SHIM_NEXT_RC:-0}" ;;\n  *) exit 99 ;;\nesac\n' "$BASH" >"$SHIMS/efibootmgr"
printf '#!%s\nprintf "%%s\\n" "$*" >>"$CASE_DIR/systemctl.log"\n' "$BASH" >"$SHIMS/systemctl"
printf '#!%s\nIFS="|"\nprintf "%%s\\n" "$*" >>"$CASE_DIR/sudo.log"\nexit "${SHIM_SUDO_RC:-0}"\n' "$BASH" >"$SHIMS/sudo"
chmod +x "$SHIMS"/*

OUT=""; ERR=""; EFI=""; SYS=""; SUDO=""; RC=0
run_case() { # script fake-uid fixture-function [script args...]
  local script="$1" uid="$2" fx="$3" case_dir
  shift 3
  case_dir=$(mktemp -d "$WORK/case.XXXXXX")
  "$fx" >"$case_dir/listing"
  : >"$case_dir/efi.log"; : >"$case_dir/systemctl.log"; : >"$case_dir/sudo.log"
  env REBOOT_TO_WINDOWS_EFIBOOTMGR="$SHIMS/efibootmgr" REBOOT_TO_WINDOWS_SYSTEMCTL="$SHIMS/systemctl" \
    REBOOT_TO_WINDOWS_SUDO="$SHIMS/sudo" CASE_DIR="$case_dir" FAKE_UID="$uid" \
    bash -c 'id() { echo "$FAKE_UID"; }; export -f id; exec "$0" "$@"' "$script" "$@" >"$case_dir/out" 2>"$case_dir/err"
  RC=$?
  OUT=$(<"$case_dir/out"); ERR=$(<"$case_dir/err"); EFI=$(<"$case_dir/efi.log")
  SYS=$(<"$case_dir/systemctl.log"); SUDO=$(<"$case_dir/sudo.log")
}

declare -a ORDER=()
declare -A DESC=() REASON=() RESULT=()
t() { # id description yes/no failure-reason
  ORDER+=("$1"); DESC[$1]="$2"; RESULT[$1]="$3"; REASON[$1]="$4"
}
ctx() { printf 'rc=%s out=[%s] err=[%s] efibootmgr=[%s] systemctl=[%s] sudo=[%s]' "$RC" "$OUT" "$ERR" "${EFI//$'\n'/;}" "${SYS//$'\n'/;}" "${SUDO//$'\n'/;}"; }

suite() { # script
  local s="$1" a
  ORDER=(); DESC=(); REASON=(); RESULT=()

  run_case "$s" 0 fx_windows
  a=$(both "$(is "$OUT" 'rebooting into Windows via Boot0000')" "$(both "$(is "$RC" 0)" "$(is "$ERR" '')")")
  t one-out "root, one Windows entry: stdout 'rebooting into Windows via Boot0000', exit 0, empty stderr" "$a" "$(ctx)"
  t one-calls "root, one Windows entry: efibootmgr gets -v then --bootnext 0000, systemctl gets reboot" \
    "$(both "$(is "$EFI" $'-v\n--bootnext 0000')" "$(is "$SYS" reboot)")" "$(ctx)"
  t one-nosudo "root: sudo is not called" "$(is "$SUDO" '')" "$(ctx)"

  run_case "$s" 0 fx_linux_only
  a=$(both "$(is "$ERR" 'no Windows boot entry found')" "$(both "$(is "$RC" 1)" "$(is "$OUT" '')")")
  t none-msg "root, no Windows entry: stderr 'no Windows boot entry found', exit 1, empty stdout" "$a" "$(ctx)"
  t none-calls "root, no Windows entry: only -v is called, no --bootnext, no reboot" \
    "$(both "$(is "$EFI" '-v')" "$(is "$SYS" '')")" "$(ctx)"
  run_case "$s" 1000 fx_linux_only
  t none-nonroot "non-root, no Windows entry: exit 1 and sudo is not called" \
    "$(both "$(is "$RC" 1)" "$(both "$(is "$SUDO" '')" "$(is "$SYS" '')")")" "$(ctx)"

  run_case "$s" 0 fx_two
  a=$(both "$(is "$ERR" 'several Windows boot entries (0000 0007), using the first')" "$(is "$OUT" 'rebooting into Windows via Boot0000')")
  t two-first "root, two entries: warning '(0000 0007), using the first', Boot0000 used" "$a" "$(ctx)"
  t two-calls "root, two entries: --bootnext 0000 and one reboot" \
    "$(both "$(is "$EFI" $'-v\n--bootnext 0000')" "$(is "$SYS" reboot)")" "$(ctx)"
  run_case "$s" 0 fx_two_rev
  a=$(both "$(is "$ERR" 'several Windows boot entries (0007 0000), using the first')" "$(is "$EFI" $'-v\n--bootnext 0007')")
  t two-order "root, two entries with 0007 listed first: listing order wins (--bootnext 0007)" "$a" "$(ctx)"

  run_case "$s" 0 fx_renamed_path
  t mixed-path "renamed label, upper-case backslash path (BootMgFw.EFI): matched, --bootnext 000a" \
    "$(both "$(is "$EFI" $'-v\n--bootnext 000a')" "$(is "$ERR" '')")" "$(ctx)"
  run_case "$s" 0 fx_renamed_slash
  t mixed-slash "inactive entry (no *), upper-case id, forward-slash path: matched, --bootnext 00B1" \
    "$(both "$(is "$EFI" $'-v\n--bootnext 00B1')" "$(is "$ERR" '')")" "$(ctx)"
  run_case "$s" 0 fx_lower_label
  t mixed-label "lower-case label 'windows boot manager' on another path: matched, --bootnext 0003" \
    "$(both "$(is "$EFI" $'-v\n--bootnext 0003')" "$(is "$ERR" '')")" "$(ctx)"

  run_case "$s" 0 fx_trap_only
  t trap-none "BootCurrent/BootNext/BootOrder lines naming Windows never match: exit 1, no --bootnext" \
    "$(both "$(is "$ERR" 'no Windows boot entry found')" "$(both "$(is "$RC" 1)" "$(is "$EFI" '-v')")")" "$(ctx)"
  run_case "$s" 0 fx_trap_plus_windows
  t trap-one "same lines plus one real entry: exactly one match (no 'several' warning), --bootnext 0000" \
    "$(both "$(is "$ERR" '')" "$(is "$EFI" $'-v\n--bootnext 0000')")" "$(ctx)"

  run_case "$s" 1000 fx_windows a 'b c'
  t sudo-reexec "non-root, Windows entry: re-exec through sudo with the script path and its arguments" \
    "$(both "$(is "$SUDO" "$s|a|b c")" "$(both "$(is "$EFI" '-v')" "$(both "$(is "$SYS" '')" "$(is "$OUT" '')")")")" "$(ctx)"
  SHIM_SUDO_RC=7 run_case "$s" 1000 fx_windows
  t sudo-rc "non-root: the exit status of sudo is the script's exit status (7)" "$(is "$RC" 7)" "$(ctx)"

  SHIM_V_RC=2 run_case "$s" 0 fx_windows
  t fail-list "efibootmgr -v failing: script fails, no --bootnext, no reboot, no sudo" \
    "$(both "$(isnt "$RC" 0)" "$(both "$(is "$EFI" '-v')" "$(both "$(is "$SYS" '')" "$(is "$SUDO" '')")")")" "$(ctx)"
  SHIM_NEXT_RC=3 run_case "$s" 0 fx_windows
  t fail-next "--bootnext failing: script fails and never reboots" \
    "$(both "$(isnt "$RC" 0)" "$(both "$(is "$SYS" '')" "$(is "$EFI" $'-v\n--bootnext 0000')")")" "$(ctx)"
}

mutate() { # src dst from to
  local src="$1" dst="$2" text
  text=$(<"$src")
  [[ "$text" == *"$3"* ]] || return 1
  printf '%s\n' "${text/"$3"/"$4"}" >"$dst"
  chmod +x "$dst"
  ! cmp -s "$src" "$dst"
}

failing_ids() { local id; for id in "${ORDER[@]}"; do [[ "${RESULT[$id]}" == yes ]] || printf '%s ' "$id"; done; }

echo ""
echo -e "${BOLD}=== reboot-to-windows: installed by services.lanzaboote only ===${NC}"
if ! json=$(nix eval --json --impure --file "$SCEN" checks 2>"$WORK/eval.err"); then
  bad "evaluation of the scenario" "$(grep -E 'error:' "$WORK/eval.err" | head -3 | tr '\n' ' ')"
  json='{}'
fi
while IFS=$'\t' read -r name result; do
  if [[ "$result" == "ok" ]]; then ok "$name"; else bad "$name" "$result"; fi
done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
[[ "$(jq 'length' <<<"$json")" -gt 0 ]] || bad "eval checks are non-empty" "no check was returned"

echo ""
echo -e "${BOLD}=== reboot-to-windows: the built script against shimmed efibootmgr, systemctl and sudo ===${NC}"
if ! pkg=$(nix build --impure --file "$SCEN" --no-link --print-out-paths script 2>"$WORK/build.err"); then
  bad "build of the reboot-to-windows script" "$(tail -3 "$WORK/build.err" | tr '\n' ' ')"
  pkg=""
fi
SCRIPT="$pkg/bin/reboot-to-windows"
if [[ -z "$pkg" || ! -x "$SCRIPT" ]]; then
  bad "reboot-to-windows binary exists and is executable" "path: '$SCRIPT'"
else
  ok "reboot-to-windows binary exists and is executable"
  suite "$SCRIPT"
  for id in "${ORDER[@]}"; do verdict "${RESULT[$id]}" "${DESC[$id]}" "${REASON[$id]}"; done
  [[ ${#ORDER[@]} -gt 0 ]] || bad "script checks are non-empty" "no check ran"

  echo ""
  echo -e "${BOLD}=== controls: mutated copies of the script must trip the matching checks ===${NC}"
  copy="$WORK/identity"; cp "$SCRIPT" "$copy"; chmod +x "$copy"
  suite "$copy"
  verdict "$([[ -z "$(failing_ids)" ]] && echo yes || echo no)" \
    "control(copy): an unmodified copy of the script passes every check" "failing: $(failing_ids)"

  control() { # name expected-ids from to
    local name="$1" want="$2" from="$3" to="$4" mut="$WORK/mut-$1" got id miss=""
    if ! mutate "$SCRIPT" "$mut" "$from" "$to"; then
      bad "control($name): mutation applies to the script text" "pattern not found or text unchanged: $from"
      return
    fi
    suite "$mut"
    got=" $(failing_ids)"
    for id in $want; do [[ "$got" == *" $id "* ]] || miss="$miss $id"; done
    verdict "$([[ -z "$miss" ]] && echo yes || echo no)" \
      "control($name): checks '$want' fail" "did not fail:$miss (failing:$got)"
  }
  control "case-sensitive grep" "mixed-path mixed-slash mixed-label" 'grep -iE' 'grep -E'
  control "loose Boot anchor" "trap-none trap-one" '^Boot[0-9a-f]{4}\*? .*' '^Boot.*'
  control "no root gate" "sudo-reexec sudo-rc" '[ "$(id -u)" -eq 0 ] || exec "$sudo" "$0" "$@"' ':'
  control "root gate before matching" "none-nonroot" 'if [ -z "$matches" ]; then' '[ "$(id -u)" -eq 0 ] || exec "$sudo" "$0" "$@"; if [ -z "$matches" ]; then'
  control "last match used" "two-first two-order" 'head -n1' 'tail -n1'
  control "silent multi-match" "two-first two-order" 'echo "several' ': "several'
  control "no bootnext" "one-calls two-calls mixed-path" '"$efibootmgr" --bootnext "$entry"' ':'
  control "no reboot" "one-calls two-calls" '"$systemctl" reboot' ':'
  control "no-match exits 0" "none-msg" 'exit 1' 'exit 0'
  control "errexit off" "fail-next" 'set -o errexit' 'set +o errexit'
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  echo -e "  ${RED}x${NC} ${BOLD}${entry%%|*}${NC}"
  echo "    ${entry#*|}"
done
exit 1
