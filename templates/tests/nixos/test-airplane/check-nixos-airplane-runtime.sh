#!/usr/bin/env bash
# Usage:
#   bash check-nixos-airplane-runtime.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SRC="${AIRPLANE_SRC:-$REPO_ROOT/modules/nixos/services/airplane/airplane.sh}"

if ! command -v jq >/dev/null || ! command -v grep >/dev/null || ! command -v sort >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#coreutils nixpkgs#gnugrep -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
ESC=$'\e'

PASS=0
FAIL=0
declare -a FAILURES=()
SECTION=""

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

check() {
  local label=$1
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    printf "  %-100s ${GREEN}✓ ok${NC}\n" "$label"
  else
    FAIL=$((FAIL + 1))
    printf "  %-100s ${RED}✗ fail${NC}\n" "$label"
    FAILURES+=("$SECTION: $label|rc=$RC out=$(tr '\n' '~' <"$S/out" 2>/dev/null) err=$(tr '\n' '~' <"$S/err" 2>/dev/null) calls=$(tr '\n' '~' <"$S/calls" 2>/dev/null)")
  fi
}
negate() { ! "$@"; }
section() { SECTION=$1; echo ""; echo -e "${BOLD}$1${NC}"; }

S="$WORK/state"
STUBS="$WORK/stubs"
VICBIN="$WORK/vicbin"
REALBIN="$WORK/realbin"
mkdir -p "$S" "$STUBS" "$VICBIN" "$REALBIN" "$WORK/home"
for t in bash cat dirname mkdir sort grep sleep; do
  ln -s "$(command -v "$t")" "$REALBIN/$t"
done
BASH_BIN=$(command -v bash)

{ echo 'set -euo pipefail'; cat "$SRC"; } >"$WORK/airplane.sh"

cat >"$STUBS/nmcli" <<'STUB'
#!/usr/bin/env bash
mode=$(cat "$AP_S/nm-mode")
query() {
  echo "radio $1" >>"$AP_S/queries"
  [[ $mode == broken ]] && exit 1
  if [[ -f $AP_S/lagleft ]]; then
    n=$(<"$AP_S/lagleft")
    if ((n <= 0)); then
      while read -r r v; do echo "$v" >"$AP_S/$r"; done <"$AP_S/pending"
      rm -f "$AP_S/lagleft" "$AP_S/pending"
    else
      echo $((n - 1)) >"$AP_S/lagleft"
    fi
  fi
  if [[ $(<"$AP_S/$1") == on ]]; then echo enabled; else echo disabled; fi
}
case "$*" in
  "radio wifi" | "radio wwan") query "$2" ;;
  "radio wifi on" | "radio wifi off" | "radio all on" | "radio all off" | "radio wwan on" | "radio wwan off")
    echo "nmcli $*" >>"$AP_S/calls"
    case $mode in fail) exit 1 ;; stuck) exit 0 ;; esac
    radios=$2
    [[ $radios == all ]] && radios="wifi wwan"
    for r in $radios; do
      if [[ $mode == lag ]]; then
        echo "$r $3" >>"$AP_S/pending"
        echo 4 >"$AP_S/lagleft"
      else
        echo "$3" >"$AP_S/$r"
      fi
    done ;;
  *) echo "bad-args nmcli $*" >>"$AP_S/calls"; exit 64 ;;
esac
STUB

cat >"$STUBS/rfkill" <<'STUB'
#!/usr/bin/env bash
mode=$(cat "$AP_S/rf-mode")
case "$*" in
  "-n -r -o TYPE") cat "$AP_S/types" ;;
  "-n -r -o SOFT,HARD list "*)
    t=${*: -1}
    hard=unblocked
    [[ -f $AP_S/hard_$t ]] && hard=$(<"$AP_S/hard_$t")
    echo "$(<"$AP_S/rf_$t") $hard" ;;
  "block all" | "unblock all")
    echo "rfkill $*" >>"$AP_S/calls"
    case $mode in fail) exit 1 ;; stuck) exit 0 ;; esac
    v=blocked
    [[ $1 == unblock ]] && v=unblocked
    for t in $(sort -u "$AP_S/types"); do echo "$v" >"$AP_S/rf_$t"; done ;;
  *) echo "bad-args rfkill $*" >>"$AP_S/calls"; exit 64 ;;
esac
STUB

