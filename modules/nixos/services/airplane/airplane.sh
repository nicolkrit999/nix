# airplane: Wi-Fi-only or full airplane mode through NetworkManager (persisted across reboots) and rfkill.

if [[ -n ${AIRPLANE_PATH_PREFIX:-} ]]; then
  PATH="$AIRPLANE_PATH_PREFIX:$PATH"
fi

AIRPLANE_SIGNAL=9
WAYBAR_PROCS='waybar|\.waybar-wrapped'
SCOPE_FILE=${AIRPLANE_SCOPE_FILE:-${XDG_STATE_HOME:-$HOME/.local/state}/airplane-scope}
TRIES=${AIRPLANE_TRIES:-15}
POLL=${AIRPLANE_POLL:-0.2}

C_OK='' C_FAIL='' C_DIM='' C_BOLD='' C_RESET=''
case ${AIRPLANE_COLOR:-auto} in
  always) use_colour=1 ;;
  never) use_colour=0 ;;
  *) if [[ -t 1 && -z ${NO_COLOR:-} ]]; then use_colour=1; else use_colour=0; fi ;;
esac
if ((use_colour)); then
  C_OK=$'\e[32m' C_FAIL=$'\e[31m' C_DIM=$'\e[2m' C_BOLD=$'\e[1m' C_RESET=$'\e[0m'
fi

failed_cmds=()
VERDICT=''

usage() {
  cat <<'EOF'
Usage: airplane [wifi|full|off|toggle|pick|status]

  (no argument)  interactive menu: Wi-Fi only off, full airplane, back online
  wifi           Wi-Fi off, every other radio untouched (nmcli radio wifi off)
  full           every radio off (nmcli radio all off + rfkill block all)
  off            back online (nmcli radio all on + rfkill unblock all)
  toggle         back online when any mode is on, else the last chosen scope (default full)
  pick           choose the mode in a vicinae dmenu list
  status         one JSON line for the waybar custom/airplane module
EOF
}

journal() {
  logger -t airplane -p "user.$1" -- "$2" 2>/dev/null || true
}

nm_state() {
  local v
  v=$(nmcli radio "$1" 2>/dev/null || true)
  case $v in
    enabled) echo on ;;
    disabled) echo off ;;
    *) echo unknown ;;
  esac
}

rfkill_types() {
  rfkill -n -r -o TYPE 2>/dev/null | grep -vxE 'wlan|wwan' | sort -u || true
}

rfkill_state() {
  local soft hard any_on=0 any_off=0 any_hard=0
  while read -r soft hard; do
    if [[ $hard == blocked ]]; then
      any_off=1 any_hard=1
    elif [[ $soft == blocked ]]; then
      any_off=1
    elif [[ -n $soft ]]; then
      any_on=1
    fi
  done < <(rfkill -n -r -o SOFT,HARD list "$1" 2>/dev/null || true)
  if ((any_on && any_off)); then
    echo partial
  elif ((any_on)); then
    echo on
  elif ((any_hard)); then
    echo hard-off
  elif ((any_off)); then
    echo off
  else
    echo unknown
  fi
}

type_label() {
  case $1 in
    bluetooth) echo Bluetooth ;;
    nfc) echo NFC ;;
    uwb) echo UWB ;;
    gps) echo GPS ;;
    fm) echo FM ;;
    wimax) echo WiMAX ;;
    *) echo "$1" ;;
  esac
}

rows() {
  local t
  printf 'Wi-Fi\twifi\t%s\n' "$(nm_state wifi)"
  printf 'WWAN\twwan\t%s\n' "$(nm_state wwan)"
  while IFS= read -r t; do
    if [[ -n $t ]]; then
      printf '%s\t%s\t%s\n' "$(type_label "$t")" "$t" "$(rfkill_state "$t")"
    fi
  done < <(rfkill_types)
}

current_mode() {
  local key state others_on=0
  if [[ $(nm_state wifi) != off ]]; then
    echo online
    return 0
  fi
  while IFS=$'\t' read -r _ key state; do
    if [[ $key != wifi && ($state == on || $state == partial) ]]; then
      others_on=1
    fi
  done < <(rows)
  if ((others_on)); then
    echo wifi-off
  else
    echo airplane
  fi
}

mode_label() {
  case $1 in
    online) echo online ;;
    wifi-off) echo "Wi-Fi off" ;;
    airplane) echo "airplane mode" ;;
    *) echo "$1" ;;
  esac
}

state_word() {
  case $1 in
    on) echo on ;;
    off) echo off ;;
    hard-off) echo "off (hardware switch)" ;;
    partial) echo "partly on" ;;
    *) echo unknown ;;
  esac
}

want_for() {
  case $1 in
    wifi)
      if [[ $2 == wifi ]]; then
        echo off
      fi
      ;;
    full) echo off ;;
    off) echo on ;;
  esac
}

matches() {
  if [[ $1 == off ]]; then
    [[ $2 == off || $2 == hard-off ]]
  else
    [[ $2 == on ]]
  fi
}

settled() {
  local key state want
  while IFS=$'\t' read -r _ key state; do
    want=$(want_for "$1" "$key")
    if [[ -n $want ]] && ! matches "$want" "$state"; then
      return 1
    fi
  done < <(rows)
  return 0
}

wait_settled() {
  local i
  for ((i = 1; i < TRIES; i++)); do
    if settled "$1"; then
      return 0
    fi
    sleep "$POLL"
  done
  settled "$1"
}

read_scope() {
  local s=''
  if [[ -r $SCOPE_FILE ]]; then
    s=$(<"$SCOPE_FILE")
  fi
  case $s in
    wifi) echo wifi ;;
    *) echo full ;;
  esac
}

