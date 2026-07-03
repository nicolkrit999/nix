---
name: adding-nix-tests
description: Use this skill when new or improved test coverage is needed for a nix module or behavior. Trigger phrases include 'add a test for this module', 'improve test coverage', 'write a test that X', 'register this test', 'test the new module', 'cover this with a test'. Drives the author-run-triage loop across nix-test-author, nix-checker, and nix-debugger. Does NOT cover merely running the existing suite with no new test (dispatch nix-checker directly instead) or authoring non-test config (use creating-nix-modules instead).
---

# Adding Nix Tests

The repo CLAUDE.md mandates delegating verification and debugging to agents -
never run the test suite directly in the main loop. The orchestrator (this
chat) dispatches each stage and loops; agents cannot call each other.

## The loop

**1. AUTHOR - dispatch `nix-test-author`** with the module or behavior to
cover. Its contract for a new test requires all 4 deliverables:
- mirrors an existing test's structure (same platform's test layout/style)
- a test dir `templates/tests/<platform>/test-<name>/` with a scenario `.nix`
  file and `check-*.sh` script(s) (or a `nix-tests` dir where that pattern
  applies)
- a MANDATORY README at `test-<name>-readme.md` in that test dir
- registration of the new test in `templates/tests/run-tests.sh`

It also runs just the new test itself to confirm basic behavior before
handing off.

**2. RUN - dispatch `nix-checker`** to run the FULL templates/tests suite,
not just the new test - a new test can break or collide with the existing
registry.

**3. TRIAGE any failures:**
- Test itself is wrong or unidiomatic (bad assertion, wrong platform dir,
  registry mistake) -> back to `nix-test-author` to fix the test.
- Test is correct and exposes a REAL config bug -> dispatch `nix-debugger`
  to fix the underlying config. NEVER weaken or delete the test to make it
  pass - the test's job is to catch this.
- After either fix, re-run via `nix-checker` (step 2) on the full suite, not
  just the one test.

**Loop 2 -> 3** until the suite is green.

**Safeguard:** after ~4 rounds without convergence, stop and report the
remaining issues to the user instead of continuing indefinitely.

## Exit condition

Full suite green including the new test, AND all 4 deliverables confirmed
present - spot-check that the README file actually exists at
`test-<name>-readme.md`, since it's mandatory for every test dir in this repo
and easy to silently skip. Report to the user what was added and where.

## Out of scope

- Merely running the existing suite with no new test to add - dispatch
  `nix-checker` directly instead of this loop.
- Authoring non-test config (new modules, options, host wiring) - that's
  `creating-nix-modules`.
