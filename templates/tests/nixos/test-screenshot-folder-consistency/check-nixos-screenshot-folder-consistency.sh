#!/usr/bin/env bash
# Every screenshot destination (DE/WM/shell scripts and tool configs) resolves to one identical folder, on both real hosts and synthetic per-shell hosts. Eval only.
#
# Usage:
#   bash check-nixos-screenshot-folder-consistency.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-screenshot-folder-consistency.nix"
VARIANTS=(nixos-desktop nixos-laptop synthetic-caelestia synthetic-noctalia)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for v in "${VARIANTS[@]}"; do
  (
    VARIANT=$v nix eval --raw --impure --file "$SCENARIO" report >"$WORK/$v.report" 2>"$WORK/$v.err"
    echo $? >"$WORK/$v.rc"
  ) &
done
wait

echo ""
echo -e "${BOLD}=== screenshot folder consistency ===${NC}"

declare -A DEST=()
for v in "${VARIANTS[@]}"; do
  echo ""
  echo -e "${BOLD}$v${NC}"
  if [[ $(cat "$WORK/$v.rc") -ne 0 ]]; then
    printf "  %-84s " "evaluate $v"
    fail "$v: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$v.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r label result; do
    [[ -z $label ]] && continue
    if [[ $label == DEST ]]; then DEST[$v]=$result; continue; fi
    printf "  %-84s " "$label"
    if [[ $result == ok ]]; then pass; else fail "$v: $label" "$result"; fi
  done <"$WORK/$v.report"
done

echo ""
echo -e "${BOLD}cross-variant${NC}"
printf "  %-84s " "shared destination identical across all variants (exact string)"
distinct=$(printf '%s\n' "${DEST[@]}" | sort -u)
if [[ ${#DEST[@]} -eq ${#VARIANTS[@]} && $(printf '%s\n' "$distinct" | wc -l) -eq 1 ]]; then
  pass
else
  fail "cross-variant: identical destination" "got: $(for k in "${!DEST[@]}"; do printf '%s=%s ' "$k" "${DEST[$k]}"; done)"
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
