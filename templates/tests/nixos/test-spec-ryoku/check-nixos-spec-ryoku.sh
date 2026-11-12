#!/usr/bin/env bash
# Ryoku specialisation checks: the real nixos-desktop and nixos-laptop (eval only), plus a
# from-scratch fixture with mutants.
#
# Usage:
#   bash check-nixos-spec-ryoku.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
REAL="$DIR/01-scenario-spec-ryoku-real.nix"
FIXTURE="$DIR/02-scenario-spec-ryoku-fixture.nix"
MIN_CHECKS=320

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

for tool in nix jq bash; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool"; exit 2; }
done

for host in nixos-desktop nixos-laptop fixture; do
  echo ""
  echo -e "${BOLD}=== $host ===${NC}"
  err=$(mktemp)
  scenario="$REAL"
  hostargs=(--argstr host "$host")
  if [[ "$host" == fixture ]]; then
    scenario="$FIXTURE"
    hostargs=()
  fi
  json=$(nix eval --impure --json --file "$scenario" "${hostargs[@]}" results 2>"$err") || {
    echo -e "  ${RED}✗ eval error${NC}"
    ((FAIL++)) || true
    FAILURES+=("$host evaluation|$(grep -E 'error:' "$err" | head -3 | tr '\n' '~')")
    rm -f "$err"
    continue
  }
  rm -f "$err"

  while IFS=$'\t' read -r label result; do
    printf "  %-100s " "${label:0:100}"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ ok${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ fail${NC}\n"
      ((FAIL++)) || true
      if [[ "$result" == "FAIL: eval error" ]]; then
        result="$result~$(CHECK_LABEL="$label" nix eval --impure --raw --file "$scenario" "${hostargs[@]}" --apply 'cs: builtins.deepSeq cs.${builtins.getEnv "CHECK_LABEL"} "x"' checks 2>&1 | grep -E 'error:' | head -3 | tr '\n' '~')"
      fi
      FAILURES+=("$host: $label|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
done

echo ""
echo -e "${BOLD}=== seed script runtime (real ryoku-settings-seed script, fixture settings) ===${NC}"
seed_err=$(mktemp)
scripts=$(nix eval --impure --json --file "$FIXTURE" seedScripts 2>"$seed_err") || {
  echo -e "  ${RED}✗ could not build the seed scripts${NC}"
  ((FAIL++)) || true
  FAILURES+=("seed script runtime|$(grep -E 'error:' "$seed_err" | head -3 | tr '\n' '~')")
  scripts=""
}
rm -f "$seed_err"

rt_check() {
  local label="$1"; shift
  printf "  %-100s " "${label:0:100}"
  if "$@"; then
    printf "${GREEN}✓ ok${NC}\n"; ((PASS++)) || true
  else
    printf "${RED}✗ fail${NC}\n"; ((FAIL++)) || true
    FAILURES+=("runtime: $label|check returned false")
  fi
}

if [[ -n "$scripts" ]]; then
  SA=$(jq -r .a <<<"$scripts"); SB=$(jq -r .b <<<"$scripts"); SE=$(jq -r .enforce <<<"$scripts")
  RT=$(mktemp -d)
  trap 'rm -rf "$RT"' EXIT
  fresh() {
    rm -rf "$RT/h"; mkdir -p "$RT/h"
    export HOME="$RT/h" XDG_CONFIG_HOME="$RT/h/c" XDG_STATE_HOME="$RT/h/s"
    CFG="$XDG_CONFIG_HOME/ryoku"; ST="$XDG_STATE_HOME/ryoku/nix"
  }
  run() { "$1" >/dev/null 2>&1; RC=$?; }
  jqe() { jq -e "$1" "$2" >/dev/null 2>&1; }
  sentinels() { ls "$ST" 2>/dev/null | grep -c '^settings-seeded-' || true; }
  sentinel_of() { ls "$ST" 2>/dev/null | grep "^settings-seeded-$1-" | head -1; }

  fresh; run "$SA"
  rt_check "fresh dirs: rc 0, theme/shell/desktop stores written with the declared values" \
    bash -c "[ $RC -eq 0 ]" 
  rt_check "fresh dirs: theme.json == the declaration" jqe '. == {"scheme":"mono"}' "$CFG/theme.json"
  rt_check "fresh dirs: shell and desktop carry the declared keys" bash -c "jq -e '.fontFamily==\"Test\" and .clipboard.pruneWeekly==true' '$CFG/shell.json' >/dev/null && jq -e '.desktop.appearance.gapsIn==6 and (.desktop.apps.terminal|type==\"string\")' '$CFG/desktop.json' >/dev/null"
  rt_check "fresh dirs: new files are 0644" bash -c "[ \"\$(stat -c %a '$CFG/theme.json')\" = 644 ]"
  rt_check "fresh dirs: exactly three sentinels named settings-seeded-<store>-<16 hex>" \
    bash -c "[ \"\$(ls '$ST' | grep -cE '^settings-seeded-(desktop|shell|theme)-[0-9a-f]{16}\$')\" = 3 ] && [ \"\$(ls '$ST' | wc -l)\" = 3 ]"

  before_theme=$(sentinel_of theme)
  jq '.scheme="hub" | .hubOnly=1' "$CFG/theme.json" > "$CFG/t.tmp" && mv "$CFG/t.tmp" "$CFG/theme.json"
  run "$SA"
  rt_check "seed-once: a second run is a no-op, the Hub edit of a declared key survives, rc 0" \
    bash -c "[ $RC -eq 0 ]" 
  rt_check "seed-once: scheme stays hub after the re-run" jqe '.scheme=="hub" and .hubOnly==1' "$CFG/theme.json"

  run "$SB"; rcb=$RC
  after_theme=$(sentinel_of theme)
  rt_check "changed declaration: re-applied (scheme light), rc 0" bash -c "[ $rcb -eq 0 ]"
  rt_check "changed declaration: the Hub-only key survives the merge" jqe '.scheme=="light" and .hubOnly==1' "$CFG/theme.json"
  rt_check "changed declaration: exactly one theme sentinel, a new one; the other sentinels are unchanged" \
    bash -c "[ -n '$before_theme' ] && [ -n '$after_theme' ] && [ '$before_theme' != '$after_theme' ] && [ \"\$(ls '$ST' | grep -c '^settings-seeded-theme-')\" = 1 ] && [ \"\$(ls '$ST' | wc -l)\" = 3 ]"

  fresh; run "$SE"
  jq '.desktop.appearance.gapsIn=99 | .hubOnly=2' "$CFG/desktop.json" > "$CFG/d.tmp" && mv "$CFG/d.tmp" "$CFG/desktop.json"
  run "$SE"
  rt_check "enforce: the declared key is re-applied on every run, a Hub-only key survives, no sentinel is written" \
    bash -c "jq -e '.desktop.appearance.gapsIn==6 and .hubOnly==2' '$CFG/desktop.json' >/dev/null && [ \"\$(ls '$ST' 2>/dev/null | wc -l)\" = 0 ]"

  fresh; mkdir -p "$CFG"; echo '{"a":1,"fontFamily":"Old"}' > "$CFG/shell.json"; chmod 640 "$CFG/shell.json"
  run "$SA"
  rt_check "existing store: the declared key wins, other keys stay, the file mode (0640) is kept" \
    bash -c "jq -e '.fontFamily==\"Test\" and .a==1' '$CFG/shell.json' >/dev/null && [ \"\$(stat -c %a '$CFG/shell.json')\" = 640 ]"

  fresh; mkdir -p "$CFG"; echo '{broken' > "$CFG/shell.json"; echo '[1]' > "$CFG/desktop.json"
  run "$SA"
  rt_check "invalid or non-object JSON: rc 1 and both files stay byte-identical" \
    bash -c "[ $RC -eq 1 ] && [ \"\$(cat '$CFG/shell.json')\" = '{broken' ] && [ \"\$(cat '$CFG/desktop.json')\" = '[1]' ]"
  rt_check "invalid JSON: the other stores are still seeded, no sentinel for the broken ones, no temp file left" \
    bash -c "jq -e '.scheme==\"mono\"' '$CFG/theme.json' >/dev/null && [ -z \"\$(ls '$ST' | grep -E 'settings-seeded-(shell|desktop)-')\" ] && [ -z \"\$(ls -A '$CFG' | grep '^\.tmp-seed')\" ]"
fi

echo ""
if [[ $((PASS + FAIL)) -lt $MIN_CHECKS ]]; then
  echo -e "${RED}${BOLD}Only $((PASS + FAIL)) checks ran (expected at least $MIN_CHECKS); refusing to pass.${NC}"
  exit 1
fi
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo "$detail" | tr '~' '\n' | while IFS= read -r line; do
    [[ -n "$line" ]] && echo -e "      ${DIM}${line}${NC}" || true
  done
done
exit 1
