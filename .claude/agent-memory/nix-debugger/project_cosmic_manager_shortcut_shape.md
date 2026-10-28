---
name: cosmic-manager-shortcut-shape
description: cosmic-manager shortcuts submodule adds description = null to every entry; exact-attrset shape checks on evaluated shortcuts must allow it; test normKey sorts modifiers
metadata:
  type: project
---

Evaluated `wayland.desktopManager.cosmic.shortcuts` entries always carry `description` (default `null`), even when the module wrote `{ key; action; }` only (the Disable shadows in cosmic-binds.nix).

**Why:** test-cosmic-binds `disableShapeOk` compared `s == { key; action; }` and failed on all 5 Disables (2026-10-29), while the module was live-verified correct.

**How to apply:** compare shapes as `(s.description or null) == null && removeAttrs s [ "description" ] == ...`. Also in that test `normKey` sorts modifiers alphabetically (`ctrl+super+3`, `alt+super+a`): hand-written expected keys must use sorted order, or filters silently return `[ ]` (the first bug there was `lib.head` on an empty list that aborted the whole results eval, because tryEval does not catch it).
