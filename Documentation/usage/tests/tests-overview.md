# Test suite overview

Everything under `templates/tests/` is the test suite of this repo. 41 tests are discovered today (`bash templates/tests/run-tests.sh --list`): 27 NixOS, 11 common and 3 darwin. Nearly all of them are **eval-time** tests: they evaluate the real hosts (or slim fake hosts) and assert on the result, so a config fix is verified by re-running the test, with no rebuild.

This page is the map. Each test folder has its own `<folder>-readme.md` with the full check tables; open the folder for the details.

## Running the suite

From anywhere (the script resolves the repo root):

```bash
bash templates/tests/run-tests.sh [--parallel] [--fast] [--only NAME[,NAME...]] [--list] [--keep-logs] [--prune-only]
```

| Flag | Effect |
|------|--------|
| (none) | run every test sequentially |
| `--parallel` | run all tests concurrently. Faster, but noisy if `nicol-nas` is unreachable (every nix process prints a "could not resolve nicol-nas" retry warning) |
| `--fast` | pass each test's `fast_args` from its `test.conf` (today only `nixos-arch-compat`: `--fast`, which skips the specialisation batches) |
| `--only X` | run only these tests. `X` is a test name from `--list`, a folder name, or an unambiguous suffix (`--only arch-compat` works). Comma-separated for several |
| `--list` | print every discovered test (name, CI group, timeout cap in minutes, platforms, CI yes/no, kind, folder) and exit |
| `--keep-logs` | do not prune old log runs at the start of this run |
| `--prune-only` | prune old log runs and exit without running tests |

Locally every platform runs, including the darwin tests (pure evals, they work on Linux).

There is no registry to edit. `templates/tests/lib/discover.py` finds the tests (see "Adding a test" below); `--list` is the authoritative list.

### Logs and pruning

Every test runs through `.github/scripts/run-test.py`, exactly as in CI, and writes one complete log per test (header with commit and nixpkgs rev, full output, the full stderr of every failing nix call, footer with exit code and duration) under

```
${XDG_STATE_HOME:-~/.local/state}/nix-tests/<timestamp>-<sha>/      (plus a `latest` symlink)
```

This is outside the repo and not in `/tmp` (a tmpfs here), so it survives a reboot. At the start of each run (not with `--list`, skipped with `--keep-logs`) `templates/tests/lib/prune_logs.py` deletes old runs, oldest first:

| Variable | Default | Meaning |
|----------|---------|---------|
| `NIX_TESTS_KEEP_RUNS` | 20 | keep at most this many runs |
| `NIX_TESTS_MAX_AGE_DAYS` | 60 | delete runs older than this (age comes from the directory name) |
| `NIX_TESTS_MAX_MB` | 500 | delete runs until all runs total at most this |

`0` disables a limit. Only `<timestamp>-<sha>` directories that the script created are deleted, and never the run `latest` points to. This is covered by `common-test-infra`.

## CI

Two workflows run the suite, both using the same discovery as `run-tests.sh`: `.github/workflows/tests-nixos.yml` (tests whose platform is `linux`) and `.github/workflows/tests-darwin.yml` (platform `darwin`). Triggers: push to `develop`/`main`, pull requests, manual dispatch, and (NixOS workflow) every Monday 06:00 UTC.

- **discover job**: runs `discover.py` and builds the matrix. It fails the run when a test folder has neither `check-*.sh` nor `*_test.nix`, when `test.conf` has an unknown key, or when two folders derive the same test name.
- **legs**: one matrix leg per CI group (`fail-fast: false`, so a red leg never cancels the others). Linux groups today: `common`, `harness`, `heavy-a`, `heavy-b`, `nixos`, `nixos-b`. Darwin: a single `darwin` leg. Each leg runs its group through `run-test.py` (per-test log, per-test timeout from `test.conf`, default 10 min).
- **artifacts**: each leg uploads its logs as `test-logs-<nixos|darwin>-<group>-<run_id>-<run_attempt>` (14 days when the tests passed, 90 days otherwise, in both workflows).
- **gate**: the last step of each leg fails the leg whenever its tests step did not succeed, so the run is red because a leg is red.
- **notify job**: runs on its own runner even if a leg died. It downloads every leg's artifact, builds `HANDOFF.md` and `summary.md` and sends the Discord report: a header message plus one message per failing test (at most 10), each with the failing test's complete log attached. A fully green run sends nothing. It is deliberately not the gate.
- **fetching logs**: the Discord header and `HANDOFF.md` carry the run id and a ready `gh run download` line (`gh run download $RUN -R $REPO -p 'test-logs-*' -D ...`). `HANDOFF.md` also prints the exact `run-tests.sh --only` repro line.

