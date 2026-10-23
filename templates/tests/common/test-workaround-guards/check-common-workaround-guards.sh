#!/usr/bin/env bash
# Usage:
#   bash check-common-workaround-guards.sh

set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-workaround-guards.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
WARN=0
declare -a FAILURES=()
declare -a WARNINGS=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-62s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(FLAKE_ROOT="$REPO_ROOT" nix eval --raw --impure --file "$SCENARIO" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}PASS${NC}\n"
      ((PASS++)) || true
    elif [[ "$result" == WARN:* ]]; then
      printf "${YELLOW}WARN${NC}\n"
      ((WARN++)) || true
      WARNINGS+=("$label|$result")
    else
      printf "${RED}FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$result")
    fi
  else
    printf "${RED}FAIL${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(grep -E "error:|missing|not available|undefined variable" "$stderr_file" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Workaround guards ===${NC}"
echo -e "${DIM}Each momentary workaround must stay effective; WARN means it became removable.${NC}"
echo ""

echo -e "${BOLD}vicinae (gcc15Stdenv override)${NC}"
run_check "check-vicinae-hm-stdenv-follows-system"              "HM package cc version == system stdenv cc"
run_check "check-vicinae-input-server-stdenv-follows-system"    "input-server cc version == system stdenv cc"
run_check "check-vicinae-hm-and-input-server-same-package"      "HM and input-server use the same package"
run_check "warn-vicinae-override-still-needed"                  "upstream gcc15 differs from our stdenv (override needed)"

echo ""
echo -e "${BOLD}tgt (TDLib pinned to the tdlib-rs version)${NC}"
run_check "check-tgt-single-package"          "exactly one tgt in nixos-desktop systemPackages"
run_check "check-tgt-links-pinned-tdlib"      "tgt builds against the pinned TDLib"
run_check "check-tgt-tdlib-rs-unchanged"      "locked tgt source still uses the tdlib-rs the pin is for"
run_check "warn-tgt-tdlib-pin-still-needed"   "nixpkgs tdlib differs from the pin (pin needed)"

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"

if [[ $WARN -gt 0 ]]; then
  echo -e "${YELLOW}${BOLD}REMOVABLE WORKAROUNDS ($WARN, not a failure):${NC}"
  for entry in "${WARNINGS[@]}"; do
    IFS="|" read -r label msg <<< "$entry"
    echo -e "  ${YELLOW}!${NC} ${BOLD}$label${NC}: ${DIM}$msg${NC}"
  done
  echo ""
fi

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed${NC} ($WARN warnings)."
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