cat >"$STUBS/notify-send" <<'STUB'
#!/usr/bin/env bash
echo "notify-send $*" >>"$AP_S/notifs"
STUB
cat >"$STUBS/logger" <<'STUB'
#!/usr/bin/env bash
echo "logger $*" >>"$AP_S/journal"
STUB
cat >"$STUBS/pkill" <<'STUB'
#!/usr/bin/env bash
echo "pkill $*" >>"$AP_S/pkills"
STUB
cat >"$VICBIN/vicinae" <<'STUB'
#!/usr/bin/env bash
echo "vicinae $*" >>"$AP_S/vicinae-args"
cat >"$AP_S/vicinae-in"
rc=$(<"$AP_S/vicinae-rc")
[[ $rc == 0 ]] && cat "$AP_S/vicinae-choice"
exit "$rc"
STUB
chmod +x "$STUBS"/* "$VICBIN"/*

reset() {
  rm -rf "$S"
  mkdir -p "$S"
  : >"$S/calls"; : >"$S/queries"; : >"$S/notifs"; : >"$S/journal"; : >"$S/pkills"; : >"$S/stdin"
  printf '%s\n' wlan bluetooth wwan nfc >"$S/types"
  echo normal >"$S/nm-mode"; echo normal >"$S/rf-mode"
  echo 0 >"$S/vicinae-rc"; echo "Wi-Fi only" >"$S/vicinae-choice"
  radios on on on on
  unset AP_TRIES AP_COLOR AP_PICKER
  RC=0
}
radios() {
  echo "$1" >"$S/wifi"; echo "$2" >"$S/wwan"
  local v
  for pair in "wlan:$1" "bluetooth:$3" "wwan:$2" "nfc:$4"; do
    v=unblocked
    [[ ${pair#*:} == off ]] && v=blocked
    echo "$v" >"$S/rf_${pair%%:*}"
  done
}

SCRIPT="$WORK/airplane.sh"
ap() {
  local path="$STUBS"
  [[ -n ${AP_PICKER:-} ]] && path="$STUBS:$VICBIN"
  env -i PATH="$REALBIN" HOME="$WORK/home" AP_S="$S" \
    AIRPLANE_PATH_PREFIX="$path" AIRPLANE_SCOPE_FILE="$S/scope" AIRPLANE_POLL=0 \
    AIRPLANE_TRIES="${AP_TRIES:-15}" AIRPLANE_COLOR="${AP_COLOR:-never}" \
    "$BASH_BIN" "$SCRIPT" "$@" <"$S/stdin" >"$S/out" 2>"$S/err"
  RC=$?
}

calls_are() {
  local want
  want=$(printf '%s\n' "$@")
  [[ $# -eq 0 ]] && want=""
  [[ $(<"$S/calls") == "$want" ]]
}
out_has() { grep -qE -- "$1" "$S/out"; }
out_lacks() { ! grep -qE -- "$1" "$S/out"; }
err_empty() { [[ ! -s $S/err ]]; }
rc_is() { [[ $RC -eq $1 ]]; }
scope_is() { [[ -f $S/scope && $(<"$S/scope") == "$1" ]]; }
no_scope() { [[ ! -e $S/scope ]]; }
notif_is() { [[ $(<"$S/notifs") == "$1" ]]; }
no_notif() { [[ ! -s $S/notifs ]]; }
pkilled() { [[ $(<"$S/pkills") == 'pkill --signal RTMIN+9 -x waybar|\.waybar-wrapped' ]]; }
no_pkill() { [[ ! -s $S/pkills ]]; }
json_is() {
  jq -e --arg t "$1" --arg a "$2" '.text == $t and .alt == $a and .class == $a and (.tooltip | type == "string" and length > 0) and (keys | sort == ["alt","class","text","tooltip"])' "$S/out" >/dev/null 2>&1
}
tip_has() { jq -e --arg s "$1" '.tooltip | contains($s)' "$S/out" >/dev/null 2>&1; }
one_line() { [[ $(wc -l <"$S/out") -eq 1 ]]; }

section "airplane wifi: Wi-Fi off only"
reset; ap wifi
check "exact calls: only nmcli radio wifi off" calls_are "nmcli radio wifi off"
check "exit 0, no stderr" rc_is 0
check "scope saved as wifi" scope_is wifi
check "Wi-Fi line is a check mark: off" out_has '^  ✓ Wi-Fi: +off$'
check "WWAN is not touched (dash, still on)" out_has '^  - WWAN: +on \(not touched\)$'
check "Bluetooth is not touched (dash, still on)" out_has '^  - Bluetooth: +on \(not touched\)$'
check "NFC (extra rfkill type) is listed and not touched" out_has '^  - NFC: +on \(not touched\)$'
check "wlan and wwan rfkill rows are not listed twice" negate out_has '^  . (wlan|wwan):'
check "verdict line: Wi-Fi off" out_has '^airplane wifi: done, state is now Wi-Fi off$'
check "no stderr output" err_empty
check "normal notification with the verdict" notif_is 'notify-send -a airplane -u normal Airplane mode done, state is now Wi-Fi off'
check "waybar refreshed with RTMIN+9" pkilled

section "airplane full: every radio off"
reset; ap full
check "exact calls: nmcli radio all off, then rfkill block all" calls_are "nmcli radio all off" "rfkill block all"
check "exit 0, no stderr" rc_is 0
check "scope saved as full" scope_is full
check "Wi-Fi off with a check mark" out_has '^  ✓ Wi-Fi: +off$'
check "WWAN off with a check mark" out_has '^  ✓ WWAN: +off$'
check "Bluetooth off with a check mark" out_has '^  ✓ Bluetooth: +off$'
check "NFC off with a check mark" out_has '^  ✓ NFC: +off$'
check "no cross and no dash lines" negate out_has '^  [✗-] '
check "verdict line: airplane mode" out_has '^airplane full: done, state is now airplane mode$'
check "normal notification with the verdict" notif_is 'notify-send -a airplane -u normal Airplane mode done, state is now airplane mode'
check "waybar refreshed with RTMIN+9" pkilled
check "journal records the commands" grep -q 'logger -t airplane -p user.info -- ran: rfkill block all' "$S/journal"

section "airplane off: back online"
reset; radios off off off off; echo wifi >"$S/scope"; ap off
check "exact calls: nmcli radio all on, then rfkill unblock all" calls_are "nmcli radio all on" "rfkill unblock all"
check "exit 0, no stderr" rc_is 0
check "scope file left unchanged (still wifi)" scope_is wifi
check "Wi-Fi on with a check mark" out_has '^  ✓ Wi-Fi: +on$'
check "WWAN on with a check mark" out_has '^  ✓ WWAN: +on$'
check "Bluetooth on with a check mark" out_has '^  ✓ Bluetooth: +on$'
check "verdict line: online" out_has '^airplane off: done, state is now online$'
reset; radios off off off off; ap off
check "off never creates a scope file" no_scope

section "airplane status: one JSON line per state, no side effects"
reset; ap status
check "online: text/alt/class online" json_is online online
check "online: a single output line, no stderr" one_line
check "online, no scope saved: tooltip names full airplane mode as the left click" tip_has "Left click: full airplane mode"
check "status makes no mutating call, no notification, no waybar refresh" calls_are
check "status sends nothing" no_notif
check "status does not signal waybar" no_pkill
reset; echo wifi >"$S/scope"; ap status
check "online, scope wifi: tooltip names Wi-Fi off as the left click" tip_has "Left click: Wi-Fi off"
reset; radios off on on on; ap status
check "wifi off, wwan and bluetooth on: text 'wifi off', alt/class wifi-off" json_is "wifi off" wifi-off
reset; radios off off on off; ap status
check "wifi off, wwan off, bluetooth still on: wifi-off" json_is "wifi off" wifi-off
reset; radios off on off off; ap status
check "wifi off, wwan still on, rfkill radios off: wifi-off" json_is "wifi off" wifi-off
reset; radios off off off off; ap status
check "everything off: text airplane, alt/class airplane" json_is airplane airplane
check "airplane tooltip names back online as the left click" tip_has "Left click: back online"
reset; radios on off off off; ap status
check "wifi on, the rest off: online (state follows Wi-Fi)" json_is online online
reset; echo broken >"$S/nm-mode"; radios off off off off; ap status
check "nmcli failing: reported as online, valid JSON" json_is online online

section "airplane toggle"
reset; ap toggle
check "online, no scope: applies full" calls_are "nmcli radio all off" "rfkill block all"
check "online, no scope: scope file written as full" scope_is full
reset; echo wifi >"$S/scope"; ap toggle
check "online, scope wifi: applies wifi only" calls_are "nmcli radio wifi off"
reset; echo full >"$S/scope"; ap toggle
check "online, scope full: applies full" calls_are "nmcli radio all off" "rfkill block all"
reset; echo bogus >"$S/scope"; ap toggle
check "garbage scope file reads as full" calls_are "nmcli radio all off" "rfkill block all"
reset; echo wifi >"$S/scope"; radios off on on on; ap toggle
check "wifi-off state: toggle goes back online" calls_are "nmcli radio all on" "rfkill unblock all"
check "toggle back online keeps the saved scope" scope_is wifi
reset; radios off off off off; ap toggle
check "airplane state: toggle goes back online" calls_are "nmcli radio all on" "rfkill unblock all"
check "toggle notifies the verdict" notif_is 'notify-send -a airplane -u normal Airplane mode done, state is now online'

section "interactive menu"
reset; printf '1\n' >"$S/stdin"; ap
check "choice 1: Wi-Fi only" calls_are "nmcli radio wifi off"
check "menu lists the three options and the current state" out_has '^  1\) Wi-Fi only off'
check "menu lists full airplane" out_has '^  2\) Full airplane'
check "menu lists back online" out_has '^  3\) Back online'
check "confirmation printed after the choice" out_has '^airplane wifi: done, state is now Wi-Fi off$'
reset; printf '2\n' >"$S/stdin"; ap
check "choice 2: full airplane" calls_are "nmcli radio all off" "rfkill block all"
check "choice 2: verdict printed" out_has '^airplane full: done, state is now airplane mode$'
reset; radios off off off off; printf '3\n' >"$S/stdin"; ap
check "choice 3: back online" calls_are "nmcli radio all on" "rfkill unblock all"
reset; printf 'q\n' >"$S/stdin"; ap
check "q: nothing changed, exit 0" calls_are
check "q: says cancelled" out_has 'cancelled, nothing changed'
check "q: no scope, no notification" no_scope
reset; printf '\n' >"$S/stdin"; ap
check "empty line cancels" calls_are
reset; printf '7\n' >"$S/stdin"; ap
check "invalid choice: exit 2, nothing changed" rc_is 2
check "invalid choice: no calls" calls_are
check "invalid choice: error on stderr" grep -q 'invalid choice 7' "$S/err"
reset; ap
check "end of input: exit 1, nothing changed" rc_is 1
check "end of input: no calls" calls_are

section "failures are reported, not hidden"
reset; echo fail >"$S/nm-mode"; ap full
check "failing nmcli: exit 1" rc_is 1
check "failing nmcli: its own cross line names the command" out_has '^  ✗ command failed: nmcli radio all off$'
check "failing nmcli: Wi-Fi row shows a cross with the wanted state" out_has '^  ✗ Wi-Fi: +on \(wanted off\)$'
check "failing nmcli: FAILED verdict" out_has '^airplane full: FAILED, state is now online$'
check "failing nmcli: rfkill still attempted" calls_are "nmcli radio all off" "rfkill block all"
check "failing nmcli: critical notification" notif_is 'notify-send -a airplane -u critical Airplane mode FAILED, state is now online'
reset; echo fail >"$S/rf-mode"; ap full
check "failing rfkill: exit 1 and its cross line" out_has '^  ✗ command failed: rfkill block all$'
check "failing rfkill: Bluetooth row shows the cross" out_has '^  ✗ Bluetooth: +on \(wanted off\)$'
reset; echo stuck >"$S/nm-mode"; AP_TRIES=3 ap wifi
check "command succeeds but the radio never changes: exit 1" rc_is 1
check "stuck radio: Wi-Fi cross with wanted off" out_has '^  ✗ Wi-Fi: +on \(wanted off\)$'
check "stuck radio: FAILED verdict" out_has '^airplane wifi: FAILED, state is now online$'
check "stuck radio: no command-failed line (exit codes were 0)" out_lacks 'command failed'
check "stuck radio: critical notification" grep -q -- '-u critical' "$S/notifs"
reset; ap wifi
NORMAL_Q=$(grep -c '^radio wifi$' "$S/queries")
reset; echo lag >"$S/nm-mode"; ap wifi
check "slow NetworkManager (applies after a few reads): still succeeds" rc_is 0
check "slow NetworkManager: final state read back is correct" out_has '^  ✓ Wi-Fi: +off$'
check "slow NetworkManager: the script polled again until it settled" test "$(grep -c '^radio wifi$' "$S/queries")" -gt "$NORMAL_Q"
reset; radios on on off on; echo blocked >"$S/hard_bluetooth"; ap full
check "hardware-blocked Bluetooth counts as off for full airplane" out_has '^  ✓ Bluetooth: +off \(hardware switch\)$'
reset; radios off off off off; echo blocked >"$S/hard_bluetooth"; ap off
check "hardware-blocked Bluetooth cannot be turned on: cross" out_has '^  ✗ Bluetooth: +off \(hardware switch\) \(wanted on\)$'
check "hardware-blocked: FAILED verdict, exit 1" rc_is 1

section "scope picker (vicinae dmenu)"
reset; AP_PICKER=1; echo "Wi-Fi only" >"$S/vicinae-choice"; ap pick
check "Wi-Fi only: wifi calls" calls_are "nmcli radio wifi off"
check "picker called with the dmenu title and prompt" test "$(<"$S/vicinae-args")" = "vicinae dmenu -n Airplane mode -p Which radios?"
check "picker list holds the three entries in order" test "$(<"$S/vicinae-in")" = "$(printf 'Wi-Fi only\nFull airplane\nBack online')"
check "pick saves the scope" scope_is wifi
reset; AP_PICKER=1; echo "Full airplane" >"$S/vicinae-choice"; ap pick
check "Full airplane: full calls" calls_are "nmcli radio all off" "rfkill block all"
reset; AP_PICKER=1; radios off off off off; echo "Back online" >"$S/vicinae-choice"; ap pick
check "Back online: online calls" calls_are "nmcli radio all on" "rfkill unblock all"
reset; AP_PICKER=1; echo 1 >"$S/vicinae-rc"; ap pick
check "escape (picker exit 1): nothing changed, exit 0" calls_are
check "escape: exit 0, no notification" rc_is 0
reset; AP_PICKER=1; : >"$S/vicinae-choice"; ap pick
check "empty pick changes nothing" calls_are
reset; AP_PICKER=1; echo "Something else" >"$S/vicinae-choice"; ap pick
check "unknown entry: exit 2, nothing changed" rc_is 2
check "unknown entry: no calls" calls_are
reset; ap pick
check "vicinae missing: exit 1, no calls" rc_is 1
check "vicinae missing: critical notification names vicinae" grep -q 'notify-send -a airplane -u critical Airplane mode No picker found (vicinae)' "$S/notifs"
check "vicinae missing: no calls" calls_are

section "arguments, colour"
reset; ap help
check "help: usage text, exit 0" out_has '^Usage: airplane \['
reset; ap bogus
check "unknown argument: exit 2, usage on stderr" rc_is 2
check "unknown argument: usage printed to stderr" grep -q '^Usage: airplane' "$S/err"
check "unknown argument: no calls" calls_are
reset; AP_COLOR=always ap full
check "colour always: check marks are wrapped in green escapes" grep -q "${ESC}\[32m✓${ESC}\[0m" "$S/out"
reset; echo stuck >"$S/nm-mode"; AP_TRIES=2 AP_COLOR=always ap wifi
check "colour always: crosses are wrapped in red escapes" grep -q "${ESC}\[31m✗${ESC}\[0m" "$S/out"
reset; ap full
check "colour never: no escape bytes in the output" negate grep -q "$ESC" "$S/out"

section "controls: mutated scripts must be caught"
mutant() {
  sed "$1" "$WORK/airplane.sh" >"$WORK/mutant.sh"
  cmp -s "$WORK/airplane.sh" "$WORK/mutant.sh" && echo "MUTANT UNCHANGED: $1" >&2
  SCRIPT="$WORK/mutant.sh"
}
mutant 's/run nmcli radio wifi off/run nmcli radio wifi on/'; reset; ap wifi
check "control: wrong nmcli arguments make the exact-calls check fail" negate calls_are "nmcli radio wifi off"
mutant 's/      run rfkill block all//'; reset; ap full
check "control: dropping rfkill block all makes the exact-calls check fail" negate calls_are "nmcli radio all off" "rfkill block all"
check "control: dropping rfkill block all leaves Bluetooth with a cross" out_has '^  ✗ Bluetooth: +on \(wanted off\)$'
mutant "s/mark='✗' colour=\$C_FAIL/mark='✓' colour=\$C_FAIL/"; reset; echo stuck >"$S/nm-mode"; AP_TRIES=2 ap wifi
check "control: a script that prints a check mark for a failed radio is caught" negate out_has '^  ✗ Wi-Fi: '
mutant 's/echo wifi-off/echo online/'; reset; radios off on on on; ap status
check "control: a mutated state decision is caught by the status check" negate json_is "wifi off" wifi-off
mutant 's/wifi | full) save_scope "\$mode" ;;/wifi | full) : ;;/'; reset; ap full
check "control: a script that does not save the scope is caught" negate scope_is full
SCRIPT="$WORK/airplane.sh"; reset; ap full
check "control: the unmutated script passes the same checks" calls_are "nmcli radio all off" "rfkill block all"

echo ""
echo "──────────────────────────────────────────────────────────────────────"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo "    → $detail"
done
exit 1
