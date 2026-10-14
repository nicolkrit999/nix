#!/usr/bin/env bash
# Usage:
#   bash check-nixos-waybar-configs.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-waybar-configs.nix"

if [[ -z ${WBC_INNER:-} ]]; then
  WBC_INNER=1 exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#bash nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

report() {
  local label=$1 value=$2
  printf "  %-78s " "$label"
  if [[ $value == ok ]]; then pass; else fail "$label" "$value"; fi
}

evaljson() {
  nix eval --json --impure --file "$SCENARIO" "$1" >"$2" 2>"$WORK/err" ||
    { report "evaluate $1" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"; return 1; }
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== Waybar configs (hyprland / mango / niri on real hosts + mango without monitors) ===${NC}"

echo ""
echo -e "${BOLD}structure and wiring${NC}"
if evaljson results "$WORK/results.json"; then
  while IFS=$'\t' read -r variant check value; do
    report "[$variant] $check" "$value"
  done < <(jq -r 'to_entries[] | .key as $v | .value | to_entries[] | [$v, .key, .value] | @tsv' "$WORK/results.json")
fi

echo ""
echo -e "${BOLD}scenario controls${NC}"
if evaljson control "$WORK/control.json"; then
  while IFS=$'\t' read -r check value; do
    report "control: $check" "$value"
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$WORK/control.json")
fi

echo ""
echo -e "${BOLD}generated config JSON${NC}"
if evaljson json-texts "$WORK/json.json"; then
  n=0
  for k in $(jq -r 'keys[]' "$WORK/json.json"); do
    n=$((n + 1))
    if out=$(jq -e 'select(type == "object" or type == "array")' <<<"$(jq -r --arg k "$k" '.[$k]' "$WORK/json.json")" 2>&1 >/dev/null); then report "[$k] jq parses config" ok; else report "[$k] jq parses config" "${out:-not an object/array}"; fi
  done
  [[ $n -ge 5 ]] && report "config JSON corpus has at least 5 files" ok || report "config JSON corpus has at least 5 files" "only $n"
fi
if echo '{"a": ' | jq -e . >/dev/null 2>&1; then report "control: jq rejects truncated JSON" "jq accepted invalid JSON"; else report "control: jq rejects truncated JSON" ok; fi

echo ""
echo -e "${BOLD}exec / on-click shell syntax (bash -n)${NC}"
if evaljson snippets "$WORK/snippets.json"; then
  mkdir -p "$WORK/sh"
  total=0; bad=0
  while IFS= read -r k; do
    f="$WORK/sh/$(printf '%s' "$k" | tr '/ ' '__').sh"
    jq -r --arg k "$k" '.[$k]' "$WORK/snippets.json" >"$f"
    total=$((total + 1))
    if ! out=$(bash -n "$f" 2>&1); then
      bad=$((bad + 1)); report "$k" "$out"
    fi
  done < <(jq -r 'keys[]' "$WORK/snippets.json")
  report "all $total snippets pass bash -n" "$([[ $bad -eq 0 && $total -ge 50 ]] && echo ok || echo "$bad bad of $total (need >= 50 snippets)")"
fi

echo ""
echo -e "${BOLD}custom/coffee exec output (systemctl stubbed: coffee.service active / inactive)${NC}"
if [[ -s $WORK/snippets.json ]]; then
  mkdir -p "$WORK/cbin"
  printf '#!/usr/bin/env bash\n[[ "$*" == "--user is-active --quiet coffee.service" ]] || exit 64\nexit "$WB_COFFEE_RC"\n' >"$WORK/cbin/systemctl"
  chmod +x "$WORK/cbin/systemctl"
  coffee_out() {
    local snippet=$1 rc=$2
    sed -E "s#/nix/store/[^ ]+/bin/systemctl#$WORK/cbin/systemctl#" <<<"$snippet" >"$WORK/coffee.sh"
    grep -q "$WORK/cbin/systemctl" "$WORK/coffee.sh" || { echo "systemctl path not found in exec"; return; }
    WB_COFFEE_RC=$rc bash "$WORK/coffee.sh" 2>&1
  }
  coffee_state() {
    local out=$1 class=$2 icon=$3
    jq -e --arg c "$class" --arg i "$icon" '.class == $c and (.text | test("^<span color=.#[0-9a-f]{6}.>" + $i + "</span>$")) and (.tooltip | length > 0)' <<<"$out" >/dev/null 2>&1 &&
      echo ok || echo "got: $out"
  }
  n=0
  while IFS= read -r k; do
    n=$((n + 1))
    snip=$(jq -r --arg k "$k" '.[$k]' "$WORK/snippets.json")
    report "[$k] coffee on: class active, cup glyph, tooltip" "$(coffee_state "$(coffee_out "$snip" 0)" active $'\xf3\xb0\x85\xb6')"
    report "[$k] coffee off: shown (class off, struck cup glyph, tooltip)" "$(coffee_state "$(coffee_out "$snip" 3)" off $'\xf3\xb0\xbe\xaa')"
  done < <(jq -r 'keys[] | select(endswith("/custom/coffee.exec"))' "$WORK/snippets.json")
  report "coffee exec corpus has at least 3 snippets" "$([[ $n -ge 3 ]] && echo ok || echo "only $n")"
  report "control: the off-state check rejects the old hidden-when-off output" "$([[ $(coffee_state '{"text":"","class":"off"}' off $'\xf3\xb0\xbe\xaa') != ok ]] && echo ok || echo "accepted an empty off pill")"
fi

printf 'if [ -n "$x" ]; then\n  echo hi\n' >"$WORK/bad.sh"
if bash -n "$WORK/bad.sh" 2>/dev/null; then report "control: bash -n rejects unterminated if" "bash accepted invalid script"; else report "control: bash -n rejects unterminated if" ok; fi

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
