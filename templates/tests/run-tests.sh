#!/usr/bin/env bash
# run-tests.sh - run the templates/tests suite locally.
# Run from anywhere; the script resolves the repo root automatically.
#
# Usage:
#   bash templates/tests/run-tests.sh [--parallel] [--jobs N|auto|max] [--fast]
#                                     [--only NAME[,NAME...]] [--list]
#                                     [--keep-logs] [--prune-only]
#
#   --parallel   run tests concurrently instead of sequentially (faster,
#                but if nicol-nas is offline, parallel nix processes will each
#                print "could not resolve nicol-nas" retry warnings - harmless,
#                but noisy; prefer sequential when the NAS is unreachable).
#                Every test is mostly a whole-host `nix eval` (~8 GB peak each),
#                so the number of tests running at once is chosen from the RAM
#                that is free right now (see --jobs); a banner at the start
#                says what was chosen and why.
#   --jobs X     with --parallel: how many tests run at once. `auto` (default)
#                = all of them when at least 52 GB are available (measured
#                uncapped peak of the full suite), otherwise
#                (available - 3 GB) / 8 GB, at least 1; `max` = never cap;
#                N = exactly N. Env: NIX_TESTS_JOBS (same values),
#                NIX_TESTS_UNCAPPED_GB, NIX_TESTS_JOB_GB, NIX_TESTS_RESERVE_GB
#                tune the auto rule. Without --parallel the banner still shows
#                what auto would pick.
#                On Linux the summary also reports the whole machine's RAM and swap
#                use (min / average / max, sampled every 2 s, samples kept in
#                <log dir>/memory-samples.tsv).
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
JOBS_ARG="${NIX_TESTS_JOBS:-auto}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --parallel) PARALLEL=1 ;;
    --jobs)     JOBS_ARG="${2:-}"; shift ;;
    --jobs=*)   JOBS_ARG="${1#--jobs=}" ;;
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

case "$JOBS_ARG" in
  auto|max) ;;
  ''|*[!0-9]*|0) echo "run-tests.sh: --jobs wants auto, max or a positive number (got '$JOBS_ARG')" >&2; exit 2 ;;
esac

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

PREV_RUN="$(readlink "$STATE_BASE/latest" 2>/dev/null || true)"   # durations for longest-first ordering
LOG_DIR="$STATE_BASE/$(date +%Y%m%dT%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
mkdir -p "$LOG_DIR"
ln -sfn "$LOG_DIR" "$STATE_BASE/latest"

STATUSES=()

# ─────────────────────────────────────────────────────────────────────────────
# Hardware-aware concurrency. Measured 2026-10-22 on the 64 GB desktop: the
# whole suite at once peaked at 51.9 GB (unit "Memory peak"); one host-toplevel
# eval peaks at ~7.8 GB. So: enough free RAM for the whole suite -> no cap
# (desktop behaviour unchanged); otherwise (available - reserve) / per-job,
# at least 1. Available RAM is read at start, so an open browser or other
# builds lower the number automatically. Details: Documentation/usage/tests/
# tests-overview.md, section "Memory needed for --parallel".
UNCAPPED_MB=$(( ${NIX_TESTS_UNCAPPED_GB:-52} * 1024 ))
PER_JOB_MB=$(( ${NIX_TESTS_JOB_GB:-8} * 1024 ))
RESERVE_MB=$(( ${NIX_TESTS_RESERVE_GB:-3} * 1024 ))

