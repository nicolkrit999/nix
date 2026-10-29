---
name: cosmic-manager-shortcut-shape
description: cosmic-manager evaluated attrsets carry null-defaulted keys (shortcut description, compositor input_touchpad/input_default); absence checks must test == null, not hasAttr; test normKey sorts modifiers
metadata:
  type: project
---

Evaluated `wayland.desktopManager.cosmic.shortcuts` entries always carry `description` (default `null`), even when the module wrote `{ key; action; }` only (the Disable shadows in cosmic-binds.nix).

**Why:** test-cosmic-binds `disableShapeOk` compared `s == { key; action; }` and failed on all 5 Disables (2026-10-29), while the module was live-verified correct.

**How to apply:** compare shapes as `(s.description or null) == null && removeAttrs s [ "description" ] == ...`. Also in that test `normKey` sorts modifiers alphabetically (`ctrl+super+3`, `alt+super+a`): hand-written expected keys must use sorted order, or filters silently return `[ ]` (the first bug there was `lib.head` on an empty list that aborted the whole results eval, because tryEval does not catch it).

Same trap for the compositor: every `defaultNullOpts.mkNullable` option (`input_touchpad`, `input_default`, ...) is present in the evaluated `compositor` attrset as `null` (the RON default shown in the source is doc-only); `cleanNullsExceptOptional` drops nulls when writing the file. "Not emitted" checks must test `(c.k or null) == null`, never `hasAttr` (03-scenario-cosmic-input, 2026-10-29, 3 false FAILs).
