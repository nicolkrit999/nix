#!/usr/bin/env bash
# School specialisation checks on the real nixos-desktop and nixos-laptop, eval only.
#
# Usage:
#   bash check-nixos-spec-school.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-spec-school.nix"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for h in "${HOSTS[@]}"; do
  (
    export HOST=$h
    nix eval --raw --impure --file "$SCENARIO" report >"$WORK/$h.report" 2>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" scripts >"$WORK/$h.scripts" 2>>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" drvs >"$WORK/$h.drvs" 2>>"$WORK/$h.err"
    echo $? >"$WORK/$h.rc"
  ) &
done
wait

syntax_check() {
  local h=$1 name=$2 file=$3 out
  printf "  %-70s " "bash -n $name"
  if out=$(bash -n "$file" 2>&1); then pass; else fail "$h: bash -n $name" "$out"; fi
}

echo ""
echo -e "${BOLD}=== school specialisation ===${NC}"

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  if [[ $(cat "$WORK/$h.rc") -ne 0 ]]; then
    printf "  %-70s " "evaluate $h"
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r label result; do
    [[ -z $label ]] && continue
    printf "  %-70s " "$label"
    if [[ $result == ok ]]; then pass; else fail "$h: $label" "$result"; fi
  done <"$WORK/$h.report"

  mkdir -p "$WORK/$h.d"
  jq -r 'to_entries[] | "\(.key)\t\(.value | @base64)"' "$WORK/$h.scripts" |
    while IFS=$'\t' read -r name b64; do printf '%s' "$b64" | base64 -d >"$WORK/$h.d/$name"; done
  for f in "$WORK/$h.d"/*; do syntax_check "$h" "$(basename "$f")" "$f"; done

  for kind in startup deep; do
    for drv in $(jq -r ".$kind[]" "$WORK/$h.drvs"); do
      n=$(basename "$drv" .drv)
      nix derivation show "$drv" | jq -r '.derivations | to_entries[0].value.structuredAttrs.text' >"$WORK/$h.d/$n"
      syntax_check "$h" "$n (generated)" "$WORK/$h.d/$n"
      printf "  %-70s " "$n names both containers"
      if grep -q '"school-ubuntu"' "$WORK/$h.d/$n" && grep -q '"school-arch"' "$WORK/$h.d/$n"; then pass
      else fail "$h: $n containers" "school-ubuntu or school-arch missing"; fi
    done
    printf "  %-70s " "$kind check derivation found"
    if [[ $(jq ".$kind | length" "$WORK/$h.drvs") -ge 1 ]]; then pass; else fail "$h: $kind drv" "no derivation in string context"; fi
  done
done

printf "\n  %-70s " "control: bash -n rejects a broken script"
echo 'if then' >"$WORK/broken.sh"
if bash -n "$WORK/broken.sh" 2>/dev/null; then fail "control bash -n" "broken script accepted"; else pass; fi

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
