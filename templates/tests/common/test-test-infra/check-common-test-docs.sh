#!/usr/bin/env bash
# Docs-sync guard: docs_sync.py on the real repo, then negative controls on a
# scratch copy (tracked templates/tests + docs, its own git index) in a temp dir.
# No nix, no network; a few seconds.
#
# Usage:
#   bash check-common-test-docs.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
GUARD="$DIR/docs_sync.py"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0
FAIL=0
declare -a FAILURES=()
ok()  { PASS=$((PASS + 1)); printf "  ${GREEN}PASS${NC}  %s\n" "$1"; }
bad() { FAIL=$((FAIL + 1)); FAILURES+=("$1: $2"); printf "  ${RED}FAIL${NC}  %s - %s\n" "$1" "$2"; }

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/test-docs.XXXXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

OV=Documentation/usage/tests/tests-overview.md
WF=Documentation/usage/ci/build-workflows.md

echo -e "\n${BOLD}docs-sync guard: real repo${NC}\n"
REAL_OUT="$(python3 -B "$GUARD" --repo "$REPO_ROOT" 2>&1)"; REAL_RC=$?
echo "$REAL_OUT"
if [[ $REAL_RC -eq 0 ]]; then
  ok "real repo: docs match discovery"
else
  bad "real repo" "docs drifted from discovery - fix every FAIL line above (file:line)"
fi

# ── pristine scratch copy ────────────────────────────────────────────────────
PRISTINE="$TMP_ROOT/pristine"
mkdir -p "$PRISTINE"
( cd "$REPO_ROOT" && git ls-files -z -- templates/tests 'Documentation/*.md' '.claude/skills/*.md' \
    '.claude/agents/*.md' CLAUDE.md | while IFS= read -r -d '' f; do [[ -e "$f" ]] && printf '%s\0' "$f"; done \
  | tar --null -T - -cf - ) | tar -xf - -C "$PRISTINE"
git -C "$PRISTINE" init -q
git -C "$PRISTINE" add -A

# fresh NAME -> a copy of the pristine scratch in $S
fresh() { S="$TMP_ROOT/$1"; cp -a "$PRISTINE" "$S"; }
guard() { OUT="$(python3 -B "$GUARD" --repo "$S" 2>&1)"; RC=$?; }

# expect_fail LABEL REGEX: the guard must exit non-zero and print a FAIL line matching REGEX.
expect_fail() {
  guard
  if [[ $RC -ne 0 ]] && grep -E "FAIL  .*$2" <<<"$OUT" >/dev/null; then
    ok "$1"
  else
    bad "$1" "guard exit $RC, no FAIL line matching /$2/: $OUT"
  fi
}
# line_of FILE REGEX -> first matching line number in $S/FILE
line_of() { grep -nE "$2" "$S/$1" | head -1 | cut -d: -f1; }

echo -e "\n${BOLD}negative controls${NC}  (scratch copies under $TMP_ROOT)\n"

fresh baseline
guard
if [[ $RC -eq 0 ]]; then ok "baseline: the unmodified scratch copy passes"; else bad "baseline" "$OUT"; fi

fresh missing-row
L="$(line_of "$OV" '^\| `common-test-infra` ')"
sed -i "${L}d" "$S/$OV"
expect_fail "missing row: deleting the common-test-infra row" "$OV:[0-9]+: no table row for \`common-test-infra\`"

fresh extra-row
L="$(line_of "$OV" '^\| `nixos-arch-compat` ')"
sed -i "${L}a | \`nixos-ghost\` | \`test-ghost\` | nixos | x | x | x |" "$S/$OV"
expect_fail "extra row: a row for a test that does not exist" "$OV:$((L + 1)): row for \`nixos-ghost\`"

fresh wrong-group-cell
L="$(line_of "$OV" '^\| `nixos-waybar-configs` ')"
sed -i "${L}s/| nixos-b |/| nixos |/" "$S/$OV"
expect_fail "wrong CI group cell in tests-overview" "$OV:$L: \`nixos-waybar-configs\` CI group cell"

fresh wrong-count
L="$(line_of "$OV" 'tests are discovered today')"
sed -i -E "${L}s/[0-9]+ tests are discovered/999 tests are discovered/" "$S/$OV"
expect_fail "wrong count: total in the count sentence" "$OV:$L: count sentence says 999 tests"

fresh wrong-platform-count
L="$(line_of "$OV" 'tests are discovered today')"
sed -i -E "${L}s/([0-9]+) darwin/77 darwin/" "$S/$OV"
expect_fail "wrong count: per-platform figure in the count sentence" "$OV:$L: count sentence .*77 darwin"

fresh readme-md
touch "$S/templates/tests/nixos/test-arch-compat/README.md"; git -C "$S" add -A
expect_fail "README.md inside a test folder" "templates/tests/nixos/test-arch-compat/README.md: README.md is forbidden"

