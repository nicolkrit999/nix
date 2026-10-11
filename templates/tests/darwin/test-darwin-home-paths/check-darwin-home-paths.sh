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
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-darwin-home-paths.nix" "$attr" 2>"$stderr_file"); then
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
echo -e "${BOLD}=== Darwin home paths (Krits-MacBook-Pro, eval-only) ===${NC}"
echo ""

echo -e "${BOLD}base host (positive control: sweep must be clean)${NC}"
run_check check-base-home-dir                  "HM home.homeDirectory under /Users"
run_check check-base-file-texts                "no /home/ in home.file texts"
run_check check-base-file-texts-nonvacuous     "control: home.file text sweep is non-empty"
run_check check-base-xdg-texts                 "no /home/ in xdg.configFile texts"
run_check check-base-session-vars              "no /home/ in home.sessionVariables"
run_check check-base-hm-activation             "no /home/ in home.activation"
run_check check-base-sys-activation            "no /home/ in system.activationScripts"
run_check check-base-sys-activation-control    "control: activation sweep sees /Users"
run_check check-base-sys-env                   "no /home/ in environment.variables"
run_check check-base-sops-template-paths       "no /home/ in sops.templates paths"
run_check check-base-sops-template-control     "control: sops.templates sweep sees /Users"
run_check check-base-nh-flake                  "programs.nh.flake under home.homeDirectory"

echo -e "${BOLD}variant: librewolf + firefox enabled${NC}"
run_check check-variant-control                "control: variant activates both browsers"
run_check check-variant-file-texts             "no /home/ in home.file texts"
run_check check-variant-xdg-texts              "no /home/ in xdg.configFile texts"
run_check check-variant-session-vars           "no /home/ in home.sessionVariables"
run_check check-variant-hm-activation          "no /home/ in home.activation"
run_check check-variant-sys-activation         "no /home/ in system.activationScripts"
run_check check-variant-firefox-user-js        "no /home/ in Firefox/LibreWolf user.js"
run_check check-variant-librewolf-settings     "no /home/ in programs.librewolf profile settings"
run_check check-variant-firefox-settings       "no /home/ in programs.firefox profile settings"
run_check check-variant-wrapper-distribution   "librewolf MOZ_APP_DISTRIBUTION under home.homeDirectory"
run_check check-variant-wrapper-text           "librewolf wrapper script has no /home/"

echo -e "${BOLD}browser home regression guard (download dir + policyRoot + wrapper)${NC}"
run_check check-variant-browser-home           "darwin: browser paths under /Users/<user>"
run_check check-linux-nixos-browser-home       "nixosConfigurations HM: browser paths under /home/<user>"
run_check check-linux-standalone-browser-home  "standalone homeConfigurations: browser paths under /home/<user>"

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
