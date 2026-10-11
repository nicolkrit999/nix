# test-test-infra

Two checks of the test infrastructure itself, run in order as one test:

1. **Log retention** (`check-common-test-infra.sh`): the pruning that `templates/tests/run-tests.sh` runs at the start of every local run, deleting old runs from `${XDG_STATE_HOME:-~/.local/state}/nix-tests/`. Pruning deletes files, so a mistake here would quietly throw away the logs a later debugging session needs, or delete something that is not a test log.
2. **Docs sync** (`check-common-test-docs.sh` + `docs_sync.py`): the docs that enumerate tests still match discovery. Tests are auto-discovered with no registry, so adding, renaming, regrouping or deleting a test changes nothing else by itself; this guard makes stale docs and forgotten `git add`s fail the suite, locally and in CI.

Discovery itself (`discover.py`) is not self-tested here; the docs guard imports it as the source of truth.

## Run

```bash
bash templates/tests/run-tests.sh --only common-test-infra                  # both checks, logged
bash templates/tests/common/test-test-infra/check-common-test-infra.sh      # pruning only
bash templates/tests/common/test-test-infra/check-common-test-docs.sh       # docs sync + controls
python3 -B templates/tests/common/test-test-infra/docs_sync.py              # docs sync, real repo only
```

Discovered as `common-test-infra` (group `common`, Linux CI leg). No nix, no network, a few seconds.

## How it works: log retention

Each scenario builds a fake `nix-tests/` tree under a fresh `mktemp -d` directory, used as `XDG_STATE_HOME`. The real `~/.local/state/nix-tests` is never used: the script refuses to run if the temp dir resolves to it, and a final check confirms no fixture run appeared there. Run directories are named the way `run-tests.sh` names them (`<YYYYmmddTHHMMSS>-<sha>`), with timestamps computed relative to now. The 200 MB "logs" are sparse files, so the 500 MB cases cost no disk space.

Every scenario calls the real entry point, `run-tests.sh --prune-only`, which calls `templates/tests/lib/prune_logs.py`. Inherited `NIX_TESTS_*` variables are unset first, so the defaults themselves are under test.

## Checks: log retention

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

## How it works: docs sync

`docs_sync.py` imports `templates/tests/lib/discover.py` and calls its `discover()` / `select()` / `ci_groups()`, so discovery is never re-implemented. Every problem is printed as `FAIL  <file>:<line>: <what to fix>`.

`check-common-test-docs.sh` runs the guard on the real repo, then copies the tracked files of `templates/tests/`, `Documentation/**/*.md`, `.claude/skills|agents/**/*.md` and `CLAUDE.md` into a fresh `mktemp -d` dir, `git init`s it and `git add`s everything. Each negative control mutates its own copy of that scratch tree and must make the guard fail with a FAIL line naming the expected file (and line).

## Checks: docs sync

| Check | Fails when |
|---|---|
| untracked files | `git ls-files --others --exclude-standard templates/tests` is non-empty (message: git add it) |
| readme name | a discovered folder lacks `<folder>-readme.md`, has another `*-readme.md` next to it, or its readme has no `## Run` section |
| readme title / scripts | the readme's first line does not start with `# <folder>`, or the readme names a bare `check-*.sh` that is not in its folder (a renamed or removed script) |
| no README.md | any `README.md` (any case) exists under `templates/tests/` |
| overview count | the sentence "N tests are discovered today ...: X NixOS, Y common and Z darwin" in `tests-overview.md` disagrees with discovery |
| overview rows | a discovered test has no row, a row names an unknown test, a test has two rows, sits in the wrong platform table, or its Folder / CI group cell differs from discovery; the Runtime cell's `cap N min` differs from the `test.conf` timeout (it must be there exactly when the timeout is not the default 10) |
| overview `--fast` row | the `--fast` flag row does not name exactly the tests that have `fast_args` |
| overview CI legs | the "Linux groups today: ... Darwin: ..." sentence lists other legs than `ci_groups()` |
| §12.2 groups table | `build-workflows.md` §12.2 lacks a row for a CI group or has one for a non-existent group; a `default for <cat>/ (N tests)` row has the wrong N; an explicit row misses a member of its group (full or short name), names a test of another group, names a hyphenated test name that no longer exists (rename/delete), gives a wrong `(N tests)`, or its `cap N` figures differ from the non-default `test.conf` timeouts of its members |
| references | a tracked `.md` file under `Documentation/`, `.claude/skills/`, `.claude/agents/`, `CLAUDE.md` or `templates/tests/` names a `templates/tests/<cat>/<path>` that does not exist, or a `run-tests.sh --only <name>` that does not resolve |

