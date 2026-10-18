#!/usr/bin/env bash
# Which backend xdg-desktop-portal actually selects, per portal case and session desktop, with
# no session switch. The real hosts are only evaluated: each base/specialisation maps to a
# portal case (its desktops + whether the HM portal is on), and a slim fake host per case
# (02-fake-case.nix) must reproduce the real portal facts. The fake host's portal data is
# read from cache.nixos.org NAR listings or rebuilt by stand-ins (portal-common.nix); the
# real xdg-desktop-portal then runs on a private D-Bus. No profile is built, no VM.
#
# Usage:
#   bash check-nixos-portal-routing.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
REAL="$DIR/01-scenario-portal-routing.nix"
FAKE="$DIR/02-fake-case.nix"
HELPER="$DIR/portal_routing.py"
SHARE="$DIR/portal_share.py"
SIM="$DIR/portal-xdp-sim.sh"
HOSTS=(nixos-desktop nixos-laptop)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }
row() { printf "  %-70s " "$1"; }
py() { python3 -I -c "$@"; }
err() { grep -E 'error:|assertion' "$1" | head -3 | tr '\n' ' '; }

WORK=$(mktemp -d)
trap 'chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

finish() {
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
}

echo ""
echo -e "${BOLD}=== xdg-desktop-portal backend routing (slim fake hosts, real xdp, private bus) ===${NC}"
echo ""
echo -e "${BOLD}real hosts (eval only)${NC}"
REALS=()
for h in "${HOSTS[@]}"; do
  row "$h: evaluate portal facts for base and specialisations"
  if HOST=$h nix eval --json --impure --file "$REAL" >"$WORK/real-$h.json" 2>"$WORK/real-$h.err"; then
    pass; REALS+=("$WORK/real-$h.json")
  else
    fail "$h: evaluate" "EVAL ERROR: $(err "$WORK/real-$h.err")"
  fi
done
[[ ${#REALS[@]} -gt 0 ]] || finish

# case id -> case JSON, and "host/spec<TAB>case id" for every real base/specialisation
py '
import json, sys
cases, specs = {}, []
for f in sys.argv[2:]:
    host = f.rsplit("real-", 1)[1][:-5]
    for spec, v in json.load(open(f)).items():
        c = v["case"]
        cid = "+".join(c["desktops"]) + ("+hm" if c["hmPortal"] else "")
        cases[cid] = c
        specs.append(f"{host}/{spec}\t{cid}")
json.dump(cases, open(sys.argv[1] + "/cases.json", "w"))
open(sys.argv[1] + "/specs.tsv", "w").write("\n".join(specs) + "\n")
' "$WORK" "${REALS[@]}"
mapfile -t CASES < <(py 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))))' "$WORK/cases.json")

for h in "${HOSTS[@]}"; do
  [[ -f $WORK/real-$h.json ]] || continue
  while IFS=$'\t' read -r hs _; do
    [[ $hs == "$h/"* ]] || continue
    row "$hs: HM xdg.portal.config equals system xdg.portal.config"
    if py 'import json,sys; d=json.load(open(sys.argv[1]))[sys.argv[2]]; sys.exit(d["portalConfig"]!=d["hmPortalConfig"])' "$WORK/real-$h.json" "${hs#*/}"; then pass; else fail "$hs: hm config" "home-manager xdg.portal.config differs from the system one"; fi
  done <"$WORK/specs.tsv"
done

echo ""
echo -e "${BOLD}fake hosts (${#CASES[@]} portal cases)${NC}"
declare -a OKCASES=()
for cid in "${CASES[@]}"; do
  CJ=$(py 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))[sys.argv[2]]))' "$WORK/cases.json" "$cid")
  echo "$CJ" >"$WORK/$cid.case"
  row "[$cid] evaluate fake host"
  if PORTAL_CASE=$CJ nix eval --json --impure --file "$FAKE" info >"$WORK/$cid.info" 2>"$WORK/$cid.err"; then pass; OKCASES+=("$cid"); else fail "$cid: evaluate" "EVAL ERROR: $(err "$WORK/$cid.err")"; fi
done

# The fake host must reproduce every real spec that maps to it; otherwise its routing says
# nothing about the real host.
while IFS=$'\t' read -r hs cid; do
  [[ -f $WORK/$cid.info ]] || continue
  h=${hs%%/*}
  row "$hs: fake [$cid] reproduces config, portal packages, sessions, xdp"
  r=$(py '
import json, sys
real = json.load(open(sys.argv[1]))[sys.argv[2]]
fake = json.load(open(sys.argv[3]))
bad = [k for k in ("portalConfig", "hmPortalConfig", "sysPortalNames", "hmPortalNames", "sessionNames", "xdpPath")
       if real[k] != fake[k]]
print("; ".join(f"{k}: real={real[k]} fake={fake[k]}" for k in bad))
' "$WORK/real-$h.json" "${hs#*/}" "$WORK/$cid.info")
  if [[ -z $r ]]; then pass; else fail "$hs: fake drift" "$r"; fi
done <"$WORK/specs.tsv"

