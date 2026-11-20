---
name: zen-7-3-4-boot-panic
description: linux_zen 7.3.4-zen1 boot panic (BH worker NULL deref); fixed in zen2 via nixpkgs PR 586820 (merged to master 2026-11-11), not in locked nixos-unstable until it lands
metadata:
  type: project
---

Upstream zen-kernel 7.3.4-zen1 panics at boot (BH worker reads through a NULL pointer). Fixed in zen-kernel 7.3.4-zen2 (commit ba87bc06). nixpkgs PR #586820 ("linux_zen: 7.3.4-zen1 -> 7.3.4--zen2", merge commit 9ca0e988) merged to master 2026-11-11. nixpkgs issue #587387 tracks the panic (open).

**Why:** the desktop's generation 1484 (locked nixpkgs d4f25a3e, zen1) panics; 1483 (f4a03c0, linux-zen 7.2.15) boots. Locked nixos-unstable is 568 commits behind the fix; nixos-unstable-small already contains it (2449 ahead of the merge commit).

**How to apply:** the repo pins the desktop kernel via the `nixpkgs-kernel` flake input (rev f4a03c0, zen 7.2.15, gen 1483; modules/nixos/toplevel/kernel.nix). When the locked nixpkgs includes 9ca0e988 (zen 7.3.4-zen2+) and a boot test passes, drop the input and use `pkgs.linuxPackages_zen` again. 7.2 is EOL upstream, so the pin is only a stopgap (linux_7_2 itself throws in current nixpkgs; the pinned set still evaluates).
