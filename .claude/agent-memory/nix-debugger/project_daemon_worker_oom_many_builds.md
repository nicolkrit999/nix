---
name: daemon-worker-oom-many-builds
description: laptop nix-daemon worker OOM (20-25 GB anon) on a nixpkgs bump with ~4000 local builds in ONE invocation; dry-run worker is 57 MB; progress persists, chunk builds
metadata:
  type: project
---
2026-11-10: after a nixpkgs bump (31ecbac -> f4a03c0), the laptop toplevel needed 4056 local builds: crane per-crate graphs (`cargo-package-*` + `crate-*.tar.gz`) of zapfast (~936), openlogi, concord, lanzaboote-stub, vicinae, all following root nixpkgs, plus the patched linux_testing kernel (7.4-rc1, never cached). The nix-daemon per-connection worker (Nix 2.34.9) grew 15 -> 25 GB anon during building and got OOM-killed twice (-j2, then -j1 --cores 1). `--dry-run` of the same target had a worker peak of only 57 MB, so the planning phase (queryMissing) is not the cause. The memory grows with the number of goals built in one invocation. That cause is an inference and was not profiled. Nov 5, when zapfast was added, the cgroup already peaked at 17.9 GB.

**Why:** The cause is not config or a single lock input. Reverting one input does not remove the crate graphs because every Rust input follows root nixpkgs.
**How to apply:** Completed builds stay in the store between runs (4056 dropped to 2999 builds left after two killed runs). Check the remaining count with `--dry-run`. Then build in chunks, either per sub-target or with `xargs -n 300 nix-store -r` over the to-build list, so each run starts a new daemon worker. Other options are building on the desktop or closing Zen and node first. Related: [[flake-check-misses-build-failures]].
