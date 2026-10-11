#!/usr/bin/env bash
# Real mango-scratch, mango-place and mango-pip scripts of nixos-desktop run against a stub mmsg.
#
# Usage:
#   bash check-nixos-mango-ipc-helpers.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-mango-ipc-helpers.nix"

if ! command -v jq >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

assert() {
  local label=$1
  shift
  printf "  %-66s " "$label"
  if "$@"; then pass; else fail "$label" "assertion false"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/run"

ev() { nix eval --raw --impure --file "$SCENARIO" "$1" 2>>"$WORK/ev.err"; }

load() {
  local name=$1 path drv
  path=$(ev "$name-path"); drv=$(ev "$name-drv")
  printf "  %-66s " "locate and build mango-$name"
  if [[ -z $path || -z $drv ]]; then
    fail "locate mango-$name" "scenario eval gave no path/drv: $(tail -n 3 "$WORK/ev.err")"
    return 1
  fi
  if ! nix build --no-link "$drv^out" >"$WORK/build.out" 2>&1 || [[ ! -r $path ]]; then
    fail "build mango-$name" "$(tail -n 5 "$WORK/build.out")"
    return 1
  fi
  pass
  assert "mango-$name declares jq and coreutils in its PATH" bash -c "grep '^export PATH=' '$path' | grep -q -- '-jq-' && grep '^export PATH=' '$path' | grep -q -- '-coreutils-'"
  grep -v '^export PATH=' "$path" >"$WORK/mango-$name.sh"
}

REAL_SLEEP=$(command -v sleep)
cat >"$WORK/bin/sleep" <<STUB
#!/usr/bin/env bash
exec "$REAL_SLEEP" 0.05
STUB

cat >"$WORK/bin/mmsg" <<'STUB'
#!/usr/bin/env bash
st=$MMSG_STATE
case "$*" in
  "get all-monitors") cat "$st/monitors.json" ;;
  "get all-clients") [[ -e $st/clients-fail ]] && exit 1; jq -e '.clients[] | select(.id == 7)' "$st/clients.json" >/dev/null 2>&1 && touch "$st/seen7"; cat "$st/clients.json" ;;
  "get focusing-client") [[ -e $st/focus.json ]] || exit 1; cat "$st/focus.json" ;;
  "dispatch togglefloating") echo "$*" >>"$st/log"; jq '.is_floating |= not' "$st/focus.json" >"$st/f.tmp" && mv "$st/f.tmp" "$st/focus.json" ;;
  "dispatch toggleglobal") echo "$*" >>"$st/log"; jq '.is_global |= not' "$st/focus.json" >"$st/f.tmp" && mv "$st/f.tmp" "$st/focus.json" ;;
  dispatch\ *) echo "$*" >>"$st/log" ;;
  *) echo "unexpected: $*" >>"$st/log"; exit 1 ;;
esac
STUB
chmod +x "$WORK/bin/"*

export MMSG_STATE="$WORK/state" XDG_RUNTIME_DIR="$WORK/run"
export PATH="$WORK/bin:$PATH"
resetstate() { rm -rf "$MMSG_STATE"; mkdir -p "$MMSG_STATE"; : >"$MMSG_STATE/log"; }
clean() { ! grep -q '^unexpected' "$MMSG_STATE/log"; }
logged() { grep -Fxq -- "$1" "$MMSG_STATE/log"; }
notlogged() { ! grep -Fxq -- "$1" "$MMSG_STATE/log"; }

echo ""
echo -e "${BOLD}=== mango IPC helper scripts on the real nixos-desktop host ===${NC}"

