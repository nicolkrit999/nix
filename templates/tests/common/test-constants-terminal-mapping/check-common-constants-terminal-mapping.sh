#!/usr/bin/env bash
# constants.terminal.name -> package/exe/module resolution checker.
#
# Usage:
#   bash check-common-constants-terminal-mapping.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-constants-terminal-mapping.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

for tool in nix jq bash; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool"; exit 2; }
done

echo ""
echo -e "${BOLD}=== constants.terminal.name mapping ===${NC}"
err=$(mktemp)
json=$(nix eval --impure --json --file "$SCENARIO" results 2>"$err") || {
  echo -e "  ${RED}✗ eval error${NC}"
  grep -E 'error:' "$err" | head -3
  rm -f "$err"
  exit 1
}
rm -f "$err"

while IFS=$'\t' read -r label result; do
  printf "  %-100s " "$label"
  if [[ "$result" == "ok" ]]; then
    printf "${GREEN}✓ ok${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"
    ((FAIL++)) || true
    if [[ "$result" == "FAIL: eval error" ]]; then
      result="$result~$(CHECK_LABEL="$label" nix eval --impure --raw --file "$SCENARIO" --apply 'cs: builtins.deepSeq cs.${builtins.getEnv "CHECK_LABEL"} "x"' checks 2>&1 | grep -E 'error:' | head -3 | tr '\n' '~')"
    fi
    FAILURES+=("$label|$result")
  fi
done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")

echo ""
if [[ $((PASS + FAIL)) -lt 15 ]]; then
  echo -e "${RED}${BOLD}Only $((PASS + FAIL)) checks ran (expected at least 15); refusing to pass.${NC}"
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
  echo "$detail" | tr '~' '\n' | while IFS= read -r line; do
    [[ -n "$line" ]] && echo -e "      ${DIM}${line}${NC}" || true
  done
done
exit 1