The full reasoning, the log format, the fetch procedure and the invariants that protect all of this are in [`Documentation/usage/ci/build-workflows.md`](../ci/build-workflows.md), section 12 ("Test workflows: discovery, logs, gate, notify"). `.github/scripts/check-workflow-invariants.py` enforces the mechanical part; run it after any workflow edit.

## Adding a test

Follow [`.claude/skills/adding-nix-tests/SKILL.md`](../../../.claude/skills/adding-nix-tests/SKILL.md) (author, run, triage loop). Short form:

1. Create `templates/tests/<nixos|common|darwin>/test-<name>/` containing either `check-*.sh` (run with bash) or `*_test.nix` (run with the nix-tests harness). A folder with neither makes discovery fail. Optionally both: their commands then run in order inside one test with one log.
2. Add `test-<name>-readme.md` (never `README.md`) with what, why, how to run and the check tables.
3. Add a `test.conf` only when the defaults are wrong. Keys: `group` (CI leg), `timeout` (minutes), `platforms` (`linux`/`darwin`), `ci` (`true`/`false`), `fast_args`. Unknown keys are an error.
4. `git add` every new file; flakes and discovery only see tracked files.

### Scope rules every test follows

- Never test which programs, WMs, DEs or kernels a host chooses to enable. Test only conflicting modules, specialisation purpose contracts, host safety values (boot, impermanence, sops, stateVersion) and cross-file consistency.
- Fake hosts enable only what the test needs (sole exception: `nixos-arch-compat` enables every module).
- Every check must be able to fail: each test carries controls or negative scenarios.
- No keys, fingerprints or tokens are hardcoded (the repo is public); values are compared with each other or parsed at test time.
- A failing test is not proof of a config bug; diagnose first, never weaken a test to make it pass.

## Reading the tables

- **Run name**: the name for `--only` and `--list`.
- **Folder**: relative to `templates/tests/`.
- **CI group**: the matrix leg (`test.conf` `group`, else `harness` for folders with `*_test.nix`, else the category).
- **Runtime**: the figure from the test's readme where it states one (warm, eval-only unless noted), plus the per-test timeout cap when it is not the default 10 min. "no figure" means the readme gives none; the test is eval-only unless noted.

## NixOS tests (`templates/tests/nixos/`)

