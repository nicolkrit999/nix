#!/usr/bin/env bash
# Runtime check of wallpaperd.sh against stub compositor tools.
#
# Usage:
#   bash check-nixos-wallpaperd-runtime.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${WPD_SCRIPT:-$DIR/../../../../modules/nixos/programs/de-wm/wallpaperd/wallpaperd.sh}"

if ! command -v jq >/dev/null || ! command -v flock >/dev/null; then
  exec nix shell --inputs-from "$DIR/../../../.." nixpkgs#jq nixpkgs#util-linux nixpkgs#coreutils nixpkgs#gnugrep -c bash "$0" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
PASS=0
FAIL=0
declare -a FAILURES=()

WORK=$(mktemp -d)
BG_PIDS=()
cleanup() {
  exec 8>&- 2>/dev/null || true
  for p in "${BG_PIDS[@]}"; do kill "$p" 2>/dev/null || true; done
  pkill -f "$WORK" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

{ echo 'set -euo pipefail'; cat "$SCRIPT"; } >"$WORK/wallpaperd.sh"

STUBS="$WORK/bin"
mkdir -p "$STUBS"

cat >"$STUBS/mpvpaper" <<'STUB'
#!/usr/bin/env bash
badargs() { echo "bad-args mpvpaper $*" >>"$WPD_S/log"; exit 1; }
[[ $# -eq 4 && $1 == -o && $2 == "loop mute=yes panscan=1.0" ]] || badargs "$@"
out=$3
if [[ -e /proc/$$/fd/9 ]]; then echo "fd9-leak mpvpaper $out" >>"$WPD_S/log"; fi
echo "mpv-start $out $4" >>"$WPD_S/log"
echo $$ >"$WPD_S/pid-$out"
sleep 300 &
sp=$!
trap 'echo "mpv-stop $out" >>"$WPD_S/log"; kill $sp 2>/dev/null; exit 0' TERM
trap 'echo "mpv-crash $out" >>"$WPD_S/log"; kill $sp 2>/dev/null; exit 1' USR1
while true; do wait; done
STUB

cat >"$STUBS/awww" <<'STUB'
#!/usr/bin/env bash
badargs() { echo "bad-args awww $*" >>"$WPD_S/log"; exit 1; }
case $1 in
  query) [[ $# -eq 1 ]] || badargs "$@"; exit 0 ;;
  img)
    [[ $# -eq 4 && $2 == -o ]] || badargs "$@"
    if [[ -e /proc/$$/fd/9 ]]; then echo "fd9-leak awww $3" >>"$WPD_S/log"; fi
    left=$(cat "$WPD_S/awww-fail" 2>/dev/null || echo 0)
    if (( left > 0 )); then
      echo $((left - 1)) >"$WPD_S/awww-fail"
      echo "img-fail $3 $4" >>"$WPD_S/log"
      exit 1
    fi
    echo "img $3 $4" >>"$WPD_S/log"
    ;;
  *) badargs "$@" ;;
esac
STUB

cat >"$STUBS/mmsg" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 2 && $1 == watch && $2 == all-monitors ]] || { echo "bad-args mmsg $*" >>"$WPD_S/log"; exit 1; }
echo stream-open >>"$WPD_S/log"
exec cat "$WPD_S/ev"
STUB

cat >"$STUBS/wlr-randr" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 1 && $1 == --json ]] || { echo "bad-args wlr-randr $*" >>"$WPD_S/log"; exit 1; }
echo list >>"$WPD_S/log"
cat "$WPD_S/outputs.json"
STUB

cat >"$STUBS/hyprctl" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 2 && $1 == monitors && $2 == -j ]] || { echo "bad-args hyprctl $*" >>"$WPD_S/log"; exit 1; }
echo list >>"$WPD_S/log"
cat "$WPD_S/outputs.json"
STUB

cat >"$STUBS/socat" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 3 && $1 == -u && $2 == "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/sig/.socket2.sock" && $3 == - ]] \
  || { echo "bad-args socat $*" >>"$WPD_S/log"; exit 1; }
echo stream-open >>"$WPD_S/log"
exec cat "$WPD_S/ev"
STUB

cat >"$STUBS/niri" <<'STUB'
#!/usr/bin/env bash
[[ $# -eq 3 && $1 == msg && $2 == -j ]] || { echo "bad-args niri $*" >>"$WPD_S/log"; exit 1; }
case $3 in
  outputs) echo list >>"$WPD_S/log"; cat "$WPD_S/outputs.json" ;;
  event-stream) echo stream-open >>"$WPD_S/log"; exec cat "$WPD_S/ev" ;;
  *) echo "bad-args niri $*" >>"$WPD_S/log"; exit 1 ;;
