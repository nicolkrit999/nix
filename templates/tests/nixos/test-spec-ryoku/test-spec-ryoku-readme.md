# test-spec-ryoku

Checks the `ryoku` specialisation: the generic module `modules/nixos/specializations/ryoku.nix` (own account `<base user>-ryoku`, explicit force-off list, portal table, arch gate, persistence) and the user layer `users/<layer>/nixos/specializations/ryoku.nix` that is merged into the same specialisation. Mostly eval only (the settings seed and the user.fish text are realised once as trivial derivations); the real settings seed script is then run on temp dirs.

Two kinds of evidence:

- **Real hosts** (`nixos-desktop`, `nixos-laptop`): the facts that must hold on the actual configuration, including the force-off list for options a host never enables (the laptop has no gnome, cosmic or mango).
- **A from-scratch fixture** (`fixture/`): hosts that load only the generic module (and, in one case, the user layer) over the constants schema, impermanence, home-manager and stylix. Its base has every forced-off option ON, so a missing `mkForce false` fails; the fixture also carries **mutants** of the generic module text (a line removed through `builtins.replaceStrings`, loaded as a real module) to prove the probes bite.

`test-spec-contract` (the force-off list and the "stays on" facts on its own fixture, with twin controls), `test-portal-routing` (the ryoku portal case) and `test-secret-service` (the Secret route in the ryoku spec) cover the rest of the contract.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-spec-ryoku` (name as shown by `--list`); the direct commands are below.

From repo root:

```bash
bash templates/tests/nixos/test-spec-ryoku/check-nixos-spec-ryoku.sh
```

From inside the directory:

```bash
bash check-nixos-spec-ryoku.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo (used for mutation checks). About 50 s cold (30 s warm); `test.conf`: group `heavy-a` (the `nixos` and `nixos-b` legs have no budget headroom), cap 6 minutes.

## How it works

