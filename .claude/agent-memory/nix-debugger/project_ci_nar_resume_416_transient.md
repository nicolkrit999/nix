---
name: ci-nar-resume-416-transient
description: CI "HTTP error 416" on a cache.nixos.org NAR + "no substituter that can build it" cascade = transient curl resume bug, not a config regression
metadata:
  type: project
---

build-darwin run 42051323052 (2026-11-05, commit d5300943) failed with `unable to download .../nar/<hash>.nar.xz: HTTP error 416` then `path '...-onnx-src' is required, but there is no substituter that can build it`, cascading to onnxruntime -> magika -> markitdown -> headroom -> home-manager-path -> darwin-system. The preceding warning was `retrying from offset 8266756` where 8266756 == the narinfo FileSize: the whole file had arrived, curl broke at the end, and the range resume past EOF returned 416. A second run on the SAME sha two minutes earlier was green.

**Why:** "some references of path X could not be realised" plus "Cannot build ... N dependencies failed" looks like a broken package, but the root is one failed NAR fetch.

**How to apply:** grep the full log (`rtk proxy gh run view --log`, the --log-failed tail hides it) for the first `error:`; if it is a download 416 / "Failed sending data to the peer", compare `retrying from offset` with the narinfo FileSize and check `gh run list --workflow ...` for a green run on the same headSha. If so: re-run, no code change. See [[flake-check-misses-build-failures]].
