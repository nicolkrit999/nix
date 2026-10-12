#!/usr/bin/env bash
# Usage:
#   bash check-common-npu-npm.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
SCENARIO="$DIR/01-scenario-npm-activation.nix"
SHELLS="$REPO_ROOT/modules/common/programs/shells"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

record() {
  local label="$1" ok="$2" detail="${3:-}"
  printf "  %-62s " "$label"
  if [[ "$ok" == "1" ]]; then
    printf "${GREEN}PASS${NC}\n"
    ((PASS++)) || true
  else
    printf "${RED}FAIL${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|CHECK FAILED|$detail")
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== npu.py URL normalisation + npm activation parsing ===${NC}"
echo ""

echo -e "${BOLD}npu.py (python3 -I, requests stubbed, no network)${NC}"
npu_rc=0
npu_out=$(python3 -I "$DIR/02-npu-table.py" "$SHELLS/npu.py" "$SHELLS/shell-aliases.nix" 2>&1) || npu_rc=$?
npu_rows=0
while IFS=$'\t' read -r status name detail; do
  [[ "$status" == "PASS" || "$status" == "FAIL" ]] || continue
  ((npu_rows++)) || true
  record "$name" "$([[ "$status" == "PASS" ]] && echo 1 || echo 0)" "$detail"
done <<<"$npu_out"
if [[ "$npu_rows" -eq 0 || ( "$npu_rc" -ne 0 && "$FAIL" -eq 0 ) ]]; then
  record "npu table ran" 0 "$(echo "$npu_out" | tail -3 | tr '\n' '~')"
fi
echo ""

echo -e "${BOLD}npm.nix activation (template-host-minimal, eval only)${NC}"
stderr_file="$WORK/nix-stderr"
rc=0
FLAKE_ROOT="$REPO_ROOT" nix eval --json --impure --file "$SCENARIO" >"$WORK/scenario.json" 2>"$stderr_file" || rc=$?
if [[ "$rc" -ne 0 ]]; then
  record "npm scenario evaluates" 0 "$(grep -E "error:|missing|undefined variable" "$stderr_file" | head -3 | tr '\n' '~' || true)"
elif [[ "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["skip"])' "$WORK/scenario.json")" == "True" ]]; then
  echo -e "  ${DIM}nixosConfigurations hidden on this platform: npm checks skipped${NC}"
else
  python3 - "$WORK" <<'EOF'
import json, sys
work = sys.argv[1]
d = json.load(open(f"{work}/scenario.json"))
open(f"{work}/activation.sh", "w").write(d["activation"])
open(f"{work}/packages.txt", "w").write(" ".join(d["packages"]))
open(f"{work}/empty.txt", "w").write(str(d["emptyHasActivation"]))
lines = d["activation"].splitlines()
start = next((i for i, l in enumerate(lines) if l.strip() == 'case "$pkg" in'), None)
end = next((i for i, l in enumerate(lines) if start is not None and i > start and l.strip() == "esac"), None)
open(f"{work}/case.sh", "w").write("" if start is None or end is None else "\n".join(lines[start:end + 1]))
EOF
  PKGS=$(cat "$WORK/packages.txt")
  EXPECTED_NAMES="@scope/pkg plain-name bare @scope/other"

  record "npm packages = [] adds no activation entry" \
    "$([[ "$(cat "$WORK/empty.txt")" == "False" ]] && echo 1 || echo 0)" "npmGlobalPackages present with an empty list"

  record "activation loops over the configured packages" \
    "$(sed 's/^[[:space:]]*//' "$WORK/activation.sh" | grep -qxF "for pkg in $PKGS; do" && echo 1 || echo 0)" "no 'for pkg in $PKGS; do' line"

  names=""
  if [[ -s "$WORK/case.sh" ]]; then
    names=$(bash -c "set -eu; for pkg in $PKGS; do $(cat "$WORK/case.sh")
      printf '%s ' \"\$name\"; done" 2>&1) || true
  fi
  record "case block parses @scope/pkg@ver and name@ver" \
    "$([[ "${names% }" == "$EXPECTED_NAMES" ]] && echo 1 || echo 0)" "got '${names% }', expected '$EXPECTED_NAMES'"

  activate() {
    : >"$WORK/run.log"
    HOME="$WORK/home" XDG_STATE_HOME="$WORK/state" RUNLOG="$WORK/run.log" bash -c '
      set -eu -o pipefail
      unset DRY_RUN
      run() { printf "%s\n" "$*" >>"$RUNLOG"; }
      source "$1"' _ "$WORK/activation.sh" >/dev/null 2>&1
  }
  mkmods() {
    rm -rf "$WORK/home/.npm-global"
    for n in "$@"; do mkdir -p "$WORK/home/.npm-global/lib/node_modules/$n"; done
  }
  installs() { grep -c "npm install -g $PKGS\$" "$WORK/run.log" || true; }
  stamp="$WORK/state/npm-global-packages.stamp"

  rm -rf "${WORK:?}/home" "${WORK:?}/state"; mkdir -p "$WORK/home"
  activate
  record "fresh home: installs every package once, writes stamp" \
    "$([[ "$(installs)" == "1" && -s "$stamp" ]] && echo 1 || echo 0)" "run.log: $(tr '\n' '~' <"$WORK/run.log")"

  read -ra expected_arr <<<"$EXPECTED_NAMES"
  mkmods "${expected_arr[@]}"
  activate
  record "stamp current + parsed module dirs present: no install" \
    "$([[ ! -s "$WORK/run.log" ]] && echo 1 || echo 0)" "run.log: $(tr '\n' '~' <"$WORK/run.log")"

  mkmods plain-name bare @scope/other
  activate
  record "scoped module dir missing: reinstalls" \
    "$([[ "$(installs)" == "1" ]] && echo 1 || echo 0)" "run.log: $(tr '\n' '~' <"$WORK/run.log")"

  read -ra literal_arr <<<"$PKGS"
  mkmods "${literal_arr[@]}"
  activate
  record "dirs named with @version only: reinstalls" \
    "$([[ "$(installs)" == "1" ]] && echo 1 || echo 0)" "run.log: $(tr '\n' '~' <"$WORK/run.log")"

  mkmods "${expected_arr[@]}"
  printf 'stale' >"$stamp"
  activate
  record "stale stamp with dirs present: reinstalls" \
    "$([[ "$(installs)" == "1" ]] && echo 1 || echo 0)" "run.log: $(tr '\n' '~' <"$WORK/run.log")"
fi
echo ""

echo -e "${DIM}----------------------------------------------------------------------${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
echo ""
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label kind err <<< "$entry"
  echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}-> $kind${NC}"
  if [[ -n "$err" ]]; then
    echo "$err" | tr '~' '\n' | while IFS= read -r line; do
      [[ -n "$line" ]] && echo -e "      ${DIM}$line${NC}" || true
    done
  fi
done
echo ""
exit 1
