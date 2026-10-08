---
name: rtk-git-diff-patch-trap
description: RTK hook rewrites `git diff > file`, so the saved "patch" is a filtered summary that git apply rejects; use `rtk proxy git diff`
metadata:
  type: project
---

The RTK PreToolUse hook rewrites `git diff` into `rtk git diff`, which prints a
compact summary instead of a real unified diff. `git diff > x.patch` followed by
`git checkout -- files` and then `git apply x.patch` therefore LOSES the edits
("No valid patches in input"). The same applies to `diff a b` output used for
comparisons, which RTK reformats.

**Why:** On 2026-10-08 a before/after drvPath comparison wiped three uncommitted
module edits, and they had to be re-applied by script.

**How to apply:** For anything that has to be machine-readable, use
`rtk proxy git diff > patch` (and `rtk proxy diff`). Check that the patch is
non-empty with `wc -l` BEFORE reverting files. Prefer re-applying edits with an
idempotent python replace script that you keep around.