fresh wrong-readme-name
git -C "$S" mv templates/tests/common/test-test-infra/test-test-infra-readme.md \
  templates/tests/common/test-test-infra/infra-readme.md
expect_fail "wrong readme name (infra-readme.md)" "templates/tests/common/test-test-infra/: missing test-test-infra-readme.md"

fresh two-readmes
cp "$S/templates/tests/common/test-test-infra/test-test-infra-readme.md" "$S/templates/tests/common/test-test-infra/old-readme.md"
git -C "$S" add -A
expect_fail "a second *-readme.md in one folder" "test-test-infra/old-readme.md: unexpected readme name"

fresh untracked
touch "$S/templates/tests/common/test-test-infra/forgotten.nix"
expect_fail "untracked file under templates/tests" "test-test-infra/forgotten.nix: untracked .*git add"

fresh new-test-no-docs
mkdir -p "$S/templates/tests/common/test-zz-new"
printf '#!/usr/bin/env bash\nexit 0\n' >"$S/templates/tests/common/test-zz-new/check-zz.sh"
echo '# test-zz-new' >"$S/templates/tests/common/test-zz-new/test-zz-new-readme.md"
echo '## Run' >>"$S/templates/tests/common/test-zz-new/test-zz-new-readme.md"
git -C "$S" add -A
guard
if [[ $RC -ne 0 ]] && grep -q "no table row for \`common-zz-new\`" <<<"$OUT" \
   && grep -q "count sentence says" <<<"$OUT" && grep -qE "$WF:[0-9]+: row \`common\` says [0-9]+ tests" <<<"$OUT"; then
  ok "new test folder with only its readme: overview row, count sentence and §12.2 count all flagged"
else
  bad "new test, no docs" "guard exit $RC: $OUT"
fi

fresh wf-member
L="$(line_of "$WF" '^\| `nixos-b` ')"
sed -i "${L}s/, borg-backup-config[^,|]*//" "$S/$WF"
expect_fail "§12.2: a group member dropped from an explicit row" "$WF:$L: row \`nixos-b\` does not name \`nixos-borg-backup-config\`"

fresh wf-default-count
L="$(line_of "$WF" '^\| `nixos` \| default for')"
sed -i -E "${L}s/\(([0-9]+) tests\)/(99 tests)/" "$S/$WF"
expect_fail "§12.2: wrong count in a 'default for' row" "$WF:$L: row \`nixos\` says 99 tests"

fresh wf-group-moved
printf 'group = solo\n' >"$S/templates/tests/nixos/test-spec-school/test.conf"; git -C "$S" add -A
expect_fail "§12.2: a test.conf group with no table row" "$WF:[0-9]+: §12.2 table has no row for CI group \`solo\`"

fresh wf-wrong-row
L="$(line_of "$WF" '^\| `heavy-b` ')"
sed -i "${L}s/\`nixos-wallpaperd-runtime\`/\`nixos-wallpaperd-runtime\`, \`nixos-spec-school\`/" "$S/$WF"
expect_fail "§12.2: a test listed under a group it does not belong to" "$WF:$L: row \`heavy-b\` names \`nixos-spec-school\`"

fresh stale-ref
echo 'See templates/tests/nixos/test-gone/check-gone.sh and run-tests.sh --only nixos-gone.' >>"$S/CLAUDE.md"
L="$(wc -l <"$S/CLAUDE.md" | tr -d ' ')"
guard
if [[ $RC -ne 0 ]] && grep -q "CLAUDE.md:$L: references templates/tests/nixos/test-gone" <<<"$OUT" \
   && grep -q "CLAUDE.md:$L: \`run-tests.sh --only nixos-gone\` does not resolve" <<<"$OUT"; then
  ok "stale reference: a deleted test's path and --only name in a doc"
else
  bad "stale reference" "guard exit $RC: $OUT"
fi

fresh no-run-section
sed -i 's/^## Run/## Usage/' "$S/templates/tests/common/test-test-infra/test-test-infra-readme.md"
expect_fail "readme without a ## Run section" "test-test-infra-readme.md:1: no \`## Run\` section"

fresh stale-title
sed -i '1s/.*/# test-old-infra/' "$S/templates/tests/common/test-test-infra/test-test-infra-readme.md"
expect_fail "readme title not the folder name (stale after a rename)" "test-test-infra-readme.md:1: title is '# test-old-infra'"

fresh script-renamed
git -C "$S" mv templates/tests/common/test-test-infra/check-common-test-docs.sh \
  templates/tests/common/test-test-infra/check-common-test-docsync.sh
expect_fail "readme names a check script that was renamed" "test-test-infra-readme.md:[0-9]+: names check-common-test-docs.sh"

