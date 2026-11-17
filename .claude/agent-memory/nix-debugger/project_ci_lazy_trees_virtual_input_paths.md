---
name: ci-lazy-trees-virtual-input-paths
description: CI test legs run Determinate Nix (lazy trees) - noContext "${flake.inputs.X}" is a virtual store path that never exists on the runner, and its hash differs from the local one
metadata:
  type: project
---
CI (`DeterminateSystems/nix-installer-action`, `determinate: true`) evaluates flake inputs lazily. `unsafeDiscardStringContext "${flake.inputs.qylock}/themes"` gives a virtual path (`8m3dx...-source` on CI, `483v9...-source` locally with Nix 2.34) that is never copied to the store, so a shell test reading it gets "No such file". Derivations that use the input WITH context are fine. Hit in test-sddm-qylock on 2026-11-17 (4/44 red, negative "! grep upstream" checks passed for the wrong reason).

**Why:** local plain Nix copies inputs eagerly, so the test is green locally and only CI fails; the hash mismatch between CI log and local store is the tell.

**How to apply:** when a test hands a flake input path to a shell script, wrap it in a tiny derivation (`runCommandLocal ... "ln -s ${input}/sub $out"`), add it to the test's `nix build` list, and guard that the expected file exists. Related: [[ci-store-snapshot-not-closure]].
