#!/usr/bin/env bash
# Constants to env/shell/hm/hardware wiring checker (real-host checks on both hosts, twins on the laptop).
#
# Usage:
#   bash check-nixos-env-shell-wiring.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-env-shell-wiring.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

for tool in nix jq bash; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool"; exit 2; }
done

for host in nixos-desktop nixos-laptop; do
  # twins are host-independent; the desktop's GNOME makes them ~3x slower (readme)
  twins=true; min_checks=45
  [[ "$host" == nixos-desktop ]] && { twins=false; min_checks=10; }
  echo ""
  echo -e "${BOLD}=== $host ===${NC}"
  err=$(mktemp)
  json=$(nix eval --impure --json --file "$SCENARIO" --argstr host "$host" --arg twins "$twins" results 2>"$err") || {
    echo -e "  ${RED}✗ eval error${NC}"
    ((FAIL++)) || true
    FAILURES+=("$host evaluation|$(grep -E 'error:' "$err" | head -3 | tr '\n' '~')")
    rm -f "$err"
    continue
  }
  rm -f "$err"

  host_n=0
  while IFS=$'\t' read -r label result; do
    ((host_n++)) || true
    printf "  %-70s " "$label"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ ok${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ fail${NC}\n"
      ((FAIL++)) || true
      if [[ "$result" == "FAIL: eval error" ]]; then
        result="$result~$(CHECK_LABEL="$label" nix eval --impure --raw --file "$SCENARIO" --argstr host "$host" --arg twins "$twins" --apply 'cs: builtins.deepSeq cs.${builtins.getEnv "CHECK_LABEL"} "x"' checks 2>&1 | grep -E 'error:' | head -3 | tr '\n' '~')"
      fi
      FAILURES+=("$host: $label|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
  if [[ $host_n -lt $min_checks ]]; then
    echo -e "  ${RED}✗ only $host_n checks ran (expected at least $min_checks)${NC}"
    ((FAIL++)) || true
    FAILURES+=("$host: check count|only $host_n checks ran, expected at least $min_checks (twins=$twins)")
  fi
done

echo ""
if [[ $((PASS + FAIL)) -lt 30 ]]; then
  echo -e "${RED}${BOLD}Only $((PASS + FAIL)) checks ran (expected at least 30); refusing to pass.${NC}"
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
