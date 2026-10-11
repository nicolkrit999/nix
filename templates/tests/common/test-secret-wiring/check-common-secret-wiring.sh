#!/usr/bin/env bash
# Secret wiring checker: sops secret names, paths, owners and consumers.
#
# Usage:
#   bash check-common-secret-wiring.sh

set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-62s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$DIR/01-scenario-secret-wiring.nix" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ PASS${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$result")
    fi
  else
    printf "${RED}✗ EVAL ERROR${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(grep -E "error:|missing|not available|undefined variable|assertion" "$stderr_file" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Secret wiring ===${NC}"
echo -e "${DIM}Secret names, paths, owners, sops files and their consumers on every host.${NC}"
echo ""

echo -e "${BOLD}claude-code MCP secrets${NC}"
run_check "check-mcp-envvars-unique"      "mcp envVars are unique and non-empty (hosts + NAS)"
run_check "check-mcp-secrets-declared"    "every mcpSecret is a sops secret (owner, /run/secrets path, file)"
run_check "check-mcp-secrets-in-yaml"     "every mcpSecret key exists in the common sops yaml"
run_check "check-mcp-nas-home-wrapper"    "NAS home build: claude wrapper exports every mcp secret"

echo ""
echo -e "${BOLD}binary caches and nix PAT${NC}"
run_check "check-cache-token-secrets"     "cachix/attic token secrets, public keys, netrc template"
run_check "check-attic-assertion-bites"   "control: attic assertion fires on an undeclared token"
run_check "check-github-pat-include"      "nix.extraOptions !includes the PAT secret path"
run_check "check-github-pat-mode-consistent" "PAT secret mode equal on NixOS and Darwin"

echo ""
echo -e "${BOLD}sops files and keys${NC}"
run_check "check-yaml-key-lookup-bites"   "control: yaml key lookup finds/rejects keys"
run_check "check-sopsfiles-and-keys"      "every secret's sopsFile exists and holds its key"

echo ""
echo -e "${BOLD}consumers${NC}"
run_check "check-davfs-secrets-template"  "davfs-secrets template root:0600 with placeholders"
run_check "check-nas-wiring-nixos"        "NAS module secret paths match declared secrets"
run_check "check-nas-secrets-darwin"      "Darwin NAS modules have their secrets declared"
run_check "check-thunderbird-forced"      "thunderbird template/secrets owners, files, keys"
run_check "check-ssh-key-paths"           "github/school ssh key paths under the user's home"

echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo "  Passed: $PASS   Failed: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  for f in "${FAILURES[@]}"; do
    IFS='|' read -r label kind detail <<<"$f"
    echo -e "  ${RED}$label [$kind]${NC}"
    echo "    ${detail//\~/$'\n    '}"
  done
  exit 1
fi
exit 0
