---
name: adding-nix-tests
description: Use this skill to add, improve, or repair tests under templates/tests/ in this nix repo. Trigger phrases include 'add a test for', 'improve test coverage', 'write a test that', 'test the new module', 'cover this with a test', 'fix a failing test', 'why is this test failing', 'rename/delete a test', 'change a test's group or timeout'. Every test change ends with its mandatory docs sync. Drives the author -> run (one nix-checker per test folder for targeted runs; one `--parallel` run for a full-suite verification) -> triage (diagnose first) loop across nix-test-author, nix-checker and nix-debugger. Does NOT cover merely running the existing suite with no new test (dispatch nix-checker directly) or authoring non-test config (use creating-nix-modules).
---

# Adding Nix Tests

Repo CLAUDE.md forbids running the suite, dry-builds or failure debugging in the
main loop. This chat is the orchestrator: it dispatches each stage and loops
(agents cannot call each other). There is NO test registry: tests are
auto-discovered, nothing is registered anywhere. But every test change has a
mandatory **docs sync** (section below): the folder readme, the overview page and
the CI group table are hand-written and go stale otherwise.

## Rules every test must follow (user rules)

1. Never test which programs / WMs / DEs / kernels a host chooses to enable.
   Test only: conflicting modules, specialisation purpose contracts, host safety
   values (boot, impermanence, sops, stateVersion), and cross-file consistency.
2. Fake hosts enable ONLY what that test needs. Sole exception: `test-arch-compat`
   deliberately enables every module.
3. Every check must be able to fail. No vacuous checks: add a control / negative
   scenario (see `./writing-non-vacuous-checks.md`).
4. Never hardcode keys, fingerprints or tokens (public repo). Compare config
   values with each other, or parse them at test time.
5. Each test folder has `<folder>-readme.md` (never `README.md`): what, why,
   how to run.
6. Auto-discovery: a folder directly under `templates/tests/{nixos,common,darwin}/`
   containing `check-*.sh` and/or `*_test.nix` IS a test; optional `test.conf`
   sets group/timeout/platforms/ci/fast_args. `run-tests.sh`, `tests-nixos.yml`
   and `tests-darwin.yml` all read `discover.py`, so they need NO edit for a new,
   renamed or removed test. See `./test-discovery-and-test-conf.md`.
7. `git add` every new or renamed file under `templates/tests/` (and `git rm` /
   `git mv` for deletions and renames) BEFORE running anything. `discover.py`
   reads the working tree, so an unstaged folder still shows in `--list`, but its
   nix evals go through the flake, which sees tracked files only, and CI sees only
   what is committed. A green run on unstaged files proves nothing.
8. A failing test is NOT proof of a config bug. Diagnose first.
9. `check-*.sh` source `templates/tests/lib/evidence.sh` so the full nix stderr
   reaches the logs (see `./reading-test-logs-locally-and-in-ci.md`).
10. Tests evaluate the real current config, so a later config fix is verified by
   re-running the test, no rebuild needed.

## The loop

**1. AUTHOR - dispatch `nix-test-author`** with the module or behavior to cover.
Hand it the rules above. Deliverables:
- folder `templates/tests/<nixos|common|darwin>/test-<name>/` (mirror a
  same-pattern existing test: scenario `.nix` + `check-*.sh`, or `*_test.nix`)
- `test-<name>-readme.md` in that folder (`# test-<name>`, `## Run` with repo-root
  and in-folder commands, `## How it works`, `## Checks` tables)
- optional `test.conf` (only when the defaults are wrong, e.g. heavy or slow test)
- `git add` of every new file, before its self-run (rule 7)
- the docs sync below, done in the same change

The author does a quick self-run of its own folder, nothing more.

**2. RUN - dispatch ONE `nix-checker` per test folder**, in parallel when several
tests changed. Each agent runs `bash templates/tests/run-tests.sh --only <name>`
(names: `bash templates/tests/run-tests.sh --list`) or the folder's `check-*.sh`.
Never hand one agent several folders. Add one more checker for the docs-sync
guard (`--only common-test-infra`) whenever any test was added, renamed, deleted
or had its checks or `test.conf` changed. For a FULL-suite verification (e.g. when the
new test touches shared `lib/` or `test.conf` semantics) do not split per folder:
run the whole suite with ONE `bash templates/tests/run-tests.sh --parallel`
(fast, ~1-4 min) in a single nix-checker, and run the builds (flake check, each
host toplevel, darwin dry, home dry) as separate parallel nix-checker agents. The
one-agent-per-folder pattern stays for targeted runs and triage of specific tests.

