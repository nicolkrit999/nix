---
name: debugging-nix-failures
description: Use this skill when a nix build, flake check, nixos-rebuild, or darwin-rebuild is failing and needs to be diagnosed and fixed. Trigger phrases include 'the build failed', 'flake check fails', 'nixos-rebuild broke', 'why won't it evaluate', 'fix this nix error', 'option does not exist', 'darwin-rebuild is erroring', 'my rebuild is broken'. Drives the reproduce-diagnose-fix-reverify loop across nix-checker and nix-debugger. Does NOT cover authoring new functionality (use creating-nix-modules instead) or pure style/format sweeps with no build failure (dispatch nix-syntax-linter directly).
---

# Debugging Nix Failures

Never run `nix flake check`, dry-builds, or the test suite directly in the main
loop - the repo CLAUDE.md mandates delegating verification and fixes to agents.
The orchestrator (this chat) only dispatches agents and loops; agents cannot
call each other.

## The loop

**Step 0 - sanity check (main loop, no agent needed):** run `git status`.
Untracked files are invisible to flakes and produce confusing eval errors that
look like real bugs. If anything relevant is untracked, tell the user or `git
add` it before dispatching anyone.

**1. REPRODUCE - dispatch `nix-checker`.**
Ask it to run the specific failing verification (flake check, the relevant
per-host dry-build, or the templates/tests suite) and report back the exact
error text. Remind it: Darwin hosts need `--impure` on `nix flake check`.
nix-checker is read-only - it never edits anything, only reports pass/fail
plus exact error output.

**2. DIAGNOSE & FIX - dispatch `nix-debugger`** with the verbatim error from
step 1 (not a paraphrase).
- nix-debugger root-causes the failure and applies the minimal fix itself.
- If the error hints at a renamed/removed attribute or an unknown option,
  first dispatch `nix-package-researcher` to confirm the correct current
  attribute path/option name, then pass those findings into nix-debugger's
  task.
- If the fix requires non-trivial authoring beyond a targeted patch (new
  module structure, larger refactor), dispatch `nix-config-architect`
  instead, with the error and any researcher findings.
- If the failure is sops/secrets-related, stop and surface it to the user -
  no agent in this fleet has sops access.

**3. RE-VERIFY - dispatch `nix-checker` again** on the SAME check(s) from step
1. A fix can pass the original check but break something else, so don't skip
this even if the fix "looks obviously correct."

**4. Loop 2 -> 3** until nix-checker reports all green on every check that
matters for this failure.

**Safeguard:** after ~4 rounds of fix -> re-verify without full convergence,
stop looping. Report the remaining errors and what's been tried to the user
instead of continuing indefinitely.

## Exit condition

`nix-checker` reports pass on `nix flake check` and the relevant per-host
dry-builds (and the tests suite, if that's what was failing). Report to the
user what was wrong and what fixed it.

## Out of scope

- Adding a new module, enabling a program/service, or any other net-new
  authoring - that's `creating-nix-modules`.
- A pure style/formatting pass with no actual failure - dispatch
  `nix-syntax-linter` directly instead of running this loop.
