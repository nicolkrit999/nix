#!/usr/bin/env bash
# Usage:
#   bash check-nixos-wm-session-services.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-wm-session-services.nix"

if [[ -z ${WSS_INNER:-} ]]; then
  WSS_INNER=1 exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#gnugrep nixpkgs#coreutils -c bash "$0" "$@"
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
  printf "  %-72s " "$label"
  if [[ $value == ok ]]; then pass; else fail "$label" "$value"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== WM session services (niri fixture + real hosts + specialisations) ===${NC}"
echo ""

if ! nix eval --json --impure --file "$SCENARIO" results >"$WORK/results.json" 2>"$WORK/err"; then
  report "evaluate results" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
else
  [[ $(jq 'has("fixture-niri")' "$WORK/results.json") == true ]] || report "niri fixture evaluated" "fixture-niri missing, every check would be vacuous"
  while IFS=$'\t' read -r variant check value; do
    report "[$variant] $check" "$value"
  done < <(jq -r 'to_entries[] | .key as $v | .value | to_entries[] | [$v, .key, .value] | @tsv' "$WORK/results.json")
fi

echo ""
echo -e "${BOLD}mutation controls${NC}"
if nix eval --json --impure --file "$SCENARIO" control >"$WORK/control.json" 2>"$WORK/err"; then
  while IFS=$'\t' read -r check value; do
    report "control: $check" "$value"
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$WORK/control.json")
else
  report "evaluate control" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
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
