# test-mime-resolution

Contract for the MIME defaults that `modules/nixos/toplevel/mime.nix` derives from the file-family role constants (`myconfig.constants.{videoPlayer,audioPlayer,imageViewer,pdfViewer,docEditor,sheetEditor,slideEditor,archiveManager}`) on the REAL `nixos-desktop` and `nixos-laptop`, and proof that the generated `mimeapps.list` really beats a flatpak exports directory that comes first in `XDG_DATA_DIRS`.

Why it exists: opening an `.mp4` once launched the Filmcraft flatpak. `mime.nix` set no video default, so GIO fell back to `mimeinfo.cache` order and the Craft flatpaks (listed before the profile in `XDG_DATA_DIRS`) won every type nobody had claimed. The slim fake-host cases of the role logic (fallback, install-once, warnings) live in `test-app-resolution`; this test covers the real hosts and the real GIO / `xdg-mime` behaviour.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-mime-resolution` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-mime-resolution/check-nixos-mime-resolution.sh
```

Or from inside the directory:

```bash
bash check-nixos-mime-resolution.sh
```

Needs `nix`, `jq`, `bash`. The sandbox layer fetches `glib`, `xdg-utils` and `desktop-file-utils` through `nix shell --inputs-from <repo> nixpkgs#...`, so they come from the flake's locked nixpkgs. About 3 minutes wall warm; the profile layer reads `share/applications` of the packages that provide the role apps (vlc, gwenview, zathura, ark on today's hosts), which may be downloaded from the cache on a cold store.

## How it works

`01-scenario-mime-resolution.nix` takes `--argstr host` and evaluates `flake.nixosConfigurations.<host>`. It reads the resolved `xdg.mimeApps.defaultApplications` of the home-manager user and holds its own list of MIME types per role (an independent copy of what `mime.nix` should own, not read from it). It exposes three things per host: `results` (pure eval checks), `profileResults` (checks that read the packages' `share/applications`, kept separate because realising a package can fail without being catchable) and `mimeappsList` (the text of the generated `mimeapps.list`).

Eval layer. Each property is a function from a config to a list of problems. The real config must give `[]`; each `control:` check applies the SAME function to a broken input (an unowned MIME type, a bogus flatpak id, a package role that resolves to a flatpak, `video/mp4` forced to Filmcraft in an `extendModules` twin, a twin whose `videoPlayer` is an unknown name) and passes only when a problem is reported. The user decision (video/audio on vlc, docx/xlsx/pptx on the Craft apps, images on Gwenview) is kept in its own `host contract` checks; everything else is derived from the constants and the host's own `services.flatpak.packages`.

Sandbox layer. The generated `mimeapps.list` of each host becomes `$XDG_CONFIG_HOME/mimeapps.list` of a throw-away tree. `XDG_DATA_DIRS` is `<fake flatpak exports>:<fake profile>`, so the flatpak dir comes first like on the real systems. The profile dir gets one fake `.desktop` per default id of the list (Craft ids go to the flatpak dir). The flatpak dir also gets fake `ai.storyteller.filmcraft` (claims every probed video and audio type), `photocraft` (every probed image type) and `pdfcraft` (`application/pdf`), indexed with `update-desktop-database`. `xdg-mime query default <type>` and `gio mime <type>` are run under `env -i` for every video, audio, image and pdf type of the list and must return the list's id. The negative control empties `mimeapps.list` (the original bug state) and requires the fake flatpak to win for the same types with both tools, which proves the sandbox would have caught the bug.

NixOS-built `gio` additionally appends the host's system and per-user profile directories after `XDG_DATA_DIRS`, so on a NixOS machine that lowest-priority tail is not hermetic; every probed type is claimed by a fake dir ahead of it, so it never decides a result. The script refuses to pass with fewer than 90 checks.

## Checks

Per host (`nixos-desktop`, `nixos-laptop`), eval layer (`results`):

| Check | Expected |
|-------|----------|
| no role fell back | no `mime:` or `home-packages: constants` warning on the real host |
| control: unknown videoPlayer | a twin with an unknown `videoPlayer` produces the fallback warning and `video/mp4` -> `mpv.desktop` |
| video/mp4 is never a Craft app | `video/mp4` does not resolve to an `ai.storyteller.*` id |
| control: Filmcraft | a twin with `video/mp4` forced to Filmcraft is flagged by that check |
| video, audio, image, pdf and archive types never resolve to a Craft app unless the host chose one for that role | the types of every such role whose constant is not a flatpak id resolve to no `ai.storyteller.*` id |
| every video/ and audio/ default | maps to the video / audio role's app |
| every image/ default and application/pdf | maps to the image / pdf role's app |
| control: prefix check | flagged on the twin with `video/mp4` forced to Filmcraft |
| control: unowned type | `video/x-no-such-type` is reported as having no explicit default |
| control: flatpak id missing from the list | `flatpakProblems` reports an id that is not in the host's flatpak list |
| control: package role resolving to a flatpak | an `imageViewer` resolving to `ai.storyteller.photocraft.desktop` is reported |
| control: two apps for one role | the Filmcraft twin makes `videoPlayer` resolve to several apps and is reported |
| `<role>: every owned type has an explicit default` (8 roles) | none of the role's types is missing from `defaultApplications` |
| `<role>: one app for all types, flatpak id consistent ...` (8 roles) | all types resolve to one id; a flatpak-id constant gives `<id>.desktop` and that id is in the host's flatpak list; a package constant never resolves to a flatpak id |
| host contract: video and audio | `video/mp4` and `audio/flac` -> `vlc.desktop` |
| host contract: office | docx -> `ai.storyteller.wordcraft.desktop`, xlsx -> `gridcraft`, pptx -> `deckcraft` |
| host contract: images | every image type -> `org.kde.gwenview.desktop`, none to a Craft app |

Per host, profile layer (`profileResults`):

| Check | Expected |
|-------|----------|
| `<role>: the default .desktop id exists ...` (8 roles) | a flatpak-id constant is in the host's flatpak list; a package constant has a profile package (`environment.systemPackages`, user packages, home-manager `home.packages`) named after it that ships the resolved `.desktop` id |
| control: bogus id | an id nothing ships is not found in the video player's packages |
| control: unknown package | a package name nothing provides has no candidates |

Per host, sandbox layer:

| Check | Expected |
|-------|----------|
| no default is a competitor id | none of the probed video/audio/image/pdf defaults is the fake Filmcraft, Photocraft or Pdfcraft |
| `xdg-mime` / `gio mime` resolve the explicit default | for every probed type both tools return the list's id although the fake flatpak dir is first |
| control: emptied list | the emptied `mimeapps.list` differs from the generated one |
| control: without the explicit defaults the fake flatpak wins (`xdg-mime`, `gio mime`) | with the list emptied both tools return the fake flatpak app for every probed type |
