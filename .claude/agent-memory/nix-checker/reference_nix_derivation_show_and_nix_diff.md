---
name: nix-derivation-show-and-nix-diff
description: Recipe for derivation-level diffs (darwin drvPath changes) - nix derivation show JSON shape, nix-diff via nix run, which attrs hold file contents
metadata:
  type: reference
---

`nix-diff` is not on PATH. Run it with `nix run nixpkgs#nix-diff -- --skip-already-compared --color never OLD.drv NEW.drv` (worked, rc=0, 2026-10-15).

`nix derivation show <drv>` returns `{"derivations": {"<basename>.drv": {...}}, "version": ...}`. Index by the `derivations` dict, not by top-level keys. Dependency drvs are not included unless asked.

File contents of leaf derivations (`hm_*`, `*-plist`, `etc-*`, `*-activation-script`) live in `structuredAttrs.text` or `env.text`/`buildCommand`. Output-path diffs in `env.out`/`outputs` are only cascades of input changes; compare the content attrs, not the paths.

**Why:** the darwin drvPath changes whenever any input changes, so a plain drvPath diff tells you nothing. Use nix-diff for the tree, then `structuredAttrs` text diffs for the actual content.

**How to apply:** for any darwin-only change audit, run nix-diff first, then diff the leaf text. Scratch scripts go in the session scratchpad, not the repo.
