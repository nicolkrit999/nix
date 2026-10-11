#!/usr/bin/env bash
# Test-infrastructure checker: run-tests.sh local log retention (pruning).
# Builds fake log trees in a throw-away XDG_STATE_HOME (never the real
# ~/.local/state/nix-tests) and runs `run-tests.sh --prune-only` on them, so the
# real entry point and templates/tests/lib/prune_logs.py are both exercised.
# No nix, no network; a few seconds. Sparse files make the 500 MB case free.
#
# Usage:
#   bash check-common-test-infra.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
RUN_TESTS="$REPO_ROOT/templates/tests/run-tests.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0
FAIL=0
declare -a FAILURES=()

# The defaults are what is under test: an inherited override would test something else.
unset NIX_TESTS_KEEP_RUNS NIX_TESTS_MAX_AGE_DAYS NIX_TESTS_MAX_MB

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/test-infra.XXXXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
REAL_BASE="$HOME/.local/state/nix-tests"

ok()  { PASS=$((PASS + 1)); printf "  ${GREEN}PASS${NC}  %s\n" "$1"; }
bad() { FAIL=$((FAIL + 1)); FAILURES+=("$1: $2"); printf "  ${RED}FAIL${NC}  %s - %s\n" "$1" "$2"; }

# ts AGE_SECONDS -> the run-tests.sh timestamp of "now - AGE_SECONDS" (portable: no GNU date -d).
ts() {
  python3 -c 'import sys, datetime as d; print((d.datetime.now() - d.timedelta(seconds=int(sys.argv[1]))).strftime("%Y%m%dT%H%M%S"))' "$1"
}

# new_state NAME -> a fresh XDG_STATE_HOME; sets BASE to its nix-tests dir.
new_state() {
  STATE="$TMP_ROOT/$1"
  BASE="$STATE/nix-tests"
  mkdir -p "$BASE"
  if [[ "$(cd "$BASE" && pwd -P)" == "$(cd "$REAL_BASE" 2>/dev/null && pwd -P)" ]]; then
    echo "refusing to run: $BASE is the real log directory" >&2
    exit 2
  fi
}

# mkrun AGE_SECONDS SHA [SIZE_MB] -> creates a run dir (one small log, plus a
# sparse SIZE_MB file) and prints its name.
mkrun() {
  local name size="${3:-0}"
  name="$(ts "$1")-$2"
  mkdir -p "$BASE/$name"
  echo "log of $name" >"$BASE/$name/fake.log"
  if [[ "$size" -gt 0 ]]; then
    python3 -c 'import sys; f = open(sys.argv[1], "wb"); f.truncate(int(sys.argv[2]) * 1024 * 1024); f.close()' \
      "$BASE/$name/big.bin" "$size"
  fi
  echo "$name"
}

latest_to() { ln -sfn "$BASE/$1" "$BASE/latest"; }

prune() {  # extra run-tests.sh flags; output in PRUNE_OUT, exit code in PRUNE_RC
  PRUNE_RC=0
  PRUNE_OUT="$(XDG_STATE_HOME="$STATE" bash "$RUN_TESTS" --prune-only "$@" 2>&1)" || PRUNE_RC=$?
}

