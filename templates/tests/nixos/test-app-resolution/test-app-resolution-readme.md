# test-app-resolution

Contract for how the app constants (`myconfig.constants.{terminal,browser,editor,fileManager}` plus the file-family roles `{videoPlayer,audioPlayer,imageViewer,pdfViewer,docEditor,sheetEditor,slideEditor,archiveManager}` that `mime.nix` installs and maps) are turned into packages and launchers: `modules/nixos/toplevel/home-packages-nixos.nix` (what gets installed, what warns) and `modules/nixos/toplevel/mime.nix` (default applications, `user-<editor>` launcher, mailto, forced `mimeapps.list`). The design intent: a constant picks an app; if a dedicated module (`programs.<x>.enable`, a home-manager program, a wrapper in `home.packages`, the krit neovim module, the zen module) provides it, home-packages and mime defer to that module (no second install, no second launcher); otherwise the vanilla package is installed once; a name nothing provides installs nothing and warns once. It does not test which apps a real host picks.

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

Needs `nix`, `jq`, `bash`. Eval-only (no builds); about 2.5 minutes wall, 3 CPU-minutes warm (about 62 NixOS twin evaluations in 12 `nix eval` processes, peak about 5 GB RSS per process).

## How it works

`01-scenario-app-resolution.nix` loads the flake only for its inputs and builds a small fake host (`shared/host-app-resolution.nix`, constants all vanilla: chromium, vim, yazi, kitty) with `denix.lib.configurations` and just the modules under test plus the zen module. Two trees are built: a BARE tree without `users/krit` (so `options ? myconfig.krit.programs.neovim` is false, like the bare fixtures of `test-ai-tool-modules`) and a KRIT tree that adds the krit neovim and dolphin modules. `shared/stylix-stub.nix` and `shared/thunderbird-stub.nix` only declare `myconfig.stylix.{enable,targets}` and `myconfig.programs.thunderbird.enable`, which the zen module and mime read. `shared/extra.nix` also declares the home-manager option `programs.plasma.resetFilesExclude` (normally from plasma-manager, absent in this tree) because `dolphin.nix` sets it. Each role scenario is an `extendModules` twin that overrides the constants with `mkForce` and enables the providing module.

Measurements: a package counts as installed once per entry named after it (`lib.getName`) across `environment.systemPackages` plus the user's `home.packages`; launchers are the user's `xdg.desktopEntries` names; MIME defaults come from `xdg.mimeApps.defaultApplications`; warnings are those starting with `home-packages: constants` or `mime: constants`. The fake tree declares `services.flatpak.packages` (normally from nix-flatpak) in `shared/extra.nix` so flatpak-id twins can list apps. Package-provided `.desktop` contents are never asserted, only names the modules control.

Every property is a function from a config to a list of problems. The real twins must give `[]`; each `control(...)` check applies the SAME function to a twin that breaks the property (a second install forced into `systemPackages`, the wrong module state for the MIME expectation, a second unknown role, mime disabled, home-packages disabled) and passes only when a problem is reported. Each check is wrapped in `tryEval`; the script refuses to pass with fewer than 85 checks.

The checks are split into named groups (`groups` in the scenario: vanilla, editor, neovim, dolphin, browser, warnings, media, roles, roleControls, extras, desktopRoles, mime), and the script runs one `nix eval` per group (`groupNames`, then `groupResults "<group>"`), merging the results. Every twin stays reachable from the scenario's `let` for the whole process, so memory grows by about 300 MB per twin: one process for all twins peaked at 22 GB RSS and timed out on the 16 GB CI runner (run 38788879011). A group re-evaluates only the twins its own checks read (vanilla appears in several), so the peak is the biggest group, about 5 GB. `groupNames` throws if a label appears in two groups, and an `abort` in one group fails that group without hiding the others.

Dolphin has no `programs.dolphin.enable` provider: home-packages installs `kdePackages.dolphin`, and the krit dolphin module only adds kio extras, so the scenario asserts a single dolphin and the `org.kde.dolphin.desktop` default.

## Checks

### Vanilla app, no providing module (bare tree)
| Check | Expected |
|-------|----------|
| installed once | chromium, vim, yazi, kitty each exactly once; cliphist and gwenview (installed by the `imageViewer` role of mime) once; the bare role apps mpv (shared by video and audio), libreoffice (shared by doc, sheet and slide), zathura and ark once each |
| no warning | no `home-packages: constants` warning |
| launcher and MIME | only the `user-vim` entry (no `custom-nvim`/`user-neovim`); text types -> `user-vim.desktop`; browser types and mailto -> `chromium-browser.desktop`; `inode/directory` -> `yazi.desktop`; images -> `org.kde.gwenview.desktop`; PDF is no longer a browser type |
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