| Negative control (scratch copy) | Expected |
|---|---|
| unmodified copy | passes (baseline) |
| `common-test-infra` row deleted | "no table row" |
| row for `nixos-ghost` added | "row for `nixos-ghost`" at that line |
| `nixos-waybar-configs` CI group cell changed | CI group cell mismatch at that line |
| total / darwin figure in the count sentence changed | count sentence mismatch at that line |
| `README.md` added (and git-added) | "README.md is forbidden" |
| readme renamed to `infra-readme.md` | "missing test-test-infra-readme.md" |
| a second `old-readme.md` | "unexpected readme name" |
| untracked `forgotten.nix` | "untracked ... git add it" |
| new folder with only check script + readme | missing overview row, count sentence and §12.2 `common` count all flagged |
| `portal-routing` dropped from the §12.2 `nixos-b` row | "does not name `nixos-portal-routing`" |
| `(99 tests)` in the §12.2 `nixos` row | wrong count at that line |
| `group = solo` in a `test.conf` | "no row for CI group `solo`" |
| `nixos-spec-school` added to the `heavy-b` row | "names `nixos-spec-school`, whose group is `nixos`" |
| a deleted test's path and `--only` name in `CLAUDE.md` | both flagged at that line |
| `## Run` heading renamed | "no `## Run` section" |
| readme title changed to `# test-old-infra` | "title is '# test-old-infra'" |
| `check-common-test-docs.sh` renamed with `git mv` | the readme "names check-common-test-docs.sh" |
| Folder cell of `nixos-arch-compat` changed | folder cell mismatch at that line |
| `darwin-home-paths` row moved into the NixOS table | "is a darwin test but sits in the nixos table" |
| `nixos-arch-compat` row duplicated | "has 2 rows" |
| `timeout = 15` for `nixos-spec-school` | its Runtime cell "states cap none" |
| `cap 30 min` changed to `cap 25 min` | stale cap at that line |
| §12.2 `heavy-b` row says `cap 25 each` | "states caps [25]" |
| `fast_args` added for `nixos-spec-school` | "`--fast` row names" mismatch |
| `heavy-b` dropped from the CI legs sentence | "CI legs listed as" mismatch |
| §12.2 row for a group `ghost` | "lists group `ghost`" |
| harness folder `test-custom-shells` renamed, no docs touched | readme name, both overview rows and the §12.2 `harness` row (missing new name, stale `custom-shells`) all flagged |
| darwin test `test-darwin-home-paths` deleted, no docs touched | count sentence, stale overview row and stale name in the §12.2 `darwin` row all flagged |

**Not checked** (cannot be checked reliably): whether a readme's Checks table matches what its script asserts; the What / Why cells and the Runtime figures (other than the cap) of `tests-overview.md`, a cap attached to the wrong test inside one §12.2 row, and the timing and "why" columns of §12.2; the dated step-budget figures in the §12.2 prose ("On 2026-10-11: `nixos` 134 ..."; the `test-step-budget` invariant in `.github/scripts/check-workflow-invariants.py` checks the real budgets); short test names in prose outside the §12.2 tests column; untracked files outside `templates/tests/` (a new doc page). In CI the untracked check passes trivially (clean checkout); it bites locally.
