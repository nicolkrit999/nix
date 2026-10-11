#!/usr/bin/env bash
# Usage:
#   bash check-nixos-keybind-conflicts.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-keybind-conflicts.nix"

if [[ -z ${KBC_INNER:-} ]]; then
  KBC_INNER=1 exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#gnugrep nixpkgs#coreutils -c bash "$0" "$@"
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
echo -e "${BOLD}=== Keybind conflicts (both hosts + specialisations) ===${NC}"
echo ""

if ! nix eval --json --impure --file "$SCENARIO" results >"$WORK/results.json" 2>"$WORK/err"; then
  report "evaluate results" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
else
  while IFS=$'\t' read -r variant check value; do
    report "[$variant] $check" "$value"
  done < <(jq -r 'to_entries[] | .key as $v | .value | to_entries[] | [$v, .key, .value] | @tsv' "$WORK/results.json")
fi

echo ""
echo -e "${BOLD}matcher controls${NC}"
if nix eval --json --impure --file "$SCENARIO" control >"$WORK/control.json" 2>"$WORK/err"; then
  while IFS=$'\t' read -r check value; do
    report "control: $check" "$value"
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$WORK/control.json")
else
  report "evaluate control" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
fi

echo ""
echo -e "${BOLD}GNOME screenshot script syntax${NC}"
if nix eval --json --impure --file "$SCENARIO" gnome-scripts >"$WORK/scripts.json" 2>"$WORK/err"; then
  for v in $(jq -r 'keys[]' "$WORK/scripts.json"); do
    jq -r --arg v "$v" '.[$v]' "$WORK/scripts.json" >"$WORK/$v.sh"
    if [[ ! -s $WORK/$v.sh ]]; then report "[$v] bash -n launch-screenshot" "empty script"; continue; fi
    if out=$(bash -n "$WORK/$v.sh" 2>&1); then report "[$v] bash -n launch-screenshot" ok; else report "[$v] bash -n launch-screenshot" "$out"; fi
  done
else
  report "evaluate gnome-scripts" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
fi
printf 'if then fi (\n' >"$WORK/bad.sh"
if bash -n "$WORK/bad.sh" 2>/dev/null; then report "control: bash -n rejects broken script" "bash accepted invalid script"; else report "control: bash -n rejects broken script" ok; fi

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
