---
name: dart-runtimedeps-multi-entry-trap
description: buildDartApplication/buildFlutterApplication runtimeDependencies with >1 entry silently yields NO LD_LIBRARY_PATH (non-structuredAttrs string treated as one array element); localsend zlib override broke this way
metadata:
  type: project
---

dart-fixup-hook.sh loops `"${runtimeDependencies[@]}"` and does `addToSearchPath ... "$dep/lib"`. Without `__structuredAttrs` (flutter/dart apps are false), the list is a single space-joined string, so with 2+ entries the hook tests `-d "/nix/store/a /nix/store/b/lib"`, fails, and the wrapper gets no LD_LIBRARY_PATH at all. Exactly one entry works.

Incident 2026-11-22: localsend.nix `overrideAttrs (old: runtimeDependencies = old ++ [zlib])` after upstream already had `[ zlib ]` -> `[zlib zlib]` -> libz.so.1 not found at start. Plain pkgs.localsend worked; override removed.

**How to apply:** for a dart/flutter app missing a dlopen'd lib, check the wrapper (`bin/<app>` LD_LIBRARY_PATH), not RUNPATH; never append to a non-empty runtimeDependencies - use `extraWrapProgramArgs = "--suffix LD_LIBRARY_PATH : ..."` instead. Related: [[python-structuredattrs-default]].
