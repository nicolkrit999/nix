#!/usr/bin/env bash
# Usage:
#   bash check-nixos-ssh-trust-pins.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-ssh-trust-pins.nix"
HOSTS=(nixos-desktop nixos-laptop Krits-MacBook-Pro)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}PASS${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}FAIL${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if command -v ssh-keygen >/dev/null 2>&1; then
  keygen() { ssh-keygen "$@"; }
else
  keygen() { nix shell nixpkgs#openssh -c ssh-keygen "$@"; }
fi

type_label() {
  case "$1" in
    ssh-ed25519) echo ED25519 ;;
    ecdsa-sha2-nistp256) echo ECDSA ;;
    ssh-rsa) echo RSA ;;
    *) echo "?$1" ;;
  esac
}

for h in "${HOSTS[@]}"; do
  (
    for attr in report nixosPins hmKnownHosts allowedSigners; do
      HOST=$h nix eval --raw --impure --file "$SCENARIO" "$attr" >"$WORK/$h.$attr" 2>>"$WORK/$h.err" || { echo 1 >"$WORK/$h.rc"; exit 0; }
    done
    echo 0 >"$WORK/$h.rc"
  ) &
done
wait

echo ""
echo -e "${BOLD}=== SSH trust pins: known_hosts and Host aliases ===${NC}"
echo -e "${DIM}Keys are parsed with ssh-keygen -lf at test time; copies are compared against each other, never against published values.${NC}"

echo ""
echo -e "${BOLD}parser control${NC}"
printf "  %-70s " "ssh-keygen -lf rejects a truncated key (the key check can fail)"
for h in "${HOSTS[@]}"; do [[ -s "$WORK/$h.nixosPins" ]] && { src=$(head -n1 "$WORK/$h.nixosPins"); break; }; done
if [[ -n ${src:-} ]]; then
  set -- $src
  printf '%s %s %s\n' "$1" "$2" "${3:0:${#3}-12}" >"$WORK/trunc"
  if keygen -lf "$WORK/trunc" >/dev/null 2>&1; then fail "parser control" "truncated key was accepted by ssh-keygen"; else pass; fi
else
  fail "parser control" "no pinned key available to truncate"
fi

check_keys_file() {
  local label="$1" file="$2" want_fields="$3" bad="" n=0 line fp t k
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    n=$((n + 1))
    read -r -a f <<<"$line"
    if [[ ${#f[@]} -ne $want_fields ]]; then bad+="[$line: ${#f[@]} fields] "; continue; fi
    t="${f[$((want_fields - 2))]}"; k="${f[$((want_fields - 1))]}"
    printf '%s %s\n' "$t" "$k" >"$WORK/one"
    if ! fp=$(keygen -lf "$WORK/one" 2>&1); then bad+="[${f[0]} $t: ssh-keygen rejects] "; continue; fi
    if [[ $fp != *"($(type_label "$t"))"* ]]; then bad+="[${f[0]}: $t blob is not a $(type_label "$t") key: $fp] "; fi
  done <"$file"
  printf "  %-70s " "$label"
  if [[ $n -gt 0 && -z $bad ]]; then pass; else fail "$label" "${bad:-no lines to check}"; fi
}

fingerprints_equal() {
  local h="$1" bad="" name t k fp1 fp2 other
  while read -r name t k; do
    [[ -z $name ]] && continue
    printf '%s %s\n' "$t" "$k" >"$WORK/a"
    fp1=$(keygen -lf "$WORK/a" 2>&1 | awk '{print $2}')
    other=$(awk -v n="$name" -v t="$t" '$1==n && $2==t {print $3}' "$WORK/$h.hmKnownHosts" | head -n1)
    printf '%s %s\n' "$t" "$other" >"$WORK/b"
    fp2=$(keygen -lf "$WORK/b" 2>&1 | awk '{print $2}')
    if [[ -z $fp1 || $fp1 != "$fp2" ]]; then bad+="[$name $t: nixos=$fp1 hm=${fp2:-<absent>}] "; fi
  done <"$WORK/$h.nixosPins"
  printf "  %-70s " "ssh-keygen fingerprints: NixOS knownHosts == HM known_hosts"
  if [[ -z $bad ]]; then pass; else fail "$h: fingerprints" "$bad"; fi
}

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  if [[ $(cat "$WORK/$h.rc" 2>/dev/null) != 0 ]]; then
    printf "  %-70s " "evaluate $h"
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  while IFS=$'\t' read -r label result; do
    [[ -z $label ]] && continue
    printf "  %-70s " "$label"
    if [[ $result == ok ]]; then pass; else fail "$h: $label" "$result"; fi
  done <"$WORK/$h.report"

  check_keys_file "every NixOS-pinned key parses with ssh-keygen -lf, type matches blob" "$WORK/$h.nixosPins" 3
  if [[ -s "$WORK/$h.hmKnownHosts" ]]; then
    check_keys_file "every HM known_hosts line parses with ssh-keygen -lf, type matches blob" "$WORK/$h.hmKnownHosts" 3
    fingerprints_equal "$h"
    sed 's/^[^ ]* //' "$WORK/$h.allowedSigners" >"$WORK/signers"
    check_keys_file "allowed_signers key parses with ssh-keygen -lf, type matches blob" "$WORK/signers" 2
  fi
done

echo ""
echo -e "${DIM}----------------------------------------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}-> $detail${NC}"
done
exit 1
