---
name: feedback-ifenabled-arg-scope
description: denix ifEnabled lambdas only receive cfg/myconfig as named args — pkgs/lib/config must come from the module's top-level args via closure
metadata:
  type: feedback
---

`nixos.ifEnabled = { cfg, myconfig, ... }: {...}` (and the `darwin.ifEnabled` /
`home.ifEnabled` equivalents) only ever gets `cfg` and `myconfig` handed to it by
denix's call site. Destructuring anything else by name there — `pkgs`, `lib`,
`config`, `inputs` — fails at eval time with:

```
error: function 'ifEnabled' called without required argument '<name>'
```

**Why:** denix builds a fixed attrset (`{ cfg, myconfig }`) to call the
`ifEnabled` lambda with. A Nix lambda pattern `{ a, b, ... }:` requires every
named key in the pattern to be present in the caller's attrset — `...` only
permits extras, it doesn't make named args optional. So naming `pkgs`/`lib`/
`config` in that specific lambda's argument pattern is a hard error, not a
silent nil.

**How to apply:** Any module attr needed inside `nixos.ifEnabled`/`darwin.ifEnabled`/
`home.ifEnabled` other than `cfg`/`myconfig` must be captured via closure from
the module's *top-level* function args instead — i.e. add it to
`{ delib, pkgs, lib, config, ... }:` at the top of the file (before
`delib.module { ... }`), then just reference it by name inside the ifEnabled
body without redeclaring it in the ifEnabled lambda's own arg pattern. This is
the pattern already used correctly in `users/krit/nixos/services/nas/owncloud.nix`
and `modules/nixos/services/autotrash.nix`/`snapshots.nix`. When writing a new
module, copy one of those files' arg-scoping shape rather than assuming denix
merges module args + ifEnabled args together.

Related gotcha found in the same session: when a NixOS-level (not home-manager-level)
module needs `mkOutOfStoreSymlink` for a `home-manager.users.<user>.home.file.*`
entry, the *outer* `config` in that file is the NixOS system config, which has
no `lib.file` namespace. Reach into the home-manager submodule instead:
`config.home-manager.users.${user}.lib.file.mkOutOfStoreSymlink "path"` — not
`config.lib.file.mkOutOfStoreSymlink`.
