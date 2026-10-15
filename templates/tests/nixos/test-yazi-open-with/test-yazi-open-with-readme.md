# test-yazi-open-with

Guards the yazi "Open with..." entry in `users/krit/common/programs/file-managers/yazi/yazi.nix`: the `O` (`open --interactive`) menu gets one extra opener that hands the hovered file to an application picked from the ones the system associates with its MIME type (Flatpak apps included), and the menu title is "Menu". Two layers: an eval layer over the yazi settings, and a behaviour layer that runs the real, shipped `yazi-open-with` helper against stubbed `gio`, `fzf` and `gtk-launch`.

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

One flake eval of three small configs plus one `nix build` of the helper (a `writeShellApplication`, cached after the first run).

## How it works

`01-scenario-yazi-open-with.nix` loads the real flake and builds three configurations with only `myconfig.krit.programs.yazi.enable` forced on (which hosts enable yazi is never asserted): the `template-host-minimal` NixOS host (Linux), the real darwin host `Krits-MacBook-Pro` (Darwin, evaluated from Linux) and the standalone home `krit@Nicol-NAS` (home-manager `moduleSystem == "home"`, Linux). It exposes one `"ok"` / `"FAIL: ..."` string per check plus the derivation path of the helper, taken from the string context of the opener's `run` (so the test builds exactly what the config would run).

The use lists are asserted against literal expectations: the pre-change lists per rule position (so the first opener, which Enter and `o` run, cannot drift) and the same lists with `open-with` appended once, at the end. The `vfs/{absent,stale}` rule has a string `use` and must stay untouched. Existing opener definitions must be identical on Linux and Darwin, so adding the entry cannot have altered one. The Darwin config must not carry the entry and its settings must not reference the helper, `gtk` or `glib` store paths (string-context scan); the Linux config must (control that the scan can see them). The standalone home build is Linux, so it carries the entry too.

`check-nixos-yazi-open-with.sh` builds the helper, deletes only its `export PATH=` line (so the stubs on `PATH` win) and runs the otherwise unmodified script in a scratch directory. The stubs: `gio info` prints the MIME type from `STUB_MIME` only if the file exists, `gio mime` prints a canned listing and records `LC_ALL`, `fzf` saves its stdin and arguments and answers with a canned pick (`pick:N`, Esc, no match, empty), `gtk-launch` records its arguments one per `<>` pair. The canned listing has the default app in the middle of the registered list, duplicates between "Registered" and "Recommended" and two Flatpak-style ids.

The runtime-inputs check parses the `PATH` line of the shipped script and requires `gio`, `fzf`, `gtk-launch`, `awk`, `sed`, `realpath` and `head` to resolve from that PATH alone, so the module stays self-sustaining.

Controls: eval side, a planted `open-with` in the middle of a list, a missing one, a swapped first opener, an entry on the download rule, the Linux rules fed to the Darwin lint, an unknown opener name, and `O` / `O x` / `<S-o>` / lowercase `o` keymap entries. Script side, each property is broken in a copy of the shipped script (via an exact text replacement that fails loudly if the script drifts) and the matching case must then fail: default-first, dedupe, prompt text, marker stripping, flatpak id mangling, unquoted file, Esc exit code, empty-selection exit code and launching, exit 0 on unknown MIME / no apps, and dropping `LC_ALL=C`. A runtime PATH without fzf and an empty PATH must be flagged.

## Checks

### Eval layer (`check-*` strings from the scenario)

| Check | Expected |
|-------|----------|
| check-linux-pick-title-menu | `pick.open_title == "Menu"` on Linux |
| check-linux-open-with-opener-shape | one `open-with` opener: desc `Open with...`, `block = true`, `for = "linux"`, run is `<store>/bin/yazi-open-with "$1"` |
| check-linux-open-with-run-is-single-helper-closure | the opener settings reference exactly one `yazi-open-with` derivation |
| check-linux-existing-openers-kept | opener names are `download edit extract open play reveal trash` plus `open-with` |
| check-linux-existing-openers-identical-to-darwin | all openers except `open-with` equal the Darwin ones |
| check-linux-open-rules-end-with-open-with | every list-valued `use` equals its literal old list plus a trailing `open-with`; the vfs rule is the plain string `download`; 12 rules |
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
| check-control-lint-flags-open-with-in-middle | the use-list lint rejects `open-with` before `reveal` |
| check-control-lint-flags-missing-open-with | the lint rejects a rule without `open-with` |
| check-control-lint-flags-changed-first-opener | the lint and the first-opener literal reject a swapped first opener |
| check-control-lint-flags-download-rule-touched | the lint rejects `open-with` on the vfs download rule |
| check-control-lint-flags-darwin-with-entry | the Darwin lint rejects the Linux rules |
| check-control-unresolved-opener-detected | the resolve probe flags a planted unknown opener |
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
