# shellcheck shell=bash
# templates/tests/lib/evidence.sh - keep the FULL stderr of every failing nix call.
#
# Sourced near the top of every check-*.sh:
#   source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
#
# Why: the check scripts capture nix stderr into a temp file, print a 2-4 line
# `grep error: | head -3 | tr '\n' '~'` excerpt and delete the file. That excerpt is
# fine for the PASS/FAIL table but it is all a later debugging session ever got -
# the eval trace was gone before CI could save it.
#
# How: when TEST_LOG_DIR is set (.github/scripts/run-test.py sets it, both in CI and
# under run-tests.sh), `nix` becomes a function that runs the real nix, hands its
# stderr back to the caller UNCHANGED (so every existing `2>"$file"`, `2>&1` and grep
# keeps working), and - only when nix exits non-zero - also writes the complete
# stderr plus the exact command line to "$TEST_LOG_DIR/nix-stderr.XXXXXXXX".
# run-test.py appends those files, redacted, to the test's log and deletes them.
#
# Without TEST_LOG_DIR (running a check script by hand) nothing is defined and the
# script behaves exactly as before. Works on bash 3.2 (macOS) too.
#
# Trade-off: nix's stderr reaches the caller when nix EXITS, not live. Every check
# script captures it into a variable or file anyway, so only the interleaving of a
# progress line with stdout can change.
#
# Rule for test authors (public repo): never `cat`/`readFile` anything under
# /run/secrets, ~/.config/sops or secrets/*.yaml, and never dump whole config
# subtrees to stderr - whatever a test prints ends up in a CI artifact and on Discord.

if [[ -n "${TEST_LOG_DIR:-}" ]]; then
  mkdir -p "$TEST_LOG_DIR" 2>/dev/null || true

  nix() {
    local _ev_err _ev_rc=0 _ev_keep
    _ev_err=$(mktemp "${TMPDIR:-/tmp}/nix-stderr.XXXXXXXX" 2>/dev/null) || { command nix "$@"; return; }
    command nix "$@" 2>"$_ev_err" || _ev_rc=$?
    cat -- "$_ev_err" >&2
    if [[ $_ev_rc -ne 0 ]] && _ev_keep=$(mktemp "$TEST_LOG_DIR/nix-stderr.XXXXXXXX" 2>/dev/null); then
      {
        printf '$ nix'
        printf ' %q' "$@"
        printf '\n# exit %s, called from %s:%s\n' "$_ev_rc" "${BASH_SOURCE[1]:-?}" "${BASH_LINENO[0]:-?}"
        cat -- "$_ev_err"
      } >"$_ev_keep" 2>/dev/null || true
    fi
    rm -f -- "$_ev_err"
    return "$_ev_rc"
  }
  export -f nix
fi

# keep_evidence <label> <file>... : copy non-nix evidence (a generated script, a
# bash -n error, a diff) next to the log; run-test.py appends it the same way.
keep_evidence() {
  [[ -n "${TEST_LOG_DIR:-}" ]] || return 0
  local label="$1" f
  shift
  mkdir -p "$TEST_LOG_DIR" 2>/dev/null || return 0
  for f in "$@"; do
    if [[ -s "$f" ]]; then
      cp -- "$f" "$TEST_LOG_DIR/evidence.${label//[^A-Za-z0-9._-]/_}.$(basename "$f")" 2>/dev/null || true
    fi
  done
  return 0
}
