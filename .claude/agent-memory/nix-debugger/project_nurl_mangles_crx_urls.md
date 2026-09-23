---
name: nurl-mangles-crx-urls
description: nurl silently returns the empty-file hash for the Chrome Web Store crx URLs in helium.nix; use `nix store prefetch-file` instead
metadata:
  type: project
---

For the `fetchCrx` URLs in `users/krit/nixos/programs/gui-programs/helium.nix`,
do **not** use `nurl -f fetchurl -H '<url>'`. Use:

```
nix store prefetch-file --name <id>.crx --json '<url>'
```

**Why:** nurl re-expands the URL's percent-escapes before handing it to
`nix store prefetch-file` *unquoted*, so `x=id%3D<id>%26installsource%3Dondemand%26uc`
becomes real `&` separators. Google's endpoint then returns a zero-byte body and
nurl happily reports `sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=`
(the hash of the empty string). It also prints
`warning: dubious URI query 'uc' is missing equal sign` - that warning is the tell.
Committing that hash turns a hash-mismatch into an empty-extension install,
which is much harder to spot.

**How to apply:** when fixing one of these recurring CWS hash drifts, prefetch
directly, then sanity-check the result before editing: the store path should be
a couple of MB and start with the `Cr24` magic (`head -c 4 <path> | od -c`).
A 0-byte result or a `47DEQpj8...` hash means the fetch failed, not that the
extension changed. Cross-check against the `got:` value in the build error -
they should agree.

**Sweep, don't fix one at a time.** A rebuild only reports the mismatches it
reached before aborting, so fixing just the ids in the error guarantees another
round. Prefetch **all** ~9 `extensionSpecs` ids in one loop (a few minutes,
~50 MB) and diff every hash against the file - on 2026-09-23 that turned a
third round into zero: the two reported ids had drifted, the other seven
(incl. the already-patched OneTab) were still correct.

Related: [[flake-check-misses-build-failures]] (a hash mismatch is a build-phase
failure, so `nix flake check` will not catch a regression here).