### File-family roles
| Check | Expected |
|-------|----------|
| bare defaults | video and audio -> `mpv.desktop`, PDF -> `org.pwmt.zathura.desktop`, doc/sheet/slide -> `writer`/`calc`/`impress.desktop`, archives -> `org.kde.ark.desktop`, no warning |
| bare images | the extra image types (avif, bmp, tiff, svg, heic, jxl, psd, xcf, dng, RAW) -> `org.kde.gwenview.desktop` |
| explicit mpv | `videoPlayer`/`audioPlayer` = the default: no warning, mpv still once |
| vlc | `videoPlayer`/`audioPlayer` = vlc: vlc installed once, `vlc.desktop` for video and audio |
| okular | `pdfViewer` = okular (a `kdePackages` name): okular once, zathura not installed, `org.kde.okular.desktop` |
| file-roller | `archiveManager` = file-roller evaluates (`programs.file-roller` is a nixpkgs-removed option that throws when read): one file-roller, no ark, `org.gnome.FileRoller.desktop`, no warning |
| xarchiver | `archiveManager` = xarchiver (name without a table entry): installed once, `xarchiver.desktop`, no ark |
| zathura via home-manager | `programs.zathura.enable` provides it: still exactly one zathura, no warning |
| `home.packages` wrapper | `videoPlayer` = a wrapper in the user's `home.packages`: `<name>.desktop`, installed once, no warning, audio keeps mpv |
| flatpak ids present | doc/sheet ids listed in `services.flatpak.packages`: `<id>.desktop`, nothing installed for them, no warning |
| all office roles on flatpak | libreoffice is not installed at all |
| image flatpak id present | every image type -> `<id>.desktop`, gwenview not installed, no warning |
| image flatpak id missing | gwenview for every image type, installed once, one warning |
| flatpak id missing | falls back to the bare default, one warning per role |
| unknown package name | `videoPlayer`/`archiveManager` fall back to `mpv.desktop`/`org.kde.ark.desktop` with exactly one warning each |
| every role unknown | each role at its bare default, exactly 8 warnings (one per role), bare apps installed once |
| control(media) | the vanilla twin fails the vlc expectation, the flatpak-missing twin fails the flatpak-present expectation |
| control(roles) | a forced second mpv, and a second zathura on top of the home-manager module, are detected; the okular twin fails the zathura expectation and vanilla fails the okular one; the photocraft twin fails the gwenview expectation; vanilla does install libreoffice; the all-unknown twin trips the quiet check and a wrong warning count |

### Removed program options
| Check | Expected |
|-------|----------|
| removed option | reading `programs.file-roller.enable` throws, yet the `archiveManager = file-roller` twin still evaluates its warnings and package names |
| control(removed option) | a declared option (`programs.firefox.enable`) reads fine, so the throw is specific to the removed option |

### extraAppPackages
| Check | Expected |
|-------|----------|
| name in pkgs (hello) | installed exactly once, no warning |
| name only in `pkgs.kdePackages` (kate) | installed exactly once, no warning |
| unknown name | exactly one `mime: extraAppPackages` warning naming it, nothing installed, no other warning |
| mixed list (hello twice, two unknown) | hello once, one warning listing both unknown names in order and not hello |
| dedupe against role installs | mpv named as an extra while the video/audio roles install it: still once, no warning |
| dedupe against a module | zathura named as an extra while `programs.zathura.enable` (home-manager) provides it: still once, no warning |
| provided by a `home.packages` wrapper | a name that is not in pkgs but provided by a wrapper: wrapper once, no unresolved warning |
| control(extras) | the vanilla twin installs neither hello nor kate and has no extras warning; `pkgs` has no top-level `kate` (so the kdePackages fallback is what resolves it); the quiet check sees the unknown-extra warning; a forced second mpv is detected |

### `.desktop` role values
| Check | Expected |
|-------|----------|
| `docEditor = "org.kde.kate.desktop"` + `extraAppPackages = [ "kate" ]` | doc types mapped verbatim to `org.kde.kate.desktop`, kate once, libreoffice still once (sheet and slide), no warning |
| same value without `extraAppPackages` | falls back to `writer.desktop`, exactly one warning (pointing at `extraAppPackages`), kate not installed |
| same value with an unrelated extra (hello) | falls back with one warning, hello installed, kate not |
| `<flatpak id>.desktop` listed in `services.flatpak.packages` | mapped verbatim, nothing installed, no warning |
| `<flatpak id>.desktop` not listed | falls back to `writer.desktop` with one warning |
| `archiveManager = "org.gnome.FileRoller.desktop"` + `extraAppPackages = [ "file-roller" ]` | verbatim id, file-roller once, ark not installed, no warning |
| control(desktop roles) | the fallback twin fails the kate expectation, the kate twin fails the writer one, the extras-only twin (no `.desktop` role) fails the kate one, the missing-flatpak twin fails the wordcraft one; the kate twin has no warning while the fallback twin trips the quiet check |

### mime
| Check | Expected |
|-------|----------|
| forced mimeapps | `xdg.configFile."mimeapps.list".force` is true |
| control(mime) | with the mime module off it is not true |
