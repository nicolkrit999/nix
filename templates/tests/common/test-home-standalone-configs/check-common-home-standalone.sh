#!/usr/bin/env bash
# Usage:
#   bash check-common-home-standalone.sh

set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-home-standalone.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

record() {
  local label="$1" result="$2" rc="$3" stderr_file="$4"
  printf "  %-62s " "$label"
  if [[ "$rc" -eq 0 ]]; then
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
    excerpt=$(grep -E "error:|missing|not available|undefined variable" "$stderr_file" | head -3 | tr '\n' '~' || true)
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
}

run_check() {
  local attr="$1" label="$2" result rc=0 stderr_file
  stderr_file=$(mktemp)
  result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$SCENARIO" "$attr" 2>"$stderr_file") || rc=$?
  record "$label" "$result" "$rc" "$stderr_file"
  rm -f "$stderr_file"
}

run_host_check() {
  local host="$1" result rc=0 stderr_file
  stderr_file=$(mktemp)
  result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$SCENARIO" check-host-instantiates \
    --apply "f: f \"$host\"" 2>"$stderr_file") || rc=$?
  record "homeConfigurations.\"$host\" drvPath instantiates" "$result" "$rc" "$stderr_file"
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Standalone homeConfigurations ===${NC}"
echo -e "${DIM}Deep drvPath instantiation plus catppuccin, pkgsStable, substituters.${NC}"
echo ""

echo -e "${BOLD}instantiation${NC}"
HOSTS=$(FLAKE_ROOT="$REPO_ROOT" nix eval --json --impure --file "$SCENARIO" hostNames | tr -d '[]"' | tr ',' ' ')
for h in $HOSTS; do run_host_check "$h"; done

echo ""
echo -e "${BOLD}home-mode imports${NC}"
run_check "check-catppuccin-home-mode"           "catppuccin enable=true autoEnable=false"
run_check "check-pkgsstable-source"              "pkgsStable.path == nixpkgs-stable input"
run_check "check-pkgsstable-older-than-main"     "pkgsStable older than nixpkgs"

echo ""
echo -e "${BOLD}nix settings${NC}"
run_check "check-substituters-match-nixos"       "extra-substituters == NixOS list"
run_check "check-trusted-keys-match-nixos"       "extra-trusted-public-keys == NixOS list"
run_check "check-nix-conf-rendered"              "nix.conf rendered with non-empty substituters"

echo ""
echo -e "${DIM}----------------------------------------------------------------------${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
echo ""
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
