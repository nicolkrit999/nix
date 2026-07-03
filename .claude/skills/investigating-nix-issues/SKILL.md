---
name: investigating-nix-issues
description: Use this skill for general debugging of this nix config whenever it is NOT already known that a build/flake check/rebuild is failing - runtime or boot-time misbehavior, hardware quirks driven by config, config that silently doesn't take effect, code that looks broken but builds, suspected dead/orphaned code, an unresolved issue recorded in a memory file, or any vague observation that something is off. The issue can come from existing code, a memory entry, or a user report alike. Trigger phrases include 'debug this', 'something is wrong with X', 'it builds but doesn't work', 'X stopped working after a successful rebuild', 'this option seems to have no effect', 'is this module even used', 'find dead code', 'look into that unresolved issue from memory', 'retry the fix we reverted', 'debug why X behaves like this'. Drives the frame-investigate-fix-verify loop across nix-debugger, nix-config-architect, nix-package-researcher, nix-checker, and Explore. Does NOT cover a KNOWN-failing build/flake check/rebuild (use debugging-nix-failures instead) or adding net-new functionality (use creating-nix-modules instead).
---

# Investigating Nix Issues

For issues where the build is GREEN but the behavior is wrong. The repo
CLAUDE.md mandates delegating research, verification, and fixes to agents -
the orchestrator (this chat) only frames the issue, dispatches agents, and
loops; agents cannot call each other.

## The loop

**Step 0 - FRAME (main loop, no agent needed):** pin down before dispatching
anyone:
- **Symptom** - what is observably wrong (behavior, boot-time failure, dead
  code suspicion, option with no effect)? If the issue comes from a memory
  file, read that entry now and mine it for context, prior attempts, and
  next steps. Read prior attempts carefully: distinguish "tried and truly
  failed" from "partially worked but reverted for unrelated reasons" - the
  latter is a candidate to re-apply and finish verifying, not to discard.
- **Existing workarounds** - is something currently masking the issue (an
  option disabling the broken thing, a pin, a commented-out block)? Note it
  and its exact revert path; a fix usually replaces it, and it must remain
  available as the fallback if the fix fails.
- **Expected** - what should happen instead.
- **Done means** - how we'll know it's fixed (an eval result, a removed
  file, a log signature, a runtime behavior the user must confirm).

If the symptom is too vague to frame (a fuzzy "something is off"), first ask
the user what they observe and when it started, or dispatch `Explore` to
survey the candidate area - don't start fixing without a pinned symptom.

If the issue bundles several distinct sub-problems (common in long-lived
memory entries), split them and run this loop on ONE at a time.

**Triage the build state.** This loop assumes the build is green. If that is
unknown (a generic "debug X" with no recent verification), dispatch
`nix-checker` on the relevant checks first: red -> switch to
`debugging-nix-failures`; green -> continue here. Likewise, if reproducing
the symptom later surfaces a failing build/eval, stop and switch loops.

**1. INVESTIGATE - gather evidence with the matching read-only agent(s).**
Pick per evidence type (dispatch several in parallel when independent):
- **Repo archaeology** (is this module referenced anywhere? which modules
  set this option? where does a value actually come from?) - dispatch
  `Explore`. It's the read-only sweep agent; dead-code hunting and
  consumer-tracing live here, not in the main loop.
- **Eval-level ground truth** (what does the merged option resolve to on
  host X? does the generated file contain what we think?) - dispatch
  `nix-debugger` explicitly reframed: "no build failure - probe via
  `nix eval`/`nix repl` what <option/path> resolves to on <host> and report;
  diagnose only, no fix yet."
- **Live system evidence** (kernel/service logs, unit status, loaded
  modules, hardware state) - dispatch `nix-debugger` reframed as a read-only
  probe: "collect and interpret <dmesg/journalctl/systemctl/...> output
  relevant to <symptom>; no fix yet." Only possible when this chat runs on
  the affected host - otherwise ask the user to paste the logs.
