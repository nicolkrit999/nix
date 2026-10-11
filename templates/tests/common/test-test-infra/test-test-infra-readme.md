# test-test-infra

Checks the local log retention of `templates/tests/run-tests.sh`: the pruning that runs at the start of every local run and deletes old runs from `${XDG_STATE_HOME:-~/.local/state}/nix-tests/`. Pruning deletes files, so a mistake here would quietly throw away the logs a later debugging session needs, or delete something that is not a test log.

This folder covers pruning only. Test discovery is not self-tested here, on purpose.

## Run

```bash
bash templates/tests/common/test-test-infra/check-common-test-infra.sh
```

Discovered as `common-test-infra` (group `common`, Linux CI leg). No nix, no network, a few seconds.

## How it works

Each scenario builds a fake `nix-tests/` tree under a fresh `mktemp -d` directory, used as `XDG_STATE_HOME`. The real `~/.local/state/nix-tests` is never used: the script refuses to run if the temp dir resolves to it, and a final check confirms no fixture run appeared there. Run directories are named the way `run-tests.sh` names them (`<YYYYmmddTHHMMSS>-<sha>`), with timestamps computed relative to now. The 200 MB "logs" are sparse files, so the 500 MB cases cost no disk space.

Every scenario calls the real entry point, `run-tests.sh --prune-only`, which calls `templates/tests/lib/prune_logs.py`. Inherited `NIX_TESTS_*` variables are unset first, so the defaults themselves are under test.

## Checks

| Scenario | Expected |
|---|---|
| 25 recent runs | the 5 oldest are deleted, 20 remain; a second prune deletes nothing |
| 25 runs, `latest` → the oldest | the oldest survives, the 4 next-oldest go, 21 remain |
| runs 1 min, 59, 61 and 400 days old | the 61- and 400-day runs go; the 59-day and fresh runs stay |
| `latest` → a 90-day-old run | it survives; another 91-day run is still deleted |
| 4 × 200 MB runs (800 MB) | the 2 oldest go, 400 MB remain |
| 2 × 240 MB runs (480 MB) | nothing deleted |
| 3 × 200 MB, `latest` → the oldest | the oldest stays, the next-oldest goes |
| foreign entries: `my-notes/`, a 900 MB `old-big/`, a bad-name dir, a run-named file, a run-named symlink | none of them (nor the symlink's target, nor `latest`) is touched, and the 900 MB do not evict a real run |
| `--keep-logs` on 26 runs incl. a 70-day 600 MB run | nothing deleted; the same tree without `--keep-logs` is pruned (control) |
| `NIX_TESTS_MAX_AGE_DAYS=sixty` | non-zero exit, nothing deleted |

## Limits being tested

| Variable | Default | Meaning |
|---|---|---|
| `NIX_TESTS_KEEP_RUNS` | 20 | keep at most this many runs |
| `NIX_TESTS_MAX_AGE_DAYS` | 60 | delete runs older than this (age from the name's timestamp, not mtime) |
| `NIX_TESTS_MAX_MB` | 500 | delete oldest runs until all runs together are at most this |

`0` disables a limit. Only real `<timestamp>-<sha>` directories are ever deleted, never the one `latest` points to.
