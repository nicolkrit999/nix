# coffee-status: print the coffee state; exit 0 = on, 3 = off, 1 = inconsistent.
# Needs coffee-lib.sh prepended.

unit_state=$(unit_prop "$COFFEE_UNIT" ActiveState)
locks=$(coffee_locks)

if coffee_active && inhibitor_present; then
  state=ON rc=0 colour=$C_OK
elif ! coffee_active && [[ -z $locks ]]; then
  state=OFF rc=3 colour=$C_RESET
else
  state=INCONSISTENT rc=1 colour=$C_FAIL
fi

linger=$(linger_state)
linger_by=""
if [[ -f $LINGER_MARKER && $(cat "$LINGER_MARKER" 2>/dev/null) == "$(boot_id)" ]]; then
  linger_by=" (enabled by coffee)"
fi
if unit_loaded hypridle.service; then
  hypridle=$(unit_prop hypridle.service ActiveState)
else
  hypridle="not installed"
fi

printf '%scoffee: %s%s%s\n' "$C_BOLD" "$colour" "$state" "$C_RESET"
printf '  unit %s: %s\n' "$COFFEE_UNIT" "${unit_state:-unknown}"
printf '  linger: %s%s\n' "${linger:-unknown}" "$linger_by"
printf '  hypridle: %s (before coffee-on: %s)\n' "${hypridle:-unknown}" "$(cat "$HYPRIDLE_RECORD" 2>/dev/null || echo "not recorded")"
if [[ $state == ON ]]; then
  printf '  blocked: automatic sleep (block-weak), idle dim/lock/screen-off and the lid action (block)\n'
  printf '  still works: manual suspend, suspend/hibernate keys, power button, shutdown, reboot\n'
fi
if [[ $state == INCONSISTENT ]]; then
  printf '  %sfix: coffee-off%s\n' "$C_FAIL" "$C_RESET"
fi

full=$(systemd-inhibit --list --no-pager 2>/dev/null || true)
echo
echo "systemd-inhibit --list (coffee and other block/block-weak locks):"
if [[ -z $full ]]; then
  echo "  (systemd-inhibit --list returned nothing)"
else
  {
    head -n 1 <<<"$full"
    tail -n +2 <<<"$full" | grep -E '^coffee[[:space:]]|[[:space:]]block(-weak)?[[:space:]]*$' || echo "  (none)"
  }
fi

exit "$rc"
