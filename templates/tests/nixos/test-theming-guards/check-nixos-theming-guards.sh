#!/usr/bin/env bash
# Theming guards on the real nixos-desktop and nixos-laptop (base, catppuccin on/off, light polarity), eval only.
#
# Usage:
#   bash check-nixos-theming-guards.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-theming-guards.nix"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for h in "${HOSTS[@]}"; do
  (
    HOST=$h nix eval --raw --impure --file "$SCENARIO" report >"$WORK/$h.report" 2>"$WORK/$h.err"
    echo $? >"$WORK/$h.rc"
  ) &
done
wait

echo ""
echo -e "${BOLD}=== theming guards (stylix / qt / gtk / portal env / hyprlock) ===${NC}"

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  if [[ $(cat "$WORK/$h.rc") -ne 0 ]]; then
    printf "  %-84s " "evaluate $h"
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r variant label result; do
    [[ -z $label ]] && continue
    printf "  %-14s %-70s " "[$variant]" "$label"
    if [[ $result == ok ]]; then pass; else fail "$h [$variant]: $label" "$result"; fi
  done <"$WORK/$h.report"
done

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
