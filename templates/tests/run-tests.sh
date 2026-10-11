#!/usr/bin/env bash
# run-tests.sh - run the templates/tests suite locally.
# Run from anywhere; the script resolves the repo root automatically.
#
# Usage:
#   bash templates/tests/run-tests.sh [--parallel] [--fast] [--only NAME[,NAME...]] [--list]
#                                     [--keep-logs] [--prune-only]
#
#   --parallel   run all tests concurrently instead of sequentially (faster,
#                but if nicol-nas is offline, parallel nix processes will each
#                print "could not resolve nicol-nas" retry warnings - harmless,
#                but noisy; prefer sequential when the NAS is unreachable)
#   --fast       pass each test's `fast_args` from its test.conf (arch-compat:
#                --fast, skipping the specialisation batches)
#   --only X     run only these tests. X is a test name (see --list), a folder
#                name, or an unambiguous suffix: `--only arch-compat` works.
#                The HANDOFF.md of a failed CI run prints the exact --only line.
#   --list       print every discovered test (name, CI group, timeout,
#                platforms, kind, folder) and exit
#   --keep-logs  do not prune old log runs at the start of this run
#   --prune-only prune old log runs (see below) and exit without running tests
#
# There is NO registry to edit. Tests are discovered by
# templates/tests/lib/discover.py: every folder under
# templates/tests/{nixos,common,darwin}/ with a check-*.sh (run with bash) or
# *_test.nix files (run with the nix-tests harness) is a test; a folder with
# neither makes discovery FAIL. CI (tests-nixos.yml / tests-darwin.yml) uses the
# same discovery, so adding a folder is all it takes.
#
# Every test runs through .github/scripts/run-test.py, exactly as in CI: one
# complete log per test (header with commit / nixpkgs rev, full output, the full
# stderr of every failing nix call, footer with exit code and duration) under
#   ${XDG_STATE_HOME:-~/.local/state}/nix-tests/<timestamp>-<sha>/   (+ `latest` symlink)
# - outside the repo and not in /tmp (a tmpfs here), so it survives a reboot.
# Locally all platforms run (darwin tests are pure evals and work on Linux).
#
# Log retention: at the start of every run (not with --list, skipped with
# --keep-logs) templates/tests/lib/prune_logs.py deletes old runs, oldest first:
#   NIX_TESTS_KEEP_RUNS=20      keep at most this many runs
#   NIX_TESTS_MAX_AGE_DAYS=60   delete runs older than this (age = name timestamp)
#   NIX_TESTS_MAX_MB=500        delete runs until all runs total at most this
# (0 disables a limit). It only deletes <timestamp>-<sha> directories that this
# script created, and never the run `latest` points to. Covered by
# templates/tests/common/test-test-infra/.

set -uo pipefail

PARALLEL=0
FAST=""
ONLY=""
LIST=0
KEEP_LOGS=0
PRUNE_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --parallel) PARALLEL=1 ;;
    --fast)     FAST="--fast" ;;
    --only)     ONLY="${2:-}"; shift ;;
    --only=*)   ONLY="${1#--only=}" ;;
    --list)     LIST=1 ;;
    --keep-logs)  KEEP_LOGS=1 ;;
    --prune-only) PRUNE_ONLY=1 ;;
    -h|--help)  sed -n '2,/^set -uo pipefail/p' "$0" | sed '$d'; exit 0 ;;
    *) echo "run-tests.sh: unknown argument '$1' (see --help)" >&2; exit 2 ;;
  esac
  shift
done

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
DISCOVER="templates/tests/lib/discover.py"
RUN_TEST=".github/scripts/run-test.py"

if [[ $LIST -eq 1 ]]; then
  exec python3 -B "$DISCOVER" --list ${ONLY:+--only "$ONLY"}
fi

STATE_BASE="${XDG_STATE_HOME:-$HOME/.local/state}/nix-tests"

# Log retention (see the header). Runs before this run's directory exists, so
# it can never touch it; prune_logs.py never deletes the `latest` target.
if [[ $KEEP_LOGS -eq 1 ]]; then
  echo -e "${DIM}--keep-logs: old log runs in $STATE_BASE are not pruned${NC}"
  [[ $PRUNE_ONLY -eq 1 ]] && exit 0
else
  prc=0
  python3 -B templates/tests/lib/prune_logs.py "$STATE_BASE" || prc=$?
  if [[ $PRUNE_ONLY -eq 1 ]]; then
    exit "$prc"
  fi
  if [[ $prc -ne 0 ]]; then
    echo -e "${RED}log pruning failed (exit $prc) - continuing without pruning${NC}" >&2
  fi
fi

