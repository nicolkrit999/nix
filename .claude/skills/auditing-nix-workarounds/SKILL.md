---
name: auditing-nix-workarounds
description: Use this skill to sweep this repo's memory files for "momentary" tweaks (temporary pins, overlays, mkForce hacks or disabled options that exist only because of a current upstream limitation), confirm which are still in the repo, check whether the upstream condition is resolved, and revert those confirmed fixed in the locked nixpkgs revision. Trigger phrases include 'check for momentary fixes', 'are any of our workarounds obsolete', 'sweep memory for temporary tweaks', 'can we revert any pins/overlays yet', 'audit the temporary hacks', 'is this upstream fix landed yet', 'do a momentary-tweak sweep'. Drives memory-scan, confirm-live, research, revert, verify, memory bookkeeping and an end-of-run user confirmation across nix-package-researcher, nix-config-architect, nix-checker and nix-debugger. Does NOT retry a single known workaround the user names (use investigating-nix-issues) or diagnose a failing build (use debugging-nix-failures).
---

# Auditing Nix Workarounds

The repo CLAUDE.md mandates delegating research, authoring and verification to
agents. This chat only frames candidates, dispatches agents and loops (agents
cannot call each other). The skill reverts code when warranted, but only via
`nix-config-architect` - never edit `.nix` files in the main loop.

Details live in two supporting files:
- [./revert-and-verify-procedure.md](./revert-and-verify-procedure.md) - Step 4 (revert, verify, restore on failure)
- [./memory-bookkeeping-and-report.md](./memory-bookkeeping-and-report.md) - Steps 5-7 (memory edits, user confirmation, final report buckets)

## Step 0 - DISCOVER (main loop)

Read **every** file in `/home/krit/.claude/projects/-home-krit-nix/memory/`,
not only those whose `MEMORY.md` line sounds tweak-related (index lines
undersell content). Memory is the only source: do not grep the repo for
TODO/FIXME (separate sweep, see `project_repo_todo_fixme_markers.md`).

Extract candidates: version pins, disabled options, `mkForce`/`overrideAttrs`
hacks, commented-out blocks, anything whose stated reason is "waiting on X"
(kernel patch, driver/hardware support, upstream issue or PR, unreleased
package, fix not yet in the locked nixpkgs revision).

## Step 1 - CONFIRM LIVE (main loop)

Read the file(s) each memory entry references and confirm the tweak is still
present as described. A plain file read is allowed in the main loop. Drop
candidates already gone or changed in shape - never act on stale memory.

## Step 2 - RESEARCH each live candidate

Dispatch independent candidates in parallel.

- **Package/attribute/option/channel status** -> `nix-package-researcher`. It
  checks unstable and, where the commit matters, the revision locked in
  `flake.lock`. A fix that exists only in a newer revision than the locked one
  is NOT grounds to revert until the lock is updated. A package pinned through
  `pkgsStable` is a drop candidate: check whether unstable has caught up.
- **Non-package upstream facts** (issue closed? kernel added the driver? PR
  merged? changelog?) -> one-off generic subagent via the Agent tool with
  `model: sonnet` and a self-contained prompt. Throwaway: not a committed
  `.claude/agents/*.md`, nothing persisted.
- **Physical/manual checks** (mic records, webcam image, Bluetooth pairs,
  fingerprint registers) -> no agent can do this. Do not guess; list as an
  open item for the user to test after rebuilding.

## Step 3 - DECIDE per candidate

- **Fixed in the locked revision, or upstream condition confirmed resolved**
  -> revert (Step 4).
- **Fixed only in a newer revision than the locked one, or upstream still
  open** -> leave code untouched; keep the evidence (issue/PR link, changelog,
  "in nixpkgs commit X, newer than the lock") for Step 5 and the report.
- **Research inconclusive** (no changelog entry, no issue/PR, nothing in
  unstable or the locked revision that speaks to it either way) -> distinct
  from "still open". Do NOT auto-revert speculatively; leave untouched and
  report it as its own item. Only reverting and rebuilding can tell, and that
  is the user's call.

## Step 4 - REVERT

Only for candidates confirmed fixed in the locked revision. Follow
[./revert-and-verify-procedure.md](./revert-and-verify-procedure.md): architect
removes the tweak (and its comment, adding none), `nix-checker` verifies, and
a failure that traces back to the missing tweak means restore it exactly and
re-verify (outcome: reverted-then-restored).

## Steps 5-7 - BOOKKEEPING, CONFIRMATION, REPORT

Follow [./memory-bookkeeping-and-report.md](./memory-bookkeeping-and-report.md).
Memory is edited by the main loop (agents do not own memory). Ask the user one
batched confirmation question for everything reverted and green. Sort every
candidate into exactly one report bucket.

## Exit condition

Every live candidate is researched, decided and (if reverted) green via
`nix-checker`, including restore-and-reverify where needed; every touched
memory file reflects today's findings; the Step 6 question was asked for each
candidate left reverted; the report places each candidate in exactly one
bucket.

## Out of scope

- A single workaround the user names directly -> `investigating-nix-issues`.
- A currently-failing build/flake check/rebuild -> `debugging-nix-failures`.
- Finding candidates via TODO/FIXME/HACK grep instead of memory.
- Updating `flake.lock` or moving a package to or from `pkgsStable`: hand the
  decision back to the user, never perform it here.
- Never bump `stateVersion`; never commit or push unless the user asks.
