#!/usr/bin/env bash
# Usage:
#   bash check-nixos-sddm-pixie-readability.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-sddm-pixie-readability.nix"

BOLD='\033[1m'; RED='\033[0;31m'; NC='\033[0m'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== sddm-pixie readability (light/dark base16 x white/black/grey wallpaper, built and inspected) ===${NC}"

if ! nix eval --json --impure --file "$SCEN" --apply 'x: { inherit (x) matrix tools; }' >"$WORK/meta.json" 2>"$WORK/err"; then
  cat "$WORK/err" >&2
  echo -e "${RED}EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')${NC}"
  exit 1
fi

mapfile -t IDS < <(python3 -I -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1]))["matrix"])))' "$WORK/meta.json")
ATTRS=(); for id in "${IDS[@]}"; do ATTRS+=("pkg.$id"); done

if ! nix build --impure --file "$SCEN" --no-link --json --keep-going "${ATTRS[@]}" >"$WORK/build.all.json" 2>"$WORK/build.err"; then
  rm -f "$WORK/build.all.json"
  for id in "${IDS[@]}"; do
    nix build --impure --file "$SCEN" --no-link --json "pkg.$id" >"$WORK/build.$id.json" 2>"$WORK/err.$id" || rm -f "$WORK/build.$id.json"
    [[ -s "$WORK/err.$id" ]] && grep -q 'error' "$WORK/err.$id" || rm -f "$WORK/err.$id"
  done
fi

python3 -I -c 'import json,sys; [print(k, v["drvPath"]) for k, v in json.load(open(sys.argv[1]))["matrix"].items()]' "$WORK/meta.json" >"$WORK/drvs"
while read -r id drv; do
  command nix log "$drv" >"$WORK/log.$id" 2>/dev/null || rm -f "$WORK/log.$id"
done <"$WORK/drvs"

python3 -I "$DIR/assert_output.py" "$WORK/meta.json" "$WORK"
