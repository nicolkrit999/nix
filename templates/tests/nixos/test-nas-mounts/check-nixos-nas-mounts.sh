#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
HOSTS=(nixos-desktop nixos-laptop)
PASS=0; FAIL=0
declare -a FAILURES=()

echo ""
echo -e "${BOLD}=== NAS, cloud and windows mount definitions ===${NC}"

for host in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}${host}${NC}"
  stderr_file=$(mktemp)
  if ! json=$(HOST_UNDER_TEST="$host" nix eval --json --impure --file "$DIR/01-scenario-nas-mounts.nix" 2>"$stderr_file"); then
    printf "  ${RED}✗ eval error${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$host: whole-host evaluation|$(grep -E 'error:' "$stderr_file" | head -3)")
    rm -f "$stderr_file"
    continue
  fi
  rm -f "$stderr_file"
  while IFS=$'\t' read -r name result; do
    printf "  %-48s " "$name"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ PASS${NC}\n"; ((PASS++)) || true
    else
      printf "${RED}✗ FAIL${NC}\n"; ((FAIL++)) || true
      FAILURES+=("$host: $name|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
done

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<< "$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
done
exit 1
