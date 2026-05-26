#!/usr/bin/env bash
# Darwin minimal defaults checker.
# Verifies that on a Darwin host with only basic identity constants set:
#   1. Constant defaults match expected values from constants-darwin.nix
#   2. Auto-enabled modules (singleEnableOption/boolOption true) are active
#
# This test uses nix eval only — no build check (Darwin cross-builds are heavy).
#
# Usage:
#   bash check-darwin-minimal-defaults.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-60s " "$label"
  local result
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-minimal-darwin.nix" "$attr" 2>&1); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ ok${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ fail${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$result")
    fi
  else
    printf "${RED}✗ eval error${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(echo "$result" | grep -E "error:|missing|not available|undefined variable" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
}

echo ""
echo -e "${BOLD}=== Darwin minimal defaults check ===${NC}"
echo -e "${DIM}Host sets only user, uid, hostname, and state versions — all else is default.${NC}"
echo ""

echo -e "${BOLD}constant defaults (from constants-darwin.nix)${NC}"
run_check "check-constant-shell"       "constants.shell == \"bash\""
run_check "check-constant-terminal"   "constants.terminal.name == \"alacritty\""
run_check "check-constant-browser"    "constants.browser == \"firefox\""
run_check "check-constant-editor"     "constants.editor == \"nano\""
run_check "check-constant-filemanager" "constants.fileManager == \"nnn\""
run_check "check-constant-catppuccin" "constants.theme.catppuccin == false"

echo ""
echo -e "${BOLD}auto-enabled module states${NC}"
run_check "check-stylix-enabled"        "myconfig.stylix.enable == true (boolOption true)"
run_check "check-home-packages-enabled" "home-packages.enable == true (singleEnableOption true)"

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
echo ""
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label kind err <<< "$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}→ $kind${NC}"
  if [[ -n "$err" ]]; then
    echo "$err" | tr '~' '\n' | while IFS= read -r line; do
      [[ -n "$line" ]] && echo -e "      ${DIM}$line${NC}" || true
    done
  fi
done
echo ""
exit 1
