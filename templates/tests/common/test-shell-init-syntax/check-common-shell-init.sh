#!/usr/bin/env bash
# Usage:
#   bash check-common-shell-init.sh

set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-shell-init.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

record() {
  local label="$1" ok="$2" detail="${3:-}"
  printf "  %-66s " "$label"
  if [[ "$ok" == 1 ]]; then
    printf "${GREEN}PASS${NC}\n"; ((PASS++)) || true
  else
    printf "${RED}FAIL${NC}\n"; ((FAIL++)) || true
    FAILURES+=("$label|$detail")
  fi
}

nixeval() { FLAKE_ROOT="$REPO_ROOT" nix eval --impure --json --file "$SCENARIO" "$@"; }

pkgbin() {
  nix build --no-link --print-out-paths --impure --expr \
    "(builtins.getFlake \"path:$REPO_ROOT\").inputs.nixpkgs.legacyPackages.x86_64-linux.$1.out" | head -1
}

echo ""
echo -e "${BOLD}=== Shell init syntax + one-shell gating ===${NC}"
echo ""

BASH_BIN="$(command -v bash)"
ZSH_BIN="$(pkgbin zsh)/bin/zsh"
FISH_BIN="$(pkgbin fish)/bin/fish"

mapfile -t NAMES < <(nixeval names | jq -r '.[]')

for v in "${NAMES[@]}"; do
  echo -e "${BOLD}$v${NC}"
  out="$WORK/$v.json"
  if ! nixeval "variant.$v" >"$out" 2>"$WORK/$v.err"; then
    record "$v: evaluation" 0 "$(grep -E 'error:' "$WORK/$v.err" | head -3 | tr '\n' '~')"
    continue
  fi

  while IFS=$'\t' read -r name result; do
    if [[ "$result" == "ok" ]]; then record "$v: $name" 1; else record "$v: $name" 0 "$result"; fi
  done < <(jq -r '.checks | to_entries[] | [.key, .value] | @tsv' "$out")

  dir="$WORK/$v"; mkdir -p "$dir"
  while IFS= read -r key; do
    jq -r --arg k "$key" '.files[$k]' "$out" >"$dir/$key"
    case "$key" in
      bash) bin=("$BASH_BIN" -n) ;;
      zsh | sys-zsh) bin=("$ZSH_BIN" -n) ;;
      fish | fishfn-*) bin=("$FISH_BIN" --no-execute) ;;
    esac
    if err=$("${bin[@]}" "$dir/$key" 2>&1); then
      record "$v: syntax $key" 1
    else
      record "$v: syntax $key" 0 "$(echo "$err" | head -3 | tr '\n' '~')"
    fi
  done < <(jq -r '.files | keys[]' "$out")

  while IFS= read -r key; do
    jq -r --arg k "$key" '.shAliases[$k]' "$out" >"$dir/alias-$key"
    if err=$("$BASH_BIN" -n "$dir/alias-$key" 2>&1); then
      record "$v: syntax alias $key (sh -c)" 1
    else
      record "$v: syntax alias $key (sh -c)" 0 "$(echo "$err" | head -3 | tr '\n' '~')"
    fi
  done < <(jq -r '.shAliases | keys[]' "$out")
  echo ""
done

echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo "$detail" | tr '~' '\n' | while IFS= read -r l; do [[ -n "$l" ]] && echo -e "      ${DIM}$l${NC}" || true; done
done
exit 1
