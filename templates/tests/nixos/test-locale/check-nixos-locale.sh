#!/usr/bin/env bash
# Usage:
#   bash check-nixos-locale.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-locale.nix"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ok() { printf "  %-96s ${GREEN}PASS${NC}\n" "$1"; PASS=$((PASS + 1)); }
bad() {
  printf "  %-96s ${RED}FAIL${NC}\n" "$1"; FAIL=$((FAIL + 1))
  FAILURES+=("$1|$2")
}
verdict() { if [[ "$1" == "yes" ]]; then ok "$2"; else bad "$2" "$3"; fi; }
has_line() { printf '%s\n' "$2" | grep -qxF -- "$1" && echo yes || echo no; }

echo ""
echo -e "${BOLD}=== services.locale: eval checks ===${NC}"
if ! json=$(nix eval --json --impure --file "$SCEN" checks 2>"$WORK/eval.err"); then
  bad "evaluation of the scenario" "$(grep -E 'error:' "$WORK/eval.err" | head -3 | tr '\n' ' ')"
  json='{}'
fi
while IFS=$'\t' read -r name result; do
  if [[ "$result" == "ok" ]]; then ok "$name"; else bad "$name" "$result"; fi
done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
[[ "$(jq 'length' <<<"$json")" -gt 0 ]] || bad "eval checks are non-empty" "no check was returned"

echo ""
echo -e "${BOLD}=== bare-name spelling trap: real glibc-locales builds ===${NC}"
build() { nix build --impure --file "$SCEN" --no-link --print-out-paths --option log-lines 2000 "$1" 2>"$2"; }

TOOLS=""; HOST_OUT=""; US_OUT=""
if TOOLS=$(build tools "$WORK/tools.err"); then :; else bad "build locale-tools (glibc locale + coreutils date)" "$(tail -3 "$WORK/tools.err" | tr '\n' ' ')"; fi
if HOST_OUT=$(build locales.host "$WORK/host.err"); then ok "host values (en_IN bare, it_CH.UTF-8): i18n.glibcLocales builds"
else bad "host values (en_IN bare, it_CH.UTF-8): i18n.glibcLocales builds" "$(grep -m3 -E 'error|unsupported' "$WORK/host.err" | tr '\n' ' ')"; fi
if US_OUT=$(build locales.us "$WORK/us.err"); then ok "control archive (no values, en_US only): i18n.glibcLocales builds"
else bad "control archive (no values, en_US only): i18n.glibcLocales builds" "$(grep -m3 -E 'error|unsupported' "$WORK/us.err" | tr '\n' ' ')"; fi

if build locales.bad "$WORK/bad.err" >/dev/null; then
  bad "time = en_IN.UTF-8 fails the glibc-locales build" "the build SUCCEEDED: nixpkgs#256688 looks fixed, update the bare-name docs in services/locale.nix, the host comments and this test"
else
  if grep -qF 'unsupported locales detected' "$WORK/bad.err"; then
    ok "time = en_IN.UTF-8 fails the glibc-locales build with \"unsupported locales detected\""
    section=$(sed -n '/unsupported locales detected/,/You should choose/p' "$WORK/bad.err")
    verdict "$(grep -qF 'en_IN.UTF-8/UTF-8' <<<"$section" && echo yes || echo no)" \
      "the unsupported list names en_IN.UTF-8/UTF-8" "unsupported section: $(tr '\n' ' ' <<<"$section" | cut -c1-200)"
    verdict "$(grep -qF -- 'en_IN/UTF-8 \' "$WORK/bad.err" && echo yes || echo no)" \
      "glibc's own SUPPORTED list spells it en_IN/UTF-8" "the printed supported list lacks 'en_IN/UTF-8 \\'"
  else
    bad "time = en_IN.UTF-8 fails the glibc-locales build with \"unsupported locales detected\"" "failed for another reason: $(grep -m3 -E 'error' "$WORK/bad.err" | tr '\n' ' ')"
  fi
fi

echo ""
echo -e "${BOLD}=== runtime evidence from the built archives (env -i, TZ=UTC) ===${NC}"
if [[ -n "$TOOLS" && -n "$HOST_OUT" && -n "$US_OUT" ]]; then
  # env -i: on NixOS a locale missing from LOCALE_ARCHIVE silently resolves via the system archive or C, so presence is read from `locale -a`
  LOCALE="$TOOLS/bin/locale"; DATE="$TOOLS/bin/date"
  arch() { echo "$1/lib/locale/locale-archive"; }
  listed() { env -i LOCALE_ARCHIVE="$(arch "$1")" "$LOCALE" -a 2>/dev/null; }
  stamp() { env -i TZ=UTC LOCALE_ARCHIVE="$(arch "$1")" LC_ALL="$2" "$DATE" -d '2026-10-29 21:05:00' '+%x|%X' 2>&1; }

  HOST_LIST=$(listed "$HOST_OUT"); US_LIST=$(listed "$US_OUT")
  verdict "$([[ -n "$HOST_LIST" ]] && echo yes || echo no)" "locale -a on the host archive prints entries (glibc and archive versions agree)" "locale -a printed nothing"
  verdict "$(has_line en_IN "$HOST_LIST")" "host archive: locale -a lists en_IN" "listed: $(tr '\n' ' ' <<<"$HOST_LIST")"
  verdict "$(has_line it_CH.utf8 "$HOST_LIST")" "host archive: locale -a lists it_CH.utf8" "listed: $(tr '\n' ' ' <<<"$HOST_LIST")"
  verdict "$(has_line en_US.utf8 "$HOST_LIST")" "host archive: locale -a lists en_US.utf8" "listed: $(tr '\n' ' ' <<<"$HOST_LIST")"
  verdict "$([[ "$(has_line en_IN "$US_LIST")" == no && "$(has_line it_CH.utf8 "$US_LIST")" == no && "$(has_line en_US.utf8 "$US_LIST")" == yes ]] && echo yes || echo no)" \
    "control(archive): the no-values archive lists en_US.utf8 but neither en_IN nor it_CH.utf8" "listed: $(tr '\n' ' ' <<<"$US_LIST")"

  IN=$(stamp "$HOST_OUT" en_IN); IN_UTF=$(stamp "$HOST_OUT" en_IN.UTF-8); CH=$(stamp "$HOST_OUT" it_CH.UTF-8); CC=$(stamp "$HOST_OUT" C)
  verdict "$([[ "$IN" == "29/10/26|09:05:00 PM"* ]] && echo yes || echo no)" "LC_ALL=en_IN: date prints day-first 29/10/26 and a 12-hour AM/PM time" "got: $IN"
  verdict "$([[ "$IN_UTF" == "$IN" ]] && echo yes || echo no)" "LC_ALL=en_IN.UTF-8 resolves to the same locale as the bare en_IN" "en_IN=$IN en_IN.UTF-8=$IN_UTF"
  verdict "$([[ "$CH" == "29.10.2026|21:05:00" ]] && echo yes || echo no)" "LC_ALL=it_CH.UTF-8: dotted date and 24-hour time (the other eight categories)" "got: $CH"
  verdict "$([[ "$CC" == "10/29/26|21:05:00" && "$CC" != "$IN" ]] && echo yes || echo no)" "control(locale): the C fallback prints month-first 10/29/26 and 24-hour 21:05:00, so a silent C fallback would fail the en_IN check" "got: $CC"
else
  bad "runtime evidence needs the tools and both archives" "a build above failed"
fi

echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $TOTAL):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
done
exit 1
