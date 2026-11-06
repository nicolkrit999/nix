#!/usr/bin/env bash
# Usage:
#   bash check-nixos-lanzaboote.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-lanzaboote.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ok() { printf "  %-100s ${GREEN}PASS${NC}\n" "$1"; PASS=$((PASS + 1)); }
bad() {
  printf "  %-100s ${RED}FAIL${NC}\n" "$1"; FAIL=$((FAIL + 1))
  FAILURES+=("$1|$2")
}
verdict() { if [[ "$1" == "yes" ]]; then ok "$2"; else bad "$2" "$3"; fi; }

echo ""
echo -e "${BOLD}=== services.lanzaboote: eval checks on the fixture host ===${NC}"
if ! json=$(nix eval --json --impure --file "$SCEN" checks 2>"$WORK/eval.err"); then
  bad "evaluation of the scenario" "$(grep -E 'error:' "$WORK/eval.err" | head -3 | tr '\n' ' ')"
  json='{}'
fi
while IFS=$'\t' read -r name result; do
  if [[ "$result" == "ok" ]]; then ok "$name"; else bad "$name" "$result"; fi
done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
[[ "$(jq 'length' <<<"$json")" -gt 0 ]] || bad "eval checks are non-empty" "no check was returned"

echo ""
echo -e "${BOLD}=== /etc/sbctl/sbctl.conf: the realised YAML file ===${NC}"
DEFAULT_BUNDLE=$(nix eval --raw --impure --file "$SCEN" bundles.default 2>/dev/null) || DEFAULT_BUNDLE=""
CUSTOM_BUNDLE=$(nix eval --raw --impure --file "$SCEN" bundles.custom 2>/dev/null) || CUSTOM_BUNDLE=""
build() { nix build --impure --file "$SCEN" --no-link --print-out-paths "etcSource.$1" 2>"$WORK/$1.err"; }

conf_ok() {
  local file="$1" bundle="$2" got want
  [[ -n "$bundle" && "$(sed -n 1p "$file")" == "%YAML 1.1" && "$(sed -n 2p "$file")" == "---" ]] || return 1
  got=$(tail -n +3 "$file" | sort)
  want=$(printf 'guid: %s\nkeydir: %s\n' "$bundle/GUID" "$bundle/keys")
  [[ "$got" == "$want" ]]
}

if [[ -z "$DEFAULT_BUNDLE" || -z "$CUSTOM_BUNDLE" || "$DEFAULT_BUNDLE" == "$CUSTOM_BUNDLE" ]]; then
  bad "bundle paths of the scenario" "default='$DEFAULT_BUNDLE' custom='$CUSTOM_BUNDLE' (both must be non-empty and different)"
elif DEFAULT_OUT=$(build default) && CUSTOM_OUT=$(build custom); then
  verdict "$(conf_ok "$DEFAULT_OUT" "$DEFAULT_BUNDLE" && echo yes || echo no)" \
    "default bundle: file is exactly the keydir and guid lines under the pkiBundle" "content: $(tr '\n' '|' <"$DEFAULT_OUT")"
  verdict "$(conf_ok "$CUSTOM_OUT" "$CUSTOM_BUNDLE" && echo yes || echo no)" \
    "custom bundle: file is exactly the keydir and guid lines under the custom pkiBundle" "content: $(tr '\n' '|' <"$CUSTOM_OUT")"
  verdict "$(conf_ok "$CUSTOM_OUT" "$DEFAULT_BUNDLE" && echo no || echo yes)" \
    "control(file): the custom file is rejected against the default bundle" "conf_ok accepted a file with the wrong bundle"
  verdict "$(conf_ok "$DEFAULT_OUT" "$CUSTOM_BUNDLE" && echo no || echo yes)" \
    "control(file): the default file is rejected against the custom bundle" "conf_ok accepted a file with the wrong bundle"
  printf '%%YAML 1.1\n---\nkeydir: %s/keys\nguid: %s/GUID\nextra: 1\n' "$DEFAULT_BUNDLE" "$DEFAULT_BUNDLE" >"$WORK/extra.conf"
  verdict "$(conf_ok "$WORK/extra.conf" "$DEFAULT_BUNDLE" && echo no || echo yes)" \
    "control(file): a file with a third key is rejected" "conf_ok accepted a file with an extra key"
  printf '%%YAML 1.1\n---\nkeydir: %s/keys2\nguid: %s/GUID\n' "$DEFAULT_BUNDLE" "$DEFAULT_BUNDLE" >"$WORK/keydir.conf"
  verdict "$(conf_ok "$WORK/keydir.conf" "$DEFAULT_BUNDLE" && echo no || echo yes)" \
    "control(file): a file with a wrong keydir is rejected" "conf_ok accepted a file with a wrong keydir"
  printf 'keydir: %s/keys\nguid: %s/GUID\n' "$DEFAULT_BUNDLE" "$DEFAULT_BUNDLE" >"$WORK/nohdr.conf"
  verdict "$(conf_ok "$WORK/nohdr.conf" "$DEFAULT_BUNDLE" && echo no || echo yes)" \
    "control(file): a file without the %YAML 1.1 / --- header is rejected" "conf_ok accepted a file without the header"
  printf '%%YAML 1.1\n---\nkeydir: "%s/keys"\nguid: %s/GUID\n' "$DEFAULT_BUNDLE" "$DEFAULT_BUNDLE" >"$WORK/quoted.conf"
  verdict "$(conf_ok "$WORK/quoted.conf" "$DEFAULT_BUNDLE" && echo no || echo yes)" \
    "control(file): a file with a quoted value is rejected (exact comparison)" "conf_ok accepted a quoted value"
else
  bad "build /etc/sbctl/sbctl.conf (remarshal)" "$(tail -3 "$WORK/default.err" "$WORK/custom.err" 2>/dev/null | tr '\n' ' ')"
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
done
exit 1
