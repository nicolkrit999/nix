# test-darwin-home-paths

Eval-only sweep proving no Linux home path (`/home/`) leaks into rendered Darwin config, where the home is `/Users/<user>`. Common modules (`librewolf-common.nix`, `firefox.nix`) hard-code `/home/${user}`; they are latent on the Mac while the browsers are not enabled there.

## Run

From the repo root:

```bash
bash templates/tests/darwin/test-darwin-home-paths/check-darwin-home-paths.sh
```

From inside the directory:

```bash
bash check-darwin-home-paths.sh
```

Runtime is about 1 to 2 minutes (lazy eval, no builds, one `nix eval` per check).

## How it works

`01-scenario-darwin-home-paths.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads `darwinConfigurations.Krits-MacBook-Pro`. It sweeps rendered strings for the substring `/home/`: `home.file.*.text`, `xdg.configFile.*.text`, `home.sessionVariables`, `home.activation.*.data`, `system.activationScripts.*.text` (except the aggregate `script`), `environment.variables` and `sops.templates.*.path`.

Two configurations are swept. The base host is the positive control and must be clean. The variant (`host.extendModules` forcing `krit.programs.librewolf` and `krit.programs.firefox` on) activates the common browser modules; there the sweep also covers the Firefox/LibreWolf `user.js` files, both browsers' profile `settings`, and the LibreWolf wrapper script (`programs.librewolf.package.text`), whose `MOZ_APP_DISTRIBUTION` must start with `home.homeDirectory`.

The variant only forces the two module toggles it needs on top of the real host; it does not assert which programs the real host enables (a host choice). Control checks prove the sweeps can bite: the file-text sweep is non-empty, the activation and sops-template sweeps see `/Users` paths, and the variant checks that both browsers (and the policies file plus three `user.js` files) are actually active.

Regression guard: the browser modules derive the home from `moduleSystem` (darwin `/Users`, else `/home`), so the Firefox/LibreWolf `browser.download.dir`/`lastDir`, the LibreWolf `policyRoot` and the wrapper `MOZ_APP_DISTRIBUTION` must follow the platform. Three variants force both browsers on: the Darwin host, `nixosConfigurations.template-host-minimal` (HM) and the standalone `homeConfigurations."krit@template-host-minimal"` (`moduleSystem == "home"`); the Linux two must resolve to `/home/<user>`. The Linux checks report `ok` when `nixosConfigurations` is hidden (Darwin IFD guard).

## Checks

### base host

| Check | Expected |
|-------|----------|
| HM `home.homeDirectory` | starts with `/Users/` |
| `home.file` texts, `xdg.configFile` texts, `home.sessionVariables`, `home.activation`, `system.activationScripts`, `environment.variables`, `sops.templates` paths | none contains `/home/` |
| control: `home.file` text sweep | non-empty |
| control: activation scripts, sops template paths | at least one `/Users` path |
| `programs.nh.flake` | under `home.homeDirectory` |

### variant (librewolf + firefox enabled)

| Check | Expected |
|-------|----------|
| control | variant on; HM programs enabled; policies file and 3 `user.js` present |
| `home.file` texts, `xdg.configFile` texts, `home.sessionVariables`, `home.activation`, `system.activationScripts` | none contains `/home/` |
| Firefox/LibreWolf `user.js` | none contains `/home/` |
| `programs.librewolf` / `programs.firefox` profile settings | none contains `/home/` |
| LibreWolf wrapper `MOZ_APP_DISTRIBUTION` | starts with `home.homeDirectory/` |
| LibreWolf wrapper script | no `/home/` |

### browser home regression guard

| Check | Expected |
|-------|----------|
| Darwin variant | download dir, lastDir (both browsers), wrapper policyRoot under `/Users/<user>` |
| `nixosConfigurations` HM variant | same paths under `/home/<user>` |
| standalone `homeConfigurations` variant | same paths under `/home/<user>` |