detect_hardware() {  # sets CPUS TOTAL_MB AVAIL_MB SWAP_MB MEM_NOTE
  CPUS="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  TOTAL_MB=0; AVAIL_MB=0; SWAP_MB=0; MEM_NOTE=""
  if [[ -r /proc/meminfo ]]; then
    TOTAL_MB=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
    AVAIL_MB=$(awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo)
    SWAP_MB=$(awk '/^SwapTotal:/{print int($2/1024)}' /proc/meminfo)
    # A memory limit on our own cgroup (e.g. systemd-run -p MemoryMax=/MemoryHigh=)
    # lowers what is really usable.
    local cg f lim cur room
    cg="$(sed -n 's/^0:://p' /proc/self/cgroup 2>/dev/null)"
    cur="$(cat "/sys/fs/cgroup${cg}/memory.current" 2>/dev/null || echo 0)"
    for f in memory.max memory.high; do
      lim="$(cat "/sys/fs/cgroup${cg}/$f" 2>/dev/null || true)"
      [[ "$lim" =~ ^[0-9]+$ ]] || continue
      room=$(( (lim - cur) / 1048576 ))
      if (( room < AVAIL_MB )); then AVAIL_MB=$room; MEM_NOTE="cgroup $f limits it"; fi
    done
  elif command -v sysctl >/dev/null 2>&1; then
    TOTAL_MB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1048576 ))
    AVAIL_MB=$(( TOTAL_MB * 6 / 10 )); MEM_NOTE="macOS: assumed 60 % of RAM is free"
  fi
}