fresh wrong-folder-cell
L="$(line_of "$OV" '^\| `nixos-arch-compat` ')"
sed -i "${L}s/| \`test-arch-compat\` |/| \`test-arch-compat-old\` |/" "$S/$OV"
expect_fail "wrong folder cell in tests-overview" "$OV:$L: \`nixos-arch-compat\` folder cell"

fresh wrong-section
L="$(line_of "$OV" '^\| `nixos-arch-compat` ')"
ROW="$(grep -E '^\| `darwin-home-paths` ' "$S/$OV")"
sed -i "/^| \`darwin-home-paths\` /d" "$S/$OV"
sed -i "${L}a $ROW" "$S/$OV"
expect_fail "a darwin row inside the NixOS table" "$OV:$((L + 1)): \`darwin-home-paths\` is a darwin test but sits in the nixos table"

fresh duplicate-row
L="$(line_of "$OV" '^\| `nixos-arch-compat` ')"
sed -i "${L}p" "$S/$OV"
expect_fail "duplicate row in tests-overview" "$OV:$((L + 1)): \`nixos-arch-compat\` has 2 rows"

fresh timeout-changed
printf 'timeout = 15\n' >"$S/templates/tests/nixos/test-spec-school/test.conf"; git -C "$S" add -A
L="$(line_of "$OV" '^\| `nixos-spec-school` ')"
expect_fail "test.conf timeout changed, overview Runtime cell has no cap" "$OV:$L: \`nixos-spec-school\` Runtime cell states cap none, test.conf timeout is 15"

fresh stale-cap
L="$(line_of "$OV" '^\| `nixos-arch-compat` ')"
sed -i "${L}s/cap 30 min/cap 25 min/" "$S/$OV"
expect_fail "overview Runtime cell states a stale cap" "$OV:$L: \`nixos-arch-compat\` Runtime cell states cap \[25\]"

fresh wf-stale-cap
L="$(line_of "$WF" '^\| `heavy-b` ')"
sed -i "${L}s/cap 20 each/cap 25 each/" "$S/$WF"
expect_fail "§12.2: a stale timeout cap in a group row" "$WF:$L: row \`heavy-b\` states caps \[25\]"

fresh fast-args
printf 'fast_args = --fast\n' >"$S/templates/tests/nixos/test-spec-school/test.conf"; git -C "$S" add -A
L="$(line_of "$OV" '^\| `--fast` ')"
expect_fail "test.conf fast_args added, --fast row not updated" "$OV:$L: \`--fast\` row names"

fresh legs-list
L="$(line_of "$OV" 'Linux groups today:')"
sed -i "${L}s/\`heavy-b\`, //" "$S/$OV"
expect_fail "CI legs sentence missing a group" "$OV:$L: CI legs listed as linux"

fresh wf-stale-group
L="$(line_of "$WF" '^\| `heavy-b` ')"
sed -i "${L}a | \`ghost\` | nixos-ghost | 1 s | x | x | x |" "$S/$WF"
expect_fail "§12.2: a row for a group no test has" "$WF:$((L + 1)): §12.2 lists group \`ghost\`"

# Rename of a nix-tests harness folder without any docs update.
fresh harness-rename
git -C "$S" mv templates/tests/nixos/test-custom-shells templates/tests/nixos/test-custom-shells2
guard
if [[ $RC -ne 0 ]] && grep -q "missing test-custom-shells2-readme.md" <<<"$OUT" \
   && grep -q "no table row for \`nixos-custom-shells2\`" <<<"$OUT" \
   && grep -q "row for \`nixos-custom-shells\`, which discovery does not know" <<<"$OUT" \
   && grep -q "row \`harness\` does not name \`nixos-custom-shells2\`" <<<"$OUT" \
   && grep -q "row \`harness\` names \`custom-shells\`, which is no discovered test" <<<"$OUT"; then
  ok "harness folder renamed, no docs: readme name, overview rows and §12.2 harness row all flagged"
else
  bad "harness rename" "guard exit $RC: $OUT"
fi

# Deletion of a darwin test without any docs update.
fresh darwin-delete
git -C "$S" rm -rqf templates/tests/darwin/test-darwin-home-paths
L="$(line_of "$WF" '^\| `darwin` ')"
guard
if [[ $RC -ne 0 ]] && grep -q "count sentence says .* 3 darwin" <<<"$OUT" \
   && grep -q "row for \`darwin-home-paths\`, which discovery does not know" <<<"$OUT" \
   && grep -q "$WF:$L: row \`darwin\` names \`darwin-home-paths\`, which is no discovered test" <<<"$OUT"; then
  ok "darwin test deleted, no docs: count sentence, overview row and §12.2 darwin row all flagged"
else
  bad "darwin delete" "guard exit $RC: $OUT"
fi

echo
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}$FAIL of $((PASS + FAIL)) checks failed:${NC}"
for f in "${FAILURES[@]}"; do echo -e "  ${RED}✗${NC} $f"; done
exit 1
