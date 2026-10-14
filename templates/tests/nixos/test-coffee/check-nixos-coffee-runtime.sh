#!/usr/bin/env bash
# Usage:
#   bash check-nixos-coffee-runtime.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SRC="${COFFEE_SRC:-$REPO_ROOT/modules/nixos/services/power/coffee}"

if ! command -v script >/dev/null || ! command -v grep >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#util-linux nixpkgs#coreutils nixpkgs#gnugrep -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
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
    printf "  %-86s ${GREEN}✓ ok${NC}\n" "$label"
  else
    FAIL=$((FAIL + 1))
    printf "  %-86s ${RED}✗ fail${NC}\n" "$label"
    FAILURES+=("$SECTION: $label")
  fi
}
negate() { ! "$@"; }
section() { SECTION=$1; echo ""; echo -e "${BOLD}$1${NC}"; }

for n in on off status toggle; do
  { echo 'set -euo pipefail'; cat "$SRC/coffee-lib.sh" "$SRC/coffee-$n.sh"; } >"$WORK/coffee-$n.sh"
done

STUBS="$WORK/bin"
mkdir -p "$STUBS"

cat >"$STUBS/systemctl" <<'STUB'
#!/usr/bin/env bash
echo "systemctl $*" >>"$CF_S/calls"
bad() { echo "bad-args systemctl $*" >>"$CF_S/calls"; exit 64; }
danger='(^| )(suspend|hibernate|hybrid-sleep|suspend-then-hibernate|sleep|poweroff|reboot|halt|kexec|soft-reboot|isolate)( |$)'
if [[ " $* " =~ $danger ]]; then echo "FORBIDDEN systemctl $*" >>"$CF_S/calls"; exit 1; fi
[[ ${1:-} == --user ]] || bad "$@"
shift
coffee_state() { cat "$CF_S/unit" 2>/dev/null || echo none; }
hyp() { cat "$CF_S/hypridle"; }
case $1 in
  show)
    [[ $# -eq 5 && $2 == -p && $4 == --value ]] || bad "$@"
    case $5:$3 in
      coffee.service:LoadState) [[ $(coffee_state) == none ]] && echo not-found || echo loaded ;;
      coffee.service:ActiveState) [[ $(coffee_state) == none ]] && echo inactive || coffee_state ;;
      hypridle.service:LoadState) [[ $(hyp) == absent ]] && echo not-found || echo loaded ;;
      hypridle.service:ActiveState) [[ $(hyp) == absent ]] && echo inactive || hyp ;;
      *) bad "$@" ;;
    esac ;;
  is-active)
    [[ $# -eq 3 && $2 == --quiet ]] || bad "$@"
    case $3 in
      coffee.service) [[ $(coffee_state) == active ]] ;;
      hypridle.service) [[ $(hyp) == active ]] ;;
      graphical-session.target) [[ -f $CF_S/graphical ]] ;;
      *) bad "$@" ;;
    esac ;;
  is-failed)
    [[ $# -eq 3 && $2 == --quiet && $3 == coffee.service ]] || bad "$@"
    [[ $(coffee_state) == failed ]] ;;
  stop)
    [[ $# -eq 2 && $2 == coffee.service ]] || bad "$@"
    [[ $(coffee_state) == none ]] && exit 5
    [[ $(cat "$CF_S/stop-mode") == refuse ]] && exit 1
    rm -f "$CF_S/unit"
    grep -v '^coffee ' "$CF_S/locks" >"$CF_S/locks.new" || true
    mv "$CF_S/locks.new" "$CF_S/locks" ;;
  reset-failed)
    [[ $# -eq 2 && $2 == coffee.service ]] || bad "$@"
    [[ $(coffee_state) == failed ]] && rm -f "$CF_S/unit"
    [[ $(coffee_state) == none ]] && exit 1
    exit 0 ;;
  start)
    [[ $# -eq 2 && $2 == hypridle.service ]] || bad "$@"
    echo active >"$CF_S/hypridle" ;;
  *) bad "$@" ;;
esac
STUB

cat >"$STUBS/systemd-run" <<'STUB'
#!/usr/bin/env bash
echo "systemd-run $*" >>"$CF_S/calls"
printf '%s\n' "$@" >"$CF_S/run-argv"
[[ ${1:-} == --user ]] || { echo "bad-args systemd-run $*" >>"$CF_S/calls"; exit 64; }
case $(cat "$CF_S/run-mode") in
  refuse) echo "Failed to start transient service unit: Access denied" >&2; exit 1 ;;
  nolock) echo active >"$CF_S/unit"; exit 0 ;;
esac
echo active >"$CF_S/unit"
pid=4200
while (($#)); do
  if [[ $1 == systemd-inhibit ]]; then
    shift
    what="" mode="" who="" why=""
    while [[ ${1:-} == --* ]]; do
      case $1 in
        --what=*) what=${1#--what=} ;;
        --mode=*) mode=${1#--mode=} ;;
        --who=*) who=${1#--who=} ;;
        --why=*) why=${1#--why=} ;;
      esac
      shift
    done
    pid=$((pid + 1))
    echo "$who 1000 tester $pid systemd-inhibit $what $why $mode" >>"$CF_S/locks"
  else
    shift
  fi
done
STUB

cat >"$STUBS/systemd-inhibit" <<'STUB'
#!/usr/bin/env bash
echo "systemd-inhibit $*" >>"$CF_S/calls"
case "$*" in
  "--list --no-legend --no-pager") ;;
  "--list --no-pager") echo "WHO UID USER PID COMM WHAT WHY MODE" ;;
  *) echo "bad-args systemd-inhibit $*" >>"$CF_S/calls"; exit 64 ;;
esac
cat "$CF_S/locks"
STUB

cat >"$STUBS/loginctl" <<'STUB'
#!/usr/bin/env bash
echo "loginctl $*" >>"$CF_S/calls"
case "$*" in
  "show-user tester -p Linger --value")
    l=$(cat "$CF_S/linger"); [[ -n $l ]] || exit 1; echo "$l" ;;
  "enable-linger tester")
    [[ $(cat "$CF_S/linger-mode") == fail ]] && exit 1
    echo yes >"$CF_S/linger" ;;
  "disable-linger tester") echo no >"$CF_S/linger" ;;
  lock-session* | lock-sessions* | unlock-* | terminate-* | kill-* | poweroff* | reboot* | suspend* | hibernate*)
    echo "FORBIDDEN loginctl $*" >>"$CF_S/calls"; exit 1 ;;
  *) echo "bad-args loginctl $*" >>"$CF_S/calls"; exit 64 ;;
