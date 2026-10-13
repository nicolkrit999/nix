# test-app-resolution

Contract for how the app constants (`myconfig.constants.{terminal,browser,editor,fileManager}`) are turned into packages and launchers: `modules/nixos/toplevel/home-packages-nixos.nix` (what gets installed, what warns) and `modules/nixos/toplevel/mime.nix` (default applications, `user-<editor>` launcher, mailto, forced `mimeapps.list`). The design intent: a constant picks an app; if a dedicated module (`programs.<x>.enable`, a home-manager program, a wrapper in `home.packages`, the krit neovim module, the zen module) provides it, home-packages and mime defer to that module (no second install, no second launcher); otherwise the vanilla package is installed once; a name nothing provides installs nothing and warns once. It does not test which apps a real host picks.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-app-resolution` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-app-resolution/check-nixos-app-resolution.sh
```

Or from inside the directory:

```bash
bash check-nixos-app-resolution.sh
```

Needs `nix`, `jq`, `bash`. Eval-only (no builds); about 2 minutes wall, 4 CPU-minutes (about 27 NixOS evaluations).

## How it works

`01-scenario-app-resolution.nix` loads the flake only for its inputs and builds a small fake host (`shared/host-app-resolution.nix`, constants all vanilla: chromium, vim, yazi, kitty) with `denix.lib.configurations` and just the modules under test plus the zen module. Two trees are built: a BARE tree without `users/krit` (so `options ? myconfig.krit.programs.neovim` is false, like the bare fixtures of `test-ai-tool-modules`) and a KRIT tree that adds the krit neovim and dolphin modules. `shared/stylix-stub.nix` and `shared/thunderbird-stub.nix` only declare `myconfig.stylix.{enable,targets}` and `myconfig.programs.thunderbird.enable`, which the zen module and mime read. Each role scenario is an `extendModules` twin that overrides the constants with `mkForce` and enables the providing module.

Measurements: a package counts as installed once per entry named after it (`lib.getName`) across `environment.systemPackages` plus the user's `home.packages`; launchers are the user's `xdg.desktopEntries` names; MIME defaults come from `xdg.mimeApps.defaultApplications`; warnings are those starting with `home-packages: constants`. Package-provided `.desktop` contents are never asserted, only names the modules control.

Every property is a function from a config to a list of problems. The real twins must give `[]`; each `control(...)` check applies the SAME function to a twin that breaks the property (a second install forced into `systemPackages`, the wrong module state for the MIME expectation, a second unknown role, mime disabled, home-packages disabled) and passes only when a problem is reported. Each check is wrapped in `tryEval`; the script refuses to pass with fewer than 40 checks.

Dolphin has no `programs.dolphin.enable` provider: home-packages installs `kdePackages.dolphin`, and the krit dolphin module only adds kio extras, so the scenario asserts a single dolphin and the `org.kde.dolphin.desktop` default.

## Checks

### Vanilla app, no providing module (bare tree)
| Check | Expected |
|-------|----------|
| installed once | chromium, vim, yazi, kitty each exactly once; cliphist and gwenview once |
| no warning | no `home-packages: constants` warning |
| launcher and MIME | only the `user-vim` entry (no `custom-nvim`/`user-neovim`); text types -> `user-vim.desktop`; browser types and mailto -> `chromium-browser.desktop`; `inode/directory` -> `yazi.desktop`; images -> `org.kde.gwenview.desktop` |
| control(once) | a forced second chromium and home-packages disabled are both detected |

### Editor
| Check | Expected |
|-------|----------|
| vim exec | `user-vim` exec is `kitty -e vim %F`; with terminal foot it is `foot -e vim %F` (not hardcoded) |
| helix / code | helix -> `user-helix` entry running `hx`; code -> `code.desktop`, no `user-code` entry |
| neovim, bare tree | `neovim` once, `user-neovim` launcher, text -> `user-neovim.desktop`, no `custom-nvim` |
| neovim, krit module loaded but off | same as the bare tree |
| neovim, krit module on | `neovim` once (module-provided, not from home-packages), only the `custom-nvim` launcher, text -> `custom-nvim.desktop`, no warning |
| nvim alias, krit module on | same as neovim |
| vim, krit neovim on | vim keeps `user-vim.desktop` and its own launcher |
| control(editor) | a forced second neovim, and the module-off / module-on twins failing the opposite expectation, are detected |

### File manager
| Check | Expected |
|-------|----------|
| dolphin (krit module / bare) | exactly one dolphin, `inode/directory` -> `org.kde.dolphin.desktop`, no warning |
| control(fileManager) | a forced second dolphin is detected |

### Browser
| Check | Expected |
|-------|----------|
| firefox via `programs.firefox.enable` (system) | one firefox, MIME `firefox.desktop`, no warning |
| firefox via home-manager `programs.firefox.enable` | one firefox, no warning |
| firefox with no module | installed once from pkgs |
| zen-beta via the zen module | one zen-beta (module-installed), `zen-beta.desktop`, no warning |
| zen-beta via the zen module while pkgs also has a `zen-beta` (overlay) | still exactly one zen-beta: the `zen-beta -> zen-browser` alias defers to the module |
| brave / chrome | `brave-browser.desktop` / `google-chrome.desktop` |
| mailto | `thunderbird.desktop` when thunderbird is enabled (browser types untouched), the browser desktop otherwise |
| control(browser) | a forced second firefox, and the vanilla twin lacking thunderbird mailto, are detected; with the overlay but without the module, zen-beta is installed once from pkgs (so the overlay package really is visible to the alias check) |

### Unknown names and provider detection
| Check | Expected |
|-------|----------|
| unknown browser | nothing installed under that name, exactly one warning naming the role and name, no other warning |
| unknown browser and file manager | exactly two warnings (one per role) |
| unknown editor | exactly one warning |
| zen-beta without the module | nothing installed, exactly one warning (so the zen alias is what silences it) |
| wrapper in `home.packages` (brave-school style) | wrapper installed once, no warning |
| control(warnings) | a second unknown role breaks the lone-warning check; the quiet check sees the unknown-name warning |

### mime
| Check | Expected |
|-------|----------|
| forced mimeapps | `xdg.configFile."mimeapps.list".force` is true |
| control(mime) | with the mime module off it is not true |
