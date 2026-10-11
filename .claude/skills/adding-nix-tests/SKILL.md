---
name: adding-nix-tests
description: Use this skill to add, improve, or repair tests under templates/tests/ in this nix repo. Trigger phrases include 'add a test for', 'improve test coverage', 'write a test that', 'test the new module', 'cover this with a test', 'fix a failing test', 'why is this test failing'. Drives the author -> run (one nix-checker per test folder for targeted runs; one `--parallel` run for a full-suite verification) -> triage (diagnose first) loop across nix-test-author, nix-checker and nix-debugger. Does NOT cover merely running the existing suite with no new test (dispatch nix-checker directly) or authoring non-test config (use creating-nix-modules).
---

# Adding Nix Tests

Repo CLAUDE.md forbids running the suite, dry-builds or failure debugging in the
main loop. This chat is the orchestrator: it dispatches each stage and loops
(agents cannot call each other). There is NO test registry: tests are
auto-discovered, nothing is registered anywhere.

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
6. Auto-discovery: add a folder with `check-*.sh` or `*_test.nix` (plus optional
   `test.conf`). See `./test-discovery-and-test-conf.md`.
7. A failing test is NOT proof of a config bug. Diagnose first.
8. `check-*.sh` source `templates/tests/lib/evidence.sh` so the full nix stderr
   reaches the logs (see `./reading-test-logs-locally-and-in-ci.md`).
9. Tests evaluate the real current config, so a later config fix is verified by
   re-running the test, no rebuild needed.

## The loop

**1. AUTHOR - dispatch `nix-test-author`** with the module or behavior to cover.
Hand it the rules above. Deliverables:
- folder `templates/tests/<nixos|common|darwin>/test-<name>/` (mirror a
  same-pattern existing test: scenario `.nix` + `check-*.sh`, or `*_test.nix`)
- `test-<name>-readme.md` in that folder (`# test-<name>`, `## Run` with repo-root
  and in-folder commands, `## How it works`, `## Checks` tables)
- optional `test.conf` (only when the defaults are wrong, e.g. heavy or slow test)
- `git add` of every new file (flakes and discovery see tracked files only)

The author does a quick self-run of its own folder, nothing more.

**2. RUN - dispatch ONE `nix-checker` per test folder**, in parallel when several
tests changed. Each agent runs `bash templates/tests/run-tests.sh --only <name>`
(names: `bash templates/tests/run-tests.sh --list`) or the folder's `check-*.sh`.
Never hand one agent several folders. For a FULL-suite verification (e.g. when the
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

## Exit condition

All touched folders green, and spot-check: `test-<name>-readme.md` exists (no
`README.md`), new files are `git add`ed, the test has a control that makes it
fail when the property is broken, no secret/key literal in the folder. Report
what was added, where, and which checks have controls. Do NOT commit unless asked.

## Supporting files

- `./test-discovery-and-test-conf.md` - how tests are found, `test.conf` keys, CI legs
- `./writing-non-vacuous-checks.md` - controls, negative scenarios, no-secrets patterns
- `./reading-test-logs-locally-and-in-ci.md` - log locations, evidence helper, fetching CI logs

## Out of scope

- Running the existing suite with no new test: dispatch `nix-checker` directly.
- Authoring non-test config: `creating-nix-modules`.
- General overview of the suite: `Documentation/usage/tests/tests-overview.md`.
