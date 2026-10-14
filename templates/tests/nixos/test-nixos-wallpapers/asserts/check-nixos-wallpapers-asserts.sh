#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
SCEN="$DIR/01-scenario-wallpapers-asserts.nix"
PASS=0; FAIL=0
FAILURES=()

ev() { nix eval --raw --impure --file "$SCEN" "$1" 2>"$ERR"; }

expect_ok() {
  local attr="$1" label="$2" out
  if out=$(ev "$attr"); then
    if [[ "$out" == ok ]]; then echo "PASS  $label"; ((PASS++)); return; fi
    echo "FAIL  $label ($out)"; FAILURES+=("$label")
  else
    echo "FAIL  $label (eval error: $(grep -m1 -E 'error: .+' "$ERR" | cut -c1-160))"; FAILURES+=("$label")
  fi
  ((FAIL++))
}

expect_error() {
  local attr="$1" label="$2" msg="$3"
  if ev "$attr" >/dev/null; then
    echo "FAIL  $label (evaluated, expected failure)"; FAILURES+=("$label"); ((FAIL++))
  elif grep -qF "$msg" "$ERR"; then
    echo "PASS  $label"; ((PASS++))
  else
    echo "FAIL  $label (failed without message '$msg')"; FAILURES+=("$label"); ((FAIL++))
  fi
}

expect_bash_n() {
  local attr="$1" label="$2" text
  if text=$(ev "$attr") && bash -n <<<"$text" 2>"$ERR"; then
    echo "PASS  $label"; ((PASS++))
  else
    echo "FAIL  $label"; FAILURES+=("$label"); ((FAIL++))
  fi
}

ERR=$(mktemp); trap 'rm -f "$ERR"' EXIT

echo "=== mk-wallpaperd asserts (synthetic) ==="
expect_ok    control    "valid targets (DP-1, desc:, *) evaluate"
expect_error dupTarget  "duplicate targetMonitor is rejected" "wallpapers: duplicate targetMonitor"
expect_error dollarParen 'targetMonitor "$(hostname)" is rejected' "not a shell substitution"
expect_error backtick   'targetMonitor with backticks is rejected' "not a shell substitution"

echo "=== needsAwww / needsMpv / runtime inputs (synthetic) ==="
for k in still video gif mixed empty inputsStill inputsVideo inputsMixed; do
  expect_ok "matrix.$k" "matrix: $k"
done

for host in nixos-desktop nixos-laptop; do
  echo "=== real host $host ==="
  for k in nonEmpty hashes uniqueTargets specCount needsAwww needsMpv mangoNeedsRandr hyprNeedsSocat niriNoWmTools mpvExtraOnce niriArgvShape; do
    expect_ok "real.$host.$k" "$host: $k"
  done
  expect_bash_n "real.$host.launcherText" "$host: hyprland launcher passes bash -n"
  expect_bash_n "real.$host.mangoLauncherText" "$host: mango launcher passes bash -n"
done

echo "=== wallpapers = [ ] ==="
expect_ok fallbackConstantsSet  "fallback wallpaper constant is set (URL + nix32 sha256)"
expect_ok emptyWmNoStartup      "WMs emit no wallpaperd/awww startup"
expect_ok emptyHyprlockFallback "hyprlock background uses the fallback constant"
expect_ok emptyGnome            "gnome-main uses the fallback constant"
expect_ok emptyKde              "kde-main evaluates"
expect_ok emptyKscreenlocker    "kde-kscreenlocker uses the fallback constant"

echo "=== non-empty list without a \"*\" entry ==="
expect_ok noStarPrimary             "primaryWallpaper is the first entry"
expect_ok noStarHyprlock            "hyprlock: per-monitor backgrounds for both entries, catch-all is the first entry"
expect_ok noStarGnome               "gnome-main uses the first entry (not 2nd, not fallback)"
expect_ok noStarKscreenlocker       "kde-kscreenlocker uses the first entry (not 2nd, not fallback)"
expect_ok noStarStylixReadsPrimary  "stylix-nixos.nix reads primaryWallpaper (no own selection logic)"
expect_ok starSecondPrimary         "a \"*\" entry that is not first still wins"

echo "=== primary entry with only videoURL/gifURL (wallpaperURL empty) ==="
expect_ok videoOnlyPrimaryIsPrimary   "fixture: the primary entry has an empty wallpaperURL and a videoURL"
expect_ok videoOnlyGnome              "gnome-main resolves to the fallback wallpaper"
expect_ok videoOnlyKdeEveryEntry      "kde-main: video-only and gif-only entries use the fallback, the explicit entry keeps its own"
expect_ok videoOnlyKscreenlocker      "kde-kscreenlocker resolves to the fallback wallpaper"
expect_ok videoOnlyStylix             "stylix-nixos (nixos-laptop twin) image is the fallback wallpaper"
expect_ok explicitStylixKeepsOwn      "control: stylix-nixos with an explicit wallpaperURL keeps its own url"
expect_ok videoOnlyMutantGnomeFails   "mutation: a gnome result without the fallback is rejected"
expect_ok videoOnlyMutantKdeFails     "mutation: a kde list without the fallback is rejected"
expect_ok videoOnlyMutantStylixFails  "mutation: a stylix image without the fallback is rejected"

echo "=== hyprlock per-monitor backgrounds ==="
expect_ok lockDesktop                "desktop-like (DP-1, DP-2, *): own wallpaper per monitor plus a lower-z catch-all with *"
expect_ok lockDesktopDistinct        "desktop-like: three distinct wallpaper files"
expect_ok lockControlRevertedFails   "control: a single '*' background does not satisfy the desktop-like expectation"
expect_ok lockControlRevertedHasNoSpecific "control: desktop-like emits more than one background"
expect_ok lockLaptopLike             "laptop-like (eDP-1, *): eDP-1 background plus catch-all"
expect_ok lockStarOnly               "only a * entry: single catch-all background"
expect_ok lockDescVideo              "desc: monitor passes through; video-only entries emit no background; catch-all is the first static"
expect_ok lockNoVideoPaths           "video-only entries never reach hyprlock"
expect_ok lockRealLaptop             "real nixos-laptop: eDP-1 background uses its own wallpaper, catch-all uses *"
expect_ok lockRealLaptopNotStar      "real nixos-laptop: eDP-1 wallpaper differs from * (control for the above)"

echo ""
echo "passed: $PASS  failed: $FAIL"
((FAIL == 0))
