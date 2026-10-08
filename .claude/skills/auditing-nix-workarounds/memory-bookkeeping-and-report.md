# Memory bookkeeping, user confirmation and final report (Steps 5-7)

## Step 5 - Memory bookkeeping (main loop, no agent)

- **Reverted and `nix-checker` green:** do not delete or mark resolved yet.
  Edit the file: reverted on today's date, verification passed, pending the
  user's live rebuild-and-test confirmation. Leave the `MEMORY.md` index line.
- **Still needed (fix not in the locked revision, or upstream unresolved):**
  add today's check date and refresh content if anything changed (new issue
  comment, PR opened/merged, status change). Mirror the existing
  "re-confirmed still needed on <date>" pattern, e.g.
  `project_vicinae_bluetooth_extension_blocked.md`,
  `project_waybar_hyprland_patch.md`.
- **Reverted then restored:** add today's date and state plainly that research
  said safe, it was reverted, `nix-checker` failed in a way traced to the
  tweak's absence, and it was restored and re-verified green, so necessity is
  now build-proven. This supersedes earlier "still needed" wording.
- **Research inconclusive:** add today's date, note no research method could
  confirm or deny the upstream condition, and that only reverting and
  rebuilding live can tell, which was left to the user.

## Step 6 - End-of-run user confirmation

For every candidate reverted and green, ask the user in ONE batched list (not
mid-run, not one question per candidate): did you rebuild and test
**<specific feature>** live, and did the reversal work?

- **Yes** -> delete that memory file and its `MEMORY.md` index line.
- **No / not tested yet** -> leave the memory file as edited in Step 5 and
  `MEMORY.md` untouched. Normal outcome, not a failure.

## Step 7 - Final report

Every processed candidate lands in exactly one bucket:

- **Reverted** - what changed, verification result, pending Step 6 (or already
  confirmed and cleaned up).
- **Must stay** - confirmed still needed: issue/PR links, changelog
  references, "landed in nixpkgs commit X, not yet in the locked revision".
- **Reverted, then proven necessary and restored** - distinct from "must
  stay": research said safe, the build proved otherwise. State that this is
  stronger evidence than research alone.
- **Cannot be verified via research - only by trying** - the Step 3
  inconclusive case. Say explicitly that no research method could decide it
  and the only way is to revert and rebuild live. Present after the buckets
  above. Do not revert without the user opting in.
- **Lock-update opportunities** - fix exists in a newer revision than the
  locked one. Ask whether to update the lock (or the specific input); never
  update it yourself.
- **Needs physical verification** - Step 2 items no agent could check, with
  what to test.
