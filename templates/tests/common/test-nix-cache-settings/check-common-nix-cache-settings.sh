#!/usr/bin/env bash
set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

echo ""
echo -e "${BOLD}=== nix cache settings ===${NC}"

err=$(mktemp)
trap 'rm -f "$err"' EXIT
if ! json=$(nix eval --raw --impure --file "$DIR/01-scenario-nix-cache-settings.nix" --apply 'x: builtins.toJSON (builtins.mapAttrs (n: v: v) x)' 2>"$err"); then
  echo -e "${RED}${BOLD}EVAL ERROR${NC}"
  grep -E "error:|missing|undefined variable|attribute" "$err" | head -5 || true
  exit 1
fi

PASS=0
FAIL=0
while IFS=$'\t' read -r name result; do
  printf "  %-60s " "$name"
  if [[ "$result" == "ok" ]]; then
    echo -e "${GREEN}PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}"
    echo -e "      ${DIM}${result}${NC}"
    FAIL=$((FAIL + 1))
  fi
done < <(jq -r 'to_entries | sort_by(.key)[] | [.key, .value] | @tsv' <<<"$json")

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}$FAIL of $((PASS + FAIL)) checks failed.${NC}"
exit 1
