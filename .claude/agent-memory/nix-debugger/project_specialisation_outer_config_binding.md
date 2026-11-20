---
name: specialisation-outer-config-binding
description: In denix files, a let-binding of the file-level `config` (e.g. `c = config.myconfig.constants`) used inside `specialisation.<x>.configuration` sees the PARENT host's values, not the spec's mkForce overrides
metadata:
  type: project
---

`users/krit/nixos/specializations/school.nix` binds `c = config.myconfig.constants` at file top (still true) and the spec does `myconfig.constants.shell = lib.mkForce "bash"` (school.nix ~546). A `c.shell` read inside `specialisation.school.configuration` evaluated to the host's `"fish"`, so a `lib.mkIf (c.shell == "bash")` shell hook was silently dropped (confirmed 2026-09-29; that hook no longer exists in school.nix, the trap is generic via `nix eval ...specialisation.school.configuration.home-manager.users.krit.programs.{bash.initExtra,fish.interactiveShellInit}`).

**Why:** the file-level `config` is the parent evaluation; the spec's overrides only exist in the nested configuration.
**How to apply:** when a spec-only behavior "does nothing", check whether it branches on a constant the spec itself overrides; eval the nested spec attr path to confirm. Related: [[denix-ifenabled-arg-set]].

Same session: school distrobox containers break whenever the distrobox store path they were created with is GC'd (distrobox bind-mounts `/nix/store/<hash>-distrobox-*/bin/distrobox-{init,export,host-exec}` by absolute path). Symptom: `crun: cannot stat .../distrobox-export`. Only fix is recreating the container.
