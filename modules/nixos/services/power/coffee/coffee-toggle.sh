# coffee-toggle: run coffee-off when coffee is on (or half on), coffee-on when it is off.
# Same state test as coffee-status; exits with the exit code of the script it runs.
# Needs coffee-lib.sh prepended.

if coffee_active && inhibitor_present; then
  state=ON next=coffee-off
elif ! coffee_active && inhibitor_absent; then
  state=OFF next=coffee-on
else
  state=INCONSISTENT next=coffee-off
fi

line="coffee-toggle: coffee is $state, running $next"
printf '%s\n' "$line"
journal info "$line"
exec "$next"
