#!/usr/bin/env bash
set -uo pipefail
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
  printf "  %-72s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-darwin-module-defaults.nix" "$attr" 2>"$stderr_file"); then
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
    excerpt=$(grep -E "error:|missing|not available|undefined variable" "$stderr_file" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Darwin module defaults (Krits-MacBook-Pro, eval-only) ===${NC}"
echo ""

echo -e "${BOLD}stylix-darwin${NC}"
run_check check-stylix-enabled                     "stylix.enable (myconfig.stylix.enable default)"
run_check check-stylix-off-control                 "control: myconfig.stylix.enable = false turns stylix.enable off"
run_check check-stylix-polarity                    "stylix.polarity follows constants.theme.polarity"
run_check check-stylix-scheme                      "stylix.base16Scheme is <base16-schemes>/share/themes/<base16Theme>.yaml"
run_check check-stylix-fonts                       "stylix monospace/sansSerif/serif all JetBrainsMono Nerd Font family"
run_check check-stylix-font-sizes                  "stylix font sizes terminal 14 / desktop 12 / popups 10"

echo -e "${BOLD}HM stylix targets${NC}"
run_check check-hm-targets-always-off              "HM stylix.targets neovim/rofi/gtksourceview are disabled"
run_check check-hm-targets-follow-catppuccin       "HM stylix bat/lazygit/starship/tmux targets == !constants.theme.catppuccin"
run_check check-hm-targets-override-control        "control: myconfig.stylix.targets.bat.enable = false overrides the default"

echo -e "${BOLD}appearance defaults${NC}"
run_check check-dark-style-dark                    "NSGlobalDomain.AppleInterfaceStyle for polarity dark"
run_check check-light-style-null                   "control: polarity light leaves AppleInterfaceStyle unset (null)"
run_check check-polarity-is-dark                   "this host's polarity (guards the dark branch above)"

echo -e "${BOLD}common-configuration-darwin and nix-darwin${NC}"
run_check check-touchid                            "sudo_local touchIdAuth + reattach"
run_check check-allow-unfree                       "nixpkgs.config.allowUnfree"
run_check check-state-version                      "system.stateVersion == constants.darwinStateVersion"
run_check check-hostnames                          "networking.hostName == computerName == constants.hostname"
run_check check-hm-backup-ext                      "home-manager.backupFileExtension"
run_check check-login-shells                       "programs.zsh and programs.fish enabled system-wide"
run_check check-nix-index                          "programs.nix-index.enable (nix-index-database darwin module imported)"
run_check check-nix-path                           "nix.nixPath"
run_check check-auto-optimise                      "nix.settings.auto-optimise-store"

echo -e "${BOLD}user-darwin shell mapping${NC}"
run_check check-shell-fish                         "constants.shell fish -> user shell pname"
run_check check-shell-zsh                          "control: constants.shell zsh -> user shell pname"
run_check check-shell-bash                         "control: constants.shell bash -> bashInteractive"

echo -e "${BOLD}home-packages-darwin roles${NC}"
run_check check-role-enabled-program-not-doubled   "terminal kitty is an enabled program, so home-packages adds no system kitty"
run_check check-role-terminal-control              "control: a terminal whose program is disabled (alacritty) lands in systemPackages"
run_check check-role-editor-control                "control: constants.editor = helix installs the helix package"
run_check check-role-editor-translation            "editor nvim is translated to pkgs.neovim (no 'nvim' attr warning)"
run_check check-role-no-warnings                   "no home-packages warning on the real host (empty browser is a silent opt-out)"
run_check check-role-warning-control               "control: a role naming a non-package emits the home-packages warning"

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
echo ""
exit 1
