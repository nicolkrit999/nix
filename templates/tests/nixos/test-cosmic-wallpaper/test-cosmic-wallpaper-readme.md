# test-cosmic-wallpaper

Contract of the declarative COSMIC wallpaper (`modules/nixos/programs/de-wm/cosmic/cosmic-wallpaper.nix`, cosmic-manager `wayland.desktopManager.cosmic.wallpapers`), evaluated on twins of the minimal `template-host-minimal` fixture (`lib/fixture-host.nix`) that enable only COSMIC, plus the real desktop and laptop when they enable COSMIC. It does not test which DE a host enables or how cosmic-bg renders.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-cosmic-wallpaper` (name as shown by `--list`); or directly:

```bash
bash templates/tests/nixos/test-cosmic-wallpaper/check-nixos-cosmic-wallpaper.sh
```

Needs `nix`, `jq`, `bash`. Eval only; the cap is 4 min (`test.conf`, group `heavy-a`: `nixos` and `nixos-b` have no step-budget headroom left).

## How it works

`01-scenario-cosmic-wallpaper.nix` exposes `results` (`label -> "ok" | "FAIL: ..."`, each check wrapped in `tryEval`). Twins set `myconfig.constants.wallpapers` and the checker compares `output -> store path` of the generated list against an independent prediction (`pkgs.fetchurl` of the entry's `wallpaperURL`/`wallpaperSHA256`, or of `fallbackWallpaperURL`/`fallbackWallpaperSHA256` when the URL is empty):

- Named targets (DP-1, DP-2, ...) become one entry each; the `*` entry is dropped because cosmic-manager forbids `all` next to per-output entries.
- Only `*` (or no usable named target) becomes one `all` entry from `primaryWallpaper`.
- Entries with only a video or gif use the fallback wallpaper; `desc:` and shell-unsafe targets are skipped.
- Duplicate targets trip cosmic-manager's "Each output can only have one wallpaper configuration" assertion.
- A cosmic-off twin has `wallpapers = null` and no `CosmicBackground` config.
- Controls: the checker itself is run on synthetic duplicate, unsafe and mixed lists and on wrong expectations and must flag them.
