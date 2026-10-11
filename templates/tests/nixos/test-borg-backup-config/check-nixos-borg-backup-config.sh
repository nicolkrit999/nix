#!/usr/bin/env bash
# Real nixos-desktop and nixos-laptop borgmatic configs: excludes lint, sops wiring, repository, timer.
#
# Usage:
#   bash check-nixos-borg-backup-config.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-borg-backup-config.nix"

if ! command -v jq >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#jq nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

echo ""
echo -e "${BOLD}=== borgmatic on the real nixos-desktop and nixos-laptop hosts ===${NC}"
echo ""

err=$(mktemp)
trap 'rm -f "$err"' EXIT
if ! json=$(nix eval --json --impure --file "$SCENARIO" 2>"$err"); then
  echo -e "${RED}${BOLD}EVAL ERROR:${NC} $(grep -E 'error:' "$err" | head -3 | tr '\n' ' ')"
  exit 1
fi

while IFS=$'\t' read -r name result; do
  label=${name#check-}
  printf "  %-62s " "$label"
  if [[ $result == ok ]]; then
    printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1))
  else
    printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$label|$result")
  fi
done < <(jq -r 'to_entries | sort_by(.key)[] | [.key, .value] | @tsv' <<<"$json")

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
