---
name: nix-tests harness read-only IFD
description: nix-tests runs `nix-instantiate --eval` = read-only store; any IFD in a fake host fails on a fresh CI store ("path ...drv is not valid") but passes locally
metadata:
  type: project
---

The nix-tests harness (pinned 866429d2, archived upstream) runs each `*_test.nix` as
`nix-instantiate --eval --strict --json` WITHOUT `--read-write-mode`, so derivations are never
written to the store. Any IFD (e.g. stylix `base16Scheme = "${pkgs.base16-schemes}/...yaml"` in a
test stub) dies with `path '<hash>-X.drv' is not valid` on a fresh store, but passes wherever an
earlier `nix eval`/`nix build`/host rebuild already wrote the .drv (desktop always; old single-job
CI because minimal-defaults/arch-compat ran first). Found 2026-10-11, CI run 38099944203.

**Why:** cost a multi-agent investigation; local runs can never reproduce it.
**How to apply:** detect locally with `NIX_CONFIG="allow-import-from-derivation = false"` on the
harness command (works through `nix run`, flags IFD even when outputs exist); fake hosts should use
an inline base16 attrset. Repro on a fresh store: `nix-instantiate --store <dir> --eval ...`.
Separate class: `readFile (unsafeDiscardStringContext drvOut)` is not IFD and the guard misses it.
Related: [[flake-check-misses-build-failures]].

Also (2026-10-16, run 38879489567): CI runs Determinate Nix 3.23 whose plain `nix eval --impure`
does NOT write .drv files either, so `readFile` of a drvPath (test-nixos-wallpapers `drvText`)
fails on CI ("path ...-plain-control.drv does not exist") unless the drv is already in the restored
snapshot. Fix pattern: `nix-instantiate "$SCEN" -A <writeText anchor carrying the strings>` first.