echo ""
echo -e "${BOLD}mango-scratch (stub mmsg)${NC}"
if load scratch; then
  MONS='{"monitors":[{"name":"DP-2","active":false},{"name":"DP-1","active":true}]}'
  client() { jq -nc --arg m "$1" --argjson t "$2" --argjson v "$3" --argjson g "$4" --argjson u "$5" \
    '{id:1,monitor:$m,tags:$t,is_visible:$v,is_global:$g,is_unglobal:$u}'; }
  scratch() {
    resetstate
    echo "$MONS" >"$MMSG_STATE/monitors.json"
    jq -nc --argjson c "$1" '{clients:$c}' >"$MMSG_STATE/clients.json"
    bash "$WORK/mango-scratch.sh" touch "$WORK/ran" 2>/dev/null
  }

  rm -f "$WORK/ran"; scratch '[]'; rc=$?
  assert "no clients: exit status 0" test "$rc" = 0
  assert "no clients: no unexpected mmsg call" clean
  assert "no clients: toggle_special_tag dispatched" logged "dispatch toggle_special_tag"
  assert "no clients: command still exec'd" test -e "$WORK/ran"

  rm -f "$WORK/ran"; scratch "[$(client DP-1 '[0]' true false false)]"; rc=$?
  assert "visible special-tag window: exit status 0" test "$rc" = 0
  assert "visible special-tag window: no unexpected mmsg call" clean
  assert "visible special-tag window: no toggle" notlogged "dispatch toggle_special_tag"
  assert "visible special-tag window: command still exec'd" test -e "$WORK/ran"

  scratch "[$(client DP-1 '[0]' true true false)]"
  assert "is_global window on the tag does not count as visible" logged "dispatch toggle_special_tag"
  scratch "[$(client DP-1 '[0]' true false true)]"
  assert "is_unglobal window on the tag does not count as visible" logged "dispatch toggle_special_tag"
  scratch "[$(client DP-1 '[0]' false false false)]"
  assert "invisible special-tag window does not count" logged "dispatch toggle_special_tag"
  scratch "[$(client DP-2 '[0]' true false false)]"
  assert "special-tag window on another monitor does not count" logged "dispatch toggle_special_tag"
  scratch "[$(client DP-1 '[1]' true false false)]"
  assert "window on a normal tag does not count" logged "dispatch toggle_special_tag"

  resetstate
  echo "$MONS" >"$MMSG_STATE/monitors.json"; touch "$MMSG_STATE/clients-fail"
  rm -f "$WORK/ran"; bash "$WORK/mango-scratch.sh" touch "$WORK/ran" 2>/dev/null
  assert "mmsg failure: active defaults to 0 (toggle dispatched)" logged "dispatch toggle_special_tag"
  assert "mmsg failure: command still exec'd" test -e "$WORK/ran"

  resetstate
  echo "$MONS" >"$MMSG_STATE/monitors.json"; echo '{"clients":[]}' >"$MMSG_STATE/clients.json"
  bash "$WORK/mango-scratch.sh" bash -c 'printf "%s|%s" "$1" "$2" >"$0"' "$WORK/args" 'a b' "c'd" 2>/dev/null
  assert "command arguments with spaces and quotes survive exec" test "$(cat "$WORK/args" 2>/dev/null)" = "a b|c'd"
  bash "$WORK/mango-scratch.sh" false 2>/dev/null
  assert "failing command: its exit status is propagated" test "$?" = 1
fi

echo ""
echo -e "${BOLD}mango-place (stub mmsg)${NC}"
if load place; then
  cat >"$WORK/bin/fakeapp" <<'STUB'
