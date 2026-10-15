---
name: ci-store-snapshot-not-closure
description: CI test legs restore a GC-trimmed store snapshot, so store paths that appear only as text in an evaluated script may be missing on the runner
metadata:
  type: project
---
The test legs restore build.yml's store snapshot, and build.yml trims it to `gc-max-store-size-linux` before saving (the toplevel is not a GC root). Which paths survive changes from snapshot to snapshot. On 2026-10-15, rsync-3.5.0 was in the snapshot that run 38764941409 restored and missing from the one run 38778921290 restored. Same lock, same test.

**Why:** a test that runs a script it pulled out of `nix eval --raw` (the store paths are only instantiated, never realised) passes or fails depending on which snapshot it got. When the binary is missing, a "command fails, so X is kept" case can pass for the wrong reason.

**How to apply:** if a CI-only failure says `.../bin/<tool>: No such file or directory` for a /nix/store path, suspect this before anything else. The test-side fix is to realise every `builtins.getContext` drv with `nix build --no-link <drv>^<outs>`, then fail loudly if any referenced store path is still missing. See test-ext-dotfiles-mappings and [[failing-test-triage]].
