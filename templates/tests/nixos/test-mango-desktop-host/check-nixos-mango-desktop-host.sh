#!/usr/bin/env bash
# Real nixos-desktop mango settings, hypridle DPMS strings, mango -p and the mango-dpms script at runtime.
#
# Usage:
#   bash check-nixos-mango-desktop-host.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-mango-desktop-host.nix"

if ! command -v awk >/dev/null; then
  exec nix shell --inputs-from "$REPO_ROOT" nixpkgs#gawk nixpkgs#coreutils -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

pass() { printf "${GREEN}✓ ok${NC}\n"; PASS=$((PASS + 1)); }
fail() { printf "${RED}✗ fail${NC}\n"; FAIL=$((FAIL + 1)); FAILURES+=("$1|$2"); }

run_check() {
  local attr=$1 label=$2 result err
  printf "  %-66s " "$label"
  err=$(mktemp)
  if result=$(nix eval --raw --impure --file "$SCENARIO" "$attr" 2>"$err"); then
    if [[ $result == ok ]]; then pass; else fail "$label" "$result"; fi
  else
    fail "$label" "EVAL ERROR: $(grep -E 'error:' "$err" | head -3 | tr '\n' ' ')"
  fi
  rm -f "$err"
}

assert() {
  local label=$1
  shift
  printf "  %-66s " "$label"
  if "$@"; then pass; else fail "$label" "assertion false"; fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== mango on the real nixos-desktop host ===${NC}"
echo ""

echo -e "${BOLD}settings${NC}"
run_check check-scratch-binds-have-tag0-rules  "every mango-scratch --class has a tags:0 window rule"
run_check check-scratch-rule-control           "control: tag0 predicate discriminates"
run_check check-no-window-rule-once         "window_rule_once is empty (no zen rule)"
run_check check-no-plain-exec               "no plain exec entries"
run_check check-media-keys-not-in-bind      "Play/Pause not duplicated in bind"
run_check check-no-duplicate-combos         "no duplicate combos across bind/bindl/bindsl"
run_check check-duplicate-combos-control        "control: duplicate predicate discriminates"
run_check check-proportion-preset-has-arg   "switch_proportion_preset always has an argument"
run_check check-proportion-preset-control       "control: empty-preset predicate discriminates"
run_check check-no-zero-opacity-rules       "no opacity:0 window rules"
run_check check-zero-opacity-control            "control: opacity predicate discriminates"

echo ""
echo -e "${BOLD}bind/rule shape and layouts${NC}"
run_check check-bind-lists-nonempty                 "bind/mousebind/axisbind/gesturebind/tag_rule/layer_rule non-empty"
run_check check-bind-rule-min-fields                "binds have >=3 comma fields, rules >=2 key:value fields"
run_check check-min-fields-control                  "control: field-count predicate discriminates"
run_check check-tag-rule-matches-option             "tag_rule: tags 1-9 per monitor agree with monitorLayouts option"
run_check check-tag-rule-one-layout-per-tag-monitor "tag_rule: exactly one entry per (tag, monitor)"
run_check check-tag-rule-fallback-per-tag           "tag_rule: defaultLayout fallback for tags 1-9"
run_check check-tag-rule-syntax                     "tag_rule entries are well formed"
run_check check-tag-rule-control                    "control: tag_rule predicate rejects mutated lists"

echo ""
echo -e "${BOLD}GDK_SCALE and systemd variables${NC}"
run_check check-gdk-scale-two-sources               "sessionVariables GDK_SCALE (not 1) vs mango env GDK_SCALE,1"
run_check check-gdk-scale-systemd-forwarded         "GDK_SCALE forwarded to systemd"
run_check check-systemd-vars-defined                "systemd.variables defined or allow-listed"
run_check check-systemd-vars-control                "control: undefined-variable predicate discriminates"

echo ""
echo -e "${BOLD}hypridle${NC}"
run_check check-hypridle-no-direct-wlopm        "hypridle never calls wlopm directly (mango-dpms present)"
run_check check-hypridle-wlopm-control          "control: wlopm/dpms predicates discriminate"
run_check check-hypridle-after-sleep-mango-dpms   "after_sleep_cmd runs mango-dpms on"
run_check check-hypridle-screen-off-mango-dpms    "screen-off listener runs mango-dpms off/on"
run_check check-hypridle-other-wms-unchanged      "Hyprland and niri branches unchanged"

echo ""
echo -e "${BOLD}mango -p${NC}"
conf=$(nix eval --raw --impure --file "$SCENARIO" mango-config 2>/dev/null)
pkg=$(nix eval --raw --impure --file "$SCENARIO" mango-package 2>/dev/null)
confdrv=$(nix eval --raw --impure --file "$SCENARIO" mango-config-drv 2>/dev/null)
pkgdrv=$(nix eval --raw --impure --file "$SCENARIO" mango-package-drv 2>/dev/null)
if [[ -n $conf && -n $pkg && -n $confdrv && -n $pkgdrv ]] && nix build --no-link "$confdrv^out" "$pkgdrv^out" >/dev/null 2>"$WORK/build.err" && [[ -x $pkg/bin/mango ]]; then
  out=$("$pkg/bin/mango" -c "$conf" -p 2>&1)
  rc=$?
  assert "mango -p exits 0" test "$rc" -eq 0
  assert "mango -p prints nothing (exit code alone is unreliable)" test -z "$out"
else
  printf "  %-66s " "build mango and its config.conf"
  fail "build mango and its config.conf" "could not realise $conf / $pkg: $(grep -E 'error:' "$WORK/build.err" 2>/dev/null | head -2 | tr '\n' ' ')"
fi

echo ""
echo -e "${BOLD}mango-dpms (stub wlopm)${NC}"
dpms=${DPMS_SCRIPT:-}
if [[ -z $dpms ]]; then
  cmd=$(nix eval --raw --impure --file "$SCENARIO" mango-dpms-cmd 2>/dev/null)
  dpms=$(grep -o '/nix/store/[^ ]*/bin/mango-dpms' <<<"$cmd" | head -1)
  dpmsdrv=$(nix eval --raw --impure --file "$SCENARIO" mango-dpms-drv 2>/dev/null)
  [[ -n $dpmsdrv ]] && nix build --no-link "$dpmsdrv^out" >/dev/null 2>&1
fi

if [[ ! -r $dpms ]]; then
  printf "  %-66s " "locate mango-dpms"
  fail "locate mango-dpms" "no readable script at '$dpms'"
else
  grep -v '^export PATH=' "$dpms" >"$WORK/mango-dpms.sh"
  mkdir -p "$WORK/bin" "$WORK/run"
  cat >"$WORK/bin/wlopm" <<'STUB'
#!/usr/bin/env bash
st=$WPD_STATE/state
if [[ $# -eq 0 ]]; then cat "$st"; exit 0; fi
[[ $# -eq 2 && ( $1 == --on || $1 == --off ) && $2 != '*' ]] || { echo "bad-args $*" >>"$WPD_STATE/log"; exit 1; }
echo "wlopm $*" >>"$WPD_STATE/log"
mode=${1#--}
sed -i "s/^$2 .*/$2 $mode/" "$st"
STUB
  chmod +x "$WORK/bin/wlopm"

  export WPD_STATE="$WORK" XDG_RUNTIME_DIR="$WORK/run" WAYLAND_DISPLAY=wl-test
  export PATH="$WORK/bin:$PATH"
  reset() { printf 'DP-1 on\nDP-2 on\nHDMI-A-1 off\n' >"$WORK/state"; : >"$WORK/log"; rm -f "$WORK"/run/mango-dpms-*; }
  logged() { grep -Fxq -- "$1" "$WORK/log"; }
  rec="$WORK/run/mango-dpms-wl-test"

  reset
  bash "$WORK/mango-dpms.sh" off
  assert "off powers DP-1 and DP-2 off" bash -c "grep -Fxq 'wlopm --off DP-1' '$WORK/log' && grep -Fxq 'wlopm --off DP-2' '$WORK/log'"
  assert "off never touches the already-off HDMI-A-1" bash -c "! grep -q HDMI '$WORK/log'"
  assert "off records the outputs that were on" test "$(sort "$rec" | tr '\n' ' ')" = "DP-1 DP-2 "

  bash "$WORK/mango-dpms.sh" off
  assert "second off keeps the record (merged with existing)" test "$(sort "$rec" | tr '\n' ' ')" = "DP-1 DP-2 "

  : >"$WORK/log"
  bash "$WORK/mango-dpms.sh" on
  assert "on re-enables DP-1 and DP-2" bash -c "grep -Fxq 'wlopm --on DP-1' '$WORK/log' && grep -Fxq 'wlopm --on DP-2' '$WORK/log'"
  assert "on never enables HDMI-A-1 or a wildcard" bash -c "! grep -Eq 'HDMI|\\*' '$WORK/log'"
  assert "on removes the record" test ! -e "$rec"
  assert "HDMI-A-1 stays off after the cycle" grep -Fxq 'HDMI-A-1 off' "$WORK/state"
  assert "no wlopm call was rejected" bash -c "! grep -q bad-args '$WORK/log'"

  reset
  bash "$WORK/mango-dpms.sh" on
  assert "on without a record (plain suspend) does nothing" test ! -s "$WORK/log"

  bash "$WORK/mango-dpms.sh" bogus 2>/dev/null
  assert "unknown argument exits 2" test "$?" -eq 2
fi

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
