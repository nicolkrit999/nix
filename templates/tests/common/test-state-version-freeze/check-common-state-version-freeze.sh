#!/usr/bin/env bash
set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-62s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-state-version-freeze.nix" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}PASS${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$result")
    fi
  else
    printf "${RED}FAIL (eval error)${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(grep -E "error:|missing|conflict|undefined variable" "$stderr_file" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== stateVersion freeze ===${NC}"

for h in nixos-desktop nixos-laptop; do
  echo -e "\n${BOLD}$h${NC}"
  run_check "check-$h-system"               "system.stateVersion == 25.11"
  run_check "check-$h-constant"             "constants.homeStateVersion == 25.11"
  run_check "check-$h-hm"                   "HM home.stateVersion == 25.11"
  run_check "check-$h-hm-matches-constant"  "HM home.stateVersion == constants.homeStateVersion"
done

echo -e "\n${BOLD}template-host-minimal${NC}"
run_check "check-template-system"              "system.stateVersion == 25.11"
run_check "check-template-hm"                  "HM home.stateVersion == 26.05"
run_check "check-template-hm-matches-constant" "HM home.stateVersion == constants.homeStateVersion"

echo -e "\n${BOLD}Krits-MacBook-Pro (darwin)${NC}"
run_check "check-darwin-system"              "system.stateVersion == 4"
run_check "check-darwin-constant"            "constants.darwinStateVersion == 4"
run_check "check-darwin-hm"                  "HM home.stateVersion == 25.11"
run_check "check-darwin-hm-matches-constant" "HM home.stateVersion == constants.homeStateVersion"

echo -e "\n${BOLD}krit@Nicol-NAS (home-only)${NC}"
run_check "check-nas-hm"                  "home.stateVersion == 26.05"
run_check "check-nas-hm-matches-constant" "home.stateVersion == constants.homeStateVersion"
run_check "check-nas-home-base-disabled"  "krit.home.base stays disabled"

echo -e "\n${BOLD}home-base hard-coded literals vs constants${NC}"
run_check "check-literal-nixos-home-base-parsed"     "nixos home-base.nix literal found"
run_check "check-literal-darwin-home-base-parsed"    "darwin home-base.nix literal found"
run_check "check-literal-nixos-home-base-desktop"    "nixos home-base literal == desktop constant"
run_check "check-literal-nixos-home-base-laptop"     "nixos home-base literal == laptop constant"
run_check "check-literal-darwin-home-base-darwin"    "darwin home-base literal == darwin constant"

echo -e "\n${BOLD}controls${NC}"
run_check "check-control-unset-fails"            "homeStateVersion = null fails eval"
run_check "check-control-valid-evals"            "homeStateVersion = 25.11 evals (control)"
run_check "check-control-divergent-conflicts"    "divergent homeStateVersion conflicts with home-base"

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
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
exit 1
