#!/usr/bin/env bash
# Usage:
#   bash check-nixos-mango-screenshot-fields.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-mango-screenshot-fields.nix"
FIXTURE="$DIR/fixture-all-monitors.json"

if ! command -v jq >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

assert() {
  local label=$1
  shift
  printf "  %-78s " "$label"
  if "$@"; then pass; else fail "$label" "assertion false"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home"

ev() { nix eval --raw --impure --file "$SCENARIO" "$1" 2>>"$WORK/ev.err"; }

echo ""
echo -e "${BOLD}=== mango-screenshot jq fields vs mango's all-monitors JSON ===${NC}"
echo ""

SRC=$(ev mango-src); PATH_=$(ev screenshot-path); DRV=$(ev screenshot-drv)
if [[ -z $SRC || -z $PATH_ || -z $DRV ]]; then
  printf "  %-78s " "locate mango source and mango-screenshot"
  fail "locate" "scenario eval gave no value: $(tail -n 3 "$WORK/ev.err")"
  exit 1
fi
if ! nix build --no-link "$DRV^out" >"$WORK/build.out" 2>&1 || [[ ! -r $PATH_ ]]; then
  printf "  %-78s " "build mango-screenshot"
  fail "build" "$(tail -n 5 "$WORK/build.out")"
  exit 1
fi
IPC="$SRC/src/ipc/ipc.c"
[[ -r $IPC ]] || { printf "  %-78s " "mango ipc.c readable"; fail "ipc.c" "missing: $IPC"; exit 1; }

grep -v '^export PATH=' "$PATH_" >"$WORK/mango-screenshot.sh"
LINE=$(grep -m1 'mmsg get all-monitors' "$WORK/mango-screenshot.sh")

fields_of() { grep -oE '\.[a-z_]+' <<<"$1" | tr -d '.' | sort -u; }

awk '/^cJSON \*build_monitor_json\(/{f=1} f{print} f&&/^}/{exit}' "$IPC" >"$WORK/monitor_fn.c"
emitted_monitor() { grep -qE "cJSON_Add[A-Za-z]*ToObject\([a-z]+, \"$1\"" "$WORK/monitor_fn.c"; }
emitted_top() { grep -qE "cJSON_AddItemToObject\(json, \"$1\"" "$IPC"; }
known_field() { emitted_monitor "$1" || emitted_top "$1"; }

filter_fields_known() {
  local f n=0
  for f in $(fields_of "$1"); do
    n=$((n + 1))
    known_field "$f" || { echo "unknown field: $f" >&2; return 1; }
  done
  [[ $n -ge 3 ]]
}

assert "script has an all-monitors jq filter" test -n "$LINE"
assert "build_monitor_json found in the pinned mango ipc.c" test -s "$WORK/monitor_fn.c"
assert "every jq field of the script is emitted by the pinned mango" filter_fields_known "$LINE"
assert "control: a planted unknown field is rejected" bash -c '! { '"$(declare -f fields_of known_field emitted_monitor emitted_top filter_fields_known)"'; WORK='"$WORK"' IPC='"$IPC"' filter_fields_known "mmsg get all-monitors | jq .monitors[] | select(.focused) | .name" 2>/dev/null; }'
assert "fixture top-level key monitors is emitted by mango" emitted_top monitors
fixture_keys_known() { local k; for k in $(jq -r '.monitors[] | keys[]' "$FIXTURE" | sort -u); do emitted_monitor "$k" || { echo "fixture key not emitted: $k" >&2; return 1; }; done; }
assert "every fixture monitor key is emitted by build_monitor_json" fixture_keys_known

cat >"$WORK/bin/mmsg" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  "get all-monitors") cat "$MMSG_JSON" ;;
  *) echo "unexpected: $*" >>"$GRIM_LOG"; exit 1 ;;
esac
STUB
cat >"$WORK/bin/grim" <<'STUB'
#!/usr/bin/env bash
echo "grim $*" >>"$GRIM_LOG"
touch "${@: -1}"
STUB
printf '#!/usr/bin/env bash\ncat >/dev/null\n' >"$WORK/bin/wl-copy"
printf '#!/usr/bin/env bash\nexit 0\n' >"$WORK/bin/notify-send"
chmod +x "$WORK/bin/"*
export PATH="$WORK/bin:$PATH" HOME="$WORK/home" GRIM_LOG="$WORK/grim.log"

shot() {
  : >"$GRIM_LOG"
  MMSG_JSON="$1" bash "$WORK/mango-screenshot.sh" output >/dev/null 2>&1
}
grim_args() { sed -n 's/^grim //p' "$GRIM_LOG" | sed -E 's# ?[^ ]*\.png$##'; }

shot "$FIXTURE"
assert "fixture: grim is told to capture the active monitor" test "$(grim_args)" = "-o TEST-2"

jq '.monitors |= map(.selected = .active | del(.active))' "$FIXTURE" >"$WORK/renamed.json"
shot "$WORK/renamed.json"
assert "control: renamed active field -> no output pinned" test "$(grim_args)" = ""

jq '.monitors |= map(.active = false)' "$FIXTURE" >"$WORK/none-active.json"
shot "$WORK/none-active.json"
assert "control: no active monitor -> no output pinned" test "$(grim_args)" = ""

jq '.monitors |= map(.output = .name | del(.name))' "$FIXTURE" >"$WORK/noname.json"
shot "$WORK/noname.json"
assert "control: renamed name field -> no output pinned" test "$(grim_args)" = ""

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
