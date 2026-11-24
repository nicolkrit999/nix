---
name: vicinae_services_programs_rename_warning
description: services.vicinae->programs.vicinae rename generates self-referential mkRenamedOptionModule warning; no upstream fix yet
metadata:
  type: project
---

## Current State

**Pinned vicinae flake rev when this was researched:** `1f6de859a4142e24e73f7cc8a70df1a6e8d77a0e` (2026-08-17 v0.26.3 bump). flake.lock now pins `35703147` (vicinae input, checked 2026-11-24); the upstream-fix conclusion below was NOT re-verified against it.

The repo's `nix flake check` warns:
```
evaluation warning: krit profile: The option `services.vicinae.settings' 
defined in ... has been renamed to `programs.vicinae.settings'.
evaluation warning: krit profile: The option `services.vicinae.themes' 
defined in ... has been renamed to `programs.vicinae.themes'.
```

Both warnings point to the **upstream** vicinae module itself at `/nix/store/.../modules/vicinae/hm.nix` (not the repo's config).

## Root Cause

Upstream vicinae's home-manager module (`nix/home-manager-module.nix`) uses `lib.mkRenamedOptionModule` to create backward-compat aliases:

```nix
imports = lib.flatten [
  (map (x: lib.mkRenamedOptionModule ["services" "vicinae" x] ["programs" "vicinae" x]) [
    "enable" "package" "enableFirefoxIntegration" "extensions" "themes" "settingOverrides" "settings"
  ])
  ...
];
```

**Why it warns:** `lib.mkRenamedOptionModule` from nixpkgs itself generates a "has been renamed to" warning whenever it declares both the old and new option names in the same module. This is a **self-referential warning** - the module defines both sides of the rename internally, so the module system sees the old name being declared in the same file as the new name, triggering the warning even though the user only sets the new name.

This is not a configuration error. The user is already doing the right thing by using `programs.vicinae.*`. The warning is an artifact of how the rename shim is implemented upstream.

## Is There a Newer Upstream Fix?

**Short answer: No.**

- Current pinned rev: `1f6de85` (2026-08-17)
- Latest upstream rev: `db651f6` (2026-08-20, just 3 days later)
- Only one commit between them: emoji list refresh (doesn't touch home-manager-module.nix)
- Last modification to home-manager-module.nix: commit `630036e` (2026-07-20, "build browser native host messaging")
- No open issues or recent PRs address this warning

The upstream vicinae repo has not fixed the mkRenamedOptionModule self-warning in recent versions.

## Would Removing Empty `themes = {}` Help?

**No** (the repo no longer has such a block in modules/nixos/programs/vicinae.nix). The warning comes from the upstream module's own rename declarations, regardless of what the user sets.

## Why This is Not Fixable in This Repo

The warning originates from upstream vicinae's implementation. The repo is already using the correct approach (`programs.vicinae.*`). The only ways to fix it would be:

1. **Upstream: Change nixpkgs' mkRenamedOptionModule** - suppress self-warnings when both halves of a rename are declared in the same module (would require nixpkgs PR)
2. **Upstream vicinae: Use a different approach** - manually declare the old names as deprecated aliases instead of using mkRenamedOptionModule (would require vicinae PR)
3. **This repo: Fork vicinae's home-manager module** - copy it, remove the mkRenamedOptionModule lines, keep only the new option names (not recommended; adds maintenance burden)

## Recommendation

**Status:** No action needed. This is a cosmetic warning that does not affect functionality. The configuration is correct. Monitor upstream for fixes in vicinae releases, but there's no workaround worth implementing in the current repo state.

If this warning becomes bothersome in the future:
- Check vicinae's GitHub issues for any filed reports about the warning
- Consider filing an upstream issue if none exists, referencing that mkRenamedOptionModule generates spurious warnings when the module declares both old and new names
