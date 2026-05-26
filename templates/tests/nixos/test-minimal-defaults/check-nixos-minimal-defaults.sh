#!/usr/bin/env bash
# NixOS minimal defaults checker.
# Verifies that on a host with only constants.user = "krit" set:
#   1. Constant defaults match expected values from constants-nixos.nix
#   2. Auto-enabled modules (singleEnableOption/boolOption true) are active
#   3. The full auto-enabled module set coexists without conflicts (dry-run)
#
# Usage:
#   bash check-nixos-minimal-defaults.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_eval_check() {
  local attr="$1" label="$2"
  printf "  %-60s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-minimal-nixos.nix" "$attr" 2>"$stderr_file"); then
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
    excerpt=$(cat "$stderr_file" | grep -E "error:|missing|not available" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

run_build_check() {
  local attr="$1" label="$2"
  printf "  %-60s " "$label"
  local err
  if err=$(nix build --dry-run --no-link --impure --file "$DIR/01-scenario-minimal-nixos.nix" "$attr" 2>&1); then
    printf "${GREEN}✓ ok${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(echo "$err" | grep -E "error:|missing|not available|Package" | head -3 | tr '\n' '~')
    FAILURES+=("$label|BUILD FAILED|$excerpt")
  fi
}

echo ""
echo -e "${BOLD}=== NixOS minimal defaults check ===${NC}"
echo -e "${DIM}Host has only constants.user = \"krit\" — all else is default.${NC}"
echo ""

echo -e "${BOLD}constant defaults (from constants-nixos.nix)${NC}"
run_eval_check "check-constant-shell" "constants.shell == \"bash\""
run_eval_check "check-constant-terminal" "constants.terminal.name == \"alacritty\""
run_eval_check "check-constant-browser" "constants.browser == \"chromium\""
run_eval_check "check-constant-editor" "constants.editor == \"nano\""
run_eval_check "check-constant-filemanager" "constants.fileManager == \"dolphin\""
run_eval_check "check-constant-catppuccin" "constants.theme.catppuccin == false"

echo ""
echo -e "${BOLD}auto-enabled module states${NC}"
run_eval_check "check-hyprland-enabled" "programs.hyprland.enable == true (singleEnableOption true)"
run_eval_check "check-stylix-enabled" "myconfig.stylix.enable == true (boolOption true)"
run_eval_check "check-swaync-enabled" "services.swaync.enable == true (boolOption true)"
run_eval_check "check-hyprlock-enabled" "services.hyprlock.enable == true (boolOption true)"
run_eval_check "check-hypridle-enabled" "services.hypridle.enable == true (boolOption true)"
run_eval_check "check-waybar-hyprland-enabled" "programs.waybar-hyprland.enable == true (boolOption true)"

echo ""
echo -e "${BOLD}coexistence (dry-run build)${NC}"
run_build_check "build-coexistence" "home.activationPackage resolves cleanly"

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
