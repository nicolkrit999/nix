#!/usr/bin/env bash
# Usage:
#   bash check-nixos-clock-format.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-clock-format.nix"

BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== use24HourClock: sddm-astronaut, sddm-pixie, hyprlock (built outputs) ===${NC}"

FARM=""
if ! FARM=$(nix build --impure --file "$SCEN" --no-link --print-out-paths all 2>"$WORK/build.err"); then
  echo -e "${RED}BUILD ERROR: the link farm of all scenarios did not build; attributing per derivation${NC}"
  tail -n 8 "$WORK/build.err" >&2
  if nix eval --json --impure --file "$SCEN" buildAttrs >"$WORK/attrs.json" 2>"$WORK/err"; then
    mapfile -t ATTRS < <(jq -r '.[]' "$WORK/attrs.json")
    for a in "${ATTRS[@]}"; do
      nix build --impure --file "$SCEN" --no-link "$a" >/dev/null 2>"$WORK/err.$a" \
        || echo -e "${RED}build failed: $a${NC}: $(grep -m3 -E 'error|HourFormat|sddm|pixie' "$WORK/err.$a" | tr '\n' ' ')"
    done
  else
    grep -E 'error:' "$WORK/err" | head -3 >&2
  fi
  exit 1
fi

mapfile -t FAILING < <(jq -r '.expectFail[]' "$FARM/meta.json")
for n in "${FAILING[@]}"; do
  rc=0
  nix build --impure --file "$SCEN" --no-link --option log-lines 100 "pkg.$n.theme" >/dev/null 2>"$WORK/expectfail.$n.err" || rc=$?
  echo "$rc" >"$WORK/expectfail.$n.rc"
done

python3 -I "$DIR/assert_clock.py" "$FARM" "$WORK"
