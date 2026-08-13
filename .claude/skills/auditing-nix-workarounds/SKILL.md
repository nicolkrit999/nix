---
name: auditing-nix-workarounds
description: Use this skill to sweep this repo's memory files for "momentary" tweaks - temporary code that exists only because of a current upstream limitation (missing hardware/kernel/driver support, an open GitHub issue/PR, a package not yet released or merged, a fix not yet in the tracked stable channel) - confirm which ones are still actually present in the repo, check whether the underlying upstream condition has resolved, and revert whichever are confirmed fixed in the current stable channel. Trigger phrases include 'check for momentary fixes', 'are any of our workarounds obsolete', 'sweep memory for temporary tweaks', 'can we revert any pins/overlays yet', 'audit the temporary hacks', 'is this upstream fix landed yet', 'do a momentary-tweak sweep'. Drives a memory-scan -> confirm-live -> research (nix-package-researcher across BOTH the stable and unstable channels, or a one-off generic agent for non-package upstream research) -> revert (nix-config-architect) -> verify (nix-checker/nix-debugger) loop, followed by memory bookkeeping and an end-of-run user confirmation phase. Does NOT retry a single already-known workaround the user points at directly (use investigating-nix-issues) or diagnose a currently-failing build (use debugging-nix-failures).
---

# Auditing Nix Workarounds

This repo's CLAUDE.md mandates delegating research, verification, and
authoring to agents - the orchestrator (this chat) only frames candidates,
dispatches agents, and loops; agents cannot call each other. This skill is
NOT read-only: it is expected to revert code when warranted, but only ever
through `nix-config-architect` - never by editing `.nix` files directly in
the main loop.

## Step 0 - DISCOVER (main loop, no agent)

Read **every** file in
`/home/krit/.claude/projects/-home-krit-nix/memory/`, not just the ones
whose `MEMORY.md` index line sounds tweak-related - the one-line index
description can undersell or misdescribe what's actually inside a file.
Discovery is memory-only for this skill; do not grep the repo for
TODO/FIXME markers as a source of new candidates (that's a different sweep,
already covered by `project_repo_todo_fixme_markers.md`).

From each file, extract candidates: version pins, disabled options,
`mkForce`/`overrideAttrs` hacks, commented-out blocks, or anything else
whose stated reason is "waiting on X" - a kernel patch, driver/hardware
support, an upstream GitHub issue or PR, a package not yet released or
merged, or a fix not yet in the tracked channel.

## Step 1 - CONFIRM LIVE (main loop, no agent)

For each candidate, read the specific file(s) the memory entry references
to confirm the tweak is still physically present as described. This is a
plain file read, not research or verification, so it stays in the main
loop per CLAUDE.md's own exception for "reading a single file to answer a
question." Drop any candidate that's already gone or has already changed
shape from what the memory describes - don't act on stale memory.

## Step 2 - RESEARCH each live candidate

Route by what kind of fact is needed. Dispatch several in parallel when
candidates are independent.

- **Package/attribute/option/channel status** -> dispatch
  `nix-package-researcher`. This repo tracks `nixos-26.05` and wants to
  stay there - the researcher must check **both** the current stable
  channel and `unstable`. Checking unstable is only to learn whether the
  underlying fix has landed there yet, as a signal of when it'll reach
  stable. **A fix present only in unstable is never grounds to revert.**
- **Non-package upstream research** (is this GitHub issue closed, did this
  kernel version add the driver, has this upstream PR merged, what does
  the changelog say) -> spawn a one-off generic subagent via the Agent tool
  with `model: sonnet` and a fresh, self-contained prompt. This is a
  throwaway agent for this one check - not one of this repo's committed
  `.claude/agents/*.md`, and nothing about it is persisted.
- **Physical/manual verification** (does the mic actually record now, does
  the webcam show an image, does Bluetooth actually pair, does the
  fingerprint reader actually register a print) -> no agent can do this.
  Do not guess. Record it as an open item for the user to test live after
  rebuilding (see Step 5).

## Step 3 - DECIDE per candidate

- **Fixed in stable, or the upstream condition is confirmed resolved** ->
  revert it (Step 4).
- **Fixed only in unstable, or the upstream condition is still open** ->
  leave the code untouched. Capture the evidence (issue/PR link, changelog
  reference, "present in unstable commit X but not yet backported" etc.)
  for the final report and the memory update in Step 5.
- **Research inconclusive** - `nix-package-researcher` and/or the one-off
  research agent turned up no evidence either confirming or denying that
  the upstream condition has resolved (no changelog entry, no issue/PR to
  check, nothing in either channel that speaks to it either way). This is
  different from "still open" - there is simply no research signal at all,
  in either direction. Do **not** auto-revert this one speculatively; leave
  the code untouched and route it to the Step 7 report as its own item -
  the only way to actually know is to revert it and rebuild, and that is
  the user's call to make, not something this skill decides on its own.

## Step 4 - REVERT (only candidates confirmed fixed in stable)

1. Dispatch `nix-config-architect` to remove the tweak and restore normal/
   upstream behavior. If the tweak had an explanatory comment, that comment
   must be removed with it - no orphaned comments, and no new comments
   added as part of the revert (this repo defaults to no comments; any
   explanation worth keeping belongs in the memory file, not the code).
   If the revert touches cross-arch code, loop `nix-compat-checker` in
   alongside it per its usual role.
2. Dispatch `nix-checker` to verify (flake check + relevant dry-builds,
   `--impure` on Darwin).