#!/usr/bin/env bash
jq --arg m "$APP_MON" --arg a "$APP_ID" '.clients += [{id:7,appid:$a,monitor:$m}]' "$MMSG_STATE/clients.json" >"$MMSG_STATE/c.tmp"
mv "$MMSG_STATE/c.tmp" "$MMSG_STATE/clients.json"
STUB
  chmod +x "$WORK/bin/fakeapp"
  place() {
    resetstate
    echo "$1" >"$MMSG_STATE/clients.json"
    APP_MON=$2 APP_ID=$3 bash "$WORK/mango-place.sh" DP-1 '^zen-beta$' -- fakeapp 2>/dev/null
  }
  placed_ok() { place "$@"; local rc=$?; [[ $rc -eq 0 ]] && clean && [[ -e $MMSG_STATE/seen7 ]]; }
  OLD='{"clients":[{"id":1,"appid":"zen-beta","monitor":"DP-2"}]}'

  place "$OLD" DP-1 zen-beta; rc=$?
  assert "window seen by the poll loop, exit status 0, no unexpected mmsg call" bash -c "(( $rc == 0 )) && [[ -e '$MMSG_STATE/seen7' ]] && ! grep -q '^unexpected' '$MMSG_STATE/log'"
  assert "focuses the target output first" logged "dispatch focusmon,DP-1"
  assert "window opens on the target output: no tagmon" bash -c "! grep -q tagmon '$MMSG_STATE/log'"

  place "$OLD" DP-2 zen-beta; rc=$?
  assert "moved window: exit status 0, no unexpected mmsg call" bash -c "(( $rc == 0 )) && ! grep -q '^unexpected' '$MMSG_STATE/log'"
  assert "window opens elsewhere: moved with tagmon,DP-1,1 client,7" logged "dispatch tagmon,DP-1,1 client,7"
  assert "pre-existing matching window (id 1) is ignored" notlogged "dispatch tagmon,DP-1,1 client,1"

  place "$OLD" DP-2 other-app; rc=$?
  assert "non-matching window existed during polling (loop really ran)" test -e "$MMSG_STATE/seen7"
  assert "non-matching new window is never moved" bash -c "! grep -q tagmon '$MMSG_STATE/log'"
  assert "non-matching window: loop gives up with exit status 0" test "$rc" = 0

  placed_ok "$OLD" DP-2 zen-beta
  assert "control: same setup with a matching appid does move (tagmon check can fail)" logged "dispatch tagmon,DP-1,1 client,7"
fi

echo ""
echo -e "${BOLD}mango-pip (stateful stub mmsg)${NC}"
if load pip; then
  pipstate() { resetstate; rm -rf "$XDG_RUNTIME_DIR/mango-pip"; jq -nc --argjson f "$1" --argjson g "$2" '{id:5,is_floating:$f,is_global:$g}' >"$MMSG_STATE/focus.json"; }
  field() { jq -r ".$1" "$MMSG_STATE/focus.json"; }
  pip() { bash "$WORK/mango-pip.sh" 2>/dev/null; }
  pipclean() { pip; local rc=$?; [[ $rc -eq 0 ]] && clean; }

  pipstate false false; pip; rc=$?
  assert "tiled window: pin exit status 0, no unexpected mmsg call" bash -c "(( $rc == 0 )) && ! grep -q '^unexpected' '$MMSG_STATE/log'"
  assert "tiled window: pin makes it floating" test "$(field is_floating)" = true
  assert "tiled window: pin makes it global" test "$(field is_global)" = true
  assert "tiled window: pin resizes to 800x450" logged "dispatch resizewin,800,450"
  assert "tiled window: no marker left" test ! -e "$XDG_RUNTIME_DIR/mango-pip/5"
  pipclean
  assert "tiled window: unpin exit status 0, no unexpected mmsg call" test "$?" = 0
  assert "tiled window: unpin drops global" test "$(field is_global)" = false
  assert "tiled window: unpin restores tiled" test "$(field is_floating)" = false

  pipstate true false; pip
  assert "floating window: pin keeps it floating and makes it global" test "$(field is_floating)$(field is_global)" = truetrue
  assert "floating window: pin leaves a marker" test -e "$XDG_RUNTIME_DIR/mango-pip/5"
  : >"$MMSG_STATE/log"; pipclean
  assert "floating window: unpin exit status 0, no unexpected mmsg call" test "$?" = 0
  assert "floating window: unpin drops global" test "$(field is_global)" = false
  assert "floating window: unpin stays floating (marker honoured)" test "$(field is_floating)" = true
  assert "floating window: unpin never toggles floating" notlogged "dispatch togglefloating"
  assert "floating window: unpin removes the marker" test ! -e "$XDG_RUNTIME_DIR/mango-pip/5"

  resetstate; echo '{"error":"no focused client"}' >"$MMSG_STATE/focus.json"; pip; rc=$?
  assert "no focused client: exit status 0" test "$rc" = 0
  assert "no focused client: no dispatch at all" test ! -s "$MMSG_STATE/log"
fi

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}→ $detail${NC}"
done
exit 1
