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
MIN_CHECKS=437

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
  mkdir -p "$FT/home"
  ff() { env -u KITTY_WINDOW_ID -u TMUX -u TERM_PROGRAM -u XDG_CONFIG_HOME -u XDG_CACHE_HOME HOME="$FT/home" TERM=dumb "$@" bash "$FT/wrapper" a b 2>&1; }
  mkcfg() { mkdir -p "$FT/home/.config/fastfetch"; printf '// comment\n{\n  // another\n  "logo": { "source": "%s", "width": 10, "height": 5 }\n}\n' "$1" > "$FT/home/.config/fastfetch/config.jsonc"; }
  echo iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg== | base64 -d > "$FT/home/logo.png"
  echo "not an image" > "$FT/home/notimg.png"
  CACHE="$FT/home/.cache/ryoku"
  nfiles() { ls "$CACHE" 2>/dev/null | wc -l; }
  eqs() { [ "$1" = "$2" ]; }

  rt_check "fastfetch wrapper: the stub replaced the real path (control)" grep -q "^real=$FT/stub\$" "$FT/wrapper"
  rt_check "fastfetch wrapper: kitty window without tmux keeps the logo, args passed through" eqs "$(ff KITTY_WINDOW_ID=1)" 'a b'
  mkcfg '~/logo.png'
  rt_check "fastfetch wrapper: kitty without tmux ignores a configured logo source and renders nothing (branch unchanged)" \
    bash -c "[ \"\$1\" = 'a b' ] && [ ! -e '$CACHE' ]" _ "$(ff KITTY_WINDOW_ID=1)"
  rt_check "fastfetch wrapper: TERM=xterm-ghostty without tmux keeps the logo" eqs "$(ff TERM=xterm-ghostty)" 'a b'
  rm -rf "$FT/home/.config"
  rt_check "fastfetch wrapper: kitty inside tmux without config gets --logo-type none, args passed through" eqs "$(ff KITTY_WINDOW_ID=1 TMUX=x)" '--logo-type none a b'
  rt_check "fastfetch wrapper: neither kitty nor ghostty without config gets --logo-type none, args passed through" eqs "$(ff)" '--logo-type none a b'
  rt_check "fastfetch wrapper: ghostty inside tmux without config gets --logo-type none" eqs "$(ff TERM=xterm-ghostty TMUX=x)" '--logo-type none a b'

  mkcfg '~/logo.png'
  out1=$(ff TMUX=x)
  rt_check "fastfetch wrapper: with a configured image the stub gets --logo <cache> --logo-type file-raw and the extra args" \
    bash -c '[[ "$1" =~ ^--logo\ '"$FT"'/home/.cache/ryoku/fastfetch-logo-[0-9a-f]{16}\.txt\ --logo-type\ file-raw\ a\ b$ ]]' _ "$out1"
  cache1=$(ls "$CACHE"/fastfetch-logo-*.txt 2>/dev/null | head -1)
  rt_check "fastfetch wrapper: the rendered cache file exists and is non-empty" test -s "$cache1"
  ino1=$(stat -c '%i %Y' "$cache1" 2>/dev/null); ff TMUX=x >/dev/null
  rt_check "fastfetch wrapper: a second run reuses the cache (same inode and mtime, one file)" \
    bash -c "[ \"\$(stat -c '%i %Y' '$cache1')\" = '$ino1' ] && [ \"\$(ls '$CACHE' | wc -l)\" = 1 ]"
  touch -d @1000000 "$FT/home/logo.png"; out2=$(ff TMUX=x)
  rt_check "fastfetch wrapper: a changed source renders a second cache file and the output names a different one" \
    bash -c '[ "$1" = 2 ] && [ "$2" != "$3" ] && [[ "$2" == "--logo "* ]]' _ "$(nfiles)" "$out2" "$out1"
  mkcfg '~/notimg.png'
  rt_check "fastfetch wrapper: a non-image source falls back to --logo-type none and leaves no temp file" \
    bash -c '[ "$1" = "--logo-type none a b" ] && [ "$2" = 2 ]' _ "$(ff TMUX=x)" "$(nfiles)"
  mkcfg '~/missing.png'
  rt_check "fastfetch wrapper: a missing source falls back to --logo-type none" eqs "$(ff TMUX=x)" '--logo-type none a b'

  mkcfgt() { mkdir -p "$FT/home/.config/fastfetch"; printf '{ "logo": { "type": "%s", "source": "%s" } }\n' "$1" "$2" > "$FT/home/.config/fastfetch/config.jsonc"; }
  rm -rf "$CACHE"
  mkcfgt builtin '~/logo.png'
  rt_check "fastfetch wrapper: a builtin logo type is passed to the real script untouched (exactly the args, no cache)" \
    bash -c "[ \"\$1\" = 'a b' ] && [ ! -e '$CACHE' ]" _ "$(ff TMUX=x)"
  mkcfgt file '~/logo.png'
  rt_check "fastfetch wrapper: a text file logo type (outside the image types) is passed untouched even with a readable source" eqs "$(ff TMUX=x)" 'a b'
  mkcfgt none ''
  rt_check "fastfetch wrapper: logo type none is passed untouched" eqs "$(ff TMUX=x)" 'a b'
  mkcfgt auto ''
  rt_check "fastfetch wrapper: auto without a source is the builtin logo and is passed untouched" eqs "$(ff TMUX=x)" 'a b'
  mkcfgt kitty-direct '~/logo.png'
  rt_check "fastfetch wrapper: an explicit image type with a source takes the sprite fallback (tmux display-message fails here)" \
    bash -c '[[ "$1" =~ ^--logo\ .*fastfetch-logo-[0-9a-f]{16}\.txt\ --logo-type\ file-raw\ a\ b$ ]]' _ "$(ff TMUX=x)"
  rt_check "fastfetch wrapper: the image sprite is a flattened render (cache file non-empty)" bash -c "[ -n \"\$(find '$CACHE' -name 'fastfetch-logo-*.txt' -size +0)\" ]"

  PERL=$(grep -o '/nix/store/[a-z0-9]*-perl-[^/ ]*/bin/perl -e' "$FW" | head -1 | sed 's/ -e$//')
  PROG=$(sed -n "/perl -e '\$/,/^ *' \"\$rows\"/p" "$FW" | sed '1d;$d')
  printf 'AAA\nBBB\nCCC\nDDD\n' > "$FT/rows"
  merge() { printf "$2" | "$PERL" -e "$1" "$FT/rows" 1 3 1 3; }
  SHORT='hdr\nos\033[7Gvalue\nkernel\033[7Gvalue2\n'
  LONG='hdr\nos\033[7Gvalue\nkernel-version-long\033[7Gvalue2\n'
  ESC=$(printf '\033')
  rt_check "fastfetch merge: the perl program and the nix perl were extracted from the wrapper" bash -c '[ -x "$1" ] && [[ "$2" == *"my (\$rf, \$lp, \$rp, \$tp, \$w) = @ARGV;"* ]]' _ "$PERL" "$PROG"
  out=$(merge "$PROG" "$SHORT")
  rt_check "fastfetch merge: short labels, the header has no ESC[..G and gets the blank logo prefix plus 8 spaces (vc = 7 + 1)" eqs "$(printf '%s\n' "$out" | sed -n 1p)" "               hdr"
  rt_check "fastfetch merge: short labels, ESC[7G becomes ESC[16G (7 + max(6,7) + 2) on the os line after the image row" eqs "$(printf '%s\n' "$out" | sed -n 2p)" " AAA   os${ESC}[16Gvalue"
  rt_check "fastfetch merge: short labels, the kernel line gets ESC[16G too" eqs "$(printf '%s\n' "$out" | sed -n 3p)" " BBB   kernel${ESC}[16Gvalue2"
  rt_check "fastfetch merge: the remaining image rows are appended with the left padding only" eqs "$(printf '%s\n' "$out" | sed -n 4,5p | tr '\n' '|')" " CCC| DDD|"
  out=$(merge "$PROG" "$LONG")
  rt_check "fastfetch merge: a 19-char label moves the header prefix to 7 + 20 spaces" eqs "$(printf '%s\n' "$out" | sed -n 1p)" "$(printf '%27shdr' '')"
  rt_check "fastfetch merge: a 19-char label gives ESC[28G (7 + 19 + 2) on the short os line" eqs "$(printf '%s\n' "$out" | sed -n 2p)" " AAA   os${ESC}[28Gvalue"
  rt_check "fastfetch merge: a 19-char label gives ESC[28G on its own line" eqs "$(printf '%s\n' "$out" | sed -n 3p)" " BBB   kernel-version-long${ESC}[28Gvalue2"
  rt_check "fastfetch merge control: without the substitution line ESC[7G stays unchanged" eqs "$(merge "$(printf '%s\n' "$PROG" | sed 's/{ s\/.*\/ge }/{ }/')" "$SHORT" | sed -n 2p)" " AAA   os${ESC}[7Gvalue"
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
