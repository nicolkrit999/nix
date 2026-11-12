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
MIN_CHECKS=375

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
echo -e "${BOLD}=== private dotfiles sync runtime (real script, local bare origin, real git) ===${NC}"
PS_SCRIPT=$(nix eval --impure --raw --file "$FIXTURE" privateSyncScript 2>/dev/null) || PS_SCRIPT=""
if [[ -z "$PS_SCRIPT" ]]; then
  echo -e "  ${RED}✗ could not build the private sync script${NC}"
  ((FAIL++)) || true
  FAILURES+=("private sync runtime|could not realise privateSyncScript")
else
  PT=$(mktemp -d)
  trap 'rm -rf "$RT" "$PT"' EXIT
  ps_env() {
    export HOME="$PT/home" GIT_CONFIG_GLOBAL="$PT/gitconfig" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  }
  ps_fresh() {
    rm -rf "$PT"; mkdir -p "$PT/home/.ssh"; : > "$PT/gitconfig"; ps_env
    echo key > "$HOME/.ssh/id_github"
    git init -q --bare -b main "$PT/origin.git"
    git clone -q "$PT/origin.git" "$PT/seed" 2>/dev/null
    git -C "$PT/seed" checkout -q -b main 2>/dev/null
    echo 1 > "$PT/seed/f"; git -C "$PT/seed" add f; git -C "$PT/seed" commit -q -m one; git -C "$PT/seed" push -q origin main
    git clone -q "$PT/origin.git" "$HOME/dotfiles-private"
  }
  ps_upstream() { echo 2 > "$PT/seed/f"; git -C "$PT/seed" commit -q -am two; git -C "$PT/seed" push -q origin main; }
  ps_run() { "$PS_SCRIPT" >/dev/null 2>&1; RC=$?; }
  ps_head() { git -C "$HOME/dotfiles-private" rev-parse HEAD; }
  ps_up() { git -C "$PT/origin.git" rev-parse main; }

  ps_fresh; ps_upstream; ps_run
  rt_check "private sync: a clean checkout behind origin fast-forwards, rc 0" bash -c "[ $RC -eq 0 ] && [ '$(ps_head)' = '$(ps_up)' ]"

  ps_fresh; ps_upstream; rm -rf "$HOME/dotfiles-private"; git clone -q --depth 1 --single-branch --branch main "file://$PT/origin.git" "$HOME/dotfiles-private"; git -C "$HOME/dotfiles-private" config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'; ps_run
  rt_check "private sync: a shallow single-branch checkout is unshallowed, its refspec healed and it fast-forwards, rc 0" \
    bash -c "[ $RC -eq 0 ] && [ \"\$(git -C '$HOME/dotfiles-private' rev-parse --is-shallow-repository)\" = false ] && [ \"\$(git -C '$HOME/dotfiles-private' config remote.origin.fetch)\" = '+refs/heads/*:refs/remotes/origin/*' ] && [ '$(ps_head)' = '$(ps_up)' ]"

  ps_fresh; ps_upstream; before=$(ps_head); echo dirty >> "$HOME/dotfiles-private/f"; ps_run
  rt_check "private sync: a dirty work tree is not updated and keeps its edit, rc 0" \
    bash -c "[ $RC -eq 0 ] && [ '$(ps_head)' = '$before' ] && grep -q dirty '$HOME/dotfiles-private/f'"

  ps_fresh; ps_upstream; echo local > "$HOME/dotfiles-private/g"; git -C "$HOME/dotfiles-private" add g; git -C "$HOME/dotfiles-private" commit -q -m local; before=$(ps_head); ps_run
  rt_check "private sync: a checkout ahead of origin is not updated (commit kept), rc 0" \
    bash -c "[ $RC -eq 0 ] && [ '$(ps_head)' = '$before' ] && [ -f '$HOME/dotfiles-private/g' ]"

  ps_fresh; rm -f "$HOME/.ssh/id_github"; ps_upstream; before=$(ps_head); ps_run
  rt_check "private sync: without ~/.ssh/id_github the script fails with rc 1 and touches nothing" \
    bash -c "[ $RC -eq 1 ] && [ '$(ps_head)' = '$before' ]"

  ps_fresh; rm -rf "$HOME/dotfiles-private"; mkdir "$HOME/dotfiles-private"; echo keep > "$HOME/dotfiles-private/x"; ps_run
  rt_check "private sync: an existing non-git directory is left untouched, rc 1" \
    bash -c "[ $RC -eq 1 ] && [ \"\$(cat '$HOME/dotfiles-private/x')\" = keep ] && [ \"\$(ls -A '$HOME/dotfiles-private')\" = x ]"
fi

echo ""
echo -e "${BOLD}=== ryoku-fastfetch wrapper runtime (real script, stub as the real binary) ===${NC}"
FW=$(nix eval --impure --raw --file "$FIXTURE" fastfetchWrapper 2>/dev/null) || FW=""
if [[ -z "$FW" ]]; then
  echo -e "  ${RED}✗ could not build the wrapper${NC}"
  ((FAIL++)) || true
  FAILURES+=("fastfetch wrapper runtime|could not realise fastfetchWrapper")
else
  FT=$(mktemp -d)
  trap 'rm -rf "$RT" "$PT" "$FT"' EXIT
  printf '#!/bin/sh\necho "$*"\n' > "$FT/stub"; chmod +x "$FT/stub"
  sed "s|^real=.*|real=$FT/stub|" "$FW" > "$FT/wrapper"
  ff() { env -u KITTY_WINDOW_ID -u TMUX -u TERM_PROGRAM TERM=dumb "$@" bash "$FT/wrapper" a b 2>&1; }
  rt_check "fastfetch wrapper: the stub replaced the real path (control)" grep -q "^real=$FT/stub\$" "$FT/wrapper"
  rt_check "fastfetch wrapper: kitty window without tmux keeps the logo, args passed through" bash -c "[ \"$(ff KITTY_WINDOW_ID=1)\" = 'a b' ]"
  rt_check "fastfetch wrapper: kitty window inside tmux gets --logo-type none, args passed through" bash -c "[ \"$(ff KITTY_WINDOW_ID=1 TMUX=x)\" = '--logo-type none a b' ]"
  rt_check "fastfetch wrapper: neither kitty nor ghostty gets --logo-type none, args passed through" bash -c "[ \"$(ff)\" = '--logo-type none a b' ]"
  rt_check "fastfetch wrapper: TERM=xterm-ghostty without tmux keeps the logo, with tmux drops it" bash -c "[ \"$(ff TERM=xterm-ghostty)\" = 'a b' ] && [ \"$(ff TERM=xterm-ghostty TMUX=x)\" = '--logo-type none a b' ]"
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
