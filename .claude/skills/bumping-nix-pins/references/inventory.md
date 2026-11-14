# Pin inventory (authoritative)

Line numbers drift; match by name. Hash form: SRI (`sha256-...`) everywhere unless the file already uses another form for a non-version asset. Batch ids: A..L.

## INCLUDED (routine, bump to latest)

### A - Flatpak Craft bundles (storytold/<name>)
- `hosts/nixos-desktop/flatpak.nix` and `hosts/nixos-laptop/flatpak.nix`: identical 15 `craftBundle name version hash` entries: cadcraft, craft-anything, deckcraft, designcraft, effectcraft, figcraft, filmcraft, gridcraft, lightcraft, pdfcraft, photocraft, soundcraft, texturecraft, vectorcraft, wordcraft.
- Source: GitHub releases of `storytold/<name>`; asset `<name>-<ver>-linux-x86_64.flatpak`; hash = SRI of that file (release `SHA256SUMS.txt`, convert).
- Coupling: both files identical; the per-app `overrides` block is separate, leave it. If a release drops/renames the linux-x86_64 asset, report, do not guess.

### B - AppImage `actual` (actualbudget/actual)
- `hosts/nixos-desktop/default.nix` and `hosts/nixos-laptop/default.nix` `appimages.apps` entry: `version`, `url` (version appears in the tag and the file name), `hash`. Both hosts together.

### C - Vicinae Raycast extensions
- `modules/nixos/programs/vicinae.nix` `raycastRev` (default, raycast/extensions main HEAD) + `extraRayCastExtensions` hashes in both host `default.nix` (9 entries each: downloads-manager, gif-search, google-search, google-translate [installName translate], lorem-ipsum, notion, remove-paywall, video-downloader, visual-studio-code-recent-projects [installName visual-studio-code]).
- A rev bump invalidates ALL hashes: recompute each via the fake-hash recipe. An extension missing upstream: report, never silently drop. The `bluetooth` extension stays commented (blocked upstream).
- Both hosts get identical hashes.

### D - headroom (`modules/common/programs/headroom.nix`)
- PyPI `headroom-ai`: `version`, 3 wheel URLs (x86_64 manylinux_2_28, aarch64-linux, aarch64-darwin macosx_11_0_arm64; the `packages/xx/yy/<hash>/` path changes per release), 3 hashes. Source `https://pypi.org/pypi/headroom-ai/json`. If wheel tags change, update the URL file names accordingly. Packaging style (`toPythonApplication`) is a design choice, leave it.

### E - yas (`modules/common/programs/yas.nix`)
- `tmck-code/yet-another-statusline` `rev` + `hash`: latest tag if any, else default-branch HEAD.

### F - agent-reach routine parts (`modules/common/programs/agent-reach.nix`)
- agent-reach (Panniantong/Agent-Reach, `tag = v${version}`): version + hash. The `postPatch` that blanks "Auto-install skill" must still match the new source; if the upstream line is gone (memory: dropped in v1.6.1) remove the postPatch, else keep it.
- PyPI wheels: bilibili-api-python, bilibili-cli, xclienttransaction: version + URL (path hash) + hash.
- Git revs: twitter-cli, rdt-cli (public-clis): latest tag else HEAD; keep `version` equal to the repo's pyproject version.
- opencli (jackwener/opencli, tag): src hash + npmDepsHash; build uses `--ignore-scripts` + manual steps and may break on new versions.
- xiaohongshu-mcp (xpzouying, tag): src hash + vendorHash. Its `postPatch` asserts `browser/browser_version.txt == xiaohongshuBrowserVersion`. If the new tag changes that file, STOP this entry and report (xiaohongshu-browser is EXCLUDED and needs a human).

### G - sddm-pixie (`modules/nixos/services/sddm/sddm-pixie.nix`)
- xCaptaiN09/pixie-sddm `rev` + `sha256`, bump deliberately to latest tag/main HEAD; update the stale `version` string. The file has many `substituteInPlace --replace-fail`: a new rev can break the build, so verify with a REAL build (system toplevel or the derivation). If it breaks, revert this entry and report; never adapt the patches in this skill.