esac
STUB
chmod +x "$STUBS"/*

write_outputs() {
  jq -R -s --arg wm "$WM" '
    [split("\n")[] | select(length > 0) | split("\t")
      | {name: .[0], make: .[1], model: .[2], serial: .[3], state: .[4]}] as $o
    | if $wm == "mango" then
        [$o[] | {name, make, model, serial, enabled: (.state == "on")}]
      elif $wm == "hyprland" then
        [$o[] | {name, make, model, serial, disabled: (.state == "off"),
                 mirrorOf: (if .state == "mirror" then 1 else "none" end)}]
      else
        [$o[] | {key: .name, value: {make, model, serial,
                 logical: (if .state == "off" then null else {x: 0} end)}}] | from_entries
      end' "$S/model.tsv" >"$S/outputs.json.tmp"
  mv "$S/outputs.json.tmp" "$S/outputs.json"
}

emit_event() {
  case $WM in
    mango) echo "DP-1 tags 1" >&8 ;;
    hyprland) echo "monitoradded>>x" >&8 ;;
    niri) echo '{"WorkspacesChanged":{}}' >&8 ;;
  esac
}

lists() { grep -c '^list$' "$S/log" || true; }

settle() {
  local before=$1 i
  for i in $(seq 100); do
    if (( $(lists) > before )); then break; fi
    sleep 0.1
  done
  sleep 0.6
}

starts() { grep -E "^(mpv-start|img) $1 " "$S/log"; }

has() { grep -Fxq -- "$1" "$S/log"; }

count() { grep -Fxc -- "$1" "$S/log" || true; }

wait_for() {
  local secs=$1 i
  shift
  for i in $(seq $((secs * 10))); do
    if "$@"; then return 0; fi
    sleep 0.1
  done
  return 1
}

started() { [[ -n $(starts "$1") ]]; }

count_ge() { (( $(count "$1") >= $2 )); }

check() {
  local label=$1
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    printf "  %-76s ${GREEN}✓ ok${NC}\n" "$label"
  else
    FAIL=$((FAIL + 1))
    printf "  %-76s ${RED}✗ fail${NC}\n" "$label"
    FAILURES+=("$WM/$FB: $label")
  fi
}

negate() { ! "$@"; }

run_scenario() {
  WM=$1
  FB=$2
  S="$WORK/$WM-$FB"
  mkdir -p "$S/run"
  : >"$S/log"
  mkfifo "$S/ev"
  export WPD_S="$S" XDG_RUNTIME_DIR="$S/run" WAYLAND_DISPLAY=wl-test
  export HYPRLAND_INSTANCE_SIGNATURE=sig
  export PATH="$STUBS:$PATH"

  printf '%s\n' \
    $'DP-1\tAcme\tLeft\tL1\ton' \
    $'DP-2\tAcme\tPanel\tS2\ton' \
    $'DP-3\tOther\tUnknown\tU3\ton' \
    $'DP-4\tOther\tOff\tU4\toff' >"$S/model.tsv"
  if [[ $WM == hyprland ]]; then
    printf '%s\n' $'DP-5\tOther\tMirror\tU5\tmirror' >>"$S/model.tsv"
  fi
  write_outputs

  local fbspec
  if [[ $FB == video ]]; then fbspec="*=video:/w/fb.mp4"; else fbspec="*=image:/w/fb.png"; fi

  exec 8<>"$S/ev"
  bash "$WORK/wallpaperd.sh" --wm "$WM" \
    "DP-1=image:/w/dp1.png" \
    "desc:Acme Panel S2=video:/w/dp2.mp4" \
    "$fbspec" >"$S/out" 2>&1 8>&- &
  local pid=$!
  BG_PIDS+=("$pid")

  local i
  for i in $(seq 100); do
    if has "img DP-1 /w/dp1.png" && has "mpv-start DP-2 /w/dp2.mp4"; then break; fi
    sleep 0.1
  done
  sleep 0.6

  local fbmatch
  if [[ $FB == video ]]; then fbmatch="mpv-start DP-3 /w/fb.mp4"; else fbmatch="img DP-3 /w/fb.png"; fi

  echo -e "${BOLD}$WM / fallback=$FB${NC}"
  check "declared name DP-1 gets its still via awww" has "img DP-1 /w/dp1.png"
  check "desc: entry gets its video on DP-2 via mpvpaper" has "mpv-start DP-2 /w/dp2.mp4"
  check "undeclared DP-3 gets the fallback" has "$fbmatch"
  check "DP-1 is started exactly once, with its declared still" test "$(starts DP-1)" = "img DP-1 /w/dp1.png"
  check "DP-2 is started exactly once, with its desc: video" test "$(starts DP-2)" = "mpv-start DP-2 /w/dp2.mp4"
  check "undeclared DP-3 is started exactly once, with the fallback" test "$(starts DP-3)" = "$fbmatch"
  check "disabled DP-4 is skipped" negate grep -Eq '^(mpv-start|img) DP-4 ' "$S/log"
  if [[ $WM == hyprland ]]; then
    check "mirrored DP-5 is skipped" negate grep -Eq '^(mpv-start|img) DP-5 ' "$S/log"
  fi
  check "no start ever targets '*' or ALL" negate grep -Eq '^(mpv-start|img) (\*|ALL) ' "$S/log"
  check "DP-2 video started exactly once" test "$(grep -Fxc 'mpv-start DP-2 /w/dp2.mp4' "$S/log")" -eq 1
  check "child processes do not inherit the lock fd" negate grep -q '^fd9-leak' "$S/log"
  check "every tool is called with exactly the expected arguments" negate grep -q '^bad-args' "$S/log"
  check "event stream opened once at startup" test "$(count stream-open)" -eq 1

  local before
  before=$(lists)
  printf '%s\n' $'HDMI-A-1\tHot\tPlug\tH1\ton' >>"$S/model.tsv"
  write_outputs
  emit_event
  settle "$before"
  if [[ $FB == video ]]; then
    check "hot-plugged undeclared HDMI-A-1 gets the fallback" has "mpv-start HDMI-A-1 /w/fb.mp4"
  else
    check "hot-plugged undeclared HDMI-A-1 gets the fallback" has "img HDMI-A-1 /w/fb.png"
  fi
  check "hot-plug does not restart DP-2" test "$(grep -Fxc 'mpv-start DP-2 /w/dp2.mp4' "$S/log")" -eq 1

  before=$(lists)
  grep -v '^DP-3' "$S/model.tsv" >"$S/model.tsv.new"
  mv "$S/model.tsv.new" "$S/model.tsv"
  write_outputs
  emit_event
  settle "$before"
  if [[ $FB == video ]]; then
    check "unplugged DP-3 has its mpvpaper stopped" has "mpv-stop DP-3"
    check "the unplug stops only DP-3 (DP-2 and HDMI-A-1 keep running)" test "$(grep -c '^mpv-stop ' "$S/log")" -eq 1
  else
    check "image fallback: the unplug stops no mpvpaper" negate grep -q '^mpv-stop ' "$S/log"
  fi

  before=$(lists)
  grep -v '^DP-4' "$S/model.tsv" >"$S/model.tsv.new"
  printf '%s\n' $'DP-4\tOther\tOff\tU4\ton' >>"$S/model.tsv.new"
  mv "$S/model.tsv.new" "$S/model.tsv"
  write_outputs
  emit_event
  settle "$before"
  if [[ $FB == video ]]; then
    check "re-enabled DP-4 now gets the fallback" has "mpv-start DP-4 /w/fb.mp4"
  else
    check "re-enabled DP-4 now gets the fallback" has "img DP-4 /w/fb.png"
  fi

  if [[ $WM == hyprland ]]; then
    before=$(lists)
    sed -i $'s/^DP-5\t.*/DP-5\tOther\tMirror\tU5\ton/' "$S/model.tsv"
    write_outputs
    emit_event
    settle "$before"
    check "un-mirrored DP-5 now gets the fallback (skip was the mirror state)" started DP-5
  fi

  if [[ $FB == image ]]; then
    echo 5 >"$S/awww-fail"
    printf '%s\n' $'DP-6\tHot\tRetry\tR6\ton' >>"$S/model.tsv"
    write_outputs
    emit_event
    check "failed still start is retried until it succeeds" wait_for 20 has "img DP-6 /w/fb.png"
    check "the failed attempts were really made" has "img-fail DP-6 /w/fb.png"
    echo 0 >"$S/awww-fail"
  fi

  local opens
  opens=$(count stream-open)
  exec 8>&-
  check "dropped event stream is reopened" wait_for 15 count_ge stream-open $((opens + 1))
  exec 8<>"$S/ev"
  sleep 0.6
  check "daemon survives a dropped event stream" kill -0 "$pid"
  check "dropped event stream does not stop the wallpapers" negate has "mpv-stop DP-2"
  check "DP-2 video not restarted by a dropped event stream" test "$(count 'mpv-start DP-2 /w/dp2.mp4')" -eq 1
  before=$(lists)
  emit_event
  printf '%s\n' $'DP-7\tHot\tAfter\tA7\ton' >>"$S/model.tsv"
  write_outputs
  emit_event
  check "an output added after the reconnect gets the fallback" wait_for 10 started DP-7

  kill -USR1 "$(cat "$S/pid-DP-2")"
  check "crashed mpvpaper is restarted" wait_for 15 count_ge 'mpv-start DP-2 /w/dp2.mp4' 2
  check "daemon survives a crashed mpvpaper" kill -0 "$pid"

  kill -TERM "$pid" 2>/dev/null || true
  for i in $(seq 100); do
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    sleep 0.1
  done
  check "supervisor exits on SIGTERM" negate kill -0 "$pid" 2>/dev/null
  if [[ $FB == video ]]; then
    check "SIGTERM stops the remaining mpvpaper (DP-2)" has "mpv-stop DP-2"
  fi

  before=$(lists)
  bash "$WORK/wallpaperd.sh" --wm "$WM" "DP-1=image:/w/dp1.png" >"$S/out2" 2>&1 8>&- &
  local pid2=$!
  BG_PIDS+=("$pid2")
  sleep 1.5
  check "second instance after SIGTERM really ran (listed outputs)" test "$(lists)" -gt "$before"
  check "lock is free after SIGTERM (second instance is not refused)" negate grep -q 'already running' "$S/out2"
  kill -TERM "$pid2" 2>/dev/null || true
  wait "$pid2" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  exec 8>&-
}

