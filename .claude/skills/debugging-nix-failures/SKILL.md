---
name: debugging-nix-failures
description: Use this skill when a nix build, flake check, nixos-rebuild, or darwin-rebuild is failing and needs to be diagnosed and fixed. Trigger phrases include 'the build failed', 'flake check fails', 'nixos-rebuild broke', 'why won't it evaluate', 'fix this nix error', 'option does not exist', 'darwin-rebuild is erroring', 'my rebuild is broken', 'hash mismatch'. Drives the reproduce-diagnose-fix-reverify loop across nix-checker and nix-debugger. Does NOT cover authoring new functionality (use creating-nix-modules instead) or pure style/format sweeps with no build failure (dispatch nix-syntax-linter directly).
---

# Debugging Nix Failures

Never run `nix flake check`, dry-builds, or the test suite directly in the main
loop - the repo CLAUDE.md mandates delegating verification and fixes to agents.
The orchestrator (this chat) only dispatches agents and loops; agents cannot
call each other.

## Step -1 - identify the host

Run `hostname` and `uname -m` (main loop, no agent needed) before anything
else - don't assume the machine/arch from context. This picks the right
dry-build target and flags (Darwin needs `--impure` on `nix flake check`).
Optionally check `./hosts/<host>/` for host-specific config.

## The loop

**Step 0 - sanity check (main loop):** run `git status`. Untracked files are
invisible to flakes and produce confusing eval errors that look like real
bugs. Tell the user or `git add` before dispatching anyone.

**Known transient noise:** `error: adding a file to a tree builder: failed to
insert entry: ... (libgit2 error code = 14)` is a nix/libgit2 git-cache race
during flake input unpacking, most likely right after a `flake.lock` update.
Don't diagnose it - just re-run step 1 once.

**Known recurring failure - fixed-output hash mismatches:** `error: hash
mismatch in fixed-output derivation ...` means upstream content at a pinned
URL changed, not a config bug. See
[`./known-hash-mismatch-culprits.md`](./known-hash-mismatch-culprits.md) for
the most-likely-culprit files, the fallback search when it's neither of
them (never stop silently), and how to regenerate a hash with `nurl`.

**1. REPRODUCE - dispatch `nix-checker`.**
Ask it to run the specific failing verification (flake check, the relevant
per-host dry-build, or the templates/tests suite) and report the exact error
text. Remind it: Darwin needs `--impure` on `nix flake check`. nix-checker is
read-only.

**2. DIAGNOSE & FIX - dispatch `nix-debugger`** with the verbatim error from
step 1 (not a paraphrase).
- nix-debugger root-causes the failure and applies the minimal fix.
- If the error hints at a renamed/removed attribute or unknown option, first
  dispatch `nix-package-researcher` to confirm the correct current attribute
  path, then pass those findings into nix-debugger's task.
- If the fix needs non-trivial authoring beyond a targeted patch, dispatch
  `nix-config-architect` instead, with the error and any researcher findings.
- If the failure is sops/secrets-related, stop and surface it to the user -
  no agent in this fleet has sops access.

**3. RE-VERIFY - dispatch `nix-checker` again** on the SAME check(s) from
step 1, even if the fix "looks obviously correct."

**4. Loop 2 -> 3** until nix-checker reports all green.

**Safeguard:** after ~4 rounds without convergence, stop looping. Report the
remaining errors and what's been tried to the user.

## Exit condition

`nix-checker` reports pass on `nix flake check` and the relevant per-host
dry-builds (and the tests suite, if that's what was failing). Report to the
user what was wrong and what fixed it.

## Out of scope

- Adding a new module, enabling a program/service, or any other net-new
  authoring - that's `creating-nix-modules`.
- A pure style/formatting pass with no actual failure - dispatch
  `nix-syntax-linter` directly instead of running this loop.