3. **On failure, first determine whether the failure is evidence the tweak
   is still load-bearing, or an unrelated/fixable bug:**
   - Dispatch `nix-debugger` with the verbatim error, reframed to explicitly
     ask it to judge which case this is before touching anything.
   - **If the failure traces directly back to the absence of the reverted
     tweak** (the research said it was safe, but the build itself now
     proves the upstream condition is not actually resolved) -> this is
     empirical proof the tweak is still necessary. Do not debug toward
     making the revert work. Instead: dispatch `nix-config-architect` to
     **restore the original tweak exactly as it was**, then re-dispatch
     `nix-checker` to confirm the restored state is green again. Treat this
     candidate as **reverted-then-restored** for Step 5/7, not as a plain
     "still needed" - the distinction (research said safe, build proved
     otherwise) is itself useful information for the user.
   - **If the failure is unrelated to the reverted tweak** (a genuine bug
     `nix-debugger` can fix on its own merits) -> let it fix and re-verify
     via `nix-checker` as normal, looping 2 -> 3 until green.
4. **Safeguard:** after ~4 rounds without convergence on an unrelated-bug
   failure, stop and fall back to the reverted-then-restored handling above
   - restore the original tweak, re-verify green, and note in the report
   that convergence wasn't reached and why.
5. Never bump `stateVersion` as part of any revert. Never commit or push -
   the user rebuilds and tests on their own machine; git actions happen
   only if the user explicitly asks, same as this session's normal rules.

## Step 5 - MEMORY BOOKKEEPING (main loop, no agent - agents don't own memory)

- **Reverted and `nix-checker` green:** do not delete or mark the memory
  file fully resolved yet. Edit its content to state the tweak was
  reverted on today's date, that verification passed, and that it is
  pending the user's live rebuild-and-test confirmation. Leave the
  `MEMORY.md` index line untouched for now.
- **Still needed (unstable-only or upstream unresolved):** update the
  memory file with today's check date, and refresh its content if anything
  changed since it was last written (new comment on the issue, a PR
  opened/merged, status changed) - mirror the existing "re-confirmed still
  needed on <date>" pattern already used in this repo's memory (e.g.
  `project_vicinae_bluetooth_extension_blocked.md`,
  `project_waybar_hyprland_patch.md`).
- **Reverted then restored (Step 4 empirical-proof case):** update the
  memory file with today's date, state plainly that research indicated the
  tweak was safe to revert, it was reverted, `nix-checker` then failed in a
  way that traced back to the tweak's absence, and it was restored and
  re-verified green - so the tweak is now confirmed (not just assumed)
  still necessary. This supersedes any prior "still needed" wording in the
  file with stronger, build-proven evidence.
- **Research inconclusive (Step 3):** update the memory file with today's
  check date, note that no research method could confirm or deny the
  upstream condition either way, and that the only way to know is to
  actually revert and rebuild live - which this skill left to the user's
  discretion rather than attempting speculatively.

## Step 6 - END-OF-RUN USER CONFIRMATION

For every candidate that was reverted and passed `nix-checker`, ask the
user (batched into one list, not one question per candidate mid-run):
did you rebuild and test **<specific feature>** live, and did the reversal
actually work?

- **Yes, it works** -> now delete that memory file and remove its line
  from `MEMORY.md`'s index.
- **No / not tested yet** -> leave the memory file as edited in Step 5 and
  leave `MEMORY.md` untouched. This is a normal, expected outcome, not a
  failure - most runs will end here since the user hasn't rebuilt yet.

## Step 7 - FINAL REPORT

Structure the report around these explicit buckets - every processed
candidate must land in exactly one:

- **Reverted** - what changed, the verification result, and that it's
  pending the Step 6 confirmation (or already confirmed and cleaned up).
- **Must stay (cannot be reverted)** - candidates confirmed still needed
  via research: precisely why (issue/PR links, changelog references,
  "landed in unstable commit X, not yet in 26.05" etc.).
- **Reverted, then proven necessary again and restored** - its own bucket,
  distinct from "must stay": research said the tweak was safe to revert,
  it was reverted, but verification (`nix-checker`) then failed in a way
  that traced back to the tweak's absence, so it was put back and
  re-verified green. State plainly that this is stronger, build-proven
  evidence of necessity than the plain "must stay" bucket, since research
  alone got it wrong here.
- **Cannot be verified via research - only by trying** - candidates from
  the Step 3 "research inconclusive" case. Tell the user explicitly that no
  research method (package/channel lookup, issue/PR/changelog check) could
  determine whether this tweak is still needed, and that the only way to
  find out is to actually revert it and rebuild live. Present these after
  the buckets above, once everything that was researchable is done. Do not
  revert these without the user opting in.
- **Unstable-only opportunities** - explicitly ask the user whether they
  want to move that specific package/component to unstable to get the fix
  early. Never make that switch yourself - a channel change is a separate,
  larger decision the user makes explicitly.
- **Needs physical verification** - anything from Step 2 that no agent
  could check, listed as an open item with what to physically test.

## Exit condition

Every discovered-and-confirmed-live candidate has been researched, decided
on, and (if reverted) verified green via `nix-checker`, including the
restore-and-reverify path for any candidate that turned out to still be
load-bearing; every touched memory file reflects today's findings; the
Step 6 confirmation question has been asked for every candidate left in
the reverted state; and the final report sorts every candidate into
exactly one of: reverted / must-stay / reverted-then-restored /
cannot-be-verified-via-research / unstable-only / needs-physical-
verification.

## Out of scope

- Retrying or investigating a single workaround the user already points at
  directly - that's `investigating-nix-issues`.
- A currently-failing build/flake check/rebuild - that's
  `debugging-nix-failures`.
- Discovering new candidates by grepping the repo for TODO/FIXME/HACK
  markers instead of memory - that's a different sweep, not this skill.
- Actually switching a host or package to the unstable channel - always
  hand that decision back to the user; never perform it as part of this
  skill.