| Run name | Folder | CI group | What it tests | Why it exists | Runtime |
|----------|--------|----------|---------------|---------------|---------|
| `nixos-arch-compat` | `test-arch-compat` | heavy-a | `nix build --dry-run` of `home.activationPackage` on `aarch64-linux` for every module, in 2 base batches plus 8 specialisation batches (all modules enabled on purpose) | A package without aarch64 support throws only at eval time on that arch; nothing else would notice before an ARM host is added | ~107 s local, ~163 s CI warm; cap 30 min; `--fast` skips the specialisation batches |
| `nixos-borg-backup-config` | `test-borg-backup-config` | nixos-b | borgmatic config on the real desktop and laptop: exclude-list hygiene, sops wiring of passphrase and SSH key, repository path, persistent timer, service, tailscale | A broken exclude, a missing secret or a non-persistent timer leaves backups silently not running | a few seconds (one eval) |
| `nixos-conflicting-modules` | `conflicting-modules` | harness | nix-tests: `services.tlp` vs `services.auto-cpufreq` and `services.sddm-astronaut` vs `services.sddm-pixie` must raise a build-time assertion when enabled together, and build fine alone | Without the assertion, mutually exclusive modules would silently fight over the same service or theme | no figure |
| `nixos-custom-shells` | `test-custom-shells` | harness | nix-tests: shell/waybar ownership (caelestia, noctalia, waybar variants) gates swayosd, swaync, hypridle, hyprlock, exec-once, packages and keybinds; dormant shells compared against no-shell scenarios | A regression does not fail the build: it silently starts two bars, drops the idle/lock daemons or leaves a dormant shell controlling a WM | no figure |
| `nixos-grub-efi-sync` | `test-grub-efi-sync` | nixos | the `boot.loader.grub.extraInstallCommands` hook in `modules/nixos/toplevel/boot.nix`: stale `EFI/NixOS*/grubx64.efi` copies are made identical to the fresh `core.efi`, run in a sandbox per host | Guards against GRUB `symbol '...' not found` after a successful rebuild (troubleshooting section 6) | no figure |
| `nixos-host-invariants` | `test-host-invariants` | nixos | boot and lockout invariants on the real desktop and laptop: impermanence, sops host key, bootloader, password wiring, tailscale base | A mistake here locks you out or leaves the machine unbootable, and still builds | no figure |
| `nixos-hyprland-lua-config` | `test-hyprland-lua-config` | nixos-b | Hyprland 0.56 Lua config of the real hosts: rendered config is valid Lua, no legacy `hyprctl dispatch` syntax, sane hypridle chain, HM/waybar workarounds still wired in | A Lua syntax error or legacy dispatch string only shows up as a broken session at login | about 1 min |
| `nixos-keybind-conflicts` | `test-keybind-conflicts` | nixos-b | per-compositor keybinding modules (Hyprland, Niri, GNOME, KDE) render collision-free, well-formed binds on the real hosts | Duplicate or malformed binds silently shadow each other | 10-20 s warm |
| `nixos-mango-desktop-host` | `test-mango-desktop-host` | heavy-b | real desktop's mango settings, hypridle DPMS strings, that the generated mango config parses silently, and the runtime behaviour of the `mango-dpms` script against a stub | Mango config errors show up only as an error bar in the session; DPMS-on can re-enable disabled outputs (see the mango gotcha doc) | ~94 s local, ~71 s CI; cap 20 min |
| `nixos-mango-ipc-helpers` | `test-mango-ipc-helpers` | nixos | the real `mango-scratch`, `mango-place` and `mango-pip` scripts of the desktop run against a stub `mmsg`; runtimeInputs are checked | The scripts talk to a compositor that cannot run in CI; a wrong call or missing runtime input breaks window helpers only at use | no figure |
| `nixos-mango-option-names` | `test-mango-option-names` | harness | nix-tests: generated mango settings and rendered `config.conf` contain none of the pre-0.18.0 keyword names, monitor rules render under `monitor_rule` | Mango 0.18 rejects old names line by line and shows only the first few in the error bar | no figure |
| `nixos-minimal-defaults` | `test-minimal-defaults` | nixos | safety-relevant constants defaults, derived constants, hypridle invariants and the hyprland module's effects on slim fake hosts | A new host that only sets identity constants must still get safe defaults | no figure |
| `nixos-monitor-layout-consistency` | `test-monitor-layout-consistency` | nixos | the monitor layout declared three times (hyprland, mango, niri) agrees on the real desktop and laptop; the laptop `home` specialisation is self-consistent | The three copies drift apart and a compositor puts monitors in the wrong place | no figure |
| `nixos-nas-mounts` | `test-nas-mounts` | nixos-b | NAS (cifs, sshfs, davfs), windows-partition and rclone cloud mount definitions on the real hosts | A bad mount option or path breaks boot or hangs on the offline NAS | 115 s inside a full parallel run (2026-10-11) |
| `nixos-portal-routing` | `test-portal-routing` | nixos-b | which backend the real xdg-desktop-portal (xdp 1.22) selects per interface, for both hosts, the base system and every specialisation, in every session desktop; builds system-path and home-path, runs the real xdp on a private D-Bus | Portal routing is silently unavailable under non-KDE/GNOME WMs when config is wrong (xdg-desktop-portal gotcha); `UseIn=` strings alone prove nothing on xdp 1.22 | cold ~12 min, warm ~6 min; cap 20 min |
| `nixos-screenshot-folder-consistency` | `test-screenshot-folder-consistency` | nixos | every DE/WM/shell that takes screenshots resolves to the same destination folder, exact and case-sensitive | `Screenshots` vs `screenshots` drift between desktops | no figure |
| `nixos-secret-service` | `test-secret-service` | nixos-b | the single-Secret-Service design: gnome-keyring is the only `org.freedesktop.secrets` provider and only SSH agent, KWallet is a frontend only, every Chromium/Electron app pinned to libsecret | A second provider or an unpinned app wins the bus name and prompts for passwords (see the secret-service gotcha doc) | 126 s inside a full parallel run (2026-10-11) |
| `nixos-snapshots-contract` | `test-snapshots-contract` | nixos | contract between the snapper configs of `services.snapshots` and the `snap-*` helper scripts that address them by name | Renaming a config breaks the helpers only when you need a snapshot | 39 s inside a full parallel run |
| `nixos-spec-contract` | `test-spec-contract` | nixos | every specialisation's `lib.mkForce` overrides land in the evaluated config | An override that does not take effect defeats the specialisation's purpose without any error | no figure |
| `nixos-spec-real-hosts-security` | `test-spec-real-hosts-security` | nixos | security and isolation of the guest, secure-travel and entertainment specialisations on the real desktop and laptop | Interactions with host and NAS modules can leak access into a specialisation meant to be isolated | 74 s inside a full parallel run |
| `nixos-spec-school` | `test-spec-school` | nixos | the `school` specialisation: isolated SSH and git identity, self-contained davfs mounts, forced tailscale, HiDPI scale, generated distrobox scripts | The school identity must not mix with the personal one | 54 s inside a full parallel run |
| `nixos-ssh-trust-pins` | `test-ssh-trust-pins` | nixos-b | SSH host-key pins and Host aliases kept in both NixOS and home-manager, plus SSH commit-signing wiring (eval plus `ssh-keygen`) | A mis-pasted or truncated key shows up only as a host-key prompt or a failed `git push` | 55 s inside a full parallel run |
| `nixos-tailscale-contract` | `test-tailscale-contract` | nixos | tailscale operator flags, firewall, the `tailscale-autoconnect` unit (non-blocking, bounded loops), school exit-node-off ordering, secure-travel privacy contract | The autoconnect unit once hung boot; bounds and ordering must stay | no figure |
| `nixos-theming-guards` | `test-theming-guards` | nixos | stylix / Qt / GTK / portal-env / hyprlock rules from the stylix-qt-kde-gtk and xdg-desktop-portal gotcha docs (HM-side qt target, not the NixOS-level one) | Re-enabling the wrong stylix target crashes Plasma or breaks portals without a build error | 76 s inside a full parallel run |
| `nixos-wallpaperd-runtime` | `test-wallpaperd-runtime` | heavy-b | runs `wallpaperd.sh` for mango, hyprland and niri against stub compositor and wallpaper tools: fallback `*` semantics, hot-plug, unplug, mirrored/disabled skipping, still vs video dispatch, single-instance lock, event-stream reconnect, crashed `mpvpaper` restart, failed-start retry | The supervisor reacts to compositor events that cannot be produced in CI; regressions leave monitors without a wallpaper | ~99 s local, ~98 s CI; cap 20 min |
| `nixos-wallpapers` | `test-nixos-wallpapers` | harness | nix-tests plus a bash companion: wallpaper dispatch (shared per-WM `<wm>-wallpaperd` supervisor with awww for stills and mpvpaper for gif/video, skwdWall, shell-owned), x86_64 and aarch64, `skwd-paper-plasma` arch guard, video>gif>static priority, wildcard vs named monitors, DE (GNOME/KDE) always static | Dispatch mistakes pick the wrong backend or arch and show no error | companion check about 1 min |
| `nixos-waybar-configs` | `test-waybar-configs` | nixos-b | generated configs of `waybar-hyprland`, `waybar-mango`, `waybar-niri`: JSON validity, module wiring, shell syntax of every `exec`/`on-click`, per-monitor bar split on Mango, systemd unit binding | A broken waybar config means no bar after login | 63 s inside a full parallel run |

