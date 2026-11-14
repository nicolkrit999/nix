---
name: bumping-nix-pins
description: Use this skill to update the ROUTINE version pins of this repo (fetchFromGitHub tags/revs, fetchurl versions and hashes, flatpak Craft bundles, AppImages, Raycast/vicinae extensions, PyPI wheels, yazi/ranger plugins, Chrome CRX extensions, proton-drive CLI, sddm-pixie, agent-reach parts, agent-floor) to their latest upstream version. It walks a pre-made inventory (references/inventory.md), so nothing is rediscovered. Trigger phrases include 'bump pins', 'update the pinned versions', 'are there new versions of our flatpaks/appimages/plugins', 'refresh the hashes', 'update fetched sources', 'check for new releases of what we pin', 'update the craft apps'. Pins that exist because of an override/overlay/upstream bug are NOT handled here (use auditing-nix-workarounds). Does NOT diagnose a failing build (use debugging-nix-failures) or bump flake.lock/nixpkgs.
---

# Bumping Nix Pins

Routine pin = pinned only because Nix needs a fixed version + hash, with no
upstream bug behind it. Workaround pins are the job of `auditing-nix-workarounds`
and must never change here. The inventory is authoritative: do not re-discover.

The repo CLAUDE.md forbids doing research, builds or edits in the main loop. This
chat only frames batches, dispatches agents and loops (agents cannot call each other):
upstream lookups -> `nix-package-researcher`, edits -> `nix-config-architect`,
verification -> `nix-checker`, failures -> `nix-debugger`.

## Files

- `references/inventory.md` - the INCLUDED entries (file, current version, upstream source, hashes, couplings) and the EXCLUDED list with reasons. Read it fully first.
- `references/recipes.md` - per-source-type how-to (GitHub tag/rev, PyPI wheel, npm/go hashes, CRX, Raycast, flatpak bundle, proton, fake-hash trick, SRI rules).

## Procedure

**0. Resource check.** `bash .claude/skills/_shared/resource-check.sh`, apply per `_shared/resource-check.md` (cap heavy agents, pass `nix_flags`, ~60 agents max per run). Sync first: fetch and fast-forward `develop` (memory: sync remote before local work).

**1. Drift check (cheap).** grep the repo for `fetchFromGitHub|fetchurl|fetchCrx|fetchzip|fetchTarball|fetchgit|sha256 =|hash =|npmDepsHash|vendorHash|cargoHash` in `*.nix` and compare file paths against the inventory (INCLUDED + EXCLUDED). Anything uncovered is reported as "uncategorised" in the final report and never bumped. Do not classify it yourself beyond that.

**2. Research.** Dispatch `nix-package-researcher` (read-only) per batch (see inventory batch ids) to find the newest version per entry using the recipes. Output a table: entry, current, latest, release date, notes (breaking changes, required companions). Skip entries already latest. Report-only entries (lanzaboote) end here.

**3. Edit.** Per batch with updates, dispatch `nix-config-architect` with the table and the recipes. It changes version/rev/tag, recomputes every listed hash (SRI form), updates the coupled spots named in the inventory (version comments, duplicated host files, postPatch, version strings). It never touches EXCLUDED items or `stateVersion`. `git add` any new file.

**4. Verify.** Dispatch `nix-checker` per batch: real `nix build` of the affected toplevels or derivations (dry-builds miss hash and patch breakage), plus only the tests the change can affect (memory: test selection = affected only). Independent batches can verify in parallel up to `max_parallel_agents`. On failure send the verbatim error to `nix-debugger`, then re-check. If an entry still fails after ~2 rounds, revert just that entry (restore its old lines) and report it; keep the rest of the batch.

**5. Guard (mandatory, last).** Run `git diff --name-only` and `git diff` and check:
- every changed hunk belongs to an INCLUDED entry (or its listed coupled spot);
- no hunk touches an EXCLUDED item, an overlay, `mkForce`, `flake.lock`, or any `stateVersion`;
- duplicated host entries (flatpak lists, actual AppImage, raycast hashes) are identical on laptop and desktop;
- all hashes are SRI (`sha256-...`).
Any violation: revert that hunk, report it. Do not commit unless the user asks.

**6. Report.** Table: entry | old -> new | verified (build/tests) | skipped/reverted reason. Add: uncategorised drift findings, report-only items, and reminders: update memory notes whose facts changed (e.g. `project_agent_reach_workarounds`, `project_agent_floor_pinned_build`) and, per CLAUDE.md, docs if a documented feature changed. Never describe fixes in docs.

## Batches and limits

Batch ids are in the inventory. Desktop may run up to the resource-check cap; on the laptop run batches sequentially. The vicinae Raycast batch (rev bump invalidates all hashes) and sddm-pixie (patch breakage risk) are the expensive ones: run them last and alone.
