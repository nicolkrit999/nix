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
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-darwin-host-contract.nix" "$attr" 2>"$stderr_file"); then
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
echo -e "${BOLD}=== Darwin host contract (Krits-MacBook-Pro, eval-only) ===${NC}"
echo ""

echo -e "${BOLD}users${NC}"
run_check check-primary-user          "system.primaryUser == constants.user"
run_check check-user-literal          "constants.user == krit"
run_check check-uid                   "users.users.<user>.uid == constants.uid"
run_check check-uid-501               "constants.uid == 501"
run_check check-known-users           "users.knownUsers contains user"
run_check check-home-dir              "users.users.<user>.home == /Users/<user>"
run_check check-hm-home-dir           "HM home.homeDirectory == users.users.<user>.home"
run_check check-shell-registered      "environment.shells contains the user's shell"

echo -e "${BOLD}system${NC}"
run_check check-nixbld-gid            "ids.gids.nixbld == 350"
run_check check-gc-off                "nix.gc.automatic == false"
run_check check-experimental-features "experimental-features has flakes + nix-command"
run_check check-host-platform         "nixpkgs.hostPlatform.system == aarch64-darwin"
run_check check-assertions            "no failing config.assertions"

echo -e "${BOLD}sops${NC}"
run_check check-sops-key-env-consistent "SOPS_AGE_KEY_FILE env == age.keyFile == sops.environment"
run_check check-sops-key-under-home     "age.keyFile lives under the user's home"
run_check check-sops-no-ssh-paths       "age/gnupg sshKeyPaths empty"
run_check check-nix-extraoptions-include "nix.extraOptions !include github PAT secret path"
run_check check-github-key-path         "github_general_ssh_key.path"
run_check check-github-key-mode         "github_general_ssh_key.mode == 0600"
run_check check-mcp-secrets-declared    "mcpSecrets all declared in sops.secrets"

echo -e "${BOLD}homebrew${NC}"
run_check check-mas-apps-empty        "homebrew.masApps == {} (mas 7.0.0 guard)"
run_check check-brew-no-zap           "onActivation.cleanup != zap"
run_check check-brew-no-upgrade       "onActivation.upgrade == false"

echo -e "${BOLD}browser opt-out${NC}"
run_check check-browser-no-pkgs       "no browser package in systemPackages"
run_check check-browser-control-bites "control: browser=firefox adds firefox package"

echo -e "${BOLD}packages${NC}"
run_check check-resolved-pkgs-exist   "term/fileManager/editor resolve to real pkgs attrs"
run_check check-network-tools-enabled "control: network-tools active (tcpdump present)"
run_check check-no-linux-only-tools   "no Linux-only network tools"

echo -e "${BOLD}home-manager${NC}"
run_check check-kitty-option-as-alt   "kitty macos_option_as_alt == yes"

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
