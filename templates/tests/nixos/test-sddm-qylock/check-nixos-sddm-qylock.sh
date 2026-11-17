#!/usr/bin/env bash
# Usage:
#   bash check-nixos-sddm-qylock.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCEN="$DIR/01-scenario-sddm-qylock.nix"

BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
ok() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS + 1)); }
bad() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo ""
echo -e "${BOLD}=== sddm-qylock (real theme builds inspected, eval errors matched) ===${NC}"

if ! nix eval --json --impure --file "$SCEN" --apply 'x: { inherit (x) matrix fixtures themesSrc assetsDir tools errIds; }' >"$WORK/meta.json" 2>"$WORK/err"; then
  cat "$WORK/err" >&2
  echo -e "${RED}EVAL ERROR: $(grep -E 'error:' "$WORK/err" | head -3 | tr '\n' ' ')${NC}"
  exit 1
fi
J() { jq -r "$1" "$WORK/meta.json"; }
MAGICK=$(J .tools.magick)
THEMES=$(J .themesSrc)

BUILT=(default h24 vid-explicit vid-auto-black vid-auto-white img-explicit terraria-opt terraria-plain nier-12h terraria-12h)
ATTRS=(); for id in "${BUILT[@]}"; do ATTRS+=("pkg.$id"); done
ATTRS+=(pkg.video-black pkg.video-white pkg.image-grey pkg.upstream-themes)
if ! nix build --impure --file "$SCEN" --no-link --json --keep-going "${ATTRS[@]}" >"$WORK/build.json" 2>"$WORK/build.err"; then
  tail -n 15 "$WORK/build.err" >&2
  echo -e "${RED}BUILD ERROR: scenario derivations did not build${NC}"
  exit 1
fi
declare -A OUT
for id in "${BUILT[@]}"; do
  OUT[$id]=$(nix build --impure --file "$SCEN" --no-link --print-out-paths "pkg.$id" 2>>"$WORK/build.err")
done
if [ ! -f "$THEMES/pixel-hollowknight/Main.qml" ]; then
  echo -e "${RED}SETUP ERROR: upstream qylock themes not realised at $THEMES${NC}"
  exit 1