### H - proton-drive CLI (`users/krit/common/programs/cli-programs/proton-cli.nix`)
- `version` + 2 hashes (linux-x64, darwin-arm64) from `https://proton.me/download/drive/cli/<ver>/<plat>/proton-drive`. Darwin hash is prefetch-only. Newest version: `https://proton.me/download/drive/cli/version.json` (see `recipes.md`). When this was recorded the repo was on 0.4.4 and upstream stable was 0.9.0.

### I - yazi plugins (`users/krit/common/programs/file-managers/yazi/yazi.nix`)
- faster-piper.yazi (alberti42), ouch.yazi (ndtoan96), recycle-bin.yazi (uhs-robert): tag + hash; rich-preview.yazi (AnirudhG07): rev (latest tag else HEAD) + hash.
- Update the `# nurl ... <version>` comment above each. faster-piper needs Yazi >= the assertion value in the same file: check the plugin's stated minimum and report if it rose above the packaged yazi. Previewer rules in the same file depend on the plugin CLI: report any breaking change.

### J - ranger plugins (`users/krit/common/programs/file-managers/ranger.nix`)
- ranger-archives (maximtrp), ranger-devicons2 (cdump), ranger_tmux (joouha), ranger_udisk_menu (SL-RU), ranger-fzf-marks (laggardkernel): rev (latest tag else HEAD) + hash each. The embedded `commands.py` imports udisk_menu and fzf-marks (`fzm`): sanity check names still exist.

### K - helium CRX extensions (`users/krit/nixos/programs/gui-programs/helium.nix`)
- 9 Chrome Web Store ids (listed in the file). URL is unversioned; content changes in place. Re-prefetch each, update `hash` only if different. Never change `prodversion=120.0.0.0`.

### L - claude-code wrappers (`users/krit/common/programs/claude-code/claude-code-wrappers.nix`)
- agent-floor (develop212/agent-floor): first `npm view agent-floor`; if published on npm, do NOT bump, report that the pin can be dropped. Otherwise bump `rev` to HEAD + `hash` + `npmDepsHash`.
- officeNodeModules `npmDepsHash`: only if `office-node/package-lock.json` is updated (`npm update` in `users/krit/common/programs/claude-code/office-node`) and newer deps exist; keep sharp native optional deps and `--ignore-scripts`. Flag to the user before running `npm update`.

### REPORT-ONLY
- `flake.nix` lanzaboote input tag (currently v1.2.0): say if a newer tag exists, never edit (Secure Boot live on both hosts).

## EXCLUDED (never touch here)

| Item | Why |
|---|---|
| tgt TDLib 1.8.61 pin (`modules/nixos/programs/tgt.nix`) | workaround, memory project_tgt_tdlib_pin |
| laptop `camera.nix` ipu7 bins/hal/omarchy patches | workaround, camera disabled, upstream issue |
| `nixpkgs-kernel` input + `modules/nixos/toplevel/kernel.nix` | zen 7.3.4 panic workaround |
| patchright wheel, mcp-server-linkedin 4.25.1 + `pyMcp1`, xiaohongshu-browser (agent-reach) | agent-reach workarounds (memory project_agent_reach_workarounds) |
| relative-motions (yazi.nix) | mkForce + ya.mgr_emit patch |
| moodle-dl master pin (school.nix) | unreleased upstream, workaround |
| `nixpkgs-stable` | scheduled release bump, memory project_26_11_release_followups |
| auto-cpufreq git+https input, floating branch flake inputs, spotify-adblock input | floating inputs, deliberate fetcher choice |
| `programs.npm` package lists | deliberately unpinned |
| vicinae gcc15 stdenv override | temporary workaround |
| wallpaper URL+sha256 lists (hosts default.nix, home.nix, constants-nixos.nix) | user's own repos, not an upstream version |
| PWA icons (progressive-web-apps.nix), school.nix iCorsi/SUPSI icons | unversioned URLs: refresh only on a hash mismatch, not a bump |
| any pin whose memory file under `/home/krit/.claude/projects/-home-krit-nix/memory/` is an ACTIVE workaround | belongs to auditing-nix-workarounds |

## Maintenance

New routine pins get added here by `creating-nix-modules` (its "pin registration" step). A new EXCLUDED item is added when a pin is introduced as a workaround.
