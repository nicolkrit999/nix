#!/usr/bin/env bash
# Specialization contract checker.
# Verifies that each specialization's lib.mkForce overrides actually land —
# checks myconfig option values and key config artifacts (autostart entries,
# shell aliases, scripts in home.packages) within each specialization's config.
#
# Usage:
#   bash check-nixos-spec-contract.sh

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-62s " "$label"
  local result
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-spec-contract.nix" "$attr" 2>&1); then
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
echo -e "${BOLD}=== Specialization contract check ===${NC}"
echo -e "${DIM}Verifies that specialization lib.mkForce overrides are effective.${NC}"
echo ""

echo -e "${BOLD}guest${NC}"
run_check "check-guest-hyprland-disabled"  "hyprland.enable == false"
run_check "check-guest-stylix-disabled"    "myconfig.stylix.enable == false"
run_check "check-guest-bluetooth-disabled" "bluetooth.enable == false"
run_check "check-guest-hyprlock-disabled"  "services.hyprlock.enable == false"
run_check "check-guest-swaync-disabled"    "services.swaync.enable == false"
run_check "check-guest-welcome-desktop"    "autostart .desktop Exec points to guest-welcome"

echo ""
echo -e "${BOLD}safe-mode${NC}"
run_check "check-safemode-stylix-disabled"      "myconfig.stylix.enable == false"
run_check "check-safemode-shell-bash"           "constants.shell == 'bash'"
run_check "check-safemode-terminal-xterm"       "constants.terminal.name == 'xterm'"
run_check "check-safemode-hyprland-disabled"    "hyprland.enable == false"
run_check "check-safemode-icewm-enabled"        "icewm.enable == true"
run_check "check-safemode-startx-enabled"       "startx.enable == true"
run_check "check-safemode-xinitrc-has-icewm"    ".xinitrc contains 'icewm-session'"
run_check "check-safemode-alias-start-icewm"    "shellAliases.start-icewm == 'startx'"

echo ""
echo -e "${BOLD}deep-focus${NC}"
run_check "check-deepfocus-swaync-enabled" "services.swaync.enable == true"

echo ""
echo -e "${BOLD}secure-travel${NC}"
run_check "check-securetravel-bluetooth-disabled"  "bluetooth.enable == false"
run_check "check-securetravel-hyprland-disabled"   "hyprland.enable == false"
run_check "check-securetravel-tailscale-disabled"  "services.tailscale.enable == false"
run_check "check-securetravel-nix-ld-disabled"     "programs.nix-ld.enable == false"
run_check "check-securetravel-gnome-enabled"       "programs.gnome.enable == true"
run_check "check-securetravel-killswitch-exists"   "NM dispatcherScript exists"

echo ""
echo -e "${BOLD}entertainment${NC}"
run_check "check-entertainment-kde-enabled"        "programs.kde.enable == true"
run_check "check-entertainment-hyprland-disabled"  "programs.hyprland.enable == false"

echo ""
echo -e "${BOLD}school${NC}"
run_check "check-school-browser-constant"  "constants.browser == 'brave-school'"
run_check "check-school-editor-constant"   "constants.editor == 'vscode-school'"
run_check "check-school-setup-script"      "school-distrobox-setup in home.packages"
run_check "check-school-check-script"      "school-distrobox-check in home.packages"
run_check "check-school-clear-script"      "school-distrobox-clear in home.packages"

echo ""
echo -e "${BOLD}home${NC}"
run_check "check-home-monitors-nonempty" "hyprland.monitors is non-empty"

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