save_scope() {
  { mkdir -p "$(dirname "$SCOPE_FILE")" && printf '%s\n' "$1" >"$SCOPE_FILE"; } 2>/dev/null ||
    printf 'airplane: could not save the scope to %s\n' "$SCOPE_FILE" >&2
}

run() {
  local rc=0
  "$@" || rc=$?
  if ((rc == 0)); then
    journal info "ran: $*"
  else
    failed_cmds+=("$*")
    journal err "failed (exit $rc): $*"
  fi
}

apply() {
  case $1 in
    wifi)
      run nmcli radio wifi off
      ;;
    full)
      run nmcli radio all off
      run rfkill block all
      ;;
    off)
      run nmcli radio all on
      run rfkill unblock all
      ;;
  esac
}

report() {
  local mode=$1 label key state want mark colour note bad=0 now cmd
  while IFS=$'\t' read -r label key state; do
    want=$(want_for "$mode" "$key")
    if [[ -z $want ]]; then
      mark='-' colour=$C_DIM note=' (not touched)'
    elif matches "$want" "$state"; then
      mark='✓' colour=$C_OK note=''
    else
      mark='✗' colour=$C_FAIL note=" (wanted $want)"
      bad=1
    fi
    printf '  %s%s%s %-10s %s%s\n' "$colour" "$mark" "$C_RESET" "$label:" "$(state_word "$state")" "$note"
  done < <(rows)
  for cmd in "${failed_cmds[@]}"; do
    printf '  %s✗%s command failed: %s\n' "$C_FAIL" "$C_RESET" "$cmd"
    bad=1
  done
  now=$(mode_label "$(current_mode)")
  if ((bad)); then
    VERDICT="FAILED, state is now $now"
    printf '%s%sairplane %s: %s%s\n' "$C_BOLD" "$C_FAIL" "$mode" "$VERDICT" "$C_RESET"
    journal err "airplane $mode: $VERDICT"
    return 1
  fi
  VERDICT="done, state is now $now"
  printf '%s%sairplane %s: %s%s\n' "$C_BOLD" "$C_OK" "$mode" "$VERDICT" "$C_RESET"
  journal info "airplane $mode: $VERDICT"
  return 0
}

refresh_waybar() {
  pkill --signal "RTMIN+$AIRPLANE_SIGNAL" -x "$WAYBAR_PROCS" 2>/dev/null || true
}

notify() {
  local urgency=normal
  if (($2 != 0)); then
    urgency=critical
  fi
  notify-send -a airplane -u "$urgency" "Airplane mode" "$1" 2>/dev/null ||
    printf 'airplane: notify-send failed (no notification daemon in this session?)\n' >&2
}

do_mode() {
  local mode=$1 rc=0
  case $mode in
    wifi | full) save_scope "$mode" ;;
  esac
  apply "$mode"
  wait_settled "$mode" || true
  report "$mode" || rc=$?
  refresh_waybar
  notify "$VERDICT" "$rc"
  return "$rc"
}

toggle() {
  if [[ $(current_mode) == online ]]; then
    do_mode "$(read_scope)"
  else
    do_mode off
  fi
}

pick() {
  local choice
  if ! command -v vicinae >/dev/null 2>&1; then
    notify "No picker found (vicinae). Run airplane in a terminal." 1
    printf 'airplane: vicinae not found, run airplane in a terminal for the menu\n' >&2
    return 1
  fi
  choice=$(printf '%s\n' 'Wi-Fi only' 'Full airplane' 'Back online' |
    vicinae dmenu -n 'Airplane mode' -p 'Which radios?') || return 0
  case $choice in
    'Wi-Fi only') do_mode wifi ;;
    'Full airplane') do_mode full ;;
    'Back online') do_mode off ;;
    '') return 0 ;;
    *)
      printf 'airplane: unknown picker entry: %s\n' "$choice" >&2
      return 2
      ;;
  esac
}

interactive() {
  local choice
  printf '%sAirplane mode%s, now: %s\n' "$C_BOLD" "$C_RESET" "$(mode_label "$(current_mode)")"
  printf '  1) Wi-Fi only off (Bluetooth and the rest stay as they are)\n'
  printf '  2) Full airplane (Wi-Fi, WWAN, Bluetooth and every other radio off)\n'
  printf '  3) Back online (every radio on)\n'
  printf '  q) Cancel\n'
  printf 'Choice [1-3/q]: '
  if ! read -r choice; then
    printf '\nairplane: no input, nothing changed\n'
    return 1
  fi
  case $choice in
    1) do_mode wifi ;;
    2) do_mode full ;;
    3) do_mode off ;;
    q | Q | '')
      printf 'airplane: cancelled, nothing changed\n'
      return 0
      ;;
    *)
      printf 'airplane: invalid choice %s, nothing changed\n' "$choice" >&2
      return 2
      ;;
  esac
}

status_json() {
  local now next text tip
  now=$(current_mode)
  if [[ $(read_scope) == wifi ]]; then
    next='Wi-Fi off'
  else
    next='full airplane mode'
  fi
  case $now in
    online)
      text=online
      tip="Radios on. Left click: $next. Right click: choose the mode"
      ;;
    wifi-off)
      text='wifi off'
      tip='Wi-Fi off, other radios on. Left click: back online. Right click: choose the mode'
      ;;
    *)
      text=airplane
      tip='Airplane mode, every radio off. Left click: back online. Right click: choose the mode'
      ;;
  esac
  printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$now" "$now" "$tip"
}

case ${1:-} in
  '') interactive ;;
  wifi | full | off) do_mode "$1" ;;
  toggle) toggle ;;
  pick) pick ;;
  status) status_json ;;
  -h | --help | help) usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
