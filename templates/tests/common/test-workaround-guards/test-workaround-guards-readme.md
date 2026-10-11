# test-workaround-guards

Guards for the momentary workarounds (vicinae gcc15Stdenv override, claude-desktop pipewire overlay, lazygit catppuccin migrated theme, openblas i686 doCheck overlay, school opencloud-desktop QML paths): each must stay effective, and the test says when one has become removable.

## Run

From the repo root:

```bash
bash templates/tests/common/test-workaround-guards/check-common-workaround-guards.sh
```

From inside the directory:

```bash
bash check-common-workaround-guards.sh
```

## How it works

`01-scenario-workaround-guards.nix` loads the real flake and evaluates `nixos-desktop` (plus the `school` specialisation and the Darwin host for lazygit). `check-common-workaround-guards.sh` runs `nix eval --raw` per attribute: `ok` is PASS, `FAIL: ...` or an eval error is FAIL. Attributes named `warn-*` are staleness controls comparing the workaround against the plain upstream value; they report WARN (never fail) with the memory file to update when the upstream gap is closed. Effectiveness checks compare against independent sources (`pkgs.stdenv`, plain `legacyPackages`, `pkgs.kdePackages`). The lazygit check builds the migrated theme and the upstream one (small, `yq` only). Only the final result is non-zero on FAIL. Runtime about 25 s warm.

## Checks

### vicinae (memory: vicinae-gcc15stdenv-override)

| Check | Expected |
|-------|----------|
| HM package cc version | equals `pkgs.stdenv.cc.version` |
| input-server package cc version | equals `pkgs.stdenv.cc.version` |
| HM and input-server package | same drvPath |
| warn: upstream vicinae cc version | differs from ours, else override removable |

### claude-desktop (memory: claude-desktop-pipewire-overlay)

| Check | Expected |
|-------|----------|
| buildInputs (module enabled via extendModules) | contain pipewire |
| warn: pipewire count | below 2, else upstream already has it and overlay is removable |

### lazygit (memory: project-lazygit-catppuccin-migrated-workaround)

| Check | Expected |
|-------|----------|
| `catppuccin.sources.lazygit.name` on nixos-desktop and Darwin | `catppuccin-lazygit-migrated` |
| built theme yml files | no `^  authorColors` under `gui:`; `theme.authorColors` kept when upstream has it |
| warn: upstream theme | still has `gui.authorColors`, else workaround removable |

### openblas (memory: openblas-i686-docheck-workaround)

| Check | Expected |
|-------|----------|
| `pkgsi686Linux.openblas.doCheck` | false |
| x86_64 `openblas.doCheck` | equals plain nixpkgs value |
| warn: plain nixpkgs i686 doCheck | not false, else overlay removable |

### school opencloud-desktop

| Check | Expected |
|-------|----------|
| package count in school specialisation | 1 |
| `qtWrapperArgs` store paths | exactly kirigami (unwrapped), qqc2-desktop-style, qqc2-breeze-style `lib/qt-6/qml` |
| `NIXPKGS_QT6_QML_IMPORT_PATH` prefixes | three |