# name<TAB>category per selected test; discovery errors abort here, loudly.
if ! SELECTED_JSON="$(python3 -B "$DISCOVER" --json ${ONLY:+--only "$ONLY"})"; then
  exit 2
fi
SELECTED="$(python3 -B -c 'import json,sys; [print(t["name"]+"\t"+t["category"]) for t in json.load(sys.stdin)]' \
  <<<"$SELECTED_JSON")"
NAMES=()
LABELS=()
while IFS=$'\t' read -r name cat; do
  [[ -z "$name" ]] && continue
  case "$cat" in nixos) plat="NixOS " ;; darwin) plat="Darwin" ;; *) plat="Common" ;; esac
  NAMES+=("$name")
  LABELS+=("$plat · $name")
done <<<"$SELECTED"
if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "No tests selected." >&2
  exit 2
fi

LOG_DIR="$STATE_BASE/$(date +%Y%m%dT%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
mkdir -p "$LOG_DIR"
ln -sfn "$LOG_DIR" "$STATE_BASE/latest"

STATUSES=()

# ─────────────────────────────────────────────────────────────────────────────
run_sequential() {
  local i rc
  for i in "${!NAMES[@]}"; do
    echo -e "\n${BOLD}━━━ ${LABELS[$i]} ━━━${NC}"
    rc=0
    python3 -B "$RUN_TEST" --test "${NAMES[$i]}" --log-dir "$LOG_DIR" $FAST || rc=$?
    STATUSES+=("$rc")
    if [[ $rc -eq 0 ]]; then echo -e "${GREEN}✓ passed${NC}"; else echo -e "${RED}✗ failed (exit $rc)${NC}"; fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
run_parallel() {
  local -a pids=()
  local i rc
  for i in "${!NAMES[@]}"; do
    echo -e "${DIM}⏳  ${LABELS[$i]}${NC}"
    python3 -B "$RUN_TEST" --test "${NAMES[$i]}" --log-dir "$LOG_DIR" --quiet $FAST &
    pids+=("$!")
  done
  echo ""
  for i in "${!pids[@]}"; do
    rc=0
    wait "${pids[$i]}" || rc=$?
    STATUSES+=("$rc")
  done
  # Replay each test's log in order (the header/footer show commit, timing, exit code).
  for i in "${!NAMES[@]}"; do
    echo -e "\n${BOLD}━━━ ${LABELS[$i]} ━━━${NC}"
    cat "$LOG_DIR/${NAMES[$i]}.log" 2>/dev/null || echo "(no log written)"
    if [[ ${STATUSES[$i]} -eq 0 ]]; then
      echo -e "${GREEN}✓ passed${NC}"
    else
      echo -e "${RED}✗ failed (exit ${STATUSES[$i]})${NC}"
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
print_summary() {
  local pass=0 fail=0 i
  local -a failed=()
  for i in "${!NAMES[@]}"; do
    if [[ ${STATUSES[$i]} -eq 0 ]]; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      failed+=("${LABELS[$i]}")
    fi
  done
  local total=$((pass + fail))

  echo -e "\n${DIM}══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD} Results${NC}"
  echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
  for i in "${!NAMES[@]}"; do
    if [[ ${STATUSES[$i]} -eq 0 ]]; then
      echo -e "  ${GREEN}✓${NC}  ${LABELS[$i]}"
    else
      echo -e "  ${RED}✗${NC}  ${LABELS[$i]}  ${DIM}(exit ${STATUSES[$i]})${NC}"
    fi
  done
  echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
  echo -e "  Full logs: $LOG_DIR"
  if [[ $fail -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}All $total tests passed.${NC}"
    echo -e "${DIM}══════════════════════════════════════════════════════════${NC}\n"
    return 0
  fi
  echo -e "  ${RED}${BOLD}$fail of $total tests failed:${NC}"
  for i in "${failed[@]}"; do
    echo -e "    ${RED}✗  $i${NC}"
  done
  echo -e "  HANDOFF for a new session: python3 .github/scripts/test-report.py --platform all \\"
  echo -e "      --title 'local tests' --artifacts '$LOG_DIR' --out '$LOG_DIR/report'"
  echo -e "${DIM}══════════════════════════════════════════════════════════${NC}\n"
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
mode="sequential"
[[ $PARALLEL -eq 1 ]] && mode="parallel"
echo -e "\n${BOLD}Running ${#NAMES[@]} tests ($mode)${NC}  ${DIM}logs: $LOG_DIR${NC}"
[[ -n "$FAST" ]] && echo -e "${DIM}--fast: each test's test.conf fast_args are applied${NC}"
echo ""

if [[ $PARALLEL -eq 1 ]]; then
  run_parallel
else
  run_sequential
fi

print_summary
