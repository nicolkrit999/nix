#!/usr/bin/env bash
# Which backend xdg-desktop-portal actually selects, per host, specialisation and session
# desktop, with no session switch: the built system-path and home-manager home-path shares
# plus the repo's xdg.portal.config run through the real xdg-desktop-portal binary on a
# private D-Bus. Builds system-path and home-path (mostly cached), no VM.
#
# Usage:
#   bash check-nixos-portal-routing.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-portal-routing.nix"
HELPER="$DIR/portal_routing.py"
SIM="$DIR/portal-xdp-sim.sh"
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

attr() { echo "path:$FLAKE_ROOT#nixosConfigurations.$1.config$2"; }
build() { nix build --no-link --print-out-paths "$1" 2>>"$WORK/build.err" | tail -1; }

echo ""
echo -e "${BOLD}=== xdg-desktop-portal backend routing (real xdp, private bus) ===${NC}"

for h in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}$h${NC}"
  mkdir -p "$WORK/$h"
  printf "  %-70s " "evaluate xdg.portal.config for base and specialisations"
  if ! HOST=$h nix eval --json --impure --file "$SCENARIO" >"$WORK/$h/cfgs.json" 2>"$WORK/$h/eval.err"; then
    fail "$h: evaluate" "EVAL ERROR: $(grep -E 'error:' "$WORK/$h/eval.err" | head -3 | tr '\n' ' ')"
    continue
  fi
  pass
  XDP="$(build "path:$FLAKE_ROOT#nixosConfigurations.$h.pkgs.xdg-desktop-portal")/libexec/xdg-desktop-portal"
  DBUS="$(build "path:$FLAKE_ROOT#nixosConfigurations.$h.pkgs.dbus")/bin"
  if [[ ! -x $XDP || ! -x $DBUS/dbus-run-session ]]; then
    printf "  %-70s " "xdg-desktop-portal and dbus binaries"
    fail "$h: binaries" "missing: xdp=$XDP dbus=$DBUS; $(tail -3 "$WORK/build.err" | tr '\n' ' ')"
    continue
  fi
  mapfile -t CONFIGS < <(python3 -I -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))))' "$WORK/$h/cfgs.json")

  for s in "${CONFIGS[@]}"; do
    if [[ $s == base ]]; then sub=""; else sub=".specialisation.$s.configuration"; fi
    SP="$(build "$(attr "$h" "$sub.system.path")")"
    SD="$(HOST=$h SPEC=$s nix build --no-link --print-out-paths --impure --file "$DIR/02-sessions.nix" 2>>"$WORK/build.err" | tail -1)"
    hmon=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]]["hmPortal"])' "$WORK/$h/cfgs.json" "$s")
    HMSHARE=/nonexistent
    if [[ $hmon == True ]]; then HMSHARE="$(build "$(attr "$h" "$sub.home-manager.users.krit.home.path")")/share"; fi
    python3 -I -c 'import json,sys; json.dump(json.load(open(sys.argv[1]))[sys.argv[2]]["portalConfig"], open(sys.argv[3], "w"))' \
      "$WORK/$h/cfgs.json" "$s" "$WORK/$h/$s.pc.json"
    CFGHOME="$WORK/$h/$s.cfg"
    python3 -I "$HELPER" write-config "$WORK/$h/$s.pc.json" "$CFGHOME"
    echo -e "  ${DIM}[$s]${NC}"
    printf "    %-68s " "HM xdg.portal.config equals system xdg.portal.config"
    if python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1]))[sys.argv[2]]; sys.exit(0 if d["portalConfig"]==d["hmPortalConfig"] else 1)' "$WORK/$h/cfgs.json" "$s"; then pass; else fail "$h/$s: hm config" "home-manager xdg.portal.config differs from the system one"; fi
    if [[ ! -d $SP/share || ! -d $SD ]]; then
      printf "    %-68s " "build system-path and session data"
      fail "$h/$s: build" "system-path=$SP sessions=$SD; $(tail -3 "$WORK/build.err" | tr '\n' ' ')"
      continue
    fi
    mapfile -t DESKTOPS < <(python3 -I "$HELPER" desktops "$SD")
    if [[ ${#DESKTOPS[@]} -eq 0 ]]; then
      printf "    %-68s " "at least one session desktop"
      fail "$h/$s: sessions" "no DesktopNames found under $SD"
      continue
    fi
    # Negative control (base only): XFCE has no packaged portals.conf, so with no config the
    # gnome-keyring manifest's UseIn must show up as the deprecated fallback.
    if [[ $s == base ]]; then
      mkdir -p "$WORK/$h/empty"
      bash "$SIM" XFCE "$HMSHARE" "$SP/share" "$WORK/$h/empty" "$XDP" "$DBUS" >"$WORK/$h/control" 2>&1
      printf "    %-68s " "self-test: no config yields deprecated UseIn lines"
      if grep -q 'deprecated UseIn' "$WORK/$h/control"; then pass; else fail "$h/$s: self-test" "simulation with empty config shows no fallback; harness is blind"; fi
    fi
    if [[ $s == base ]]; then
      python3 -I "$HELPER" bleed-variant "$WORK/$h/$s.pc.json" "$WORK/$h/$s.bleed.json"
      python3 -I "$HELPER" write-config "$WORK/$h/$s.bleed.json" "$WORK/$h/$s.bleedcfg"
      cd_=""
      for d in "${DESKTOPS[@]}"; do [[ ${d,,} != *kde* ]] && { cd_=$d; break; }; done
      if [[ -n $cd_ ]]; then
        bash "$SIM" "$cd_" "$HMSHARE" "$SP/share" "$WORK/$h/$s.bleedcfg" "$XDP" "$DBUS" >"$WORK/$h/bleed.sim" 2>&1
        printf "    %-68s " "self-test: kde added to defaults is flagged as a bleed ($cd_)"
        r=$(python3 -I "$HELPER" verdict "$cd_" "$WORK/$h/bleed.sim")
        if [[ $r == *"another desktop"* ]]; then pass; else fail "$h/$s: bleed control" "variant not flagged: $r"; fi
      fi
    fi
    for d in "${DESKTOPS[@]}"; do
      bash "$SIM" "$d" "$HMSHARE" "$SP/share" "$CFGHOME" "$XDP" "$DBUS" >"$WORK/$h/$s.$d.sim" 2>&1 &
    done
    wait
    for d in "${DESKTOPS[@]}"; do
      out="$WORK/$h/$s.$d.sim"
      printf "    %-68s " "$d"
      r=$(python3 -I "$HELPER" verdict "$d" "$out")
      if [[ $r == ok ]]; then pass; else fail "$h/$s: $d" "$r"; fi
    done
  done
done

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