fi
T() { echo "${OUT[$1]}/share/sddm/themes/$2"; }
VBLACK=$(J .fixtures.\"video-black\"); VWHITE=$(J .fixtures.\"video-white\"); IGREY=$(J .fixtures.\"image-grey\")
dim_of() { grep -o 'color: "black"; opacity: [0-9.]*' "$1/BackgroundVideo.qml" | tail -n1 | sed 's/.*opacity: //'; }
mean_of() { "$MAGICK" "$1" -format '%[fx:mean]' info:; }

echo -e "${BOLD}-- theme value and package name${NC}"
check "default: sddm.theme = pixel-hollowknight" "[ \"\$(J .matrix.default.theme)\" = pixel-hollowknight ]"
check "default: package name = sddm-qylock-pixel-hollowknight" "[ \"\$(J .matrix.default.pkgName)\" = sddm-qylock-pixel-hollowknight ]"
check "nier: sddm.theme = nier-automata" "[ \"\$(J '.matrix.\"img-explicit\".theme')\" = nier-automata ]"

echo -e "${BOLD}-- clock format (pixel-hollowknight)${NC}"
HK=$(T default pixel-hollowknight)
check "12h default: Main.qml has hh:mm AP" "grep -q '\"hh:mm AP\"' '$HK/Main.qml'"
check "12h default: Main.qml has no HH:mm" "! grep -q '\"HH:mm\"' '$HK/Main.qml'"
check "control: the upstream theme does contain HH:mm" "grep -q '\"HH:mm\"' '$THEMES/pixel-hollowknight/Main.qml'"
check "use24HourClock=true: HH:mm kept" "grep -q '\"HH:mm\"' '$(T h24 pixel-hollowknight)/Main.qml'"
check "use24HourClock=true: no hh:mm AP" "! grep -q 'hh:mm AP' '$(T h24 pixel-hollowknight)/Main.qml'"
check "no background: bg.mp4 is the upstream file" "cmp -s '$HK/bg.mp4' '$THEMES/pixel-hollowknight/bg.mp4'"
check "no background: no scrim Rectangle appended" "[ -z \"\$(dim_of '$HK')\" ]"

echo -e "${BOLD}-- custom video background${NC}"
VE=$(T vid-explicit pixel-hollowknight)
check "bg.mp4 replaced byte-identically with the custom video" "cmp -s '$VE/bg.mp4' '$VBLACK'"
check "custom video differs from the upstream bg.mp4" "! cmp -s '$VE/bg.mp4' '$THEMES/pixel-hollowknight/bg.mp4'"
check "explicit backgroundDim 0.4: scrim opacity 0.4" "[ \"\$(dim_of '$VE')\" = 0.4 ]"
check "scrim is a full-size black Rectangle" "grep -q 'Rectangle { anchors.fill: parent; color: \"black\"; opacity: 0.4 }' '$VE/BackgroundVideo.qml'"
DB=$(dim_of "$(T vid-auto-black pixel-hollowknight)"); DW=$(dim_of "$(T vid-auto-white pixel-hollowknight)")
echo "  auto dim: black video=$DB white video=$DW"
check "auto dim on a black video is the weakest step (0)" "[ '$DB' = 0 ]"
check "auto dim on a white video is stronger than on a black one" "[ -n '$DW' ] && awk -v w='$DW' -v b='$DB' 'BEGIN { exit !(w > b) }'"
check "auto dim on a white video is one of the ladder steps >= 0.5" "awk -v w='$DW' 'BEGIN { exit !(w >= 0.5 && w <= 0.8) }'"

echo -e "${BOLD}-- custom image background (nier-automata, plain filename in assetsDir)${NC}"
NI=$(T img-explicit nier-automata)
SRC_M=$(mean_of "$IGREY"); OUT_M=$(mean_of "$NI/bg.png"); UP_M=$(mean_of "$THEMES/nier-automata/bg.png")
echo "  mean luminance: source=$SRC_M baked=$OUT_M upstream=$UP_M"
check "bg.png is darker than the source image" "awk -v o='$OUT_M' -v s='$SRC_M' 'BEGIN { exit !(o < s) }'"
check "bg.png luminance is about half of the source (dim 0.5)" "awk -v o='$OUT_M' -v s='$SRC_M' 'BEGIN { d = o - s * 0.5; exit !(d < 0.03 && d > -0.03) }'"
check "bg.png is not the upstream image" "! cmp -s '$NI/bg.png' '$THEMES/nier-automata/bg.png'"
check "24h theme without HH:mm is untouched by the clock sed" "! grep -q 'hh:mm AP' '$NI/Main.qml'"

echo -e "${BOLD}-- themeOptions${NC}"
check "terraria.backgroundMode=time lands in theme.conf" "grep -qx 'background_mode=time' '$(T terraria-opt terraria)/theme.conf'"
check "control: without the option theme.conf keeps the upstream mode" "grep -qx 'background_mode=random' '$(T terraria-plain terraria)/theme.conf'"
check "control: upstream mode is not time" "! grep -qx 'background_mode=time' '$THEMES/terraria/theme.conf'"

echo -e "${BOLD}-- 12h clock on themes without HH:mm (rewrite skipped, build succeeds)${NC}"
for pair in nier-12h:nier-automata terraria-12h:terraria; do
  id=${pair%%:*}; theme=${pair##*:}
  D=$(T "$id" "$theme")
  check "$theme, use24HourClock=false: builds and Main.qml is byte-identical to upstream" "cmp -s '$D/Main.qml' '$THEMES/$theme/Main.qml'"
  check "$theme, use24HourClock=false: no hh:mm AP inserted" "! grep -q 'hh:mm AP' '$D/Main.qml'"
  check "control: upstream $theme has no \"HH:mm\" clock" "! grep -q '\"HH:mm\"' '$THEMES/$theme/Main.qml'"
  drv=$(nix path-info --impure --derivation "${OUT[$id]}" 2>/dev/null)
  nix log "$drv" >"$WORK/log.$id" 2>&1 || true
  check "$theme: build log has the 'clock left as the theme ships it' notice" "grep -qF 'no \"HH:mm\" clock in $theme/Main.qml, clock left as the theme ships it' '$WORK/log.$id'"
done
check "control: a theme with HH:mm (default) has no 'clock left' notice" "! nix log \"\$(nix path-info --derivation '${OUT[default]}')\" 2>&1 | grep -q 'clock left as the theme ships it'"

echo -e "${BOLD}-- eval errors${NC}"
declare -A WANT=(
  [kind-video-theme-image]="uses a video background (bg.mp4); \`background\` must be a video"
  [kind-image-theme-video]="uses a image background (bg.png); \`background\` must be a picture"
  [unsupported-genshin]="theme 'Genshin' has no single bg.mp4/bg.png/background.png"
  [missing-file]="missing-file.mp4 not found in users/"
  [absolute-path]="/etc/hostname: absolute paths outside the store are impure"
)
for id in "${!WANT[@]}"; do
  rc=0
  nix eval --raw --impure --file "$SCEN" "err.$id" >/dev/null 2>"$WORK/err.$id" || rc=$?
  check "$id: eval fails" "[ $rc -ne 0 ]"
  if grep -qF -- "${WANT[$id]}" "$WORK/err.$id"; then ok "$id: message matches"; else bad "$id: message matches"; fi
done
check "control: the error-free default scenario evaluates" "nix eval --raw --impure --file '$SCEN' matrix.default.drvPath >/dev/null 2>&1"

echo ""
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
