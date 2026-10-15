#!/usr/bin/env bash
# School specialisation checks on the real nixos-desktop and nixos-laptop, eval only.
#
# Usage:
#   bash check-nixos-spec-school.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-spec-school.nix"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for h in "${HOSTS[@]}"; do
  (
    export HOST=$h
    nix eval --raw --impure --file "$SCENARIO" report >"$WORK/$h.report" 2>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" scripts >"$WORK/$h.scripts" 2>>"$WORK/$h.err" &&
      nix eval --raw --impure --file "$SCENARIO" drvs >"$WORK/$h.drvs" 2>>"$WORK/$h.err"
    echo $? >"$WORK/$h.rc"
  ) &
done
wait

stub_run_setup() {
  local h=$1 rc kind argc b64 text d setup bad=0 n=0 found=0
  d="$WORK/$h.stub"
  setup="$WORK/$h.d/school-distrobox-setup"
  mkdir -p "$d/home"
  cat >"$d/stubs.sh" <<'STUBS'
distrobox_stub() {
  local sub=$1
  shift
  case $sub in
    create) touch "$STUB_DIR/c.$2" ;;
    enter)
      printf 'enter %s %s\n' "$#" "$(printf %s "${!#}" | base64 -w0)" >>"$STUB_DIR/log"
      case ${!#} in "command -v"* | "test -x"*) return 1 ;; esac
      ;;
  esac
  return 0
}
podman_stub() {
  case $1 in
    container) [ -e "$STUB_DIR/c.$3" ] ;;
    exec) printf 'exec %s %s\n' "$#" "$(printf %s "${!#}" | base64 -w0)" >>"$STUB_DIR/log" ;;
  esac
}
STUBS
  sed -E 's#/nix/store/[a-z0-9]+-(distrobox|podman)[^/ ]*/bin/(distrobox|podman)#\2_stub#g' "$setup" >"$d/setup.sh"
  printf "  %-70s " "setup script: no distrobox/podman store path left after stubbing"
  : >"$d/log"
  if grep -qE 'bin/(distrobox|podman)' "$d/setup.sh"; then
    fail "$h: stub substitution" "a real distrobox/podman path remains"
    rc=99
  else
    pass
    STUB_DIR="$d" HOME="$d/home" bash -c 'source "$1"; source "$2"' _ "$d/stubs.sh" "$d/setup.sh" >"$d/out" 2>&1
    rc=$?
  fi
  printf "  %-70s " "setup script stub-run exits 0 and provisions both containers"
  if [[ $rc -eq 0 && -e $d/c.school-ubuntu && -e $d/c.school-arch ]]; then pass; else fail "$h: setup stub-run" "rc=$rc; $(tail -3 "$d/out" | tr '\n' ' ')"; fi
  while read -r kind argc b64; do
    n=$((n + 1))
    text=$(printf %s "$b64" | base64 -d)
    if [[ $kind == enter && $argc -ne 5 ]] || [[ $kind == exec && $argc -ne 7 ]]; then bad=$((bad + 1)); fi
    if [[ $text == *"sed -i"* && $text == *"grep -q 'SetJavaHome'"* && $argc -eq 5 ]]; then found=1; fi
  done <"$d/log"
  printf "  %-70s " "every distrobox enter/podman exec command is exactly one argument"
  if [[ $n -ge 7 && $bad -eq 0 ]]; then pass; else fail "$h: argument counts" "$bad of $n invocations have a wrong argument count"; fi
  printf "  %-70s " "sqldeveloper postInstall (sed + grep) is ONE container argument"
  if [[ $found -eq 1 ]]; then pass; else fail "$h: postInstall quoting" "no single-argument invocation holds both the sed and the grep line"; fi
}

syntax_check() {
  local h=$1 name=$2 file=$3 out
  printf "  %-70s " "bash -n $name"
  if out=$(bash -n "$file" 2>&1); then pass; else fail "$h: bash -n $name" "$out"; fi
}

echo ""
echo -e "${BOLD}=== school specialisation ===${NC}"

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  if [[ $(cat "$WORK/$h.rc") -ne 0 ]]; then
    printf "  %-70s " "evaluate $h"
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r label result; do
    [[ -z $label ]] && continue
    printf "  %-70s " "$label"
    if [[ $result == ok ]]; then pass; else fail "$h: $label" "$result"; fi
  done <"$WORK/$h.report"

  mkdir -p "$WORK/$h.d"
  jq -r 'to_entries[] | "\(.key)\t\(.value | @base64)"' "$WORK/$h.scripts" |
    while IFS=$'\t' read -r name b64; do printf '%s' "$b64" | base64 -d >"$WORK/$h.d/$name"; done
  for f in "$WORK/$h.d"/*; do syntax_check "$h" "$(basename "$f")" "$f"; done

  for kind in startup deep; do
    for drv in $(jq -r ".$kind[]" "$WORK/$h.drvs"); do
      n=$(basename "$drv" .drv)
      nix derivation show "$drv" | jq -r '.derivations | to_entries[0].value.structuredAttrs.text' >"$WORK/$h.d/$n"
      syntax_check "$h" "$n (generated)" "$WORK/$h.d/$n"
      printf "  %-70s " "$n names both containers"
      if grep -q '"school-ubuntu"' "$WORK/$h.d/$n" && grep -q '"school-arch"' "$WORK/$h.d/$n"; then pass
      else fail "$h: $n containers" "school-ubuntu or school-arch missing"; fi
    done
    printf "  %-70s " "$kind check derivation found"
    if [[ $(jq ".$kind | length" "$WORK/$h.drvs") -ge 1 ]]; then pass; else fail "$h: $kind drv" "no derivation in string context"; fi
  done

  stub_run_setup "$h"
done

printf "\n  %-70s " "control: an unquoted multi-word command splits into several arguments"
set -f
# shellcheck disable=SC2089 # deliberate: the control proves unquoted expansion word-splits under set -f
text="sudo sed -i 's|a|b|' f && echo x"
# shellcheck disable=SC2090 # same deliberate unquoted expansion
set -- enter c -- bash -c $text
set +f
if [[ $# -gt 5 ]]; then pass; else fail "control word splitting" "unquoted text stayed one argument"; fi
printf "  %-70s " "control: bash -n rejects a broken script"
echo 'if then' >"$WORK/broken.sh"
if bash -n "$WORK/broken.sh" 2>/dev/null; then fail "control bash -n" "broken script accepted"; else pass; fi

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
