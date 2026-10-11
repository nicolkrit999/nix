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

run_lazygit_build_check() {
  local label="lazygit theme builds: authorColors moved under gui.theme"
  printf "  %-62s " "$label"
  local stderr_file out up
  stderr_file=$(mktemp)
  if out=$(FLAKE_ROOT="$REPO_ROOT" nix build --impure --no-link --print-out-paths --file "$SCENARIO" lazygit-source-drv 2>"$stderr_file") &&
     up=$(FLAKE_ROOT="$REPO_ROOT" nix build --impure --no-link --print-out-paths --file "$SCENARIO" lazygit-upstream-drv 2>>"$stderr_file"); then
    local bad="" f n=0
    for f in "$out"/*/*.yml; do
      n=$((n + 1))
      if grep -q '^  authorColors' "$f"; then bad+="$f has top-level gui.authorColors~"; fi
      if grep -q '^  authorColors' "$up/${f#"$out"/}" && ! grep -q '^    authorColors' "$f"; then
        bad+="$f lost theme.authorColors~"
      fi
    done
    if [[ $n -eq 0 ]]; then bad="no theme yml files found~"; fi
    if [[ -z "$bad" ]]; then
      printf "${GREEN}PASS${NC}\n"
      ((PASS++)) || true
      if ! grep -rqs '^  authorColors' "$up"; then
        WARNINGS+=("$label|WARN: upstream catppuccin lazygit no longer uses gui.authorColors; workaround is removable (memory: project-lazygit-catppuccin-migrated-workaround)")
        ((WARN++)) || true
      fi
    else
      printf "${RED}FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$bad")
    fi
  else
    printf "${RED}FAIL${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|BUILD ERROR|$(tail -3 "$stderr_file" | tr '\n' '~')")
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
echo -e "${BOLD}claude-desktop (pipewire overlay)${NC}"
run_check "check-claude-desktop-has-pipewire"       "buildInputs contain pipewire"
run_check "warn-claude-desktop-overlay-redundant"   "upstream lacks pipewire (overlay needed)"

echo ""
echo -e "${BOLD}lazygit (catppuccin migrated theme)${NC}"
run_check "check-lazygit-migrated-source-nixos"   "nixos-desktop uses catppuccin-lazygit-migrated"
run_check "check-lazygit-migrated-source-darwin"  "darwin uses catppuccin-lazygit-migrated"
run_lazygit_build_check

echo ""
echo -e "${BOLD}openblas (i686 doCheck overlay)${NC}"
run_check "check-openblas-i686-docheck-disabled"          "pkgsi686Linux.openblas.doCheck == false"
run_check "check-openblas-x86_64-untouched"               "x86_64 openblas.doCheck == plain nixpkgs"
run_check "warn-openblas-i686-override-still-needed"      "plain nixpkgs i686 doCheck != false (overlay needed)"

echo ""
echo -e "${BOLD}school opencloud-desktop (QML import paths)${NC}"
run_check "check-school-opencloud-single"            "exactly one opencloud-desktop in school"
run_check "check-school-opencloud-qml-paths"         "kirigami, qqc2-desktop-style, qqc2-breeze-style paths"
run_check "check-school-opencloud-qml-prefix-form"   "three NIXPKGS_QT6_QML_IMPORT_PATH prefixes"

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
