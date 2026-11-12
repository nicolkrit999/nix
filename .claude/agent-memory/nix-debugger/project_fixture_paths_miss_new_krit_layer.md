---
name: fixture-paths-miss-new-krit-layer
description: fake-host test fixtures list module paths by hand; moving generic->krit coupling into a NEW krit file (e.g. neovim-mime.nix) silently drops it from the fixture tree
metadata:
  type: project
---

Fake-host fixtures (`denix.lib.configurations { paths = [ ... ]; }`, e.g. test-app-resolution's KRIT tree) hand-list every module. When a refactor removes a krit check from a generic module and moves it into a new krit-layer file (b9d93d95: mime.nix `hasKritNvim` -> `users/krit/nixos/programs/neovim-mime.nix` setting `myconfig.mime.editorDesktopIds`), the fixture keeps evaluating but the new file is absent, so the "module on" twins fall back to vanilla (user-neovim instead of custom-nvim) and the control check reports "did not detect".

**Why:** 2026-11-12 app-resolution 3/89 failures looked like a config regression; config was correct, fixture path list was stale.
**How to apply:** when a test of a generic module suddenly loses krit-specific behaviour, `git show --stat HEAD` for new `users/krit/**` files and grep `templates/tests` for fixtures listing the old sibling path. Related: [[test-controls-host-toggle-coupling]].
