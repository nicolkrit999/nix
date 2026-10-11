#!/usr/bin/env bash
set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$(cd "$DIR/../../../.." && pwd)}"

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
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-monitor-layout-consistency.nix" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ PASS${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|$result")
    fi
  else
    printf "${RED}✗ eval error${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|EVAL ERROR: $(grep -E 'error:|missing|undefined variable' "$stderr_file" | head -3 | tr '\n' '~')")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Monitor layout consistency ===${NC}"

echo -e "\n${BOLD}desktop (hyprland / mango / niri)${NC}"
run_check check-desktop-presence "DP-1, DP-2, HDMI-A-1 declared in all three"
run_check check-desktop-width "width agrees"
run_check check-desktop-height "height agrees"
run_check check-desktop-refresh "refresh (rounded) agrees"
run_check check-desktop-scale "scale agrees"
run_check check-desktop-rotation "rotation agrees"
run_check check-desktop-position "position agrees (disabled/mirrored excluded)"
run_check check-desktop-hdmi-off "HDMI-A-1 disabled or mirrored in all three"

echo -e "\n${BOLD}laptop base${NC}"
run_check check-laptop-presence "eDP-1 declared in all three"
run_check check-laptop-mode "mode agrees"
run_check check-laptop-scale "scale agrees"
run_check check-laptop-position "position agrees"
run_check check-laptop-no-rotation "rotation agrees"

echo -e "\n${BOLD}laptop specialisation home${NC}"
run_check check-home-spec-covered "every desc: monitor has a niri output"
run_check check-home-spec-mode "mode agrees"
run_check check-home-spec-scale "scale agrees"
run_check check-home-spec-rotation "rotation agrees"
run_check check-home-spec-position "position agrees"
run_check check-home-spec-niri-no-extras "no niri output without hyprland monitor"
run_check check-home-spec-workspace-monitors "monitorWorkspaces monitors are declared"
run_check check-home-spec-wallpaper-targets "wallpaper targetMonitor are declared"
run_check check-home-spec-lid-ignore "HandleLidSwitch* all ignore"

echo -e "\n${BOLD}controls (comparison must bite)${NC}"
run_check check-control-scale-bites "mutated scale is flagged"
run_check check-control-refresh-bites "mutated refresh is flagged"
run_check check-control-position-bites "mutated position is flagged"
run_check check-control-rotation-bites "mutated rotation is flagged"
run_check check-control-position-skips-disabled "disabled HDMI-A-1 excluded from position"

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
