---
name: flake-lock-root-nixpkgs-node
description: flake.lock root `nixpkgs` input resolves to node nixpkgs_2 (2786a2a7), NOT the top-level "nixpkgs" node (cab77823) that the lock also contains; check root.inputs before answering "the locked rev"
metadata:
  type: reference
---

In `/home/krit/nix/flake.lock` there are two nixpkgs nodes. The root input `nixpkgs` points at node `nixpkgs_2` (rev `2786a2a72088ecf32aea5b3ec52099e6a7cff78f`, lastModified 1795234589, about 2026-11-20). The node named `nixpkgs` (rev `cab778239e705082fe97bb4990e0d24c50924c04`, lastModified 1754340878, 2025-08-04) is a transitive dependency only. `nixpkgs-stable` root maps to `0dc498bf...`.

**Why:** a research request named cab778 as "the locked rev", but that is not what the flake evaluates. Versions differ a lot (mas 2.2.2 vs 7.0.0, gcc 14.3.0 vs 16.2.0, vicinae absent vs 0.30.0).

**How to apply:** resolve the effective rev from `root.inputs.nixpkgs` (python: `nodes[root]["inputs"]["nixpkgs"]`) before quoting a rev. Name both if the user cites the top-level node. Do the same check whenever a flake.lock edit moves the root input.
