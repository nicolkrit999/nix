---
name: portal-test-cache-listing-design
description: nixos-portal-routing no longer builds real profiles (2026-10-18): fake hosts + cache.nixos.org NAR listings + empty-store dry-run guard; structuredAttrs drvs hide src from `nix derivation show` env
metadata:
  type: project
---

Since 2026-10-18 `nixos-portal-routing` (moved heavy-c -> heavy-a, cap 15, ~3 min local warm) evaluates real hosts only and runs 6 slim fake-host cases. Portal data comes from `nix store ls --json -R --store https://cache.nixos.org` / `nix store cat` (0.1-0.4 s each, no closure download); repo-built portal pkgs use eval-asserted stand-ins (wlr overlay = stock + postFixup sed; mango meson install_data). Guard = empty chroot store + cache.nixos.org-only dry run of the build set, non-trivial will-be-built fails.

Final cause of the heavy-c timeouts: real profiles are ~1600 drvs each against cache.nixos.org alone; school spec added stylix-themed inkscape + gtksourceview4 after useGlobalPkgs (888c7b2b). Real gnome-shell/gnome-session are stylix-patched, never on cache.nixos.org.

Trap: for `__structuredAttrs` derivations `nix derivation show` puts the attrs under top-level `structuredAttrs`; `env` holds only outputs. A "has src?" trivial-check that reads only `env` passes gtksourceview as trivial.

2026-10-28 (run 40659334671): first case failed assemble "nixos-version was neither cached, a stand-in nor built" although `nix build` exited 0 (the artifact had no nix-stderr evidence file, and evidence.sh keeps one for every non-zero nix) and the next case found the path. The fake nixos-version (ylsz...) is test-only, so it is never in the CI snapshot. The cause is unproven (outputs unrooted under --no-link, so a daemon GC is the suspect). The build step now roots its outputs (--out-link in $WORK), uses --keep-going, fails on non-zero exit and checks that every output exists. If it comes back, the build-step message now says which of these happened.

**Why:** per-incident package filters (noctalia, openlogi) never ended the timeouts.
**How to apply:** if this test fails "uncached heavy entry" or "guard", add a stand-in in portal-common.nix or fix the fake host; never go back to building system.path/home.path. See [[ci-tests-narrow-substituters]].