## Common tests (`templates/tests/common/`)

All run on the Linux CI leg `common` unless noted.

| Run name | Folder | CI group | What it tests | Why it exists | Runtime |
|----------|--------|----------|---------------|---------------|---------|
| `common-dev-env-templates` | `test-dev-env-templates` | heavy-a | the 19 dev-environment template flakes under `templates/krit/dev-environments/`: every shell instantiates, expected packages, shellHooks (`bash -n` plus heredoc-terminator lint), `JAVA_HOME`, `RUST_SRC_PATH`, go versions; the registry check fails if a flake exists on disk but not in the table | A template silently breaks when its own nixpkgs pin or a package changes | ~1.5 min warm (cold downloads several nixpkgs tarballs); cap 15 min |
| `common-ext-dotfiles-mappings` | `test-ext-dotfiles-mappings` | common | integrity of the `ext-dotfiles-private` mappings (NixOS and Darwin) and safety of the generated `sync_back` activation script, which `rm -rf`s live GUI-written files after copying them into the repo; runs the real script in a fake home | A duplicate leaf or wrong mapping silently drops a file; a broken sync_back deletes data | about 1 min |
| `common-flake-outputs` | `test-flake-outputs` | common | structural invariants of `flake.nix` outputs: which hosts land in which `*Configurations`, `pkgsStable` wired to `nixpkgs-stable`, stable pin consistent between `flake.nix` and `flake.lock` | A host in the wrong output set or a drifted stable pin | no figure |
| `common-home-standalone-configs` | `test-home-standalone-configs` | common | deep-evaluates standalone `homeConfigurations` (which `nix flake check` does not) and the home-mode wiring: catppuccin flags, `pkgsStable`, nix settings vs the NixOS host | The NAS home build breaks without any host build noticing | about 1-2 min |
| `common-nix-cache-settings` | `test-nix-cache-settings` | common | binary-cache wiring per host: substituter/key pairing, attic netrc and priority, cachix, nix-sweep TOML, nh/GC settings | A substituter without its key is ignored or untrusted; a wrong netrc silently disables the cache | about 15 s |
| `common-secret-wiring` | `test-secret-wiring` | common | every sops secret name, path, owner and consumer lines up on desktop, laptop, Mac and NAS (key names only, no values read) | A mismatched secret name or owner fails only at activation or first use | no figure |
| `common-shell-init-syntax` | `test-shell-init-syntax` | common | syntax-lints generated init code of bash/zsh/fish/atuin/tailscale (`bash -n`, `zsh -n`, `fish --no-execute`) over several host variants; exactly one shell active per platform | A syntax error in shell init breaks every new terminal | no figure |
| `common-state-version-freeze` | `test-state-version-freeze` | common | `system.stateVersion` and `home.stateVersion` of every real host are pinned, and the independent sources of `home.stateVersion` agree | A bump is one-way (Postgres majors, HM defaults) and forbidden by CLAUDE.md | about 30 s |
| `common-test-infra` | `test-test-infra` | common | log pruning of `run-tests.sh --prune-only` (20 runs / 60 days / 500 MB, `latest` protected, never touches non-test directories), on a fake tree in a temp dir | Pruning deletes files; a mistake would throw away the logs needed for debugging or delete something else. Discovery is deliberately not self-tested here | a few seconds, no nix, no network |
| `common-unstable-switch-invariants` | `test-unstable-switch-invariants` | common | facts of the switch to nixos-unstable: permanent `nixpkgs-stable` input and `pkgsStable` arg, catppuccin `enable`/`autoEnable`, vicinae font override, atuin keybindings, no `pkgs-unstable`/`nixpkgs-unstable` names left | The switch is easy to undo by accident and fails only on specific hosts | no figure |
| `common-workaround-guards` | `test-workaround-guards` | common | each momentary workaround stays effective (vicinae gcc15Stdenv, claude-desktop pipewire overlay, lazygit migrated theme, openblas i686 doCheck, school opencloud-desktop QML paths); `warn-*` staleness controls say when one became removable (WARN, never FAIL) | A workaround silently stops working, or lingers after upstream fixed the problem | about 25 s warm |

## Darwin tests (`templates/tests/darwin/`)

CI group `darwin` (`tests-darwin.yml`). They are pure evals of the aarch64-darwin host and also run on Linux locally.

| Run name | Folder | CI group | What it tests | Why it exists | Runtime |
|----------|--------|----------|---------------|---------------|---------|
| `darwin-home-paths` | `test-darwin-home-paths` | darwin | no Linux `/home/` path leaks into rendered Darwin config (home is `/Users/<user>`) | Common modules such as `librewolf-common.nix` and `firefox.nix` hard-code `/home/${user}`; latent until a browser is enabled on the Mac | about 1-2 min |
| `darwin-host-contract` | `test-darwin-host-contract` | darwin | the real `Krits-MacBook-Pro` still evaluates with the intended identity, sops wiring, homebrew guards and browser opt-out | The Mac is CI-only and never built locally, so this is the guard that it still evaluates | about 30 s |
| `darwin-minimal-defaults` | `test-minimal-defaults` | darwin | a nix-darwin host with only identity constants gets the right `myconfig.constants.*` defaults, and the home-packages body is forced through `environment.systemPackages` (control host with `browser = ""`) | New Darwin hosts must get safe defaults | no figure |
