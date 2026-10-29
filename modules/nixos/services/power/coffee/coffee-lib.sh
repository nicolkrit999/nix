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
COSMIC_IDLE_DIR=${COFFEE_COSMIC_IDLE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicIdle/v1}
COSMIC_IDLE_RECORD="$COFFEE_STATE_DIR/cosmic-idle-before"
COSMIC_IDLE_KEYS=(screen_off_time suspend_on_ac_time suspend_on_battery_time)
# Idle-manager markers, first match wins: "process:label". Ground truth is what runs for this user.
DESK_MARKERS=(
  cosmic-idle:COSMIC
  gnome-shell:GNOME
  plasmashell:"KDE Plasma"
  kwin_wayland:"KDE Plasma"
  Hyprland:Hyprland
  niri:niri
  mango:mango
  hypridle:hypridle
)
DESK_NAME='' DESK_FAMILY=none DESK_HOW='' DESK_STALE=0
SHELL_ENV_HOW='XDG_CURRENT_DESKTOP of this shell'
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
# hypridle.service is PartOf/WantedBy exactly these; outside such a session nothing may start it.
wm_session_active() {
  unit_active hyprland-session.target || unit_active niri.service || unit_active mango-session.target
}

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

desk_family() {
  case ${1,,} in
    *hyprland* | *niri* | *mango* | *wlroots* | *hypridle*) echo wlroots ;;
    *kde* | *plasma*) echo kde ;;
    *gnome*) echo gnome ;;
    *cosmic*) echo cosmic ;;
    "") echo none ;;
    *) echo other ;;
  esac
}

# Sets DESK_NAME, DESK_FAMILY (wlroots|kde|gnome|cosmic|other|none), DESK_HOW and DESK_STALE.
# Order: running processes of this user, the user manager's environment, this shell's $XDG_CURRENT_DESKTOP.
# DESK_STALE=1 when the shell's variable names another desktop than the detection (stale tmux/kitty server).
detect_desktop() {
  local m proc shell_desk=${XDG_CURRENT_DESKTOP:-} uenv=''
  DESK_NAME='' DESK_FAMILY=none DESK_HOW='' DESK_STALE=0
  for m in "${DESK_MARKERS[@]}"; do
    proc=${m%%:*}
    # Nix wraps binaries: comm is ".cosmic-idle-wr" (kernel truncates to 15 chars), so match the wrapper form too.
    if pgrep -u "$(id -u)" -- "^[.]?${proc}(-wr.*)?\$" >/dev/null 2>&1; then
      DESK_NAME=${m#*:}
      DESK_HOW="running process $proc"
      break
    fi
  done
  if [[ -z $DESK_NAME ]]; then
    uenv=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^XDG_CURRENT_DESKTOP=//p') || uenv=''
    if [[ -n $uenv ]]; then
      DESK_NAME=$uenv
      DESK_HOW="systemd user manager environment"
    elif [[ -n $shell_desk ]]; then
      DESK_NAME=$shell_desk
      DESK_HOW=$SHELL_ENV_HOW
    fi
  fi
  DESK_FAMILY=$(desk_family "$DESK_NAME")
  if [[ -n $shell_desk && $DESK_FAMILY != none && $DESK_HOW != "$SHELL_ENV_HOW" &&
    $(desk_family "$shell_desk") != "$DESK_FAMILY" ]]; then
    # shellcheck disable=SC2034 # read by coffee-on and coffee-status, unused in coffee-off which shares this lib
    DESK_STALE=1
  fi
}

notify() {
  if notify-send -a coffee "$1" "$2" 2>/dev/null; then
    ok "notification: sent"
  else
    warn "notification: notify-send failed (no notification daemon in this session?)" "notify-send '$1'"
  fi
}

cosmic_idle_value() {
  local v
  v=$(<"$1") || return 1
  v=${v//[[:space:]]/}
  [[ $v == None ]]
}

cosmic_idle_has_record() {
  [[ -e $1 || -e $1.link || -e $1.absent ]]
}

cosmic_idle_recorded() {
  [[ -d $COSMIC_IDLE_RECORD ]]
}

# cosmic-idle uses ext-idle-notify and ignores logind locks: coffee writes None (never) to its timers.
# Each original (content, symlink target or absent) is recorded first and put back by cosmic_idle_release.
# A recorded key that was rewritten meanwhile (home-manager activation) is recorded again.
cosmic_idle_hold() {
  local key f r
  mkdir -p "$COSMIC_IDLE_DIR" "$COSMIC_IDLE_RECORD" || return 1
  for key in "${COSMIC_IDLE_KEYS[@]}"; do
    f=$COSMIC_IDLE_DIR/$key
    r=$COSMIC_IDLE_RECORD/$key
    if cosmic_idle_has_record "$r"; then
      if [[ ! -L $f ]] && cosmic_idle_value "$f" 2>/dev/null; then
        continue
      fi
      rm -f "$r" "$r.link" "$r.absent"
    fi
    if [[ -L $f ]]; then
      readlink "$f" >"$r.link" || return 1
    elif [[ -e $f ]]; then
      cp -p "$f" "$r" || return 1
    else
      : >"$r.absent" || return 1
    fi
    printf 'None' >"$f.coffee-tmp" || return 1
    mv -f "$f.coffee-tmp" "$f" || return 1
  done
}

# Puts the recorded originals back. A key that no longer reads None was rewritten meanwhile
# (home-manager activation): that newer value stays. Sets COSMIC_RESTORED / COSMIC_KEPT / COSMIC_FAILED.
cosmic_idle_release() {
  local key f r
  COSMIC_RESTORED=0 COSMIC_KEPT=0 COSMIC_FAILED=0
  for key in "${COSMIC_IDLE_KEYS[@]}"; do
    f=$COSMIC_IDLE_DIR/$key
    r=$COSMIC_IDLE_RECORD/$key
    cosmic_idle_has_record "$r" || continue
    if [[ -L $f ]] || { [[ -e $f ]] && ! cosmic_idle_value "$f" 2>/dev/null; }; then
      COSMIC_KEPT=$((COSMIC_KEPT + 1))
    elif [[ -e $r.link ]]; then
      if ln -sfn "$(<"$r.link")" "$f"; then COSMIC_RESTORED=$((COSMIC_RESTORED + 1)); else COSMIC_FAILED=$((COSMIC_FAILED + 1)); fi
    elif [[ -e $r ]]; then
      if cp -p "$r" "$f.coffee-tmp" && mv -f "$f.coffee-tmp" "$f"; then COSMIC_RESTORED=$((COSMIC_RESTORED + 1)); else COSMIC_FAILED=$((COSMIC_FAILED + 1)); fi
    else
      if rm -f "$f"; then COSMIC_RESTORED=$((COSMIC_RESTORED + 1)); else COSMIC_FAILED=$((COSMIC_FAILED + 1)); fi
    fi
  done
  if ((COSMIC_FAILED == 0)); then
    rm -rf "$COSMIC_IDLE_RECORD"
  fi
}
