# test-yazi-open-with

Guards the yazi "Open with" entry in `users/krit/common/programs/file-managers/yazi/yazi.nix`: the `O` (`open --interactive`) menu gets one extra opener that hands the hovered file to an application picked from the ones the system associates with its MIME type (Flatpak apps included), and the menu title is "Menu". Three layers: an eval layer over the yazi settings, a behaviour layer that runs the real, shipped `yazi-open-with` helper against stubbed `gio`, `fzf` and `gtk-launch`, and an opener layer that executes the configured `run` string exactly the way yazi executes an opener.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-yazi-open-with` (name as shown by `--list`).

From the repo root:

```bash
bash templates/tests/nixos/test-yazi-open-with/check-nixos-yazi-open-with.sh
```

From inside the directory:

```bash
bash check-nixos-yazi-open-with.sh
```

One flake eval of three small configs plus two `nix build`s: the helper (a `writeShellApplication`) and the configured yazi package (substituted from the cache / already in the store).

## How it works

`01-scenario-yazi-open-with.nix` loads the real flake and builds three configurations with only `myconfig.krit.programs.yazi.enable` forced on (which hosts enable yazi is never asserted): the `template-host-minimal` NixOS host (Linux), the real darwin host `Krits-MacBook-Pro` (Darwin, evaluated from Linux) and the standalone home `krit@Nicol-NAS` (home-manager `moduleSystem == "home"`, Linux). It exposes one `"ok"` / `"FAIL: ..."` string per check plus the derivation path of the helper, taken from the string context of the opener's `run` (so the test builds exactly what the config would run), the `run` string itself and the derivation of the configured `programs.yazi.package`.

The use lists are asserted against literal expectations: the pre-change lists per rule position (so the first opener, which Enter and `o` run, cannot drift) and the same lists with `open-with` inserted once at index 1. The `vfs/{absent,stale}` rule has a string `use` and must stay untouched. Existing opener definitions must be identical on Linux and Darwin, so adding the entry cannot have altered one. The Darwin config must not carry the entry and its settings must not reference the helper, `gtk` or `glib` store paths (string-context scan); the Linux config must (control that the scan can see them). The standalone home build is Linux, so it carries the entry too.

`check-nixos-yazi-open-with.sh` builds the helper, deletes only its `export PATH=` line (so the stubs on `PATH` win) and runs the otherwise unmodified script in a scratch directory. The stubs: `gio info` prints the MIME type from `STUB_MIME` only if the file exists, `gio mime` prints a canned listing and records `LC_ALL`, `fzf` saves its stdin and arguments and answers with a canned pick (`pick:N`, Esc, no match, empty), `gtk-launch` records its arguments one per `<>` pair. The canned listing has the default app in the middle of the registered list, duplicates between "Registered" and "Recommended" and two Flatpak-style ids.

The runtime-inputs check parses the `PATH` line of the shipped script and requires `gio`, `fzf`, `gtk-launch`, `awk`, `sed`, `realpath` and `head` to resolve from that PATH alone, so the module stays self-sustaining.

### The yazi opener contract (why the opener layer exists)

An earlier version used `run = '<helper> "$1"'` and the shape check asserted exactly that, so the test passed while the real menu entry failed with `Process exited with status code: 2` (the helper's own "missing argument" exit). Yazi (checked against 26.9.1, source `yazi-26.9.1` from `pkgs.yazi-unwrapped.srcs.code_src`) does not pass files as shell positional arguments:

- `yazi-actor/src/mgr/open_do.rs` (`OpenDo::open_with`, used by both Enter and the `O` picker): `cmd: Splatter::new(files).splat(&opener.run)`; files are chunked one per call unless the run string is "spread" (`size = if opener.spread { files.len() } else { 1 }`).
- `yazi-scheduler/src/process/shell.rs`: unix spawn is `Command::new("sh").arg("-c").arg(opt.cmd)` with no further arguments, so `$0` is `sh` and `$1`/`$@` are empty.
- `yazi-fs/src/splatter.rs`: `%s` = all selected files, `%sN` = the N-th (missing one = `''`), `%S` = URLs, `%d`/`%dN` = parent dirs, `%h` = hovered (always `''` for openers, the `&[File]` source has no hovered file), `%%` = literal `%`. Every expanded value goes through `cue()` = `yazi_shared::shell::escape_os_str`, so the placeholder must stay UNQUOTED in the run string. `OpenerRule::fill` sets `spread` when any placeholder without an index is used (`Splatter::spread`).
- `yazi-shared/src/shell/unix.rs` (`escape_os_bytes`): a non-empty value made only of `[A-Za-z0-9-_=/,.+]` is left bare, anything else is wrapped in `'...'` with `'` and `!` written as `'\''` / `'\!'`.
- The shipped default presets (`yazi-default.toml`, embedded in the binary) use `run = "xdg-open %s1"` on Linux.

So the correct form for a single-file helper is `<helper> %s1`: one file per call, shell-escaped by yazi.

The opener layer encodes that contract in a small Python model of the splatter (written to the scratch dir by the check script): `open` mode reproduces `open_with` (spread probe, chunking, one `sh -c <cmd>` per chunk, no positional args, cwd set); `splat` mode is the bare `Splatter::splat`. The model is pinned to upstream by reproducing the unix vectors of the `splatter.rs` unit test that apply to a single-tab file list, and its escaping must round-trip tricky names through `sh -c`. A contract check builds the configured yazi package, follows the wrapper to the real binary and requires its embedded preset to contain `run = "xdg-open %s1"` and no `xdg-open "$1"` / `xdg-open "$@"`, so a future yazi that changes the convention fails here instead of silently passing. The configured run string is then executed through the model with the helper's store path swapped for an argv recorder (it must receive exactly one argument, the absolute path, for a plain name and for names with spaces, parentheses, `'`, `$` and `!`; two selected files must give two calls) and for a wrapper around the real helper under the stubbed tools (end to end: the picked app is launched with the file).

