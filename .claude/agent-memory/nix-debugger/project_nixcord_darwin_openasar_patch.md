---
name: nixcord-darwin-openasar-patch
description: Darwin-only discord/openasar build failures come from nixcord's own pkgs/discord (openasar.patch on top of nixpkgs openasar); Linux uses nixpkgs discord and never builds it
metadata:
  type: project
---

discord.nix routes Linux to nixpkgs `pkgs.discord` (nixpkgs openasar, cached), but darwin uses nixcord's `pkgs/discord`, which applies `patching/openasar.patch` to `pkgs.openasar` (our nixpkgs, via follows). When the nixcord patch and nixpkgs openasar `postPatch` (`--replace-fail` on src/cmdSwitches.js) both rewrite the same lines, only the darwin build breaks, and only at build time: a dry-run passes and the Linux toplevels stay green.

2026-11-20: nixcord 0388b27 -> 8502898 (PR #66 lock bump; nixpkgs unchanged) caused this. Fix: the darwin branch of discord.nix passes an openasar with `--replace-fail` -> `--replace-quiet`.

**Why:** darwin CI is the only place this builds, and nobody owns a Mac ([[darwin-ci-cold-rebuild-eviction]]).
**How to apply:** reproduce on Linux with `pkgs.openasar.overrideAttrs (o: { patches = o.patches ++ [ "${inputs.nixcord}/pkgs/discord/patching/openasar.patch" ]; })`. The source is platform-independent, so it fails or passes the same way on Linux as on darwin. If that builds without the override, the override can be removed.
