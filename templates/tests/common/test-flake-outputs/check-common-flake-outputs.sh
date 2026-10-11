#!/usr/bin/env bash
# Flake output shape checker.
# Locks structural host placement invariants,
# pkgsStable wiring and the nixpkgs-stable pin.
#
# Usage:
#   bash check-common-flake-outputs.sh

set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"

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
  if result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$DIR/01-scenario-flake-outputs.nix" "$attr" 2>"$stderr_file"); then
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
    excerpt=$(cat "$stderr_file" | grep -E "error:|missing|not available|undefined variable" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

run_grep_check() {
  local label="$1" pattern="$2"
  printf "  %-62s " "$label"
  local hits
  hits=$(cd "$REPO_ROOT" && grep -rInE --include='*.nix' "$pattern" flake.nix modules hosts users packages 2>/dev/null | head -5 | tr '\n' '~' || true)
  if [[ -z "$hits" ]]; then
    printf "${GREEN}✓ ok${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|CHECK FAILED|$hits")
  fi
}

echo ""
echo -e "${BOLD}=== Flake outputs shape ===${NC}"
echo -e "${DIM}Output names per platform, host exclusions, pkgsStable wiring, stable pin.${NC}"
echo ""

echo -e "${BOLD}output names${NC}"
run_check "check-nas-not-in-nixos"       "Home-only and darwin hosts absent from nixosConfigurations"
run_check "check-home-only-placement"    "Home-only hosts only in homeConfigurations"
run_check "check-home-covers-nixos"      "Every nixos host has a krit@<host> homeConfiguration"
run_check "check-home-no-darwin"         "No darwin host in homeConfigurations"

echo ""
echo -e "${BOLD}pkgsStable wiring${NC}"
run_check "check-pkgsstable-nixos-hosts" "NixOS hosts: pkgsStableFor entry + stable source"
run_check "check-pkgsstable-darwin"      "Darwin host: pkgsStableFor entry + stable source"
run_check "check-pkgsstable-home"        "All homeConfigurations: pkgsStable is nixpkgs-stable"

echo ""
echo -e "${BOLD}host imports and pin${NC}"
run_check "check-root-fs-single-definition" "every NixOS host defines fileSystems.\"/\" exactly once"
run_check "check-stable-pin-consistent"     "nixpkgs-stable pin: flake.nix == flake.lock == lib.version"

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
