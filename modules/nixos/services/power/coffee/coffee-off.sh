# coffee-off: release the coffee lock, undo what coffee-on changed and verify the restore.
# Needs coffee-lib.sh prepended.

was_on=0
if unit_loaded "$COFFEE_UNIT" || ! inhibitor_absent; then
  was_on=1
fi

if ((was_on)); then
  lid=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed 2>/dev/null || true)
  if [[ $lid == "b true" ]]; then
    warn "lid: closed, logind runs the lid action (suspend) as soon as the lock is released" "coffee-on"
  fi
fi

if unit_loaded "$COFFEE_UNIT"; then
  if systemctl --user stop "$COFFEE_UNIT" 2>/dev/null; then
    ok "inhibitor unit: $COFFEE_UNIT stopped"
  else
    fail "inhibitor unit: could not stop $COFFEE_UNIT" "systemctl --user stop $COFFEE_UNIT"
  fi
  systemctl --user reset-failed "$COFFEE_UNIT" 2>/dev/null || true
else
  ok "inhibitor unit: $COFFEE_UNIT not running (coffee was already off)"
fi

if wait_until inhibitor_absent; then
  ok "verify: no coffee lock in systemd-inhibit --list (automatic sleep, idle and the lid action act normally again)"
else
  fail "verify: a coffee lock is still listed by systemd-inhibit --list" "pkill -f -- '--who=coffee'"
fi

if coffee_active; then
  fail "verify: $COFFEE_UNIT is still active" "systemctl --user stop $COFFEE_UNIT"
elif systemctl --user is-failed --quiet "$COFFEE_UNIT" 2>/dev/null; then
  warn "verify: $COFFEE_UNIT is left in the failed state" "systemctl --user reset-failed $COFFEE_UNIT"
else
  ok "verify: no $COFFEE_UNIT unit left"
fi

linger=$(linger_state)
if [[ -f $LINGER_MARKER ]]; then
  if [[ $linger == yes ]]; then
    loginctl disable-linger "$COFFEE_USER" 2>/dev/null || true
    linger=$(linger_state)
  fi
  if [[ $linger == no ]]; then
    rm -f "$LINGER_MARKER"
    ok "linger: disabled again (coffee had enabled it), verified"
  else
    fail "linger: still '${linger:-unknown}' although coffee had enabled it" "loginctl disable-linger $COFFEE_USER"
  fi
else
  ok "linger: left as is (${linger:-unknown}, not enabled by coffee)"
fi

before=$(cat "$HYPRIDLE_RECORD" 2>/dev/null || echo unknown)
if unit_loaded hypridle.service; then
  if hypridle_active; then
    ok "hypridle: active, idle dim/lock/screen-off work again"
  elif [[ $before == active ]] && ! wm_session_active; then
    ok "hypridle: not started, the Hyprland/niri/mango session that owned it is gone (other desktop now)"
  elif [[ $before == active ]] || { unit_active graphical-session.target && wm_session_active; }; then
    if systemctl --user start hypridle.service 2>/dev/null && wait_until hypridle_active; then
      ok "hypridle: was not running, started again and verified active"
    else
      fail "hypridle: not running and could not be started" "systemctl --user restart hypridle.service"
    fi
  else
    ok "hypridle: not running, and it was not running before coffee-on either"
  fi
elif [[ $before == active ]]; then
  warn "hypridle: was running before coffee-on, its unit is not loaded now" "systemctl --user start hypridle.service"
else
  ok "hypridle: not installed for this user"
fi
rm -f "$HYPRIDLE_RECORD"

if cosmic_idle_recorded; then
  cosmic_idle_release
  if ((COSMIC_FAILED > 0)); then
    fail "cosmic-idle: could not restore $COSMIC_FAILED timer file(s) in $COSMIC_IDLE_DIR, the record in $COSMIC_IDLE_RECORD is kept" "coffee-off"
  elif ((COSMIC_KEPT > 0)); then
    ok "cosmic-idle: $COSMIC_RESTORED timer(s) restored, $COSMIC_KEPT rewritten meanwhile (home-manager activation) and kept as they are"
  else
    ok "cosmic-idle: $COSMIC_RESTORED timer(s) restored to their values from before coffee-on"
  fi
fi

refresh_waybar

if ((was_on)); then
  notify "Coffee mode off" "Automatic sleep, idle lock and the lid action act normally again."
else
  ok "notification: skipped (coffee was already off)"
fi

if inhibitor_absent && ! coffee_active; then
  summary off OFF
else
  summary off "STILL ON"
fi