**3. TRIAGE failures - diagnose first.** Dispatch `nix-debugger` read-only (tell it
not to edit) with the log path from the checker's report. It must answer:
- REAL config bug -> fix the config (nix-debugger or nix-config-architect), keep
  the test as is, re-run that folder via `nix-checker`. NEVER weaken or delete
  the test to make it pass.
- TEST-WRONG (bad assertion, vacuous control, wrong scenario, over-enabled fake
  host) -> back to `nix-test-author`, then re-run that folder.
- Infra/flaky (offline NAS, cache miss, timeout) -> say so, re-run once; if it
  persists, look at `./reading-test-logs-locally-and-in-ci.md`.

**Loop 2 -> 3** until every touched folder is green. After ~4 rounds without
convergence stop and report the remaining issues to the user.

## Docs sync (mandatory for ANY test change)

This is the one checklist; the agents and the overview page point here. It
applies to adding, renaming or deleting a test, adding/removing/changing a check,
and changing `test.conf` (`group`, `timeout`, `platforms`, `ci`, `fast_args`).
A checks-only edit is NOT "folder only": the overview row describes the checks.

1. **Staged:** every new/renamed file under `templates/tests/` is `git add`ed,
   removed ones `git rm`ed (rule 7).
2. **Folder readme** `<folder>-readme.md` (never `README.md`): title is the
   folder name; `## Run` commands use the current run name and script names;
   the `## Checks` tables list exactly the checks the code runs (one row per
   check, none missing, none left over from a removed check, expected values
   current); a stated runtime still holds.
3. **`Documentation/usage/tests/tests-overview.md`:** the count sentence ("N
   tests are discovered today ... X NixOS, Y common and Z darwin", compare with
   `run-tests.sh --list`); exactly one table row per discovered test, in its
   category table, with run name, folder and CI group as `--list` prints them and
   "What it tests" / "Runtime" matching the current checks and cap; the CI
   section's "Linux groups today" list when a group appears or disappears; the
   `--fast` row when `fast_args` changes.
4. **`Documentation/usage/ci/build-workflows.md` §12.2:** the leg table (which
   tests are in which leg, per-leg test counts) and, when a group or timeout
   changed, the per-group `step_budget` figures. After a group/timeout change also
   run `python3 .github/scripts/check-workflow-invariants.py`.
5. **Anything else naming the test:** on a rename or delete,
   `grep -rn '<old-folder>\|<old-run-name>' Documentation .claude CLAUDE.md .github templates/tests`
   (features.md, gotcha docs, other agents and readmes cite tests by name).
6. **Run the guard before declaring done:**
   `bash templates/tests/run-tests.sh --only common-test-infra`. Its docs-sync
   check fails when the overview count/rows/caps/`--fast` row, the §12.2 table
   (members, counts, caps, stale names) or the readmes (name, title, `## Run`,
   script names) drift from discovery, or a doc cites a missing
   `templates/tests/...` path or `--only` name. It cannot judge prose, so these
   stay manual: items 2 and 3 "matches the checks", the §12.2 timing columns and
   dated step-budget prose (item 4), and short test names in prose elsewhere
   (item 5's grep). A green guard is necessary, not sufficient.

## Exit condition

All touched folders green, the docs sync above done and `common-test-infra`
green, and spot-check: `test-<name>-readme.md` exists (no `README.md`), new
files are `git add`ed, the test has a control that makes it
fail when the property is broken, no secret/key literal in the folder. Report
what was added, where, and which checks have controls. Do NOT commit unless asked.

## Supporting files

- `./test-discovery-and-test-conf.md` - how tests are found, `test.conf` keys, CI legs, what never needs editing
- `./writing-non-vacuous-checks.md` - controls, negative scenarios, no-secrets patterns
- `./reading-test-logs-locally-and-in-ci.md` - log locations, evidence helper, fetching CI logs

## Out of scope

- Running the existing suite with no new test: dispatch `nix-checker` directly.
- Authoring non-test config: `creating-nix-modules`.
- General overview of the suite: `Documentation/usage/tests/tests-overview.md`.
