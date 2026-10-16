#!/usr/bin/env bash
# Usage:
#   bash check-nixos-ibus-autostart-hidden.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-ibus-autostart-hidden.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

report() {
  local label=$1 value=$2
  printf "  %-80s " "$label"
  if [[ $value == ok ]]; then pass; else fail "$label" "$value"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== ibus autostart override (real hosts + specialisations) ===${NC}"
echo ""

for attr in report control; do
  if nix eval --raw --impure --file "$SCENARIO" "$attr" >"$WORK/$attr" 2>"$WORK/err"; then
    [[ -s $WORK/$attr ]] || report "$attr evaluated" "empty output, every check would be vacuous"
    while IFS=$'\t' read -r label value; do
      [[ -z $label ]] && continue
      report "$label" "$value"
    done <"$WORK/$attr"
  else
    report "evaluate $attr" "EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')"
  fi
done

echo ""
echo -e "${BOLD}source guards (the old workarounds stay gone)${NC}"
HYPR="$REPO_ROOT/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix"
KDE="$REPO_ROOT/modules/nixos/programs/de-wm/kde/kde-main.nix"
GNOME="$REPO_ROOT/modules/nixos/toplevel/gnome.nix"

guard() {
  local label=$1 file=$2
  if [[ ! -f $file ]]; then report "$label" "FAIL: $file missing"
  elif grep -qiE 'pkill[^"]*ibus|killall[^"]*ibus|kde-ibus-kill' "$file"; then report "$label" "FAIL: ibus kill workaround found in $file"
  else report "$label" ok; fi
}
guard "hyprland-main.nix has no ibus kill" "$HYPR"
guard "kde-main.nix has no ibus kill or kde-ibus-kill autostart" "$KDE"
guard "gnome.nix has no ibus kill" "$GNOME"

printf 'exec_once = pkill ibus-daemon\n' >"$WORK/planted.nix"
if grep -qiE 'pkill[^"]*ibus|killall[^"]*ibus|kde-ibus-kill' "$WORK/planted.nix"; then
  report "control: planted pkill ibus-daemon is detected" ok
else
  report "control: planted pkill ibus-daemon is detected" "FAIL: guard regex misses the planted line"
fi

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
