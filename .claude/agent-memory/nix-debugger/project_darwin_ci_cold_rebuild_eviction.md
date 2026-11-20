---
name: darwin-ci-cold-rebuild-eviction
description: build-darwin.yml timeout with an unchanged toplevel drv = krit-nixos cachix evicted the darwin closure; a silent log means both --max-jobs 2 slots are hung (herdr zig fetchDeps, 2026-11-20)
metadata:
  type: project
---
Run 44714428494 (2026-11-20) timed out at 150 min, while the green run 40 min earlier fetched everything. Both commits evaluated to the SAME toplevel drv (`6q0l...darwin-system-26.11.ff0e21a`), but its output had become a 404 on krit-nixos.cachix.org, so CI rebuilt all ~395 local derivations. The log went silent 2 min in. The darwin build uses `--max-jobs 2`, so silence with no new `building` lines means both slots are stuck. Here they were herdr-core and herdr-app `-zig-deps` (zig_0_16.fetchDeps fetchAll; kevinpita's cache is x86_64-linux only). A cold run on 2026-11-18 had built the same deps in about 69 minutes.

**Why:** the free cachix cache evicts entries, so any eviction turns the next darwin run into a cold build. Any darwin package built from source that has a network fetch FOD can then hang until the timeout.

**How to apply:** to diagnose, eval `git+file://...?rev=<sha>#darwinConfigurations.Krits-MacBook-Pro.system.drvPath` for both runs. If the drvPaths are equal, curl `<hash>.narinfo` on krit-nixos. Diff the "will be built" lists and find the last `building` lines before the silence. herdr was disabled on the Mac host as the fix. See [[project_gitea_assets_ci_403_cachix_eviction]].
