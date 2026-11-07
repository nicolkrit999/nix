---
name: gitea-assets-ci-403-cachix-eviction
description: gitea.nicolkrit.ch (Cloudflare) returns 403 to GitHub runners; CI never fetched wallpaper media from it, always from krit-nixos cachix - eviction exposes it (2026-10-17)
metadata:
  type: project
---

`gitea.nicolkrit.ch` is behind Cloudflare (public A 104.21.4.72 / 172.67.131.194; on the tailnet it resolves to 100.101.189.91, so local curl bypasses Cloudflare). GitHub runners get `curl: (22) 403` for the nixpkgs fetchurl of the desktop wallpaper videos. From a residential IP through Cloudflare the same URLs work with the exact nixpkgs UA (`curl/X Nixpkgs/26.11`) and over HTTP/1.1 or /2, so the block depends on the source IP, not the UA, HTTP version or Nix version.

CI has **never** fetched these from gitea. The first run after they were added (2026-08-20, run 32345516616) already copied them from krit-nixos cachix. That copy came from the user's machine. The last time cachix served them was 2026-10-15 (run 38708071817). They were still in cachix at 2026-10-16 17:52 (pushed=0 on run 38937529033) and evicted before 2026-10-17 17:05. The 2026-10-16 desktop toplevel was evicted in the same window, which is storage-pressure eviction after a flake.lock bump. The first gitea attempt, and the first 403, was run 39050487225 on 2026-10-17.

Also: the CI store snapshot never protects them. The cache-nix-action save step (`gc-max-store-size-linux`) GCs every dead path, toplevels included, and restore only works for the same lock.

The videos ARE in the runtime closure (the mk-wallpaperd launcher argv references them).

Second failure mode (2026-11-06): public DNS became `gitea.nicolkrit.ch` CNAME `wg.nicolkrit.ch` A 193.223.80.2, not proxied. That IP times out from the internet, and the old Cloudflare IPs return 522. CI then shows `curl: (28) Failed to connect ... after ~135000 ms`, not a 403. All 6 develop runs on 11-06 failed heavy-b `nixos-mango-desktop-host` "build mango and its config.conf", each on a different asset (girl-desk-working.MP4, purple-car.mp4, 01 Nordic Blue.jpg). Each asset was in cachix by the next run, so one asset kept missing at a time. Local runs always pass because the tailnet resolves wg to 100.x. Check: `dig +short gitea.nicolkrit.ch @1.1.1.1` and `curl --resolve` against the public IP.

**Why:** about 8 gitea URLs live in hosts/, users/ and the wallpaper tests. Any of them breaks CI as soon as cachix evicts it and a cold run needs it.
**How to apply:** if CI shows a 403 on a gitea URL, check the cachix narinfo first (404 = evicted). A re-push is only a stopgap. The structural fix is a runner-reachable mirror in fetchurl `urls`, or a Cloudflare skip rule for `/krit/wallpapers-repo/raw/`. See [[ci-tests-narrow-substituters]] for the earlier eviction history.
