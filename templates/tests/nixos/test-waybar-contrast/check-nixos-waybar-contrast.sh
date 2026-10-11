#!/usr/bin/env bash
# Usage:
#   bash check-nixos-waybar-contrast.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"

BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== Waybar contrast (4 extreme schemes x hyprland/niri/mango, plus mocha control and flat edge scenario) ===${NC}"

if ! nix eval --json --impure --file "$DIR/01-scenario-waybar-contrast.nix" >"$WORK/schemes.json" 2>"$WORK/err"; then
  cat "$WORK/err" >&2
  echo -e "${RED}EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')${NC}"
  exit 1
fi

python3 -I "$DIR/contrast.py" "$WORK/schemes.json"
