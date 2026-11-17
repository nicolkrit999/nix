# test-sddm-qylock

Builds the real `sddm-qylock-<theme>` package (`modules/nixos/services/sddm/sddm-qylock.nix`, theme source = flake
input `qylock`) for a handful of option combinations and inspects the **built theme files**: 12h/24h clock rewrite,
custom video background (byte-identical replacement plus the dim scrim), custom image background (darkened),
`themeOptions`, the `sddm.theme` value and `assetsDir` filename resolution. The kind-mismatch and unsupported-theme
errors are matched at evaluation time.

## Run

```bash
bash templates/tests/run-tests.sh --only nixos-sddm-qylock      # from the repo root
bash check-nixos-sddm-qylock.sh                                 # from this folder
```

Expected result: PASS. A red check is a finding about the module (or upstream drift in the qylock themes): do not
loosen it. Cap 10 min (CI group heavy-b).

## How it works

1. `01-scenario-sddm-qylock.nix` evaluates one slim fake host (`host/`, `nixos-extra/`: only `services.sddm-qylock`,
   no stylix, no WM) and makes one `extendModules` twin per scenario (options forced with `mkOverride 10`). The
   fixtures are generated in the test: two 1 s 64x64 mp4s (black, white; ffmpeg) and a flat `#c0c0c0` PNG
   (ImageMagick); a store directory `assetsDir` holds the PNG under a plain filename.
2. `check-nixos-sddm-qylock.sh` builds the eight scenario packages and the fixtures in one `nix build`, builds the
   failing one (`nier-12h`) alone and matches its log, then runs one `nix eval` per error scenario and matches
   stderr. Everything is read from the built files with `grep`, `cmp` and `magick`; no module code is reused.
3. The hollowknight builds copy the ~40 MB theme video each, so the number of builds is kept small.

## Checks

| Scenario | Check | Expected |
|---|---|---|
| default (pixel-hollowknight) | `sddm.theme`, package name | `pixel-hollowknight`, `sddm-qylock-pixel-hollowknight` |
| default | Main.qml clock | contains `"hh:mm AP"`, no `"HH:mm"` (control: upstream has `"HH:mm"`) |
| default | no background | `bg.mp4` equals upstream, no scrim Rectangle appended |
| `use24HourClock = true` | Main.qml clock | `"HH:mm"` kept, no `hh:mm AP` |
| video, `backgroundDim = "0.4"` | `bg.mp4` | byte-identical to the custom video, differs from upstream |
| video, `backgroundDim = "0.4"` | BackgroundVideo.qml | black full-size Rectangle with `opacity: 0.4` |
| video, auto dim, black video | scrim opacity | `0` (weakest step) |
| video, auto dim, white video | scrim opacity | greater than the black one, in 0.5..0.8 |
| nier-automata, image via `assetsDir` filename, dim 0.5 | `bg.png` | darker than the source, mean luminance about half of it, not the upstream image |
| nier-automata, `use24HourClock = true` | Main.qml | not rewritten (no `hh:mm AP`) |
| nier-automata | `sddm.theme` | `nier-automata` |
| terraria `themeOptions.terraria.backgroundMode = "time"` | theme.conf | `background_mode=time` (controls: plain terraria and upstream keep `random`) |
| nier-automata, `use24HourClock = false` | build | fails, log names the missing `"HH:mm"` clock |
| image for hollowknight (video theme) | eval | fails: `must be a video` |
| video for nier-automata (image theme) | eval | fails: `must be a picture` |
| Genshin + background | eval | fails: no single bg.mp4/bg.png/background.png |
| missing plain filename in `assetsDir` | eval | fails: `not found in users/` |
| absolute path outside the store | eval | fails: `absolute paths outside the store are impure` |
| default | control | evaluates without error |