- `01-scenario-spec-ryoku-real.nix` (`--argstr host <name>`) reads `flake.nixosConfigurations.<host>` and its `specialisation.ryoku.configuration`. Every check is `ok` or `FAIL: <detail>`; a throwing check becomes `FAIL: eval error`. The other dedicated user (school) is looked up by the name `school` only when the host has that specialisation; the base user comes from `constants.user`, so no personal name is hardcoded. The generic module source is grepped for the base user's name, with a control that the user layer module does contain it.
- `02-scenario-spec-ryoku-fixture.nix` builds three denix hosts from scratch (`fixture/host-bob.nix` with the user layer, `fixture/host-alice.nix` without it, `fixture/host-aarch64.nix`) over `fixture/nixos-extra.nix` (users, tmpfiles, a tmpfs root, home-manager and stylix modules) and `fixture/option-sinks.nix` (the forced-off `myconfig.*.enable` options as plain bool options defaulting to true; `fixture/krit-option-sinks.nix` does the same for the user layer's personal modules). `fixture/home-user-follows-constants.nix` is a copy of the flake's extension of the same name, without which denix would put the spec's home blocks under the fixed `homeManagerUser`; a check fails if `flake.nix` stops carrying the same body. The user-layer name for the source probe is read from the directories under `users/`.
- The mutants load a copy of the generic module with one anchor replaced (the anchor must match exactly once, so a refactor of the module fails loudly instead of silently disabling the mutant). `../toplevel/xdg-portal-config.nix` is rewritten to its absolute path inside the copy.
- `fixture/probes.nix` holds the text probes shared by both scenarios (chord extraction and duplicate detection for the two bind files, hyprland unbind/bind pairing, legacy-word probe, bare-tool probe); every probe is applied to synthetic text with a control that it can fail. `fixture/bind-option-sinks.nix` declares the `extraBinds`-style options the bind modules own. The fixture loads the real `stylix-nixos.nix`, `ryoku-binds.nix`, fake `ryoku-*` sessions (`fixture/nixos-sessions.nix`) and the generic module; its home-manager user enables kitty, fish, yazi and eza and declares a `catppuccin.eza.enable` sink.
- The fixture also exposes `seedScripts` (the realised `ryoku-settings-seed` scripts of three alice twins: declaration A, declaration B with one changed value, and A in `enforce` mode). `check-nixos-spec-ryoku.sh` runs them against temp `HOME`/`XDG_*` directories (jq required).
- `check-nixos-spec-ryoku.sh` evaluates `01` for both hosts and `02` once, runs the seed script scenarios, prints one line per check and refuses to pass with fewer than 437 checks.

An `x86_64` gate: the assertion alone is not enough upstream (the Ryoku module throws on `aarch64-linux` while the assertions are collected), so the spec also sets `programs.ryoku.enable = isX86`. The fixture collects only the failing assertions (the filesystem assertions throw when their message is forced on a healthy config).

## Checks

### Real hosts (per host, `nixos-desktop` and `nixos-laptop`)

| Check | Expected |
|-------|----------|
| spec exists | tag `ryoku`, `programs.ryoku.enable` true in the spec, false in the base |
| user | `constants.user` equals `<base user>-ryoku` and differs from the base user |
| uid | integer, differs from the base user's and the school user's (when the host has that spec) |
| subuid / subgid | set, and overlapping neither the base user's nor the school user's ranges; control: the overlap probe flags overlap and accepts disjoint ranges |
| base user absent | `users.users.<base>` does not exist in the spec; the base has it and not the ryoku user |
| home-manager users | exactly `[ <ryoku user> ]` in the spec and `[ <base user> ]` in the base |
| sops | no secret or template owned by or placed under the base user's home; controls: the base has some, the claim probe flags synthetic owners/paths |
| tmpfiles / mounts | no rule or `fileSystems` entry names the base user's home; control: the probe flags a synthetic base rule |
| home rule | exactly one rule creates `/home/<ryoku user>`, type `d`, the account's `homeMode`, owned by the ryoku user |
| `/home` mount | not tmpfs, `neededForBoot`, ryoku home under `/home/` |
| source | the generic module text has no occurrence of the base user's name; control: the user layer text does |
| force-off list | for each of the 26 options (17 `programs.*`, 7 `services.*`, `qt`, `bluetooth`): the option is declared on this host (a rename fails instead of being skipped by the module's filter) and false in the spec, even when the host never enables it (26 rows per host) |
| catppuccin | `constants.theme.catppuccin` false in the spec |
| shell | `constants.shell`, `programs.ryoku.shell` and the default user shell agree |
| borg | the borg backup modules that exist on the host are false in the spec; at least one exists |
| personal re-enables | every personal module the base has on (ssh config, clouds, opencloud/smb/sshfs mounts, home base, private dotfiles) is on in the spec too; at least one is on in the base |
| `updateFlake` | not the option default, not under `/home/`, not the flake checkout directory |
| compositor | `defaultCompositor == "hyprland"` |
| stays on | pipewire, gnome-keyring, polkit, NetworkManager, power-profiles-daemon, gpu-screen-recorder and `myconfig.services.audio` are on in the spec |
| sddm | enabled with theme `ryoku` in the spec; the base theme differs |
| sddm cursor | the spec's rendered sddm settings carry `Theme.CursorTheme` Bibata-Modern-Ice and `CursorSize` 24; `GreeterEnvironment` holds `XCURSOR_PATH=/run/current-system/sw/share/icons` once and `QT_WAYLAND_SHELL_INTEGRATION=layer-shell` only with the kwin compositor; the cursor package is in the spec's systemPackages with a name matching the theme; `/share/icons` is in `pathsToLink`; control: the base has neither our theme nor `XCURSOR_PATH` |
| sddm weston cursor | with the weston compositor the spec `compositorCommand` is `env XCURSOR_PATH=... XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=24 <weston> --shell=kiosk -c <weston.ini>`, the same weston as the base (when the base uses weston), and the base command has no `XCURSOR_THEME`; control: the probe flags a plain or wrong-theme command |
| fastfetch wrapper | the spec user has exactly one `ryoku-fastfetch` package in `home.packages` (base user none); its script has the absolute `-ryoku-desktop-data/bin/ryoku-fastfetch` real path, absolute chafa, jq, gnused, imagemagick and coreutils store paths, `KITTY_WINDOW_ID`/`xterm-kitty`/`xterm-ghostty`/`TERM_PROGRAM`, the TMUX test, the unchanged `exec "$real" "$@"` branch, the `--logo-type file-raw` render path with the `ryoku/fastfetch-logo-` cache and the `--logo-type none` fallback; control: the probe flags missing parts and a self-calling path |
| sessions | Ryoku adds `ryoku-hyprland`, `ryoku-niri`, `ryoku-mango` to `sessionPackages` in the spec and in no other config (control that the mango filter is needed) |
| session data | `sessionData.sessionNames` of the spec has `ryoku-hyprland` and `ryoku-niri`, not `ryoku-mango`, and `autologinSession` is not `ryoku-mango` |
| session desktops | the `sessionData.desktops` derivation's build command (read, nothing built) references every other session package and not the `ryoku-mango` one |
| default session | starts with `ryoku-` |
| portal table | the spec's `xdg.portal.config` equals the base table (Ryoku's own fragments do not leak in), every route's Secret is exactly `gnome-keyring`, and hyprland, niri and mango entries exist |
| host units | `kbd-backlight-relight` and `niri-flake-polkit` are disabled or absent in the spec, `hyprland-jetkvm-teardown` is absent from the spec's home; control: this host defines at least one of the two host-defined units |
| persistence | with impermanence on, `/var/lib/ryoku` is persisted in the spec and not in the base |
| safety | `system.stateVersion` and the home-manager `stateVersion` equal the base's; boot loader flags, the mount definitions of `/`, `/persist`, `/home`, the sops age key file and default sops file, and `myconfig.services.impermanence.enable` equal the base's |
| sddm seed | the unit `ryoku-sddm-theme-seed` exists exactly when impermanence and sddm are on in the spec and never in the base; when present it is oneshot, wanted by and Before `display-manager.service`, `RequiresMountsFor` `/var/lib/ryoku`, its script has the `Main.qml` guard, `/nix/store/` paths and no bare tool |
| settings options | `settings` default `{}`, `settingsMode` default `seed-once`; no settings assertion fails on the host |
| settings unit | `ryoku-settings-seed` exists exactly when settings are declared, not in the base; after and requires `ryoku-materialize`, before `ryoku-shell`, wanted by `ryoku-session.target`, `ConditionUser` equals the ryoku user, oneshot |
| emblem | the krit layer leaves `fastfetchEmblem` null (a Hub/GUI choice), the spec has no `ryoku-fastfetch-emblem-seed` unit and the layer file does not mention `hawk.png` |
| fastfetch wrapper | exactly one `ryoku-fastfetch` in the spec user's packages, none in the base; `real` is the absolute `ryoku-desktop-data` store path; the text has the kitty/ghostty outside-tmux passthrough, the `.logo.type` read with image types handled and every other type passed through (`*) exec "$real" "$@"`), the tmux-kitty `kitten icat --unicode-placeholder --passthrough tmux` pipeline whose info is printed with `--logo-type none --logo-padding-left 0 ... --pipe false` and merged beside the image rows by a perl script (padding read via `.logo.padding.{left,right,top}`; the placeholder branch must not use a `file-raw` logo, which fastfetch would count 2 columns per cell), the `--logo-type file-raw` sprite fallback, the magick-flattened (`flat2`) chafa sprite fallback and the `--logo-type none` default; control: synthetic wrappers fail the probe |
| emblem script | calls `fastfetch import-logo`, names the sentinel `fastfetch-emblem-<hash>` and writes it only after `fastfetch save`; control: the sentinel-order probe rejects a missing sentinel and a sentinel before save |
| settings script | one `seed <store> <json> <16 hex>` call per declared store, `settings-seeded-$store-$hash` sentinel, `mode=seed-once`, no bare tool, `flock` only when `desktop` is declared; control: the sentinel-line and bare-tool probes reject bad lines |
| input | `settings.desktop.desktop.input`: `kbLayout`/`kbVariant` are the first comma entry of `constants.keyboardLayout`/`keyboardVariant`, `kbOptions` is empty, `naturalScroll` false; anchor: `us` / `alt-intl` |
| matugen | the `matugen` store has `mode` = `constants.theme.polarity`, `scheme-expressive`, `darkness`, contrast 0; shell mode is the capitalised polarity, ryogami mode the polarity |
| home option | `myconfig.specializations.ryoku.user` / `.home` equal the spec user and its home; `launcher.heroImage` is `file://<home>/Pictures/Wallpapers/wallhaven-vpyrm5.jpg`; `settings.theme.scheme` is not declared |
| power | both hosts declare `power-profile.profile` `performance` and `performance.autoPowerSaverOnBattery` true; the `power` store has the `power-saver` profile (`powersave`, `balance_power`, 90) and idle `enabled` and `onDesktops` true; battery and AC `dimSec`/`lockSec`/`screenOffSec` equal the `hypridle` options; `suspendSec` is 0/0 on the desktop and 900/1800 on the laptop; control: the idle values are not all equal; the seed script seeds the power store from exactly the declared value and that JSON has the power-saver definition and the idle values |
| orpheus | the desktop has `settings.shell.orpheus` equal to `{ scale = 1.3; }`, the laptop has no orpheus table |
| apps | `settings.desktop.desktop.apps` derives from the constants (terminal-wrapped editor/file manager); the current values are `zen-beta`, `kitty`, `kitty -e nvim`, `kitty -e yazi`, `kitty -e nvim` (anchor); `programs.ryoku.browser` stays null |
| binds files | `hypr/user.lua` and `niri/user.kdl` exist for the ryoku user with `force = true` and not for the base user; no `mango/user.conf` is rendered |
| binds content | none of vicinae, swayosd, swaync, waybar, grimblast; every file parses into binds with no duplicate chord (case and modifier order ignored); hyprland unbind immediately before bind; controls for each probe on synthetic text |
| binds base anchors | when the base user has hyprland binds, the anchor chords (`SUPER+SHIFT + C`, `SUPER + return`, `SUPER + F`, `SUPER + B`, `SUPER + C`) are still in them |
| personal config | kitty: `kitty.conf` off and `user.conf` on while the base has `kitty.conf`; fish: `config.fish` off, `user.fish` on without the `__fish_home_manager_config_sourced` guard line (the base file has it), eza aliases kept; yazi: `yazi.toml` off, `YAZI_CONFIG_HOME` is `~/.config/yazi-user` in `home.sessionVariables` and `environment.sessionVariables` (not in the base), the link farm holds `yazi.toml`; `home-manager.backupFileExtension` set (each only when the program is on) |
| audit | the spec's system ssh config has the `Host gitea-ssh.nicolkrit.ch` block (`Port 2222`, the ryoku user's `id_github`) and the `[gitea-ssh.nicolkrit.ch]:2222` known host (so a plain `git push` from the clone works); `programs.dconf` and `services.fwupd` on, `wallpapersLink` false, NAS secret sops files equal the base's, exist and end in the literal `krit-common-secrets-sops.yaml`, peer ssh `User` is each peer's own constant in `programs.ssh.extraConfig` and the home-manager settings (never the ryoku user), the `sops-common` alias points at an existing `users/<dir>/common/sops/<dir>-common-secrets-sops.yaml` and not at the ryoku user |
| stylix-lite | stylix on with `autoEnable` false at NixOS and home-manager level; the home-manager targets on are exactly bat blender cava fzf gdu gedit lazygit nixcord tmux zathura zen-browser; gtk hyprland kde kitty starship swaync yazi fontconfig font-packages nixos-icons are off; the repo-level targets mirror both lists; control: the base user has more targets on; scheme equal to the base's; `catppuccin.eza` equals base catppuccin and eza on |
| user layer | one `~/.ssh` rule for the ryoku user (owned by the ssh-config module); `ryoku-dotfiles-sync` and `ryoku-nix-sync` in the spec's home and not in the base user's; both are one-shot, `Restart=on-failure`, not start-limited, wanted by `default.target`; `ryoku-dotfiles-private-sync` joins them (all three in the spec's home only, with `GIT_SSL_CAINFO` set); every script has `merge --quiet --ff-only`, `status --porcelain`, `rev-list --count`, `--unshallow`, the `remote.origin.fetch` healing refspec, `GIT_TERMINAL_PROMPT=0` and a temp-dir-only `rm -rf`, and none of `reset`, `--hard`, `--depth`, `--branch`, `clean -`, `checkout`, `rm -rf "$dir"` or key/token literals; the two public units use their exact https urls with no ssh bits, the private one (Gitea, never github.com) the exact `ssh://git@gitea-ssh.nicolkrit.ch:2222/krit/dotfiles-private.git` url with `id_github`, `IdentitiesOnly=yes`, `StrictHostKeyChecking=yes` and the pinned `ryoku-gitea-known-hosts` file; the public ones must not contain ssh, `git@` or gitea (control: `reset --hard`, `--depth` and a removed `--unshallow` variant trip the probe for every unit) |

### Fixture

| Check | Expected |
|-------|----------|
| bob spec | exists, tagged `ryoku`, `programs.ryoku` on in the spec only |
| user | `<base>-ryoku`, differs from the base user |
| uid / ranges | uid differs from the base's, ranges set and not overlapping |
| base user absent | not in the spec's `users.users`, present in the base; the ryoku user is present |
| home-manager users | `[ bob-ryoku ]` in the spec, `[ bob ]` in the base |
| tmpfiles | no spec rule names the base home; control: the base's own rule does |
| home | exactly one `d /home/<ryoku user>` rule owned by the ryoku user |
| portability | with base user `alice` the spec evaluates and yields `alice-ryoku`, its own uid, no alice/bob user, home-manager users `[ alice-ryoku ]`; control: the two fixture bases differ |
| force-off list | all 26 options false in the spec while the base has them on |
| catppuccin | false in the spec, true in the base |
| mutant: vicinae | removing `programs.vicinae` from the list makes the force-off probe fail |
| control | the force-off probe rejects a base that does not have an option on |
| session data | the fixture gets fake sessions `ryoku-hyprland`, `ryoku-niri`, `ryoku-mango` (`fixture/nixos-sessions.nix`): the spec's `sessionNames` has the first two, not mango, and no mango autologin; its desktops derivation links the other packages and not the mango one (control: the mango package is received) |
| mutant: session filter | without the `ryoku-mango` filter in the generic module the session data lists `ryoku-mango` and links its package |
| portal | the spec's `xdg.portal.config` equals the repo table `xdg-portal-config.nix` (list values joined with `;` like the option type does) and routes Secret to `gnome-keyring` once in hyprland, niri and mango |
| mutant: portal | without `lib.mkForce portalConfig` the Ryoku fragments duplicate entries and the probe notices |
| x86_64 | no failing ryoku assertion on x86_64, `programs.ryoku` on |
| aarch64 | with the spec enabled on `aarch64-linux` exactly one failing assertion mentions `x86_64` and `programs.ryoku` stays off |
| mutant: arch gate | with the assertion made trivially true the aarch64 fixture reports no failing ryoku assertion |
| persistence | `/var/lib/ryoku` is persisted in the spec with impermanence on, not in the base; control: with impermanence off it is not |
| sddm seed | with impermanence and sddm the spec has the oneshot unit (wanted by, Before display-manager, mounts `/var/lib/ryoku`), the base has none; script guard and absolute paths; absent with impermanence off and with sddm off; mutants: impermanence gate removed (the off twin gets the unit), `Before` removed |
| settings | options and defaults; with the layer several stores, without it only `desktop.desktop.apps` and `.input`; empty declaration gives no unit; unit ordering and `ConditionUser` for bob-ryoku and alice-ryoku; script calls, sentinel hashes (a changed value changes only its store's hash), `enforce` text; four assertions (hub, i18n-llm, unknown store, `shell.python.general.location`) each with their own message and a valid control; mutants: each assertion removed, `ConditionUser`/`before`/`after` removed |
| sddm cursor (fixture) | options default to null/null/24 and alice (no layer) has no cursor theme, no size and no `XCURSOR_PATH`; bob (krit layer) gets Bibata-Modern-Ice, 24, `XCURSOR_PATH` and the bibata package (control); alice declaring the options gets theme, size 32, `GreeterEnvironment` exactly `[XCURSOR_PATH]` under weston, the package and `/share/icons`; with the kwin compositor `layer-shell` is merged ahead of `XCURSOR_PATH`; mutant: `XCURSOR_PATH` removed from `GreeterEnvironment` is detected |
| sddm weston cursor (fixture) | a weston host declaring the options gets the env-wrapped kiosk command and a readable `weston.ini` with `[shell] cursor-theme/cursor-size` plus the `[libinput]`/`[keyboard]` sections; without the options and under kwin the command has no `XCURSOR_THEME`; bob gets Bibata at 24; mutant: the module with the `compositorCommand` block disabled is flagged |
| fastfetch wrapper | bob's wrapper passes the wrapper probe, alice (no layer) has none; mutants: no `--logo-type none` default, no TMUX test, no unicode-placeholder pipeline, `file-raw` dropped, merge pipeline pieces dropped (`--logo-padding-left 0`, `--pipe false`, padding jq reads, perl print, the `ESC[<n>G` column-shift substitution, its `$maxk` longest-label term or `+ 2` gap, the header indent), placeholder `file-raw` logo restored, `flat2` key or magick flatten dropped, non-image passthrough dropped (all detected) |
| power store | `power` is an accepted store (no settings assertion) and an unknown store is still rejected (control); mutant: `power` removed from the allowed list is rejected as unknown (detected) |
| power idle | with the layer, battery and AC dim/lock/screen off equal the `hypridle` options for the defaults (300/330/360) and for changed values (111/222/333), suspend 900 battery and 1800 AC, `onDesktops` and `enabled` true; a host `suspendSec` of 0 beats the layer default; profile, power-saver and auto switch come from the layer, alice (no layer) has no power store; mutants: a hard-coded `dimSec` ignores the changed option, `mkDefault` removed makes the host override conflict (both detected) |
| emblem | the option defaults to null and without it (alice, no layer) there is no unit; with the layer (bob) the value stays null and there is no unit; a declared emblem on alice gives the unit with the ordering and `ConditionUser` `alice-ryoku`; the real script passes the sentinel-after-save probe; mutants: no sentinel write, sentinel before save (both detected) |
| input | layout `de,us` / variant `nodeadkeys,` / options `grp:ctrl_alt_toggle` gives `de` / `nodeadkeys` / `""` and `naturalScroll` false; an empty variant gives `""`; a leaf override (`kbLayout`, `naturalScroll`) wins and the others stay; mutant: whole layout string instead of the first entry |
| matugen / theme assertion | with the layer: dark gives mode `dark`, light gives `light` (shell `Light`, ryogami `light`), scheme-expressive, darkness, contrast 0; mutant: hard-coded dark stays dark under light; `Dracula` + dark passes, `Dracula` + light fails naming the table (`known polarities`), an unknown theme + light passes; mutant: assertion removed lets Dracula + light pass |
| home / hero image | the `user` and `home` options equal the spec account (bob and alice); `heroImage` follows the base user (`/home/alice-ryoku/...`, no `bob` or `krit`); `settings.theme.scheme` not declared |
| apps | derived from the constants; terminal editor/file manager wrapped (`kitty -e nvim`); GUI editor/file manager bare with notes equal to the editor; foot terminal; one overridden key wins and the others stay; `programs.ryoku.browser` null; mutant: hardcoded kitty fails the foot control |
| binds | force on both files, no mango file, base user has none; no legacy words (mutant: a vicinae launcher in the profile leaks); no duplicate chord, pairing (control twin with a repeated extra bind); host extras reach both files and are absent without them; mutant: `force = false` detected |
| binds lib | fixed constants and profile give 98 hyprland binds (control: a null launcher gives 97), 78 niri binds, mango 99/14/2/2/2/8 lines per type, with recorded anchor chords |
| personal config | kitty.conf/config.fish/yazi.toml off, user.conf/user.fish on, guard-free `user.fish` with eza aliases, yazi variable in both session-variable sets, link farm holds `yazi.toml`, backup extension; mutants: guard-stripping sed removed, `home.sessionVariables` entry removed |
| audit | `programs.dconf` and `services.fwupd` on in the spec (fwupd off in the base); borg off, the other 10 personal modules on in the spec (control: the probe flags the borg list) |
| stylix-lite | autoEnable false in the spec (true in the base); exact on and off target sets; repo-level targets mirror them; scheme equals the base's; `catppuccin.eza` true for the catppuccin base bob, false for alice; mutants: gtk removed from the off list (gtk turns on), `catppuccin.eza` forced false |
| fastfetch wrapper runtime | the real wrapper with the real path replaced by a stub that prints its args (19 checks plus 8 merge checks, fake HOME, generated 1x1 PNG): kitty/ghostty without tmux pass args through and ignore a configured logo (no cache); inside tmux or elsewhere without config the stub gets `--logo-type none`; with a configured image it gets `--logo <cache> --logo-type file-raw` plus the extra args, the cache is non-empty, reused on a second run (same inode/mtime), a changed source mtime gives a second cache name, a non-image or missing source falls back to `--logo-type none` without leftovers; a `type` outside `kitty-direct|kitty|kitty-icat|sixel|iterm|chafa` (`builtin`, `file`, `none`) or `auto` without a source reaches the stub untouched (exactly `a b`, no cache), while an explicit image type with a source under `TMUX=x` (no real tmux, so the tmux-kitty branch is skipped) takes the flattened sprite fallback; the perl merge program extracted from the wrapper (nix perl, 4-row image, padding 1/3/1, off 7): with short labels `ESC[7G` becomes `ESC[16G` (7 + max(6,7) + 2) on every value line, the header gets the blank logo prefix plus 8 spaces, the remaining image rows are appended; with a 19-char label both escapes become `ESC[28G` and the header prefix is 7 + 20 spaces; with the substitution removed `ESC[7G` stays (control; +8 checks) |
| seed script runtime | the real script on temp dirs (14 checks): fresh write with declared values, 0644 files, three `settings-seeded-<store>-<16 hex>` sentinels; seed-once skip keeps a Hub edit; a changed declaration re-applies, keeps Hub-only keys and swaps only that sentinel; enforce re-applies and writes no sentinel; an existing store keeps other keys and mode 0640; invalid or non-object JSON stays byte-identical with rc 1 while other stores are seeded |
| user layer present | with the layer loaded: the three repo sync units (settings and script probe as above); the base host has none |
| user layer absent | without the layer: none of the three repo sync units |
| user layer mutants | every repo sync script with `reset --hard` for the ff-only merge, without the porcelain dirty guard, with `rm -rf "$dir"`, a `--depth` clone, without the unshallow healing, or with swapped https/ssh urls is detected by the probe |
| private sync runtime | the real script with real git against a local bare origin (6 checks, the private unit's script): clean checkout behind fast-forwards; a shallow single-branch checkout is unshallowed, gets the wildcard refspec and fast-forwards; dirty tree not updated and edit kept; ahead of origin not updated; missing `~/.ssh/id_github` gives rc 1 and no change; non-git directory untouched with rc 1 (the clone path needs the network and is not run) |
| user layer off list | only the two borg modules are false in the spec while the base has them on; the 10 other personal modules stay on |
| user layer values | `wallpapersLink` false in the spec and `true` in the base; the yazi go-to exclusion stays `[ ]` in both (the layer no longer sets it) |
| source | the generic module names no user layer (option namespace `<layer>.`, quoted `"<layer>"`, `<layer>-`); controls: the layer module does, and the layer lives under `users/<layer>/` |
| fixture mirror | `fixture/home-user-follows-constants.nix` and `flake.nix` carry the same extension body |
