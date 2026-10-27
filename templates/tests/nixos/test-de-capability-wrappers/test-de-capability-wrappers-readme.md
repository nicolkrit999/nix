# test-de-capability-wrappers

Per-DE hardening contract, evaluated on twins of the minimal `template-host-minimal` fixture (`lib/fixture-host.nix`) with only the DE under test enabled: KDE's `kwin_wayland` wrapper carries no file capabilities, GNOME's package exclusions take effect and rygel stays off, COSMIC's CosmicTk font files carry the stylix fonts. It does not test which DE a host enables.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-de-capability-wrappers` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-de-capability-wrappers/check-nixos-de-capability-wrappers.sh
```

Or from inside the directory:

```bash
bash check-nixos-de-capability-wrappers.sh
```

Needs `nix`, `jq`, `bash`. About 1 min (three twin evaluations plus a small linkFarm build for the COSMIC font files).

## How it works

`01-scenario-de-capability-wrappers.nix` exposes `results` (`label -> "ok" | "FAIL: ..."`), each check wrapped in `tryEval`. Properties are functions from a config to a list of problems; `control(...)` checks apply the same function to a twin that breaks the property (a `mkOverride 10` capability on the wrapper, an emptied exclude list plus rygel on) and pass only when a problem is reported.

KDE: the wrapper must exist (so the check is not satisfied by absence) with `capabilities == ""`; a kde-off twin must have no such wrapper, proving the module is the source. GNOME: `environment.gnome.excludePackages` is non-empty, none of its packages remain in `environment.systemPackages` (a control shows the unexcluded list does leak packages), and `services.gnome.rygel.enable` is false. COSMIC: the `cosmic-tk-fonts` package is built at eval time and its `interface_font` / `monospace_font` files must name the stylix sans-serif / monospace font; sans and monospace must differ so a swap is detectable. The stylix-off case is not testable here (a stylix-off twin breaks the home-manager stylix options), so the negative scenario is a cosmic-off twin.

## Checks

### Fixture host
| Check | Expected |
|-------|----------|
| kde wrapper | `security.wrappers.kwin_wayland` exists and `capabilities == ""` with kde on |
| kde control | no `kwin_wayland` wrapper with kde off |
| gnome | exclude list non-empty, nothing from it in `systemPackages`, desktopManager on, rygel off |
| cosmic fonts | `cosmic-tk-fonts` present; `interface_font` names the stylix sans font, `monospace_font` the monospace font, `weight: Normal` |
| cosmic control | no `cosmic-tk-fonts` with cosmic off |

### Controls (must be flagged)
| Control | Expected |
|---------|----------|
| capability-bearing kwin wrapper | kwin check reports |
| emptied exclude list + rygel on | gnome check reports |
| emptied exclude list | packages from the list appear in `systemPackages` |
| swapped font file contents | font check reports |
| cosmic-off twin | cosmic font check reports the missing package |
