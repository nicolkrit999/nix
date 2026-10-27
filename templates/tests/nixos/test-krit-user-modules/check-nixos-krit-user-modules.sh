#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0; FAIL=0
declare -a FAILURES=()

echo ""
echo -e "${BOLD}=== krit user modules (dolphin, helium vs chromium, PWAs, rclone, logid; minimal fixtures) ===${NC}"

stderr_file=$(mktemp)
if ! json=$(nix eval --json --impure --file "$DIR/01-scenario-krit-user-modules.nix" 2>"$stderr_file"); then
  printf "  ${RED}✗ eval error${NC}\n"
  ((FAIL++)) || true
  FAILURES+=("module fixtures: evaluation|$(grep -E 'error:' "$stderr_file" | head -3)")
else
  while IFS=$'\t' read -r name result; do
    printf "  %-60s " "$name"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ PASS${NC}\n"; ((PASS++)) || true
    else
      printf "${RED}✗ FAIL${NC}\n"; ((FAIL++)) || true
      FAILURES+=("$name|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
fi
rm -f "$stderr_file"

# --- cloud modules on a minimal fixture (positive case and control) ---
echo ""
echo -e "${BOLD}cloud modules (minimal fixture)${NC}"
stderr_file=$(mktemp)
if ! json=$(nix eval --json --impure --file "$DIR/03-scenario-cloud-fixture.nix" 2>"$stderr_file"); then
  printf "  ${RED}✗ eval error${NC}\n"
  ((FAIL++)) || true
  FAILURES+=("cloud fixture: evaluation|$(grep -E 'error:' "$stderr_file" | head -3)")
else
  while IFS=$'\t' read -r name result; do
    printf "  %-60s " "$name"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ PASS${NC}\n"; ((PASS++)) || true
    else
      printf "${RED}✗ FAIL${NC}\n"; ((FAIL++)) || true
      FAILURES+=("cloud fixture: $name|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<<"$json")
fi
rm -f "$stderr_file"

# --- Dolphin places: the real dolphin-places-sync of nixos-desktop on fixture xbel files ---
echo ""
echo -e "${BOLD}dolphin places sync (real script, fixture files)${NC}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PSCEN="$DIR/02-scenario-dolphin-places.nix"
pev() { nix eval --raw --impure --file "$PSCEN" "$1" 2>>"$WORK/ev.err"; }
PSYNC=$(pev sync-path); PSEED=$(pev seed-path); PHOME=$(pev home); PFLAKE=$(pev flake-dir)
SDRV=$(pev sync-drv); EDRV=$(pev seed-drv)

pass() { printf "${GREEN}✓ PASS${NC}\n"; ((PASS++)) || true; }
fail() { printf "${RED}✗ FAIL${NC}\n"; ((FAIL++)) || true; FAILURES+=("dolphin places: $1|$2"); }
assert() {
  local label=$1; shift
  printf "  %-60s " "$label"
  if "$@" >/dev/null 2>&1; then pass; else fail "$label" "assertion false"; fi
}

printf "  %-60s " "locate and build dolphin-places-sync and its seed"
if [[ -z $PSYNC || -z $SDRV || -z $PSEED || -z $EDRV ]]; then
  fail "locate dolphin-places-sync" "scenario eval gave no path/drv: $(tail -n 3 "$WORK/ev.err")"
elif ! nix build --no-link "$SDRV^out" "$EDRV^out" >"$WORK/build.out" 2>&1 || [[ ! -x $PSYNC || ! -r $PSEED ]]; then
  fail "build dolphin-places-sync" "$(tail -n 5 "$WORK/build.out")"
else
  pass

  hrefs() { grep -o '<bookmark href="[^"]*"' "$1" | sed 's/<bookmark href="//; s/"$//'; }
  EXPECTED=$(printf '%s\n' "file://$PHOME" "file://$PHOME/Documents" "file://$PHOME/Pictures" "file://$PHOME/$PFLAKE" \
    "file://$PHOME/Downloads" "file://$PHOME/momentary" "file:///mnt" "remote:/" \
    "recentlyused:/files" "recentlyused:/locations" "file://$PHOME/Projects" "trash:/")
  mark() { # one fixture bookmark, optional KDE metadata (the second argument)
    printf ' <bookmark href="%s">\n  <title>%s</title>\n  <info>\n   <metadata owner="http://freedesktop.org">\n    <bookmark:icon name="folder"/>\n   </metadata>\n%s  </info>\n </bookmark>\n' "$1" "$2" "$3"
  }
  kde() { printf '   <metadata owner="http://www.kde.org">\n    <ID>%s</ID>\n    <isSystemItem>true</isSystemItem>\n   </metadata>\n' "$1"; }
  fixture() { # old Dolphin file: the pre-change order plus Dolphin and user extras
    cat <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdefile="http://www.kde.org/standards/kdefile">
 <info>
  <metadata owner="http://www.kde.org">
   <kde_places_version>4</kde_places_version>
   <withBaloo>true</withBaloo>
  </metadata>
 </info>
XML
    mark "file://$PHOME" Home ""
    mark "file://$PHOME/Documents" Documents ""
    mark "file://$PHOME/Downloads" Downloads ""
    mark "remote:/" Network ""
    mark "trash:/" Trash ""
    mark "recentlyused:/files" "Recent Files" "$(kde 111/0)"
    mark "recentlyused:/locations" "Recent Locations" "$(kde 111/1)"
    mark "file://$PHOME/Projects" "My Projects" "$(kde 222/0)"
    mark "file://$PHOME/momentary" momentary ""
    mark "file:///mnt" mnt ""
    echo "</xbel>"
  }
  run() { "$PSYNC" "$PSEED" "$1" --last trash:/; }
  same() { cmp -s "$1" "$2"; }
  wellformed() { python3 -c 'import sys, xml.etree.ElementTree as E; E.parse(sys.argv[1])' "$1"; }
  nodup() { [[ -z $(hrefs "$1" | sort | uniq -d) ]]; }
  count_is() { [[ $(hrefs "$1" | wc -l) == "$2" ]]; }
  nth_from_end() { [[ $(hrefs "$1" | tail -n "$2" | head -n 1) == "$3" ]]; }
  order_is() { [[ $(hrefs "$1") == "$2" ]]; }

  P="$WORK/old.xbel"; fixture >"$P"; cp "$P" "$WORK/orig.xbel"
  assert "precondition: the fixture is not already in the declared order" test "$(hrefs "$P")" != "$EXPECTED"
  run "$P"; rc=$?
  assert "existing file: sync exits 0" test "$rc" = 0
  assert "existing file: exact declared order, extras before Trash, Trash last" order_is "$P" "$EXPECTED"
  assert "existing file: the result is well-formed xbel" wellformed "$P"
  assert "existing file: Dolphin header metadata kept (withBaloo)" grep -q '<withBaloo>true</withBaloo>' "$P"
  assert "existing file: KDE attributes of Dolphin bookmarks kept (ID 111/0)" grep -q '<ID>111/0</ID>' "$P"
  assert "existing file: user extra bookmark kept with its title" grep -q '<title>My Projects</title>' "$P"
  assert "existing file: user extra bookmark kept with its KDE attributes" grep -q '<ID>222/0</ID>' "$P"
  assert "existing file: 10 fixture bookmarks plus Pictures and nix, none lost" count_is "$P" 12
  assert "existing file: no bookmark duplicated" nodup "$P"
  assert "existing file: previous file saved once as .bak" same "$P.bak" "$WORK/orig.xbel"

  cp "$P" "$WORK/pass1.xbel"; run "$P"; rc=$?
  assert "second run: exits 0" test "$rc" = 0
  assert "second run: the file is byte-identical (idempotent)" same "$P" "$WORK/pass1.xbel"
  assert "second run: .bak still holds the original, not the first result" same "$P.bak" "$WORK/orig.xbel"

  sed '$d' "$P" >"$WORK/added.xbel"
  mark "file://$PHOME/Music" Music "" >>"$WORK/added.xbel"; echo "</xbel>" >>"$WORK/added.xbel"
  cp "$WORK/added.xbel" "$P"; run "$P"
  assert "a bookmark the user adds later is the last one before Trash" nth_from_end "$P" 2 "file://$PHOME/Music"
  assert "a bookmark the user adds later: Trash stays last" nth_from_end "$P" 1 "trash:/"
  assert "a bookmark the user adds later: managed places stay first" nth_from_end "$P" 13 "file://$PHOME"

  N="$WORK/new/places.xbel"; run "$N"; rc=$?
  FRESH=$(printf '%s\n' "file://$PHOME" "file://$PHOME/Documents" "file://$PHOME/Pictures" "file://$PHOME/$PFLAKE" \
    "file://$PHOME/Downloads" "file://$PHOME/momentary" "file:///mnt" "remote:/" "trash:/")
  assert "missing file: sync exits 0" test "$rc" = 0
  assert "missing file: created from the seed in the declared order" order_is "$N" "$FRESH"
  assert "missing file: mode 644" test "$(stat -c %a "$N")" = 644

  B="$WORK/broken.xbel"; printf '<xbel><bookmark href="x">' >"$B"; cp "$B" "$WORK/broken.orig"
  run "$B"; rc=$?
  assert "malformed file: sync fails" test "$rc" != 0
  assert "malformed file: the file is untouched and gets no .bak" bash -c "cmp -s '$B' '$WORK/broken.orig' && test ! -e '$B.bak'"
  S="$WORK/sep.xbel"; fixture | sed 's|</xbel>| <separator/>\n</xbel>|' >"$S"; cp "$S" "$WORK/sep.orig"
  run "$S"; rc=$?
  assert "unknown content between bookmarks: sync fails" test "$rc" != 0
  assert "unknown content between bookmarks: file untouched" same "$S" "$WORK/sep.orig"
  assert "no temp files left behind" test -z "$(find "$WORK" -name '.user-places.*')"

  O="$WORK/order-control.xbel"; fixture >"$O"
  printf "  %-60s " "control: order_is fails on the unsynced fixture"
  if order_is "$O" "$EXPECTED"; then fail "control: order_is" "the order comparison accepted the unsynced fixture"; else pass; fi
  run "$O"
  SWAPPED=$(awk 'NR==2{a=$0; next} NR==3{print; print a; next} {print}' <<<"$EXPECTED")
  printf "  %-60s " "control: the swapped expectation really differs"
  if [[ $SWAPPED != "$EXPECTED" ]]; then pass; else fail "control: swap" "the swapped expectation equals the real one"; fi
  printf "  %-60s " "control: order_is fails on a swapped expectation after sync"
  if order_is "$O" "$SWAPPED"; then fail "control: order_is" "the order comparison accepted a swapped expectation"; else pass; fi
fi

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<< "$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  [[ -n "$detail" ]] && echo -e "    ${DIM}$detail${NC}"
done
exit 1
