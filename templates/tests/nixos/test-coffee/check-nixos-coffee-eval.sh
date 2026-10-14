#!/usr/bin/env bash
# Usage:
#   bash check-nixos-coffee-eval.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-coffee.nix"

if ! command -v jq >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

report() {
  local label=$1 value=$2
  printf "  %-92s " "$label"
  if [[ $value == ok ]]; then
    printf "${GREEN}✓ PASS${NC}\n"
    PASS=$((PASS + 1))
  else
    printf "${RED}✗ FAIL${NC}\n"
    FAIL=$((FAIL + 1))
    FAILURES+=("$label|$value")
  fi
}

run_set() {
  local attr=$1 prefix=$2 min=$3 n=0
  if ! nix eval --json --impure --option allow-import-from-derivation false --file "$SCENARIO" "$attr" >"$WORK/$attr.json" 2>"$WORK/err"; then
    report "evaluate $attr" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
    return
  fi
  while IFS=$'\t' read -r check value; do
    n=$((n + 1))
    report "$prefix$check" "$value"
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$WORK/$attr.json")
  if ((n < min)); then
    report "$attr has at least $min checks" "only $n"
  fi
}

echo ""
echo -e "${BOLD}=== Coffee mode: module contract (eval) ===${NC}"
echo -e "${DIM}Fake host + extendModules twins: WM gate, enable gate, guest/secure-travel, units, logind, package text, hypridle.${NC}"
echo ""
echo -e "${BOLD}contract${NC}"
run_set results "" 20
echo ""
echo -e "${BOLD}scenario controls${NC}"
run_set control "control: " 8

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