exists()  { [[ -d "$BASE/$1" ]]; }
nruns()   { find "$BASE" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*T[0-9]*-*' | wc -l | tr -d ' '; }

expect_present() {  # LABEL NAME...
  local label="$1" n; shift
  for n in "$@"; do exists "$n" || { bad "$label" "$n was deleted ($PRUNE_OUT)"; return; }; done
  ok "$label"
}
expect_gone() {  # LABEL NAME...
  local label="$1" n; shift
  for n in "$@"; do ! exists "$n" || { bad "$label" "$n was NOT deleted ($PRUNE_OUT)"; return; }; done
  ok "$label"
}
expect_count() {  # LABEL N
  local got; got="$(nruns)"
  if [[ "$got" == "$2" && "$PRUNE_RC" -eq 0 ]]; then ok "$1"; else bad "$1" "expected $2 runs and exit 0, got $got runs, exit $PRUNE_RC ($PRUNE_OUT)"; fi
}

echo -e "\n${BOLD}run-tests.sh log retention${NC}  (state dirs under $TMP_ROOT)\n"

# ── 1. keep at most 20 runs (default NIX_TESTS_KEEP_RUNS) ────────────────────
new_state keep20
declare -a R=()
for i in $(seq 1 25); do R+=("$(mkrun $((i * 60)) "abc$(printf '%04d' "$i")")"); done  # R[0] newest
latest_to "${R[0]}"
prune
expect_count  "keep-20: 25 recent runs -> 20 left" 20
expect_gone   "keep-20: the 5 oldest are the ones deleted" "${R[@]:20:5}"
expect_present "keep-20: the 20 newest are kept" "${R[@]:0:20}"
prune
expect_count  "keep-20: a second run with 20 runs deletes nothing" 20

# ── 2. keep-20 never deletes the `latest` target ────────────────────────────
new_state keep20-latest
R=()
for i in $(seq 1 25); do R+=("$(mkrun $((i * 60)) "def$(printf '%04d' "$i")")"); done
latest_to "${R[24]}"   # latest -> the OLDEST run
prune
expect_present "keep-20: the oldest run survives when latest points to it" "${R[24]}"
expect_gone    "keep-20: the 4 next-oldest runs are deleted instead" "${R[@]:20:4}"
expect_count   "keep-20 + latest: 21 runs left" 21

# ── 3. 60-day age limit (default NIX_TESTS_MAX_AGE_DAYS) ─────────────────────
new_state age
DAY=86400
A_NEW="$(mkrun 60 aaa0001)"
A_59="$(mkrun $((59 * DAY)) aaa0002)"
A_61="$(mkrun $((61 * DAY)) aaa0003)"
A_400="$(mkrun $((400 * DAY)) aaa0004)"
latest_to "$A_NEW"
prune
expect_gone    "age: runs older than 60 days are deleted" "$A_61" "$A_400"
expect_present "age: a 59-day-old run and a fresh run are kept" "$A_59" "$A_NEW"

new_state age-latest
A_NEW="$(mkrun 60 bbb0001)"
A_90="$(mkrun $((90 * DAY)) bbb0002)"
A_91="$(mkrun $((91 * DAY)) bbb0003)"
latest_to "$A_90"
prune
expect_present "age: a 90-day-old run survives when latest points to it" "$A_90"
expect_gone    "age: the other old run is still deleted" "$A_91"

# ── 4. 500 MB total cap (default NIX_TESTS_MAX_MB), oldest first ─────────────
new_state size
S1="$(mkrun 60 ccc0001 200)"     # newest
S2="$(mkrun 120 ccc0002 200)"
S3="$(mkrun 180 ccc0003 200)"
S4="$(mkrun 240 ccc0004 200)"    # oldest; 800 MB in total
latest_to "$S1"
prune
expect_gone    "size: 800 MB -> the 2 oldest 200 MB runs are deleted" "$S4" "$S3"
expect_present "size: the 2 newest (400 MB <= 500) are kept" "$S1" "$S2"

new_state size-under
U1="$(mkrun 60 ddd0001 240)"
U2="$(mkrun 120 ddd0002 240)"    # 480 MB: under the cap
latest_to "$U1"
prune
expect_present "size: 480 MB in total is under the cap, nothing deleted" "$U1" "$U2"

new_state size-latest
L1="$(mkrun 60 eee0001 200)"
L2="$(mkrun 120 eee0002 200)"
L3="$(mkrun 180 eee0003 200)"   # oldest, latest points here
latest_to "$L3"
prune
expect_present "size: the latest target is kept even though it is the oldest" "$L3" "$L1"
expect_gone    "size: the next-oldest run is deleted instead" "$L2"

# ── 5. only run dirs run-tests.sh created are ever touched ───────────────────
new_state foreign
F_NEW="$(mkrun 60 fff0001)"
mkdir -p "$BASE/my-notes" "$BASE/20200101T000000-NOTHEX!" "$BASE/old-big"
python3 -c 'import sys; f = open(sys.argv[1], "wb"); f.truncate(900 * 1024 * 1024); f.close()' "$BASE/old-big/blob"
touch "$BASE/20200101T000000-abc1234.txt"             # a FILE with a run-like name
mkdir -p "$TMP_ROOT/elsewhere/keepme"
ln -s "$TMP_ROOT/elsewhere/keepme" "$BASE/20200102T000000-abc1234"   # a symlink with a run name
latest_to "$F_NEW"
prune
if [[ -d "$BASE/my-notes" && -d "$BASE/20200101T000000-NOTHEX!" && -f "$BASE/old-big/blob" \
      && -f "$BASE/20200101T000000-abc1234.txt" && -L "$BASE/20200102T000000-abc1234" \
      && -d "$TMP_ROOT/elsewhere/keepme" && "$PRUNE_RC" -eq 0 ]]; then
  ok "foreign: non-run dirs, files, symlinks and their targets are never deleted"
else
  bad "foreign" "something that run-tests.sh did not create was deleted or pruning failed ($PRUNE_OUT)"
fi
expect_present "foreign: 900 MB of foreign data does not evict a real run" "$F_NEW"
if [[ -L "$BASE/latest" ]]; then ok "foreign: the latest symlink itself is kept"; else bad "foreign" "latest symlink removed"; fi

# ── 6. --keep-logs skips pruning entirely ───────────────────────────────────
new_state keep-logs
R=()
for i in $(seq 1 25); do R+=("$(mkrun $((i * 60)) "ab$(printf '%05d' "$i")")"); done
K_OLD="$(mkrun $((70 * DAY)) ab99999 600)"
latest_to "${R[0]}"
prune --keep-logs
expect_count   "--keep-logs: 26 runs, 70-day-old and 600 MB, all kept" 26
expect_present "--keep-logs: the old big run is still there" "$K_OLD"
prune
expect_gone    "control: the same tree WITHOUT --keep-logs is pruned" "$K_OLD" "${R[@]:20:5}"

# ── 7. a malformed limit prunes nothing ─────────────────────────────────────
new_state bad-env
B_OLD="$(mkrun $((300 * DAY)) 0bad0001)"
B_NEW="$(mkrun 60 0bad0002)"
latest_to "$B_NEW"
PRUNE_RC=0
PRUNE_OUT="$(NIX_TESTS_MAX_AGE_DAYS=sixty XDG_STATE_HOME="$STATE" bash "$RUN_TESTS" --prune-only 2>&1)" || PRUNE_RC=$?
if [[ "$PRUNE_RC" -ne 0 ]] && exists "$B_OLD"; then
  ok "bad env: NIX_TESTS_MAX_AGE_DAYS=sixty fails loudly and deletes nothing"
else
  bad "bad env" "exit $PRUNE_RC, old run present: $(exists "$B_OLD" && echo yes || echo no) ($PRUNE_OUT)"
fi

# ── 8. the real log directory was never used ─────────────────────────────────
if [[ -d "$REAL_BASE" ]] && find "$REAL_BASE" -maxdepth 1 -name '*-abc0001' | grep -q .; then
  bad "isolation" "a fixture run appeared in the real $REAL_BASE"
else
  ok "isolation: the real ~/.local/state/nix-tests was not touched"
fi

echo
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi
echo -e "${RED}${BOLD}$FAIL of $((PASS + FAIL)) checks failed:${NC}"
for f in "${FAILURES[@]}"; do echo -e "  ${RED}✗${NC} $f"; done
exit 1