- **Upstream facts** (renamed/deprecated option, known upstream or
  driver/kernel bug, version history, firmware/package changelogs) -
  dispatch `nix-package-researcher`.
- **Platform-specific symptom** (works on Linux, wrong on the mac, or vice
  versa) - dispatch `nix-compat-checker`.

**2. DIAGNOSE & FIX - dispatch `nix-debugger`** with the assembled evidence
verbatim (not a paraphrase) and the framing from step 0. It root-causes and
applies the minimal fix.
- Dead-code removal, module restructuring, or any authoring beyond a
  targeted patch - dispatch `nix-config-architect` instead, with the
  evidence and the explicit list of what to remove/change.
- If the fix replaces an existing workaround, record the workaround's exact
  content in the report so it can be restored in one step.
- sops/secrets-related root cause - stop and surface to the user; no agent
  has sops access.
- Never let any agent bump `stateVersion` as a "fix" - a symptom pointing
  at stateful-module defaults has its real cause elsewhere.
- A valid outcome of this step is "**not a config bug**" - evidence points
  at an upstream/hardware/driver problem no repo change can fix. Don't force
  a config change; go to Closing the loop and record the verdict.

**3. VERIFY THE BUILD - dispatch `nix-checker`.** Any change, even a pure
deletion, goes through flake check + the relevant dry-builds (both platforms
if a shared module was touched). Green build does NOT mean the symptom is
fixed - it only means the fix didn't break anything.

**4. VERIFY THE SYMPTOM - close against "done means" from step 0:**
- Assertable at eval time -> dispatch `nix-debugger` to re-probe the exact
  value/path and confirm it now matches Expected.
- Only observable at runtime (a service, a UI, boot behavior, hardware) ->
  the fleet cannot see it. Hand the user a precise test plan: rebuild
  command, exact conditions (e.g. full power-off vs reboot, device attached
  from cold start), the SUCCESS signature (specific log line / behavior)
  AND the FAILURE signature, plus the one-step revert. Absence of the old
  error is necessary but not sufficient - name the positive signal to look
  for. Report the fix as "applied, pending runtime confirmation" - never as
  confirmed fixed.
- **Boot/kernel/hardware-level changes carry stability risk** - the next
  boot may be degraded. Say so explicitly, let the user choose when to
  reboot/test, and never leave the system in a risky state without the
  revert path spelled out.

**5. Loop 2 -> 4** until build is green AND the symptom check passes (or is
handed to the user for runtime confirmation).

**Safeguard:** after ~4 rounds without convergence, stop looping. Report the
evidence gathered, what was tried, and the remaining unknowns.

## Closing the loop

- **Memory-file issues:** update the originating memory entry in the main
  loop whatever the outcome - agents don't own memory. Resolved -> close or
  delete it. Unresolved or pending runtime confirmation -> rewrite it with
  the new evidence, what was ruled out, what partially worked, and the
  refined next steps, so the next session doesn't re-tread this one.
- **Regression guard (optional):** if the root cause was silent config drift
  that an eval assertion could have caught, offer the `adding-nix-tests`
  loop to pin the fixed behavior.

## Exit condition

Build green via `nix-checker`, symptom verified (eval-level) or explicitly
handed to the user with a runtime test plan, and any originating memory
entry updated. A well-evidenced "not fixable in config" verdict with an
updated memory entry is also a valid exit. Report the root cause (or best
current hypothesis), what changed, and what the user still needs to confirm.

## Out of scope

- A failing build, flake check, or rebuild - that's `debugging-nix-failures`.
- Adding net-new functionality or modules - that's `creating-nix-modules`.
- A pure style/format sweep with no behavioral issue - dispatch
  `nix-syntax-linter` directly.
- A pure lookup question with nothing wrong - dispatch
  `nix-package-researcher` directly.
