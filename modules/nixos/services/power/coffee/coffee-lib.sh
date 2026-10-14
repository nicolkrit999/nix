# Shared helpers, prepended to coffee-on.sh / coffee-off.sh / coffee-status.sh / coffee-toggle.sh.

if [[ -n ${COFFEE_PATH_PREFIX:-} ]]; then
  PATH="$COFFEE_PATH_PREFIX:$PATH"
fi

COFFEE_UNIT=coffee.service
COFFEE_SIGNAL=8
COFFEE_WHAT_WEAK="sleep"
COFFEE_WHAT_BLOCK="idle:handle-lid-switch"
COFFEE_USER=${COFFEE_USER:-${USER:-$(id -un)}}
COFFEE_STATE_DIR=${COFFEE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/coffee}
COFFEE_TRIES=${COFFEE_TRIES:-15}
COFFEE_POLL=${COFFEE_POLL:-0.2}
# Exists only while coffee-on enabled linger; survives reboots because linger itself may be persisted.
LINGER_MARKER="$COFFEE_STATE_DIR/linger-by-coffee"
HYPRIDLE_RECORD="$COFFEE_STATE_DIR/hypridle-before"
WAYBAR_PROCS='waybar|\.waybar-wrapped'

C_OK='' C_WARN='' C_FAIL='' C_BOLD='' C_RESET=''
case ${COFFEE_COLOR:-auto} in
  always) use_colour=1 ;;
  never) use_colour=0 ;;
  *) if [[ -t 1 && -z ${NO_COLOR:-} ]]; then use_colour=1; else use_colour=0; fi ;;
esac
if ((use_colour)); then
  C_OK=$'\e[32m' C_WARN=$'\e[33m' C_FAIL=$'\e[31m' C_BOLD=$'\e[1m' C_RESET=$'\e[0m'
fi

n_ok=0
n_warn=0
n_fail=0

journal() {
  logger -t coffee -p "user.$1" -- "$2" 2>/dev/null || true
}

emit() {
  local level=$1 msg=$2 fix=${3:-} tag colour prio line
  case $level in
    OK) tag='[ OK ]' colour=$C_OK prio=info n_ok=$((n_ok + 1)) ;;
    WARN) tag='[WARN]' colour=$C_WARN prio=warning n_warn=$((n_warn + 1)) ;;
    *) tag='[FAIL]' colour=$C_FAIL prio=err n_fail=$((n_fail + 1)) ;;
  esac
  line="$tag $msg"
  if [[ -n $fix ]]; then
    line+="  fix: $fix"
  fi
  printf '%s%s%s %s%s\n' "$colour" "$tag" "$C_RESET" "$msg" "${fix:+  fix: $fix}"
  journal "$prio" "$line"
}

ok() { emit OK "$1"; }
warn() { emit WARN "$1" "$2"; }
fail() { emit FAIL "$1" "$2"; }

summary() {
  local name=$1 state=$2 line colour prio=info rc=0
  if ((n_fail > 0)); then
    line="coffee-$name: FAILED, coffee is $state ($n_ok ok, $n_warn warn, $n_fail fail)"
    colour=$C_FAIL
    prio=err
    rc=1
  elif ((n_warn > 0)); then
    line="coffee-$name: done with warnings, coffee is $state ($n_ok ok, $n_warn warn, 0 fail)"
    colour=$C_WARN
  else
    line="coffee-$name: done, coffee is $state ($n_ok ok, 0 warn, 0 fail)"
    colour=$C_OK
  fi
  printf '%s%s%s%s\n' "$C_BOLD" "$colour" "$line" "$C_RESET"
  journal "$prio" "$line"
  return "$rc"
}

wait_until() {
  local i
  for ((i = 1; i < COFFEE_TRIES; i++)); do
    if "$@"; then
      return 0
    fi
    sleep "$COFFEE_POLL"
  done
  "$@"
}

boot_id() {
  if [[ -n ${COFFEE_BOOT_ID:-} ]]; then
    printf '%s\n' "$COFFEE_BOOT_ID"
  else
    cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown
  fi
}

inhibit_list() {
  systemd-inhibit --list --no-legend --no-pager 2>/dev/null || true
}

coffee_locks() {
  local list
  list=$(inhibit_list)
  grep -E '^coffee[[:space:]]' <<<"$list" || true
}

inhibitor_present() {
  local locks
  locks=$(coffee_locks)
  grep -qE "[[:space:]]${COFFEE_WHAT_WEAK}[[:space:]].*[[:space:]]block-weak[[:space:]]*\$" <<<"$locks" &&
    grep -qE "[[:space:]]${COFFEE_WHAT_BLOCK}[[:space:]].*[[:space:]]block[[:space:]]*\$" <<<"$locks"
}

inhibitor_absent() {
  [[ -z $(coffee_locks) ]]
}

unit_prop() {
  systemctl --user show -p "$2" --value "$1" 2>/dev/null || true
}

unit_loaded() {
  [[ $(unit_prop "$1" LoadState) == loaded ]]
}

unit_active() {
  systemctl --user is-active --quiet "$1" 2>/dev/null
}

coffee_active() { unit_active "$COFFEE_UNIT"; }
hypridle_active() { unit_active hypridle.service; }

linger_state() {
  loginctl show-user "$COFFEE_USER" -p Linger --value 2>/dev/null || true
}

refresh_waybar() {
  local rc=0
  pkill --signal "RTMIN+$COFFEE_SIGNAL" -x "$WAYBAR_PROCS" 2>/dev/null || rc=$?
  case $rc in
    0) ok "waybar: pill refreshed (signal RTMIN+$COFFEE_SIGNAL)" ;;
    1) ok "waybar: not running, nothing to refresh" ;;
    *) warn "waybar: refresh signal failed (pkill exit $rc)" "pkill --signal RTMIN+$COFFEE_SIGNAL -x '$WAYBAR_PROCS'" ;;
  esac
}

notify() {
  if notify-send -a coffee "$1" "$2" 2>/dev/null; then
    ok "notification: sent"
  else
    warn "notification: notify-send failed (no notification daemon in this session?)" "notify-send '$1'"
  fi
}
