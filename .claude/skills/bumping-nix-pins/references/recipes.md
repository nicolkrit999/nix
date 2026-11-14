# Per-source recipes

All hashes end as SRI: `nix hash convert --hash-algo sha256 --to sri <base32-or-hex>`. Bare base64 gets the `sha256-` prefix.

## GitHub tag/rev (fetchFromGitHub)
- Latest tag: `gh api repos/<o>/<r>/releases/latest --jq .tag_name` (fallback `gh api repos/<o>/<r>/tags --jq '.[0].name'`). Rev-pinned repos with no tags: `gh api repos/<o>/<r>/commits/HEAD --jq .sha`.
- Hash: `nurl https://github.com/<o>/<r> <tag-or-rev>` (prints a ready fetcher) or `nix-prefetch-url --unpack --type sha256 <archive url>` then convert.
- Keep `tag =` vs `rev =` style as the file has it; update the `# nurl ...` comment if present.

## PyPI wheel (fetchurl, format = "wheel")
- `curl -s https://pypi.org/pypi/<pkg>/json | jq` -> `.info.version`, `.urls[]` (filename, url, `.digests.sha256` hex). Pick the file name matching the wheel tag the file already uses. The `packages/xx/yy/<hash>/` URL segment changes every release: copy the new url verbatim. Convert hex to SRI.

## npm / Go / Cargo derived hashes
- Set the hash to `lib.fakeHash` (or `""`), build the derivation, copy the `got:` value. `npmDepsHash` alternative: `prefetch-npm-deps package-lock.json`. Do it for src hash first, then npmDepsHash/vendorHash.

## Chrome Web Store CRX (helium)
- `nix-prefetch-url --name <id>.crx "<url from fetchCrx>"` then convert; compare with current hash; change only if different.

## Raycast extensions (vicinae)
- New rev: `gh api repos/raycast/extensions/commits/main --jq .sha`. Per extension: set hash to fake, build the vicinae-extension derivation (or the host toplevel) and take the `got:` hash. Do all 9 per host, same values on both hosts.

## Flatpak Craft bundle
- `gh release view v<ver> -R storytold/<name>` / download `SHA256SUMS.txt`, or `nix-prefetch-url --type sha256 <url>`; convert to SRI. Check the `linux-x86_64.flatpak` asset exists.

## proton-drive CLI
- Version discovery (confirmed): `curl -s https://proton.me/download/drive/cli/version.json | jq '.Releases[] | select(.CategoryName=="Stable") | {Version, ReleaseDate}'`. Each release lists `Files[]` with `Url`, `Platform` and `Sha512CheckSum` (sha512 only, not usable as a Nix hash). Take the stable `Version`, then `nix-prefetch-url --type sha256` the `linux-x64` and `darwin-arm64` URLs and convert to SRI (the file also lists linux-x64-musl, arm64, darwin-x64, freebsd and windows builds; the repo uses only the two).
- Optionally cross-check the prefetched file with the listed sha512 (`sha512sum`).
- The README (github.com/ProtonDriveApps/sdk/blob/main/cli/README.md) mentions a `linux/x64-baseline` build for CPUs without AVX2; this repo does not use it. If a user reports `Illegal instruction`, that is the fallback.
- The CLI jumped 0.4.4 -> 0.9.0, so check the release notes for breaking flags before bumping; the module only installs the binary.

## Verification builds
- Real builds, not dry-runs: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` (flags from resource-check, `nice -n 19`), or the specific derivation when isolated. Darwin-only hashes (proton darwin) cannot be built here: prefetch only.
