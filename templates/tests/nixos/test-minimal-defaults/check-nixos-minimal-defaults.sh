#!/usr/bin/env bash
# NixOS minimal defaults checker.
# See test-minimal-defaults-readme.md for what each check asserts.
#
# Usage:
#   bash check-nixos-minimal-defaults.sh

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
echo -e "${DIM}Hosts: minimal (user krit), override (user alice + custom idle timeouts), nowm (hyprland off).${NC}"
echo ""

echo -e "${BOLD}constants safety and derivation${NC}"
run_eval_check "check-emergency-access-off" "constants.emergencyAccess defaults to false"
run_eval_check "check-screenshots-abs-default" "screenshotsAbs expands \$HOME for krit"
run_eval_check "check-screenshots-abs-follows-user" "screenshotsAbs follows constants.user (alice)"
run_eval_check "check-primary-wallpaper-is-fallback" "primaryWallpaper falls back to fallbackWallpaperURL"

echo ""
echo -e "${BOLD}hypridle invariants${NC}"
run_eval_check "check-idle-timeouts-ordered-default" "default timeouts ordered dim < lock < screenOff"
run_eval_check "check-idle-timeouts-reach-listeners-default" "listeners use the configured timeouts (default)"
run_eval_check "check-idle-timeouts-reach-listeners-override" "listeners use the configured timeouts (override)"
run_eval_check "check-no-wm-no-idle-actions" "no WM enabled => hypridle not enabled"

echo ""
echo -e "${BOLD}hyprland module effects${NC}"
run_eval_check "check-hyprland-wrapper-no-caps" "Hyprland wrapper has no capabilities"
run_eval_check "check-hyprland-disabled-no-nixos-hyprland" "disabled module => NixOS programs.hyprland off"

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