Controls: eval side, a planted `open-with` appended last or placed first, the old `Open with...` desc, a missing one, a swapped first opener, an entry on the download rule, the Linux rules fed to the Darwin lint, an unknown opener name, `O` / `O x` / `<S-o>` / lowercase `o` keymap entries, and run strings using `"$1"`, `$1`, `"$@"`, `"%s1"`, `'%s1'`, `%s`, `%S` or `%h` instead of the bare `%s1`. Script side, each property is broken in a copy of the shipped script (via an exact text replacement that fails loudly if the script drifts) and the matching case must then fail: default-first, dedupe, prompt text, marker stripping, flatpak id mangling, unquoted file, Esc exit code, empty-selection exit code and launching, exit 0 on unknown MIME / no apps, and dropping `LC_ALL=C`. A runtime PATH without fzf and an empty PATH must be flagged. Opener side, the same execution model is run with the wrong conventions: `"$1"` (argv recorder gets an empty argument; the real helper exits 2), `"$@"` (no argument), a double-quoted `"%s1"` (the escaped quotes become part of the path) and spread `%s` (both files in one call); each must be caught.

## Checks

### Eval layer (`check-*` strings from the scenario)

| Check | Expected |
|-------|----------|
| check-linux-pick-title-menu | `pick.open_title == "Menu"` on Linux |
| check-linux-open-with-opener-shape | one `open-with` opener: desc `Open with`, `block = true`, `for = "linux"`, run is `<store>/bin/yazi-open-with %s1` (yazi placeholder, unquoted) |
| check-linux-open-with-run-is-single-helper-closure | the opener settings reference exactly one `yazi-open-with` derivation |
| check-linux-existing-openers-kept | opener names are `download edit extract open play reveal trash` plus `open-with` |
| check-linux-existing-openers-identical-to-darwin | all openers except `open-with` equal the Darwin ones |
| check-linux-open-rules-have-open-with-second | every list-valued `use` equals its literal old list with `open-with` inserted at index 1 (second; before `reveal` / `trash`); the vfs rule is the plain string `download`; 12 rules |
| check-linux-first-opener-unchanged | first opener per rule is `open edit open play extract edit edit edit download edit open open` |
| check-linux-catch-all-rule-last | the last rule is the `*` catch-all |
| check-linux-every-used-opener-resolves | every name in any `use` is a defined opener |
| check-linux-keymap-leaves-O-alone | mgr keymap is non-empty and no binding starts with `O` / `<S-o>` |
| check-standalone-home-has-open-with | standalone home (Linux): opener shape, use lists and the "Menu" title |
| check-darwin-pick-title-menu | `pick.open_title == "Menu"` on Darwin |
| check-darwin-no-open-with-opener | Darwin opener names are exactly the seven existing ones |
| check-darwin-rules-unchanged | Darwin use lists equal the literal old lists |
| check-darwin-settings-do-not-reference-linux-helper | no `yazi-open-with` / `gtk` / `glib` in the string context of the Darwin settings |
| check-darwin-every-used-opener-resolves | every Darwin `use` name is a defined opener |
| check-darwin-keymap-leaves-O-alone | same as Linux |
| check-control-linux-settings-do-reference-helper | the reference scan finds the helper on Linux (not vacuous) |
| check-control-lint-flags-open-with-last | the use-list lint rejects `open-with` appended last |
| check-control-lint-flags-open-with-first | the lint and the first-opener literal reject `open-with` as the first opener |
| check-control-old-desc-rejected | the desc check rejects the old `Open with...` |
| check-control-lint-flags-missing-open-with | the lint rejects a rule without `open-with` |
| check-control-lint-flags-changed-first-opener | the lint and the first-opener literal reject a swapped first opener |
| check-control-lint-flags-download-rule-touched | the lint rejects `open-with` on the vfs download rule |
| check-control-lint-flags-darwin-with-entry | the Darwin lint rejects the Linux rules |
| check-control-unresolved-opener-detected | the resolve probe flags a planted unknown opener |
| check-control-run-shape-rejects-other-conventions | the shape check rejects `"$1"`, `$1`, `"$@"`, `"%s1"`, `'%s1'`, `%s`, `%S`, `%h` after the helper path and accepts `%s1` |
| check-control-keymap-lint-detects-O | the keymap lint flags `O`, a `O x` chord and `<S-o>`, and not lowercase `o` |

