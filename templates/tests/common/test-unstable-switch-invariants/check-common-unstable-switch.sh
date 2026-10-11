#!/usr/bin/env bash
# Unstable-channel switch invariants checker.
# Locks in the facts the switch to nixos-unstable introduced: the stable input
# and pkgsStable module argument, the catppuccin enable/autoEnable pair, the
# vicinae font override, the atuin keybindings, and the absence of removed inputs.
#
# Usage:
#   bash check-common-unstable-switch.sh

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
  if result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$DIR/01-scenario-unstable-switch.nix" "$attr" 2>"$stderr_file"); then
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
  hits=$(cd "$REPO_ROOT" && grep -rInE --include='*.nix' "$pattern" flake.nix modules hosts users packages 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' | head -5 | tr '\n' '~' || true)
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
echo -e "${BOLD}=== Unstable switch invariants ===${NC}"
echo -e "${DIM}Inputs, pkgsStable, catppuccin, vicinae font, atuin bindings, removed-name sweep.${NC}"
echo ""

echo -e "${BOLD}flake inputs${NC}"
run_check "check-stable-input-exists"        "nixpkgs-stable input exists"
run_check "check-no-nixpkgs-unstable-input"  "nixpkgs-unstable input is gone"
run_check "check-stable-older-than-main"     "nixpkgs-stable is older than nixpkgs"

echo ""
echo -e "${BOLD}pkgsStable module argument${NC}"
run_check "check-pkgsstable-nixos-system"  "NixOS system modules receive pkgsStable"
run_check "check-pkgsstable-nixos-home"    "NixOS home-manager modules receive pkgsStable"
run_check "check-pkgsstable-darwin-system" "Darwin system modules receive pkgsStable"
run_check "check-pkgsstable-darwin-home"   "Darwin home-manager modules receive pkgsStable"

echo ""
echo -e "${BOLD}catppuccin${NC}"
run_check "check-catppuccin-nixos-system" "NixOS system enable=true autoEnable=false"
run_check "check-catppuccin-nixos-home"   "NixOS home-manager enable=true autoEnable=false"
run_check "check-catppuccin-darwin-home"  "Darwin home-manager enable=true autoEnable=false"

echo ""
echo -e "${BOLD}vicinae${NC}"
run_check "check-vicinae-font-family"      "font family == JetBrainsMono Nerd Font"
run_check "check-vicinae-font-size"        "font size == 12"
run_check "check-vicinae-stylix-fonts-off" "stylix vicinae fonts.enable == false"

echo ""
echo -e "${BOLD}atuin${NC}"
run_check "check-atuin-ctrl-r-disabled" "flags == [ --disable-ctrl-r ]"
run_check "check-atuin-bash-ctrl-o"     "bash: Ctrl-O -> atuin-search"
run_check "check-atuin-zsh-ctrl-o"      "zsh: Ctrl-O -> atuin-search"
run_check "check-atuin-fish-ctrl-o"     "fish: Ctrl-O -> atuin-search"
run_check "check-atuin-fish-insert-ctrl-o" "fish: insert-mode Ctrl-O -> atuin-search"
run_check "check-atuin-disabled-no-bindings" "atuin disabled: no atuin bindings"

echo ""
echo -e "${BOLD}removed names${NC}"
run_grep_check "no pkgs-unstable in config .nix files"    'pkgs-unstable'
run_grep_check "no nixpkgs-unstable in config .nix files" 'nixpkgs-unstable'

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
