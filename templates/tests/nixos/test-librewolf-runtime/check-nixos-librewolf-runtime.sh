#!/usr/bin/env bash
# LibreWolf runtime checker: starts the real package headless with the generated profiles.
#
# Usage:
#   bash check-nixos-librewolf-runtime.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-librewolf-runtime.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

for tool in nix jq python3 bash; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool"; exit 2; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo -e "${BOLD}=== build LibreWolf + allow-list file ===${NC}"
pkg=$(nix build --no-link --print-out-paths --impure --file "$SCENARIO" pkg 2>"$work/err") || {
  echo -e "  ${RED}✗ build error${NC}"; grep -E 'error' "$work/err" | head -5; exit 1; }
perms=$(nix build --no-link --print-out-paths --impure --file "$SCENARIO" permsFile 2>"$work/err") || {
  echo -e "  ${RED}✗ build error${NC}"; grep -E 'error' "$work/err" | head -5; exit 1; }
nix eval --impure --json --file "$SCENARIO" userJs >"$work/userjs.json" 2>"$work/err" || {
  echo -e "  ${RED}✗ eval error${NC}"; grep -E 'error' "$work/err" | head -5; exit 1; }
jq -r .default "$work/userjs.json" >"$work/default.js"
jq -r .privacy "$work/userjs.json" >"$work/privacy.js"
nix eval --impure --json --file "$SCENARIO" layout >"$work/layout.json" 2>"$work/err" || {
  echo -e "  ${RED}✗ eval error${NC}"; grep -E 'error' "$work/err" | head -5; exit 1; }

echo -e "${BOLD}=== headless sessions ===${NC}"
if ! python3 -I "$DIR/lw_runtime_checks.py" "$pkg" "$perms" "$work/default.js" "$work/privacy.js" "$work/layout.json" >"$work/results.tsv" 2>"$work/py.err"; then
  echo -e "  ${RED}✗ runtime harness crashed${NC}"
  tail -15 "$work/py.err"
  keep_evidence librewolf-runtime "$work/py.err"
  exit 1
fi

PASS=0
FAIL=0
declare -a FAILURES=()
while IFS=$'\t' read -r label result; do
  printf "  %-104s " "${label:0:104}"
  if [[ "$result" == "ok" ]]; then
    printf "${GREEN}✓ ok${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|$result")
  fi
done <"$work/results.tsv"

echo ""
if [[ $((PASS + FAIL)) -lt 22 ]]; then
  echo -e "${RED}${BOLD}Only $((PASS + FAIL)) checks ran (expected at least 22); refusing to pass.${NC}"
  exit 1
fi
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo -e "      ${DIM}${detail}${NC}"
done
exit 1
