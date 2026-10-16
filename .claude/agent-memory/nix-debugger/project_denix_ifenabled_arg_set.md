---
name: denix-ifenabled-arg-set
description: denix ifEnabled/always bodies receive ONLY {name, myconfig, cfg, parent} - no config/lib/pkgs; use myconfig.constants.hostname for per-host gating
metadata:
  type: project
---

denix's `nixos.* / home.* / darwin.* / myconfig.*` block bodies are **not** NixOS
modules. In `lib/configurations/module.nix` denix does `wrap = x: if typeOf x ==
"lambda" then x args else x` with `args = { name; myconfig; cfg; parent; }`.
Nothing else is passed. Adding `config`, `lib`, `pkgs`, `osConfig`, or `hm` to the
lambda's arg pattern throws `function 'ifEnabled' called without required argument
'<arg>'` - the `...` ellipsis permits *extra* args, never *missing* ones, so the
error names denix's own attr, not your file, which makes it look framework-level.

**Why:** the wrapped result is placed inside `lib.mkIf enabled (...)` in `imports`,
so it must already be a plain attrset - there is no module-system evaluation step
that could inject `config`/`lib`.

**How to apply:**
- `lib` / `pkgs` / `inputs` → destructure them in the **file's top-level** arg set
  (`{ delib, lib, pkgs, ... }:`) and close over them.
- Need the NixOS `config`? You usually don't: for per-host gating use
  `myconfig.constants.hostname` (repo idiom, see `modules/nixos/toplevel/kernel.nix`,
  `users/krit/nixos/services/windows-mount.nix`), not `config.networking.hostName`.
- Genuinely needing `config` means the code belongs in an `imports`-ed submodule
  inside an `always {}` block - `imports` under `ifEnabled` hits the mkIf trap.

- Proven working (2026-10-16, btrfs autoScrub in common-configuration-nixos.nix):
  `nixos.always = { myconfig, ... }: { imports = [ ({ config, ... }: { ... }) ]; ... }`.
  For moduleSystem "nixos" apply.nix passes the block result unchanged into `imports`,
  so the nested lambda is a real NixOS module and receives `config`.
- `delib.host` blocks (`myconfig = ...` in hosts/*/default.nix) are wrapped the same way
  (lib/configurations/host.nix) with only `{ name, cfg, myconfig }`: `config.myconfig.X`
  there must be `myconfig.X`. Same error text: "function 'myconfig' called without
  required argument 'config'". Audit batches have introduced both variants at once, so
  after fixing one, re-eval every host before calling it done.

Related: [[feedback_delib_home_ifenable_patterns]]