### Helper layer (prefix `helper:`)

| Check | Expected |
|-------|----------|
| order-default-first-marker-deduped | fzf input is `* default`, then the other registered / recommended apps once each, two-space indented |
| prompt-shows-Menu-and-mime | fzf is given `--prompt=Menu (text/plain)> ` |
| choosing-default-launches-it | picking line 1 runs `gtk-launch custom-nvim.desktop <file>` |
| choosing-other-strips-marker | picking a non-default line launches the bare id |
| flatpak-ids-pass-through-unchanged | `com.github.tchx84.Flatseal.desktop` and `org.gnome.TextEditor.desktop` reach `gtk-launch` verbatim |
| esc-exits-0-and-launches-nothing | fzf exit 130: exit 0, no launch (fzf did run) |
| empty-selection-exits-0-and-launches-nothing | fzf prints nothing: exit 0, no launch |
| no-match-exits-0-and-launches-nothing | fzf exit 1: exit 0, no launch |
| unknown-mime-message-and-nonzero | no content type: message "could not determine the MIME type", non-zero, no fzf, no launch |
| no-apps-message-and-nonzero | no default and no registered apps: message, non-zero, no fzf, no launch |
| only-default-app-is-listed | only a default: single `* id` line, launchable |
| no-default-means-no-marker | no default: plain two-space lines, no `*` |
| file-name-with-spaces-stays-one-argument | a name with spaces, parentheses, quotes and `$x` reaches `gio info -- <file>` and `gtk-launch` as one argument |
| dash-leading-relative-name-made-absolute | relative `-dash file.txt` is launched as its absolute path |
| gio-mime-runs-with-LC_ALL-C | `gio mime` is called with `LC_ALL=C` |
| missing-file-message-and-exit-1 | missing file: exit 1 with "could not determine the MIME type"; missing directory: exit 1 with "no such file"; no fzf, no launch |
| missing-argument-prints-usage-exit-2 | no argument or an empty one: usage, exit 2 |
| the shipped script prepends its own runtime PATH | exactly one `export PATH=` line, stripped from the copy under test |
| the runtime PATH alone provides gio fzf gtk-launch awk sed realpath head | all resolve from the script's own PATH |

### Controls (script mutants, prefix `control:`)

| Check | Expected |
|-------|----------|
| dropping default-first is detected | the order case fails |
| dropping the dedupe is detected | the order case fails |
| a different prompt is detected | the prompt case fails |
| keeping the marker in the id is detected | the default-launch case fails |
| stripping .desktop from flatpak ids is detected | the flatpak case fails |
| an unquoted file argument is detected | the spaces case fails |
| a non-zero exit on Esc is detected | the Esc case fails |
| a non-zero exit on empty selection is detected | the empty-selection case fails |
| launching on empty selection is detected | the empty-selection case fails |
| exit 0 on an unknown MIME type is detected | the unknown-MIME case fails |
| exit 0 on no associated apps is detected | the no-apps case fails |
| dropping LC_ALL=C is detected | the locale case fails |
| a runtime PATH without fzf is detected | the tool probe flags fzf |
| an empty runtime PATH is detected | the tool probe flags missing tools |

### Opener layer (yazi execution contract)

| Check | Expected |
|-------|----------|
| opener: run string starts with the built helper's bin path | the evaluated `run` begins with `<helper out>/bin/yazi-open-with ` |
| contract: shipped yazi presets use %s1, not $1/$@ | the real binary behind the configured yazi package embeds `run = "xdg-open %s1"` and neither `xdg-open "$1"` nor `xdg-open "$@"` |
| splat model: reproduces upstream splatter.rs unix test vectors | `ls %s`, `ls %s1 %s3 %s2`, `cd %d`, `cd %d1 %d3 %d2`, `ls %s %s2 %s`, `echo % %% %s2 %%h %d`, and the empty-selection cases give the upstream expected strings |
| splat model: escaped names survive sh -c unchanged | names with spaces, `'`, `!`, `"`, `\`, a tab, and the empty string come back verbatim from `sh -c "printf %s <splat>"` |
| opener: hovered file with spaces, quotes, $ and ! arrives as $1 | the argv recorder gets exactly one argument, the absolute path, rc 0 |
| opener: plain file arrives as $1 | same for a plain name |
| opener: two selected files: one helper call per file | two calls, one file each, in selection order |
| opener: end to end: real helper launches the pick for the file | the real helper (stubbed tools, pick 3) runs `gtk-launch org.kde.kate.desktop <file>`, rc 0 |

### Controls (run-string conventions, prefix `control:`)

| Check | Expected |
|-------|----------|
| positional "$1" (yazi passes no args) is detected | the plain-file case fails |
| positional "$1" breaks the end-to-end run | the end-to-end case fails (helper exit 2) |
| positional "$@" is detected | the plain-file case fails |
| a double-quoted "%s1" (double escaping) is detected | the tricky-name case fails |
| spread %s (all files in one call) is detected | the two-files case fails |
