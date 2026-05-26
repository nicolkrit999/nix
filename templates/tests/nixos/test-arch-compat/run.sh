#!/usr/bin/env bash
# aarch64-linux architecture compatibility checker.
# Evaluates the full home.activationPackage closure for each module batch on
# aarch64-linux via `nix build --dry-run`. Any package (or transitive dep) that
# lacks aarch64 support throws at eval time and is reported here.
#
# Usage:
#   bash run.sh          # run all batches
#   bash run.sh --fast   # skip specialisation batches

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

FAST=0
[[ "${1:-}" == "--fast" ]] && FAST=1

# ── test matrix ──────────────────────────────────────────────────────────────
# Format: "scenario_file|attr_name|display_label"
TESTS=(
  "scenario-auto-cpufreq-sddm-astronaut.nix|all-modules-auto-cpufreq-sddm-astronaut|base (auto-cpufreq + sddm-astronaut)"
  "scenario-tlp-sddm-pixie.nix|all-modules-tlp-sddm-pixie|base (tlp + sddm-pixie)"
)

if [[ $FAST -eq 0 ]]; then
  TESTS+=(
    "scenario-auto-cpufreq-sddm-astronaut.nix|specialisation-deep-focus-auto-cpufreq|specialisation: deep-focus (auto-cpufreq)"
    "scenario-auto-cpufreq-sddm-astronaut.nix|specialisation-guest-auto-cpufreq|specialisation: guest (auto-cpufreq)"
    "scenario-auto-cpufreq-sddm-astronaut.nix|specialisation-safe-mode-auto-cpufreq|specialisation: safe-mode (auto-cpufreq)"
    "scenario-auto-cpufreq-sddm-astronaut.nix|specialisation-secure-travel-auto-cpufreq|specialisation: secure-travel (auto-cpufreq)"
    "scenario-tlp-sddm-pixie.nix|specialisation-deep-focus-tlp|specialisation: deep-focus (tlp)"
    "scenario-tlp-sddm-pixie.nix|specialisation-guest-tlp|specialisation: guest (tlp)"
    "scenario-tlp-sddm-pixie.nix|specialisation-safe-mode-tlp|specialisation: safe-mode (tlp)"
    "scenario-tlp-sddm-pixie.nix|specialisation-secure-travel-tlp|specialisation: secure-travel (tlp)"
  )
fi

# ── helpers ───────────────────────────────────────────────────────────────────
PASS=0
FAIL=0
declare -a FAILURES=()

classify_error() {
  local err="$1"
  # Known flake-input module names — error here = direct module issue.
  # Uses --show-trace output so derivation names like 'caelestia-shell-1.0.0' are visible.
  local flake_modules=("noctalia-shell" "caelestia-shell" "claude-desktop" "vicinae" "antigravity-nix" "nix-doom-emacs")
  for m in "${flake_modules[@]}"; do
    if echo "$err" | grep -q "$m"; then
      echo "DIRECT MODULE ($m)"
      return
    fi
  done
  # Nix uses Unicode smart-quotes in error messages — match any single-char quote boundary.
  local pkg
  pkg=$(echo "$err" | grep -oP "Package .([a-zA-Z0-9._+-]+). in" | grep -oP "[a-zA-Z0-9._+-]+(?=. in)" | head -1 || true)
  if [[ -n "$pkg" ]]; then
    echo "TRANSITIVE DEP ($pkg)"
    return
  fi
  pkg=$(echo "$err" | grep -oP "attribute .[^.'''\'']+. missing" | grep -oP "(?<=attribute .).*(?=. missing)" | head -1 || true)
  if [[ -n "$pkg" ]]; then
    echo "MISSING ATTR ($pkg)"
    return
  fi
  echo "UNKNOWN"
}

run_check() {
  local file="$1" attr="$2" label="$3"
  printf "  %-55s " "$label"
  local err
  # --show-trace makes module names visible in traces (needed for DIRECT MODULE classification).
  if err=$(nix build --dry-run --no-link --impure --show-trace --file "$DIR/$file" "$attr" 2>&1); then
    printf "${GREEN}✓ ok${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"
    ((FAIL++)) || true
    local kind
    kind=$(classify_error "$err")
    # Pre-filter to 3 key lines; encode newlines as ~ to survive array storage.
    local excerpt
    excerpt=$(echo "$err" \
      | grep -v "^[[:space:]]*…" \
      | grep -E "error:|missing|not available|not supported|Package" \
      | grep -v "^$" \
      | head -3 \
      | tr '\n' '~')
    FAILURES+=("$label|$kind|$excerpt")
  fi
}

# ── run ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=== aarch64-linux compatibility check ===${NC}"
echo -e "${DIM}Evaluating full derivation closure for each batch — no builds happen.${NC}"
echo ""

for entry in "${TESTS[@]}"; do
  IFS="|" read -r file attr label <<< "$entry"
  run_check "$file" "$attr" "$label"
done

# ── summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS batches passed — no aarch64 incompatibilities found.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
echo ""

for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label kind err <<< "$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}→ $kind${NC}"
  echo "$err" | tr '~' '\n' | while IFS= read -r line; do
    [[ -n "$line" ]] && echo -e "      ${DIM}$line${NC}" || true
  done
  echo ""
done

echo -e "${DIM}Tip: a DIRECT MODULE failure means the flake input has no aarch64-linux output."
echo -e "     A TRANSITIVE DEP failure means a dependency of a module is x86-only.${NC}"
echo ""
exit 1
