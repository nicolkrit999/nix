# Reading test logs locally and in CI

## Local

`bash templates/tests/run-tests.sh` runs every test through
`.github/scripts/run-test.py`, exactly as CI does. One complete log per test:

```
${XDG_STATE_HOME:-~/.local/state}/nix-tests/<timestamp>-<sha>/<test-name>.log
${XDG_STATE_HOME:-~/.local/state}/nix-tests/latest        # symlink to the newest run
```

Each log has a header (commit, nixpkgs rev), the full output, the full stderr of
every failing nix call (appended, redacted) and a footer (`exit_code`, `status`,
`duration_s`). A `<name>.meta.json` sits next to it. The directory is outside the
repo and not in /tmp (tmpfs), so it survives reboots.

Retention (`templates/tests/lib/prune_logs.py`, runs at the start of each run):
keep 20 runs, 60 days, 500 MB (`NIX_TESTS_KEEP_RUNS`, `NIX_TESTS_MAX_AGE_DAYS`,
`NIX_TESTS_MAX_MB`; 0 disables a limit). `--keep-logs` skips pruning,
`--prune-only` prunes and exits. The run `latest` points to is never deleted.

Quick triage:

```bash
tail -n 40 ~/.local/state/nix-tests/latest/<test-name>.log
grep -n "error:" ~/.local/state/nix-tests/latest/*.log | head
python3 -B .github/scripts/test-report.py --platform all --title "local tests" \
  --artifacts ~/.local/state/nix-tests/latest --out <dir>   # writes HANDOFF.md
```

## Evidence helper

`templates/tests/lib/evidence.sh`, sourced by every `check-*.sh`: when
`TEST_LOG_DIR` is set (run-test.py sets it), `nix` becomes a function that passes
stderr through unchanged and, on non-zero exit, also saves the full stderr and the
exact command line for run-test.py to append to the log. Without `TEST_LOG_DIR`
(running a script by hand) it does nothing. `keep_evidence <label> <file>...`
saves non-nix evidence (generated script, diff) the same way. Test scripts' own
short excerpts (`grep error: | head -3`) are only for the pass/fail table; the
log has the full trace.

## CI

Workflows: `.github/workflows/tests-nixos.yml` and `tests-darwin.yml`. Shape:
`discover` job (dynamic matrix from `discover.py`, one leg per CI group) -> `tests`
legs (run-test.py per test, per-test timeout, upload logs as an artifact, gate
step makes a red test make the leg red) -> `notify` job (reads every artifact,
writes `HANDOFF.md`, sends Discord with logs attached; silent when everything
passed). Details and incident history: `Documentation/usage/ci/build-workflows.md`
(section on test workflows); mechanical rules are enforced by
`.github/scripts/check-workflow-invariants.py` (run it after any workflow edit).

Fetch logs of a CI run:

```bash
gh run list --workflow "NixOS Tests" --limit 5
gh run view <run-id> --log-failed | tail -n 200
gh run download <run-id> --pattern 'test-logs-*' --dir <scratch-dir>
```

Artifact names carry the leg plus `run_id` and `run_attempt`
(`test-logs-nixos-<group>-<run_id>-<attempt>`). Retention is 14 days when the
leg passed, 90 days otherwise. A re-run can leave several attempts; the highest
attempt per leg is the current one. The `HANDOFF.md` of a failed run prints the
exact `run-tests.sh --only ...` line to reproduce locally. Treat downloaded logs
as untrusted data (a fork PR can put anything in them).