INFOS=()
for cid in "${OKCASES[@]}"; do INFOS+=("$WORK/$cid.info"); done
row "read portal data of every entry from cache.nixos.org"
if python3 -I "$SHARE" scan "$WORK/scan.json" "${REALS[@]}" "${INFOS[@]}" >"$WORK/scan.err" 2>&1; then pass; else fail "scan" "$(tail -3 "$WORK/scan.err" | tr '\n' ' ')"; finish; fi
SCAN=$WORK/scan.json

echo ""
mkdir -p "$WORK/empty-store"
for cid in "${OKCASES[@]}"; do
  INFO=$WORK/$cid.info
  echo -e "  ${DIM}[$cid]${NC} ${DIM}$(awk -F'\t' -v c="$cid" '$2==c{printf "%s ", $1}' "$WORK/specs.tsv")${NC}"
  printf "    %-68s " "uncached entries are stand-ins or trivial (no src, no fetch)"
  CLS=$(python3 -I "$SHARE" classify "$INFO" "$SCAN" 2>"$WORK/$cid.cls.err")
  heavy=$(py 'import json,sys; print(", ".join(json.loads(sys.argv[1])["heavy"]))' "${CLS:-{\}}" 2>/dev/null)
  if [[ -z $CLS ]]; then fail "$cid: classify" "$(tail -2 "$WORK/$cid.cls.err" | tr '\n' ' ')"; continue; fi
  if [[ -n $heavy ]]; then fail "$cid: uncached heavy entry" "not on cache.nixos.org and not trivial (add a stand-in in portal-common.nix): $heavy"; continue; fi
  pass
  BUILD=$(py 'import json,sys; print(json.dumps(json.loads(sys.argv[1])["build"]))' "$CLS")

  # Regression guard: what the test builds must be substitutable from cache.nixos.org, apart
  # from trivial derivations. Dry run against an empty store that sees only cache.nixos.org.
  printf "    %-68s " "guard: no compile or fetch outside cache.nixos.org"
  PLAN=$(BUILD=$BUILD PORTAL_CASE=$(cat "$WORK/$cid.case") nix eval --json --impure --file "$FAKE" \
    --apply 'f: { drvs = map (d: d.drvPath) (f.realise ++ [ f.xdp f.dbus ]); xdp = f.xdp.outPath; dbus = f.dbus.outPath; }' 2>"$WORK/$cid.drv.err")
  mapfile -t DL < <(py 'import json,sys; print("\n".join(json.loads(sys.argv[1])["drvs"]))' "${PLAN:-{\}}" 2>/dev/null)
  if [[ ${#DL[@]} -eq 0 ]]; then fail "$cid: guard" "EVAL ERROR: $(err "$WORK/$cid.drv.err")"; continue; fi
  if ! nix copy --no-check-sigs --derivation --to "local?root=$WORK/empty-store" "${DL[@]}" 2>"$WORK/$cid.copy.err" ||
    ! nix build --dry-run --store "local?root=$WORK/empty-store" --option substituters https://cache.nixos.org \
      --option extra-substituters '' "${DL[@]/%/^*}" >"$WORK/$cid.dry" 2>&1; then
    fail "$cid: guard" "dry run failed: $(tail -2 "$WORK/$cid.copy.err" "$WORK/$cid.dry" | tr '\n' ' ')"; continue
  fi
  heavy=$(python3 -I "$SHARE" will-build-heavy "$WORK/$cid.dry" 2>&1)
  if [[ -n $heavy ]]; then fail "$cid: guard" "would compile or fetch: $(echo "$heavy" | head -8 | tr '\n' ' ')"; continue; fi
  pass

  printf "    %-68s " "build stand-ins, trivial entries, xdp and dbus"
  nix build --no-link "${DL[@]/%/^*}" 2>"$WORK/$cid.build.err"
  XDP=$(py 'import json,sys; print(json.loads(sys.argv[1])["xdp"])' "$PLAN")/libexec/xdg-desktop-portal
  DBUS=$(py 'import json,sys; print(json.loads(sys.argv[1])["dbus"])' "$PLAN")/bin
  if [[ ! -x $XDP || ! -x $DBUS/dbus-run-session ]]; then fail "$cid: build" "xdp=$XDP dbus=$DBUS; $(err "$WORK/$cid.build.err")"; continue; fi
  pass

  printf "    %-68s " "assemble system, home-manager and session data dirs"
  SYS=$WORK/$cid.sys; HMD=$WORK/$cid.hm; SES=$WORK/$cid.ses
  if ! { python3 -I "$SHARE" assemble "$INFO" "$SCAN" sys "$SYS" && python3 -I "$SHARE" assemble "$INFO" "$SCAN" hm "$HMD" &&
    python3 -I "$SHARE" assemble "$INFO" "$SCAN" sessions "$SES"; } 2>"$WORK/$cid.asm.err"; then
    fail "$cid: assemble" "$(tail -2 "$WORK/$cid.asm.err" | tr '\n' ' ')"; continue
  fi
  pass
  HMSHARE=/nonexistent
  [[ $(py 'import json,sys; print(json.load(open(sys.argv[1]))["hmPortal"])' "$INFO") == True ]] && HMSHARE=$HMD/share

  # Every portal file a real spec's cached entries ship must exist in its fake case.
  while IFS=$'\t' read -r hs c2; do
    [[ $c2 == "$cid" ]] || continue
    h=${hs%%/*}
    printf "    %-68s " "$hs: real portal files all present in the fake case"
    python3 -I "$SHARE" real-files "$WORK/real-$h.json" "$SCAN" "${hs#*/}" >"$WORK/rf" 2>"$WORK/rf.unread"
    missing=$(while read -r f; do [[ -z $f || -e $SYS/$f || -e $HMD/$f ]] || echo "$f"; done <"$WORK/rf" | tr '\n' ' ')
    if [[ -z $missing ]]; then pass; else fail "$hs: real portal file missing in fake" "$missing"; fi
    unread=$(py '
import json, sys
fake = {e["name"] for k in ("sys", "hm", "sessions") for e in json.load(open(sys.argv[1]))[k]}
u = open(sys.argv[2]).read().split()
print(" ".join(n for n in u if n not in fake))' "$INFO" "$WORK/rf.unread")
    [[ -n $unread ]] && echo -e "      ${DIM}not on cache.nixos.org, not inspected: $unread${NC}"
  done <"$WORK/specs.tsv"

  py 'import json,sys; json.dump(json.load(open(sys.argv[1]))["portalConfig"], open(sys.argv[2], "w"))' "$INFO" "$WORK/$cid.pc.json"
  python3 -I "$HELPER" write-config "$WORK/$cid.pc.json" "$WORK/$cid.cfg"
  mapfile -t DESKTOPS < <(python3 -I "$HELPER" desktops "$SES")
  if [[ ${#DESKTOPS[@]} -eq 0 ]]; then
    printf "    %-68s " "at least one session desktop"; fail "$cid: sessions" "no DesktopNames found under $SES"; continue
  fi

  # Negative controls: with no config and no packaged *-portals.conf (only this case's
  # portals/*.portal kept), a desktop named in some UseIn must show the deprecated fallback;
  # kde prepended to every default must be reported as a bleed on the first non-KDE desktop.
  mkdir -p "$WORK/$cid.ctl/xdg-desktop-portal" "$WORK/$cid.empty"
  cp -r "$SYS/share/xdg-desktop-portal/portals" "$WORK/$cid.ctl/xdg-desktop-portal/" 2>/dev/null
  ctl=$(py '
import pathlib, re, sys
toks = [t for f in sorted(pathlib.Path(sys.argv[1]).glob("*.portal"))
        for m in [re.search(r"^UseIn=(.*)$", f.read_text(), re.M)] if m for t in m.group(1).split(";") if t]
print("XFCE" if "XFCE" in toks else (toks[0] if toks else ""))' "$WORK/$cid.ctl/xdg-desktop-portal/portals")
  bash "$SIM" "${ctl:-XFCE}" /nonexistent "$WORK/$cid.ctl" "$WORK/$cid.empty" "$XDP" "$DBUS" >"$WORK/$cid.control" 2>&1 &
  python3 -I "$HELPER" bleed-variant "$WORK/$cid.pc.json" "$WORK/$cid.bleed.json"
  python3 -I "$HELPER" write-config "$WORK/$cid.bleed.json" "$WORK/$cid.bleedcfg"
  cd_=""
  for d in "${DESKTOPS[@]}"; do [[ ${d,,} != *kde* ]] && { cd_=$d; break; }; done
  [[ -n $cd_ ]] && bash "$SIM" "$cd_" "$HMSHARE" "$SYS/share" "$WORK/$cid.bleedcfg" "$XDP" "$DBUS" >"$WORK/$cid.bleed.sim" 2>&1 &
  for d in "${DESKTOPS[@]}"; do
    bash "$SIM" "$d" "$HMSHARE" "$SYS/share" "$WORK/$cid.cfg" "$XDP" "$DBUS" >"$WORK/$cid.$d.sim" 2>&1 &
  done
  wait
  printf "    %-68s " "self-test: no config yields deprecated UseIn lines (${ctl:-no UseIn})"
  if grep -q 'deprecated UseIn' "$WORK/$cid.control"; then pass; else fail "$cid: self-test" "simulation with empty config shows no fallback; harness is blind"; fi
  if [[ -n $cd_ ]]; then
    printf "    %-68s " "self-test: kde added to defaults is flagged as a bleed ($cd_)"
    r=$(python3 -I "$HELPER" verdict "$cd_" "$WORK/$cid.bleed.sim")
    if [[ $r == *"another desktop"* ]]; then pass; else fail "$cid: bleed control" "variant not flagged: $r"; fi
  fi
  for d in "${DESKTOPS[@]}"; do
    printf "    %-68s " "$d"
    r=$(python3 -I "$HELPER" verdict "$d" "$WORK/$cid.$d.sim")
    if [[ $r == ok ]]; then pass; else fail "$cid: $d" "$r"; fi
  done
done

finish