echo ""
echo -e "${BOLD}=== wallpaperd runtime check ===${NC}"
echo -e "${DIM}Runs wallpaperd.sh against stub compositor and wallpaper tools.${NC}"
echo ""

for wm in mango hyprland niri; do
  for fb in video image; do
    run_scenario "$wm" "$fb"
  done
done

# mango reads each config value with sscanf("%255[^\n]") (src/config/load.c) and
# silently drops the rest, so an exec_once longer than 255 chars is spawned cut.
mango_config_values() {
  echo ""
  echo -e "${BOLD}--- mango config values reach mango intact ---${NC}"
  WM=mango FB=config
  local flake="$DIR/../../../.."
  local json
  json=$(nix eval --json "$flake#nixosConfigurations" --apply '
    cs: builtins.mapAttrs (_: c:
      builtins.mapAttrs (_: u:
        let m = u.wayland.windowManager.mango or { enable = false; }; in
        if m.enable && builtins.isAttrs m.settings then
          builtins.mapAttrs (_: v:
            if builtins.isList v then builtins.filter builtins.isString v
            else if builtins.isString v then [ v ]
            else [ ]) m.settings
        else { })
        (c.config.home-manager.users or { }))
      cs' 2>"$WORK/eval.err")
  if [[ -z $json ]]; then
    check "mango settings of every host evaluate" false
    sed 's/^/    /' "$WORK/eval.err" | tail -5
    return
  fi
  check "at least one host enables mango" test "$(jq '[.[][] | select(length > 0)] | length' <<<"$json")" -gt 0
  check "the wallpaperd launcher script is a whole mango exec_once command" test "$(jq '[.[][].exec_once // [] | .[] | select(test("mango-wallpaperd-start$"))] | length' <<<"$json")" -gt 0

  local ctl="sh -c 'exec wallpaperd --wm mango DP-1=image:/a DP-2=video:/b *=video:/$(printf 'c%.0s' $(seq 300))'"
  check "control: a 255-cut of an over-long inlined argv is rejected by bash -n" negate bash -n -c "${ctl:0:255}"
  check "control: the over-long sample really exceeds 255 chars" test "${#ctl}" -gt 255

  local host user key v cut bad=0
  while IFS=$'\t' read -r host user key v; do
    v=$(base64 -d <<<"$v")
    cut=${v:0:255}
    if (( ${#v} > 255 )); then
      bad=1
      check "$host/$user $key fits mango's 255-char value (${#v}): ${v:0:40}..." false
    fi
    if [[ $key == exec_once || $key == exec ]] && ! bash -n -c "$cut" 2>/dev/null; then
      bad=1
      check "$host/$user $key is valid shell as mango reads it: ${v:0:40}..." false
    fi
  done < <(jq -r 'to_entries[] | .key as $h | .value | to_entries[] | .key as $u
    | .value | to_entries[] | .key as $k | .value[] | [$h, $u, $k, @base64] | @tsv' <<<"$json")
  check "every mango config value is at most 255 chars and every exec parses" test "$bad" -eq 0
}

if command -v nix >/dev/null; then
  mango_config_values
fi

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  echo -e "  ${RED}✗${NC} $entry"
done
exit 1