choose_jobs() {  # sets JOBS (0 = no cap) and JOBS_WHY; needs detect_hardware
  local n=${#NAMES[@]}
  if [[ "$JOBS_ARG" == max ]]; then JOBS=0; JOBS_WHY="--jobs max: never capped"; return; fi
  if [[ "$JOBS_ARG" != auto ]]; then JOBS=$JOBS_ARG; JOBS_WHY="--jobs $JOBS_ARG (forced)"; return; fi
  if (( AVAIL_MB <= 0 )); then JOBS=0; JOBS_WHY="free RAM unknown: not capped"; return; fi
  if (( AVAIL_MB >= UNCAPPED_MB )); then
    JOBS=0; JOBS_WHY="$((AVAIL_MB / 1024)) GB free >= $((UNCAPPED_MB / 1024)) GB the whole suite needs at once: not capped"
    return
  fi
  JOBS=$(( (AVAIL_MB - RESERVE_MB) / PER_JOB_MB ))
  (( JOBS < 1 )) && JOBS=1
  JOBS_WHY="($((AVAIL_MB / 1024)) GB free - $((RESERVE_MB / 1024)) GB reserve) / $((PER_JOB_MB / 1024)) GB per host eval, at least 1"
  (( JOBS >= n )) && { JOBS=0; JOBS_WHY="$JOBS_WHY: enough for all $n tests, not capped"; }
}

print_hardware_banner() {
  local cap="no cap (all ${#NAMES[@]} at once)"
  (( JOBS > 0 )) && cap="$JOBS at a time"
  echo -e "${BOLD}Hardware${NC}  ${CPUS} CPUs, $((TOTAL_MB / 1024)) GB RAM ($((AVAIL_MB / 1024)) GB available${MEM_NOTE:+, $MEM_NOTE}), $((SWAP_MB / 1024)) GB swap"
  if [[ $PARALLEL -eq 1 ]]; then
    echo -e "${BOLD}Tuning${NC}    parallel, ${BOLD}${cap}${NC}  ${DIM}[$JOBS_WHY]${NC}"
    (( JOBS > 0 )) && echo -e "           ${DIM}longest tests of the previous run start first; override with --jobs N|max${NC}"
    (( JOBS == 1 )) && (( AVAIL_MB > 0 && AVAIL_MB < PER_JOB_MB + RESERVE_MB )) && \
      echo -e "           ${RED}only $((AVAIL_MB / 1024)) GB free: one host eval needs ~$((PER_JOB_MB / 1024)) GB, heavy tests may swap or be OOM-killed${NC}"
  else
    local pick="no cap"; (( JOBS > 0 )) && pick="$JOBS at a time"
    echo -e "${BOLD}Tuning${NC}    sequential (one test at a time); --parallel would pick: ${pick}  ${DIM}[$JOBS_WHY]${NC}"
  fi
}

# Reorder NAMES/LABELS so the tests that took longest in the previous run start
# first (a cap otherwise leaves the heaviest ones for the end). No history: no-op.
order_longest_first() {
  [[ -n "$PREV_RUN" && -d "$PREV_RUN" ]] || return 0
  local i d lines=""
  local -a new_n=() new_l=()
  for i in "${!NAMES[@]}"; do
    d="$(sed -n 's/^# duration_s: //p' "$PREV_RUN/${NAMES[$i]}.log" 2>/dev/null | head -1)"
    lines+="${d:-0}"$'\t'"$i"$'\n'
  done
  while IFS=$'\t' read -r d i; do
    [[ -z "$i" ]] && continue
    new_n+=("${NAMES[$i]}"); new_l+=("${LABELS[$i]}")
  done < <(printf '%s' "$lines" | sort -t$'\t' -k1,1nr -k2,2n)
  NAMES=("${new_n[@]}"); LABELS=("${new_l[@]}")
}

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
  local i rc p running
  for i in "${!NAMES[@]}"; do
    # Capped: wait for a free slot (polling keeps this working on bash 3.2).
    if (( JOBS > 0 )); then
      while :; do
        running=0
        for p in "${pids[@]+"${pids[@]}"}"; do kill -0 "$p" 2>/dev/null && running=$((running + 1)); done
        (( running < JOBS )) && break
        sleep 1
      done
    fi
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
# Whole-machine memory over the run (Linux only: needs /proc/meminfo): every 2 s
# "used RAM MB<TAB>used swap MB" into $LOG_DIR/memory-samples.tsv; the summary
# prints min / average / max. It is system-wide, so other programs count too.
MEM_SAMPLES="$LOG_DIR/memory-samples.tsv"
MEM_SAMPLER_PID=""
start_mem_sampler() {
  [[ -r /proc/meminfo ]] || return 0
  : >"$MEM_SAMPLES"
  (
    while :; do
      awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} /^SwapTotal:/{st=$2} /^SwapFree:/{sf=$2}
           END{printf "%d\t%d\n", (t-a)/1024, (st-sf)/1024}' /proc/meminfo >>"$MEM_SAMPLES"
      sleep 2
    done
  ) &
  MEM_SAMPLER_PID=$!
}
stop_mem_sampler() {
  [[ -n "$MEM_SAMPLER_PID" ]] || return 0
  kill "$MEM_SAMPLER_PID" 2>/dev/null; wait "$MEM_SAMPLER_PID" 2>/dev/null
  MEM_SAMPLER_PID=""
}
trap stop_mem_sampler EXIT
print_mem_stats() {
  [[ -s "$MEM_SAMPLES" ]] || return 0
  awk -F'\t' -v tot="$TOTAL_MB" -v swt="$SWAP_MB" '
    NR==1 { rmin=rmax=$1; smin=smax=$2 }
    { rs+=$1; ss+=$2; n++
      if ($1<rmin) rmin=$1; if ($1>rmax) rmax=$1
      if ($2<smin) smin=$2; if ($2>smax) smax=$2 }
    END { printf "  Memory     RAM  min %5.1f  avg %5.1f  max %5.1f GB of %.0f\n", rmin/1024, rs/n/1024, rmax/1024, tot/1024
          printf "  (system)   swap min %5.1f  avg %5.1f  max %5.1f GB of %.0f   [%d samples, 2 s apart]\n", smin/1024, ss/n/1024, smax/1024, swt/1024, n }' "$MEM_SAMPLES"
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
  print_mem_stats
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
detect_hardware
choose_jobs
[[ $PARALLEL -eq 1 ]] && (( JOBS > 0 )) && order_longest_first
echo -e "\n${BOLD}Running ${#NAMES[@]} tests ($mode)${NC}  ${DIM}logs: $LOG_DIR${NC}"
print_hardware_banner
[[ -n "$FAST" ]] && echo -e "${DIM}--fast: each test's test.conf fast_args are applied${NC}"
echo ""

start_mem_sampler
if [[ $PARALLEL -eq 1 ]]; then
  run_parallel
else
  run_sequential
fi
stop_mem_sampler

print_summary
