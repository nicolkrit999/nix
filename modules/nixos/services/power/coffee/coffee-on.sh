# coffee-on: block automatic sleep (weak lock), idle and the lid action (full lock) until coffee-off.
# Manual suspend, the suspend/hibernate keys, the power button, shutdown and reboot keep working.
# Needs coffee-lib.sh prepended.

already_on=0
if coffee_active && inhibitor_present; then
  already_on=1
fi

detect_desktop
desk=$DESK_NAME
how="detected from $DESK_HOW"
case $DESK_FAMILY in
  wlroots)
    ok "desktop: $desk (idle, dim, lock and screen-off come from hypridle, which honours the idle lock; $how)"
    ;;
  kde)
    warn "desktop: KDE Plasma runs its own power manager, coffee does not change its settings ($how)" "kcmshell6 kcm_powerdevilprofilesconfig"
    ;;
  gnome)
    warn "desktop: GNOME runs its own power manager, coffee does not change its settings ($how)" "gnome-control-center power"
    ;;
  cosmic)
    ok "desktop: $desk (cosmic-idle ignores logind locks, coffee sets its screen-off and suspend timers to never; COSMIC has no idle dim or lock; $how)"
    ;;
  none)
    warn "desktop: no graphical session in this shell (SSH or TTY?), the lock needs an active local session" "coffee-on"
    ;;
  *)
    warn "desktop: $desk is not Hyprland/niri/mango, its own power settings may still act ($how)" "systemd-inhibit --list"
    ;;
esac
if ((DESK_STALE)); then
  ok "desktop: XDG_CURRENT_DESKTOP of this shell (${XDG_CURRENT_DESKTOP:-}) is stale, the running session is $desk (old tmux/kitty server?); coffee follows the running session"
fi

if mkdir -p "$COFFEE_STATE_DIR" 2>/dev/null; then
  ok "state: $COFFEE_STATE_DIR"
else
  fail "state: cannot create $COFFEE_STATE_DIR" "mkdir -p '$COFFEE_STATE_DIR'"
fi

if ((already_on)) && [[ -f $HYPRIDLE_RECORD ]]; then
  ok "hypridle: state before coffee-on already recorded ($(cat "$HYPRIDLE_RECORD"))"
elif unit_loaded hypridle.service; then
  if hypridle_active; then
    echo active >"$HYPRIDLE_RECORD" 2>/dev/null || true
    ok "hypridle: running, its dim/lock/screen-off listeners are held off by the idle lock"
  else
    echo inactive >"$HYPRIDLE_RECORD" 2>/dev/null || true
    ok "hypridle: not running, nothing to hold off"
  fi
else
  echo absent >"$HYPRIDLE_RECORD" 2>/dev/null || true
  ok "hypridle: not installed for this user"
fi

lock_ok=0
if ((already_on)); then
  lock_ok=1
  ok "inhibitor: $COFFEE_UNIT already holds the coffee locks (coffee was already on)"
else
  if coffee_active || unit_loaded "$COFFEE_UNIT"; then
    systemctl --user stop "$COFFEE_UNIT" 2>/dev/null || true
  fi
  systemctl --user reset-failed "$COFFEE_UNIT" 2>/dev/null || true
  if ! err=$(systemd-run --user --unit=coffee --description="Coffee mode inhibitor" --collect \
    -p Restart=on-failure -p RestartSec=2 \
    systemd-inhibit --what="$COFFEE_WHAT_WEAK" --mode=block-weak --who=coffee \
    --why="Coffee mode: no automatic sleep (manual suspend still works)" \
    systemd-inhibit --what="$COFFEE_WHAT_BLOCK" --mode=block --who=coffee \
    --why="Coffee mode: no idle dim/lock/screen-off, lid closing does nothing" \
    sleep infinity 2>&1); then
    fail "inhibitor: systemd-run could not start $COFFEE_UNIT: ${err//$'\n'/ }" "systemctl --user reset-failed $COFFEE_UNIT"
  elif wait_until inhibitor_present; then
    lock_ok=1
    ok "inhibitor: $COFFEE_UNIT holds $COFFEE_WHAT_WEAK (block-weak) + $COFFEE_WHAT_BLOCK (block); manual suspend, suspend/hibernate keys, power button, shutdown and reboot keep working"
  else
    systemctl --user stop "$COFFEE_UNIT" 2>/dev/null || true
    systemctl --user reset-failed "$COFFEE_UNIT" 2>/dev/null || true
    fail "inhibitor: logind refused the lock (no active local session? coffee cannot start over SSH alone), coffee.service removed again" "coffee-on"
  fi
fi

if ((lock_ok)); then
  bid=$(boot_id)
  linger=$(linger_state)
  # The marker proves coffee enabled linger, across reboots too (linger can be persisted).
  # It is stale only when linger is no longer yes.
  if [[ -f $LINGER_MARKER && $linger != yes ]]; then
    rm -f "$LINGER_MARKER"
  fi
  case $linger in
    yes)
      if [[ -f $LINGER_MARKER ]]; then
        ok "linger: already enabled by coffee"
      else
        ok "linger: already enabled (not by coffee, coffee-off leaves it on)"
      fi
      ;;
    no)
      if loginctl enable-linger "$COFFEE_USER" 2>/dev/null && [[ $(linger_state) == yes ]]; then
        printf '%s\n' "$bid" >"$LINGER_MARKER" 2>/dev/null || true
        ok "linger: enabled, coffee and tmux keep running after logout"
      else
        warn "linger: could not enable it, coffee stops at logout" "loginctl enable-linger $COFFEE_USER"
      fi
      ;;
    *)
      warn "linger: cannot read the linger state from logind, coffee may stop at logout" "loginctl enable-linger $COFFEE_USER"
      ;;
  esac
fi

if ((lock_ok)) && [[ $DESK_FAMILY == cosmic ]]; then
  if cosmic_idle_hold; then
    ok "cosmic-idle: screen_off_time, suspend_on_ac_time and suspend_on_battery_time are None, originals kept in $COSMIC_IDLE_RECORD"
  else
    fail "cosmic-idle: could not write $COSMIC_IDLE_DIR" "coffee-off"
  fi
fi

refresh_waybar

if ((already_on)); then
  ok "notification: skipped (coffee was already on)"
elif ((lock_ok)); then
  notify "Coffee mode on" "No automatic sleep, idle lock or lid action until coffee-off. Manual suspend, power button and shutdown still work."
fi

if ((lock_ok)); then
  summary on ON
else
  summary on OFF
fi