esac
STUB

cat >"$STUBS/busctl" <<'STUB'
#!/usr/bin/env bash
echo "busctl $*" >>"$CF_S/calls"
[[ "$*" == "get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed" ]] ||
  { echo "bad-args busctl $*" >>"$CF_S/calls"; exit 64; }
cat "$CF_S/lid"
STUB

cat >"$STUBS/notify-send" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 4 && $1 == -a && $2 == coffee ]] || { echo "bad-args notify-send $*" >>"$CF_S/calls"; exit 64; }
echo "notify-send $3" >>"$CF_S/calls"
[[ $(cat "$CF_S/notify-mode") != fail ]]
STUB

cat >"$STUBS/logger" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 6 && $1 == -t && $2 == coffee && $3 == -p && $4 == user.* && $5 == -- ]] ||
  { echo "bad-args logger $*" >>"$CF_S/calls"; exit 64; }
printf '%s\t%s\n' "${4#user.}" "$6" >>"$CF_S/journal"
STUB

cat >"$STUBS/pkill" <<'STUB'
#!/usr/bin/env bash
echo "pkill $*" >>"$CF_S/calls"
[[ $# -eq 4 && $1 == --signal && $2 == RTMIN+8 && $3 == -x && $4 == 'waybar|\.waybar-wrapped' ]] ||
  { echo "bad-args pkill $*" >>"$CF_S/calls"; exit 64; }
[[ $(cat "$CF_S/waybar") == running ]]
STUB

for n in on off; do
  printf '#!/usr/bin/env bash\necho "exec coffee-%s" >>"$CF_S/calls"\nexec bash %q "$@"\n' "$n" "$WORK/coffee-$n.sh" >"$STUBS/coffee-$n"
done

for f in hyprctl hyprlock swaylock poweroff reboot shutdown halt brightnessctl wlopm xset systemd-sleep wlr-randr; do
  printf '#!/usr/bin/env bash\necho "FORBIDDEN %s $*" >>"$CF_S/calls"\nexit 1\n' "$f" >"$STUBS/$f"
done
chmod +x "$STUBS"/*

OTHER_LOCKS='NetworkManager 0 root 812 NetworkManager sleep NetworkManager needs to turn off networks delay
coffeemaker 1000 tester 3100 coffeemaker sleep brewing block-weak
steam 1000 tester 3000 steam idle Game running block'

new_state() {
  S="$WORK/$1"
  mkdir -p "$S"
  : >"$S/calls"
  : >"$S/journal"
  printf '%s\n' "$OTHER_LOCKS" >"$S/locks"
  echo no >"$S/linger"
  echo active >"$S/hypridle"
  echo running >"$S/waybar"
  echo "b false" >"$S/lid"
  touch "$S/graphical"
  for k in run-mode stop-mode notify-mode linger-mode; do echo ok >"$S/$k"; done
}

coffee_env() {
  printf '%s\0' COFFEE_PATH_PREFIX="$STUBS" COFFEE_STATE_DIR="$S/state" COFFEE_TRIES=1 COFFEE_POLL=0 \
    COFFEE_BOOT_ID="${BOOT:-boot-A}" COFFEE_USER=tester CF_S="$S" XDG_CURRENT_DESKTOP="${DESK-Hyprland}"
}

run() {
  OUT="$S/out-$2"
  : >"$S/journal"
  mapfile -d '' -t envs < <(coffee_env)
  env -u NO_COLOR -u COFFEE_COLOR "${envs[@]}" ${EXTRA_ENV:+$EXTRA_ENV} bash "$WORK/coffee-$1.sh" >"$OUT" 2>&1
  RC=$?
}

run_tty() {
  OUT="$S/out-$2"
  : >"$S/journal"
  mapfile -d '' -t envs < <(coffee_env)
  local cmd
  printf -v cmd '%q ' env -u NO_COLOR -u COFFEE_COLOR "${envs[@]}" ${EXTRA_ENV:+$EXTRA_ENV} bash "$WORK/coffee-$1.sh"
  SHELL=/bin/sh script -q -e -c "$cmd" /dev/null >"$OUT" 2>&1
  RC=$?
}

has() { grep -Fq -- "$1" "$OUT"; }
line_has() { grep -F -- "$1" "$OUT" | grep -Fq -- "$2"; }
rc_is() { [[ $RC -eq $1 ]]; }
ncalls() { grep -c -- "$1" "$S/calls" || true; }
calls_eq() { [[ $(ncalls "$1") -eq $2 ]]; }
locks_coffee() { grep -c '^coffee ' "$S/locks" || true; }
no_unit() { [[ ! -f $S/unit ]]; }
file_is() { [[ -f $1 && $(cat "$1") == "$2" ]]; }
no_colour() { ! grep -q "$ESC" "$OUT"; }
colour() { grep -q "$ESC\[" "$OUT"; }

steps_well_formed() {
  local body last
  body=$(sed '$d' "$OUT")
  last=$(tail -n 1 "$OUT")
  [[ -n $body ]] || return 1
  ! grep -vE '^\[( OK |WARN|FAIL)\] ' <<<"$body" | grep -q . || return 1
  [[ $last =~ ^coffee-(on|off):\  ]]
}

problems_have_fix() {
  ! grep -E '^\[(WARN|FAIL)\] ' "$OUT" | grep -vE '  fix: [^ ].*$' | grep -q .
}

journal_mirrors() {
  local line prio n_out n_j
  n_out=$(wc -l <"$OUT")
  n_j=$(wc -l <"$S/journal")
  [[ $n_out -gt 0 && $n_out -eq $n_j ]] || return 1
  while IFS= read -r line; do
    case $line in
      '[ OK ] '*) prio=info ;;
      '[WARN] '*) prio=warning ;;
      '[FAIL] '*) prio=err ;;
      *FAILED*) prio=err ;;
      *) prio=info ;;
    esac
    grep -Fxq -- "$prio"$'\t'"$line" "$S/journal" || return 1
  done <"$OUT"
}

run_argv_ok() {
  local a="$S/run-argv"
  [[ -f $a ]] || return 1
  [[ $(head -n 1 "$a") == --user ]] && grep -Fxq -- --unit=coffee "$a" && grep -Fxq -- --collect "$a" || return 1
  local pairs
  pairs=$(awk '/^systemd-inhibit$/{n++} /^--what=/{w[n]=substr($0,8)} /^--mode=/{m[n]=substr($0,8)} END{for(i=1;i<=n;i++) print w[i] " " m[i]}' "$a")
  [[ $pairs == $'sleep block-weak\nidle:handle-lid-switch block' ]] || return 1
  [[ $(grep -c -- '^--who=coffee$' "$a") -eq 2 ]] || return 1
  [[ $(tail -n 2 "$a" | tr '\n' ' ') == "sleep infinity " ]]
}

clean_calls() { ! grep -qE '^(FORBIDDEN|bad-args) ' "$S/calls"; }

echo ""
echo -e "${BOLD}=== Coffee mode: script runtime (stubbed systemd/logind) ===${NC}"
echo -e "${DIM}Runs coffee-lib.sh + coffee-{on,off,status}.sh against stubs that model coffee.service, the inhibitor list and linger.${NC}"

section "static: script text"
strip() { sed -E 's/(^|[[:space:]])#.*$//; s/"([^"\\]|\\.)*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$@"; }
FORBID_RE='(^|[^[:alnum:]_-])(poweroff|reboot|shutdown|halt|hyprctl|hyprlock|swaylock|brightnessctl|wlopm|xset)([^[:alnum:]_-]|$)|systemctl.*(suspend|hibernate|poweroff|reboot)|loginctl[[:space:]]+(lock|unlock|terminate|kill)|[Dd][Pp][Mm][Ss]'
ALL_SRC=("$SRC/coffee-lib.sh" "$SRC/coffee-on.sh" "$SRC/coffee-off.sh" "$SRC/coffee-status.sh" "$SRC/coffee-toggle.sh")
check "no handle-power-key / handle-suspend-key / handle-hibernate-key anywhere" negate grep -qE 'handle-(power|suspend|hibernate)-key' "${ALL_SRC[@]}"
check "inhibitor types defined once: sleep (weak) and idle:handle-lid-switch (block)" \
  bash -c 'grep -Fxq "COFFEE_WHAT_WEAK=\"sleep\"" "$1" && grep -Fxq "COFFEE_WHAT_BLOCK=\"idle:handle-lid-switch\"" "$1"' _ "$SRC/coffee-lib.sh"
check "every --what= uses those two variables (no shutdown or other type)" \
  bash -c '[[ $(grep -ohE -- "--what=[^ ]+" "$@" | sort -u | tr "\n" " ") == "--what=\"\$COFFEE_WHAT_BLOCK\" --what=\"\$COFFEE_WHAT_WEAK\" " ]]' _ "${ALL_SRC[@]}"
check "no suspend/poweroff/reboot/lock/dpms/brightness command outside messages and comments" negate grep -qE "$FORBID_RE" <(strip "${ALL_SRC[@]}")
check "control: the command scan catches 'systemctl suspend', 'loginctl lock-session', 'hyprctl dispatch dpms off'" \
  bash -c '[[ $(printf "%s\n" "systemctl suspend" "loginctl lock-session" "x=1; hyprctl dispatch dpms off" | grep -cE "$1") -eq 3 ]]' _ "$FORBID_RE"
check "control: the command scan ignores quoted prose and comments" \
  negate grep -qE "$FORBID_RE" <(printf '%s\n' 'ok "power button, shutdown and reboot keep working"' '# shutdown and reboot keep working' | strip)

section "lifecycle: on, on again, status, off, off again, status"
new_state lifecycle
run on on1
check "coffee-on exits 0" rc_is 0
check "every line is a [ OK ]/[WARN]/[FAIL] step, last line is the summary" steps_well_formed
check "7 steps, all [ OK ], no [WARN]/[FAIL]" bash -c '[[ $(grep -c "^\[ OK \] " "$1") -eq 7 && $(grep -cE "^\[(WARN|FAIL)\]" "$1") -eq 0 ]]' _ "$OUT"
check "summary: coffee-on: done, coffee is ON (7 ok, 0 warn, 0 fail)" has "coffee-on: done, coffee is ON (7 ok, 0 warn, 0 fail)"
check "systemd-run called once" calls_eq '^systemd-run ' 1
check "systemd-run: --user transient --unit=coffee --collect; sleep block-weak wraps idle:handle-lid-switch block; sleep infinity" run_argv_ok
check "both coffee locks are listed after coffee-on" test "$(locks_coffee)" -eq 2
check "coffee.service is active" file_is "$S/unit" active
check "linger enabled by coffee (enable-linger once, Linger=yes)" bash -c '[[ $(grep -c "^loginctl enable-linger tester$" "$1/calls") -eq 1 && $(cat "$1/linger") == yes ]]' _ "$S"
check "linger marker holds this boot id" file_is "$S/state/linger-by-coffee" boot-A
check "hypridle state recorded before coffee: active" file_is "$S/state/hypridle-before" active
check "waybar pill refreshed (pkill --signal RTMIN+8 -x 'waybar|\\.waybar-wrapped')" calls_eq '^pkill --signal RTMIN+8 ' 1
check "notification 'Coffee mode on' sent" calls_eq '^notify-send Coffee mode on$' 1
check "every output line is in the journal (logger -t coffee) with its priority" journal_mirrors
check "no colour codes when stdout is not a TTY" no_colour

run on on2
check "second coffee-on exits 0" rc_is 0
check "second coffee-on: inhibitor 'already holds', no [WARN]/[FAIL]" bash -c 'grep -Fq "already holds the coffee locks" "$1" && ! grep -qE "^\[(WARN|FAIL)\]" "$1"' _ "$OUT"
check "second coffee-on starts no second unit (systemd-run still 1, locks still 2)" bash -c '[[ $(grep -c "^systemd-run " "$1/calls") -eq 1 && $(grep -c "^coffee " "$1/locks") -eq 2 ]]' _ "$S"
check "second coffee-on: no second notification, no second enable-linger" bash -c '[[ $(grep -c "^notify-send" "$1/calls") -eq 1 && $(grep -c "enable-linger" "$1/calls") -eq 1 ]]' _ "$S"
check "second coffee-on: linger 'already enabled by coffee', marker and hypridle record kept" bash -c 'grep -Fq "linger: already enabled by coffee" "$1" && [[ $(cat "$2/state/linger-by-coffee") == boot-A && $(cat "$2/state/hypridle-before") == active ]]' _ "$OUT" "$S"

run status st-on
check "coffee-status exits 0 when on" rc_is 0
check "coffee-status: 'coffee: ON', linger 'yes (enabled by coffee)'" bash -c 'grep -Fxq "coffee: ON" "$1" && grep -Fq "linger: yes (enabled by coffee)" "$1"' _ "$OUT"
check "coffee-status: still works: manual suspend, suspend/hibernate keys, power button, shutdown, reboot" has "still works: manual suspend, suspend/hibernate keys, power button, shutdown, reboot"
check "coffee-status lists both coffee locks and other block locks, not delay locks" bash -c '[[ $(grep -c "^coffee " "$1") -eq 2 ]] && grep -q "^steam " "$1" && ! grep -q "^NetworkManager " "$1"' _ "$OUT"

run off off1
check "coffee-off exits 0" rc_is 0
check "coffee-off: no [WARN]/[FAIL]" bash -c '! grep -qE "^\[(WARN|FAIL)\]" "$1"' _ "$OUT"
check "coffee-off: steps well-formed" steps_well_formed
check "coffee-off: summary 'coffee is OFF'" has "coffee-off: done, coffee is OFF"
check "coffee-off: lid not reported (lid open)" negate has "lid:"
check "coffee-off stopped coffee.service, no unit left" bash -c 'grep -q "^systemctl --user stop coffee.service$" "$1/calls" && [[ ! -f $1/unit ]]' _ "$S"
check "coffee-off verified: no coffee lock listed, other apps' locks untouched" bash -c '[[ $(grep -c "^coffee " "$1/locks") -eq 0 && $(wc -l <"$1/locks") -eq 3 ]] && grep -Fq "verify: no coffee lock" "$2"' _ "$S" "$OUT"
check "coffee-off: linger disabled again (coffee had enabled it), marker removed" bash -c 'grep -q "^loginctl disable-linger tester$" "$1/calls" && [[ $(cat "$1/linger") == no && ! -f $1/state/linger-by-coffee ]]' _ "$S"
check "coffee-off: hypridle verified active, record removed" bash -c 'grep -Fq "hypridle: active" "$1" && [[ ! -f $2/state/hypridle-before ]]' _ "$OUT" "$S"
check "coffee-off: waybar pill refreshed" calls_eq '^pkill --signal RTMIN+8 ' 3
check "coffee-off: notification 'Coffee mode off' sent" calls_eq '^notify-send Coffee mode off$' 1
check "coffee-off: every output line in the journal" journal_mirrors

stops=$(ncalls '^systemctl --user stop ')
run off off2
check "second coffee-off exits 0, 'already off', no [WARN]/[FAIL]" bash -c '[[ $1 -eq 0 ]] && grep -Fq "coffee was already off" "$2" && ! grep -qE "^\[(WARN|FAIL)\]" "$2"' _ "$RC" "$OUT"
check "second coffee-off: no stop, no disable-linger, no notification" bash -c '[[ $(grep -c "^systemctl --user stop " "$1/calls") -eq $2 && $(grep -c "disable-linger" "$1/calls") -eq 1 && $(grep -c "^notify-send" "$1/calls") -eq 2 ]]' _ "$S" "$stops"
check "second coffee-off: summary 'coffee is OFF'" has "coffee-off: done, coffee is OFF"

run status st-off
check "coffee-status exits 3 and prints 'coffee: OFF' when off" bash -c '[[ $1 -eq 3 ]] && grep -Fxq "coffee: OFF" "$2"' _ "$RC" "$OUT"
check "lifecycle: no forbidden command, every stub called with expected arguments" clean_calls

section "coffee-toggle: off -> on -> off, half-on state, exit code"
new_state toggle
run toggle t-on
check "toggle from off exits 0 and says 'coffee is OFF, running coffee-on'" bash -c '[[ $1 -eq 0 ]] && [[ $(head -n 1 "$2") == "coffee-toggle: coffee is OFF, running coffee-on" ]]' _ "$RC" "$OUT"
check "toggle from off ran coffee-on once and not coffee-off" bash -c '[[ $(grep -c "^exec coffee-on$" "$1/calls") -eq 1 ]] && ! grep -q "^exec coffee-off$" "$1/calls"' _ "$S"
check "toggle from off: coffee.service active, both coffee locks listed" bash -c '[[ $(cat "$1/unit") == active && $(grep -c "^coffee " "$1/locks") -eq 2 ]]' _ "$S"
check "toggle from off: coffee-on's summary 'coffee is ON' is the last line" bash -c '[[ $(tail -n 1 "$1") == "coffee-on: done, coffee is ON (7 ok, 0 warn, 0 fail)" ]]' _ "$OUT"
check "toggle from off: notification 'Coffee mode on' sent, pill refreshed" bash -c '[[ $(grep -c "^notify-send Coffee mode on$" "$1/calls") -eq 1 && $(grep -c "^pkill --signal RTMIN+8 " "$1/calls") -eq 1 ]]' _ "$S"
check "toggle from off: every output line in the journal (toggle line included)" journal_mirrors
run toggle t-off
check "toggle from on exits 0 and says 'coffee is ON, running coffee-off'" bash -c '[[ $1 -eq 0 ]] && [[ $(head -n 1 "$2") == "coffee-toggle: coffee is ON, running coffee-off" ]]' _ "$RC" "$OUT"
check "toggle from on ran coffee-off once (coffee-on still once)" bash -c '[[ $(grep -c "^exec coffee-off$" "$1/calls") -eq 1 && $(grep -c "^exec coffee-on$" "$1/calls") -eq 1 ]]' _ "$S"
check "toggle from on: no unit, no coffee lock, linger back to no" bash -c '[[ ! -f $1/unit && $(grep -c "^coffee " "$1/locks") -eq 0 && $(cat "$1/linger") == no ]]' _ "$S"
check "toggle from on: notification 'Coffee mode off' sent, pill refreshed again" bash -c '[[ $(grep -c "^notify-send Coffee mode off$" "$1/calls") -eq 1 && $(grep -c "^pkill --signal RTMIN+8 " "$1/calls") -eq 2 ]]' _ "$S"
run toggle t-on2
check "third toggle turns coffee on again" bash -c '[[ $1 -eq 0 && $(cat "$2/unit") == active && $(grep -c "^exec coffee-on$" "$2/calls") -eq 2 ]]' _ "$RC" "$S"
check "toggle: no forbidden command (no suspend/lock/dpms), expected arguments" clean_calls

new_state toggle-half
echo active >"$S/unit"
run toggle t-half
check "half on (unit active, no lock): toggle runs coffee-off, exits 0, nothing left" bash -c '[[ $1 -eq 0 && $(head -n 1 "$2") == "coffee-toggle: coffee is INCONSISTENT, running coffee-off" && ! -f $3/unit ]] && grep -q "^exec coffee-off$" "$3/calls" && ! grep -q "^exec coffee-on$" "$3/calls"' _ "$RC" "$OUT" "$S"
check "half on: no forbidden command, expected arguments" clean_calls

new_state toggle-fail
echo refuse >"$S/run-mode"
run on direct
direct_rc=$RC
new_state toggle-fail2
echo refuse >"$S/run-mode"
run toggle t-fail
check "toggle exits with coffee-on's exit code when coffee-on fails (non-zero, equal)" bash -c '[[ $1 -ne 0 && $1 -eq $2 ]] && grep -Fq "coffee-on: FAILED, coffee is OFF" "$3"' _ "$RC" "$direct_rc" "$OUT"
check "failed toggle: no unit, no lock, no notification" bash -c '[[ ! -f $1/unit && $(grep -c "^coffee " "$1/locks") -eq 0 ]] && ! grep -q "^notify-send" "$1/calls"' _ "$S"
check "failed toggle: no forbidden command, expected arguments" clean_calls

section "linger enabled by the user is never disabled by coffee"
new_state linger-user
echo yes >"$S/linger"
run on on
check "coffee-on exits 0, linger 'already enabled (not by coffee, coffee-off leaves it on)'" bash -c '[[ $1 -eq 0 ]] && grep -Fq "already enabled (not by coffee, coffee-off leaves it on)" "$2"' _ "$RC" "$OUT"
check "no enable-linger call, no marker" bash -c '! grep -q enable-linger "$1/calls" && [[ ! -f $1/state/linger-by-coffee ]]' _ "$S"
run off off
check "coffee-off exits 0, linger 'left as is (yes, not enabled by coffee)'" bash -c '[[ $1 -eq 0 ]] && grep -Fq "linger: left as is (yes, not enabled by coffee)" "$2"' _ "$RC" "$OUT"
check "no disable-linger call, Linger still yes" bash -c '! grep -q disable-linger "$1/calls" && [[ $(cat "$1/linger") == yes ]]' _ "$S"
check "no forbidden command, expected arguments" clean_calls

section "stale linger marker from an earlier boot"
new_state linger-stale
echo yes >"$S/linger"
mkdir -p "$S/state"
echo boot-OLD >"$S/state/linger-by-coffee"
run on on
check "coffee-on drops the stale marker and treats linger as not coffee's" bash -c '[[ $1 -eq 0 && ! -f $2/state/linger-by-coffee ]] && grep -Fq "already enabled (not by coffee" "$3"' _ "$RC" "$S" "$OUT"
run off off
check "coffee-off leaves Linger=yes (no disable-linger)" bash -c '[[ $1 -eq 0 && $(cat "$2/linger") == yes ]] && ! grep -q disable-linger "$2/calls"' _ "$RC" "$S"
new_state linger-stale-off
echo yes >"$S/linger"
mkdir -p "$S/state"
echo boot-OLD >"$S/state/linger-by-coffee"
run off off
check "coffee-off with only a stale marker: marker removed, linger left as is" bash -c '[[ $1 -eq 0 && ! -f $2/state/linger-by-coffee && $(cat "$2/linger") == yes ]] && grep -Fq "marker from an earlier boot removed" "$3"' _ "$RC" "$S" "$OUT"
check "no forbidden command, expected arguments" clean_calls

section "FAIL: systemd-run refuses the unit"
new_state fail-run
echo refuse >"$S/run-mode"
run on on
check "coffee-on exits non-zero" negate rc_is 0
check "[FAIL] inhibitor line with fix: systemctl --user reset-failed coffee.service" line_has "[FAIL] inhibitor: systemd-run could not start" "  fix: systemctl --user reset-failed coffee.service"
check "every [WARN]/[FAIL] carries a fix: hint" problems_have_fix
check "summary: coffee-on: FAILED, coffee is OFF" has "coffee-on: FAILED, coffee is OFF"
check "no unit left, no coffee lock" bash -c '[[ ! -f $1/unit && $(grep -c "^coffee " "$1/locks") -eq 0 ]]' _ "$S"
check "no linger change, no notification after a FAIL" bash -c '! grep -qE "enable-linger|^notify-send" "$1/calls" && [[ ! -f $1/state/linger-by-coffee ]]' _ "$S"
check "the FAIL reaches the journal at priority err" bash -c 'grep -q "^err	\[FAIL\] inhibitor" "$1/journal"' _ "$S"
check "no forbidden command, expected arguments" clean_calls

section "FAIL: lock refused (SSH, no local session)"
new_state fail-lock
echo nolock >"$S/run-mode"
DESK="" run on on
check "coffee-on exits non-zero" negate rc_is 0
check "[WARN] desktop: no graphical session, fix: coffee-on" line_has "[WARN] desktop: no graphical session" "  fix: coffee-on"
check "[FAIL] inhibitor: logind refused the lock, fix: coffee-on" line_has "[FAIL] inhibitor: logind refused the lock" "  fix: coffee-on"
check "every [WARN]/[FAIL] carries a fix: hint" problems_have_fix
check "the half-started coffee.service is stopped again, no unit left" bash -c 'grep -q "^systemctl --user stop coffee.service$" "$1/calls" && [[ ! -f $1/unit ]]' _ "$S"
check "no linger change, no notification" bash -c '! grep -qE "enable-linger|^notify-send" "$1/calls"' _ "$S"
check "no forbidden command, expected arguments" clean_calls

section "WARN: KDE session, linger and notification failures"
new_state warn
echo fail >"$S/linger-mode"
echo fail >"$S/notify-mode"
DESK=KDE run on on
check "coffee-on exits 0 (warnings only)" rc_is 0
check "[WARN] desktop KDE, fix: kcmshell6 kcm_powerdevilprofilesconfig" line_has "[WARN] desktop: KDE Plasma" "  fix: kcmshell6 kcm_powerdevilprofilesconfig"
check "[WARN] linger, fix: loginctl enable-linger tester" line_has "[WARN] linger: could not enable it" "  fix: loginctl enable-linger tester"
check "[WARN] notification, fix: notify-send 'Coffee mode on'" line_has "[WARN] notification: notify-send failed" "  fix: notify-send 'Coffee mode on'"
check "every [WARN]/[FAIL] carries a fix: hint" problems_have_fix
check "summary: done with warnings, coffee is ON (4 ok, 3 warn, 0 fail)" has "coffee-on: done with warnings, coffee is ON (4 ok, 3 warn, 0 fail)"
check "WARN lines reach the journal at priority warning" bash -c '[[ $(grep -c "^warning	\[WARN\]" "$1/journal") -eq 3 ]]' _ "$S"
check "no marker when enable-linger failed" negate test -f "$S/state/linger-by-coffee"
echo ok >"$S/notify-mode"
run off off
check "coffee-off then never calls disable-linger" bash -c '[[ $1 -eq 0 ]] && ! grep -q disable-linger "$2/calls"' _ "$RC" "$S"
check "no forbidden command, expected arguments" clean_calls

section "WARN: coffee-off with the lid closed"
new_state lid
run on on
echo "b true" >"$S/lid"
run off off
check "coffee-off exits 0" rc_is 0
check "[WARN] lid: closed ..., fix: coffee-on" line_has "[WARN] lid: closed" "  fix: coffee-on"
check "the lock is still released (no coffee lock, no unit)" bash -c '[[ $(grep -c "^coffee " "$1/locks") -eq 0 && ! -f $1/unit ]]' _ "$S"
check "summary: done with warnings, coffee is OFF" has "coffee-off: done with warnings, coffee is OFF"
check "no forbidden command, expected arguments" clean_calls

section "FAIL: coffee-off cannot release the lock"
new_state fail-off
run on on
echo refuse >"$S/stop-mode"
run off off
check "coffee-off exits non-zero" negate rc_is 0
check "[FAIL] could not stop coffee.service, fix: systemctl --user stop coffee.service" line_has "[FAIL] inhibitor unit: could not stop" "  fix: systemctl --user stop coffee.service"
check "[FAIL] coffee lock still listed, fix: pkill -f -- '--who=coffee'" line_has "[FAIL] verify: a coffee lock is still listed" "  fix: pkill -f -- '--who=coffee'"
check "every [WARN]/[FAIL] carries a fix: hint" problems_have_fix
check "summary: coffee-off: FAILED, coffee is STILL ON" has "coffee-off: FAILED, coffee is STILL ON"
check "no forbidden command, expected arguments" clean_calls

section "hypridle restore"
new_state hypridle-restart
run on on
echo inactive >"$S/hypridle"
run off off
check "hypridle stopped during coffee is started again and verified" bash -c '[[ $1 -eq 0 ]] && grep -q "^systemctl --user start hypridle.service$" "$2/calls" && grep -Fq "started again and verified active" "$3"' _ "$RC" "$S" "$OUT"
new_state hypridle-was-off
echo inactive >"$S/hypridle"
rm -f "$S/graphical"
run on on
run off off
check "control: hypridle that was not running before coffee-on is not started" bash -c '[[ $1 -eq 0 ]] && ! grep -q "start hypridle" "$2/calls" && grep -Fq "not running before coffee-on either" "$3"' _ "$RC" "$S" "$OUT"
check "no forbidden command, expected arguments" clean_calls

section "colour only on a TTY"
new_state tty
check "control: script(1) gives the command a TTY" bash -c '[[ $(SHELL=/bin/sh script -q -e -c "test -t 1 && echo TTY" /dev/null) == TTY* ]]'
run_tty off tty-auto
check "TTY, COFFEE_COLOR unset: colour codes present" colour
check "TTY: the journal stays plain (no escape codes)" negate grep -q "$ESC" "$S/journal"
EXTRA_ENV=COFFEE_COLOR=never run_tty off tty-never
check "TTY, COFFEE_COLOR=never: no colour codes" no_colour
EXTRA_ENV=NO_COLOR=1 run_tty off tty-nocolor
check "TTY, NO_COLOR=1: no colour codes" no_colour
run off pipe-auto
check "pipe, COFFEE_COLOR unset: no colour codes" no_colour
EXTRA_ENV=COFFEE_COLOR=always run off pipe-always
check "pipe, COFFEE_COLOR=always: colour codes present" colour
check "no forbidden command, expected arguments" clean_calls

section "stub controls"
new_state control
CF_S="$S" "$STUBS/systemctl" suspend >/dev/null 2>&1
CF_S="$S" "$STUBS/systemctl" --user poweroff >/dev/null 2>&1
CF_S="$S" "$STUBS/loginctl" lock-session >/dev/null 2>&1
CF_S="$S" "$STUBS/hyprctl" dispatch dpms off >/dev/null 2>&1
CF_S="$S" "$STUBS/systemd-inhibit" --what=shutdown --mode=block true >/dev/null 2>&1
check "control: suspend/poweroff/lock/dpms calls are logged FORBIDDEN (4)" test "$(grep -c '^FORBIDDEN ' "$S/calls")" -eq 4
check "control: a direct systemd-inhibit lock is logged bad-args" grep -q '^bad-args systemd-inhibit --what=shutdown' "$S/calls"
check "control: clean_calls fails on this log" negate clean_calls
printf '%s\n' "[ OK ] a" "[WARN] b" "coffee-on: done" >"$S/out-x"; OUT="$S/out-x"
check "control: a [WARN] without fix: is rejected" negate problems_have_fix
printf '%s\n' "[ OK ] a" "stray" "coffee-on: done" >"$S/out-y"; OUT="$S/out-y"
check "control: a non-step line is rejected" negate steps_well_formed
printf '%s\n' --user --unit=coffee --collect systemd-inhibit --what=sleep --mode=block --who=coffee systemd-inhibit --what=idle:handle-lid-switch --mode=block --who=coffee sleep infinity >"$S/run-argv"
check "control: a full (non-weak) sleep lock is rejected" negate run_argv_ok
printf '%s\n' --user --unit=coffee --collect systemd-inhibit --what=sleep --mode=block-weak --who=coffee systemd-inhibit --what=idle:handle-lid-switch:shutdown --mode=block --who=coffee sleep infinity >"$S/run-argv"
check "control: an added shutdown lock is rejected" negate run_argv_ok

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  echo -e "  ${RED}✗${NC} $entry"
done
for f in "$WORK"/*/out-*; do
  [[ -s $f ]] && keep_evidence "coffee output $(basename "$(dirname "$f")")/$(basename "$f")" "$f"
done
exit 1
