#!/usr/bin/env bash
# Usage:
#   bash check-common-ai-tool-modules.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-ai-tool-modules.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_group() {
  local group="$1" title="$2" json rc=0 stderr_file
  echo -e "${BOLD}${title}${NC}"
  stderr_file=$(mktemp)
  json=$(FLAKE_ROOT="$REPO_ROOT" nix eval --json --impure --file "$SCENARIO" "$group" 2>"$stderr_file") || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    printf "  %-62s ${RED}FAIL (eval error)${NC}\n" "$group"
    ((FAIL++)) || true
    FAILURES+=("$group|EVAL ERROR|$(grep -E "error:|missing|undefined variable" "$stderr_file" | head -3 | tr '\n' '~' || true)")
    rm -f "$stderr_file"
    echo ""
    return
  fi
  rm -f "$stderr_file"
  while IFS=$'\t' read -r name result; do
    printf "  %-62s " "$name"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}PASS${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$group/$name|CHECK FAILED|$result")
    fi
  done < <(python3 -c 'import json,sys; [print(f"{k}\t{v}") for k,v in sorted(json.load(sys.stdin).items())]' <<<"$json")
  echo ""
}

echo ""
echo -e "${BOLD}=== AI tool modules: headroom, claude-code cowork + krit openrouterAliases, codex overlay ===${NC}"
echo -e "${DIM}template-host-minimal + extendModules toggles, eval only.${NC}"
echo ""

run_group headroom "headroom"
run_group cowork   "claude-code cowork toggle"
run_group codex    "codex overlay"
run_group openrouter "claude-code krit openrouterAliases"

echo -e "${DIM}----------------------------------------------------------------------${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
echo ""
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label kind err <<< "$entry"
  echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}-> $kind${NC}"
  if [[ -n "$err" ]]; then
    echo "$err" | tr '~' '\n' | while IFS= read -r line; do
      [[ -n "$line" ]] && echo -e "      ${DIM}$line${NC}" || true
    done
  fi
done
echo ""
exit 1
