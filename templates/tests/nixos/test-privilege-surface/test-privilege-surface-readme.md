# test-privilege-surface

Wiring-consistency contract for the privilege surface of the REAL `nixos-desktop` and `nixos-laptop` configurations: who the nix daemon trusts, which binary caches it uses (and that CI uses the same ones), polkit auto-approvals, root-capability wrappers, inbound SSH exposure and the crash-kernel reservation. It does not test which programs or shells a host enables.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-privilege-surface` (name as shown by `--list`); the direct commands are below.

From the repo root:

```bash
bash templates/tests/nixos/test-privilege-surface/check-nixos-privilege-surface.sh
```

Or from inside the directory:

```bash
bash check-nixos-privilege-surface.sh
```

Needs `nix`, `jq`, `bash`. Eval-only (no builds); about 12 s per host.

## How it works

`01-scenario-privilege-surface.nix` takes `{ host, ciBuild ? "", ciDarwin ? "" }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (`FLAKE_ROOT` is exported by the runner; the scenario throws if unset) and exposes `results`, an attrset of `label -> "ok" | "FAIL: ..."`. Each check is wrapped in `tryEval`. `check-nixos-privilege-surface.sh` runs it per host and refuses to pass with fewer than 30 checks.

Every property is a function from a config to a list of problems. The real config must give `[]`. A `control(...)` check applies the SAME function to an `extendModules` twin that breaks the property (duplicate `root`, `openFirewall`, a `gpu-screen-recorder` polkit rule, a niri cache, a dropped CI cache, ...) and passes only when the function reports a problem. `ciBuild` / `ciDarwin` optionally point at alternative workflow files, to mutation-test the drift guard against a scratch copy.

Drift guard: the module's declared set is `nix.settings.extra-substituters` / `extra-trusted-public-keys` minus the attic entries (identified through `myconfig.attic.serverUrl` / `publicKey`). The CI side is parsed at test time from the `extra-substituters =` / `extra-trusted-public-keys =` lines of `.github/workflows/build.yml` (read from the flake source, so staged files only). Every occurrence in `build.yml` must equal the module's set exactly (both directions). `build-darwin.yml` deliberately carries only the caches that apply to aarch64-darwin, so it must be a non-empty subset of the module's set with every substituter paired with a key. `cache.nixos.org`, the host cachix and attic come from other modules and are not CI `extra-*` entries. No key or fingerprint literal appears in the test: values are compared with each other.

`extra-platforms` may contain `i686-linux` only when `boot.binfmt.emulatedSystems` is non-empty (the NixOS binfmt module adds it itself). The gpu-screen-recorder wrappers are checked with a noctalia and a caelestia twin (the shell, its Hyprland option and the Hyprland module forced on), because the shells own the recorder. The PasswordAuthentication value and Hyprland/kwin_wayland empty-capability wrappers are deliberately out of scope (the latter are covered elsewhere).

## Checks

### Both hosts
| Check | Expected |
|-------|----------|
| trust | `nix.settings.trusted-users` contains `@wheel` once, `root` once, nothing else |
| platforms | `extra-platforms` has no duplicates and equals `binfmt.emulatedSystems` (plus binfmt's own `i686-linux`); laptop with no emulation has none |
| cache | no substituter or key mentions niri, no duplicates, every substituter has a key with the matching prefix (cachix host, cache.nixos.org, attic cache name) |
| drift: build.yml | each `extra-substituters` / `extra-trusted-public-keys` line equals the module's set; at least one such line exists |
| drift: build-darwin.yml | non-empty subset of the module's set, substituters paired with keys |
| polkit | RealtimeKit high-priority and real-time clauses present; no `action.lookup(` (except the exact `action.lookup("unit")` and `action.lookup("verb")` of the laptop's pinned haptics-rebind rule), `gpu-screen-recorder`, `gsr-kms-server` or `org.freedesktop.policykit.exec` in the rules |
| wrappers, shells off | no `gpu-screen-recorder` and no `gsr-kms-server` in `security.wrappers` |
| wrappers, noctalia on / caelestia on | `gsr-kms-server` wrapped with `cap_sys_admin+ep`, `gpu-screen-recorder` main binary not wrapped |
| ssh | `services.openssh.enable`, `openFirewall` false, 22 not in `allowedTCPPorts` or any range, `tailscale0` in `trustedInterfaces` |
| crashdump | `boot.crashDump.enable`, `reservedMemory == "512M"`, `crashkernel=512M` in `kernelParams` |

### Controls (twins that must be flagged)
| Control | Expected |
|---------|----------|
| trust | duplicate `root` flagged; extra trusted user flagged |
| platforms | stray `riscv64-linux` flagged; duplicate platform flagged |
| cache | niri substituter and key flagged; substituter without key flagged |
| drift | substituter swapped in CI text flagged; key swapped flagged; text without the lines flagged; darwin CI with a foreign substituter flagged |
| polkit | gpu-screen-recorder substring rule flagged; `action.lookup("program")` flagged even next to the allowed unit/verb lookups; the unit/verb lookups alone not flagged; missing RealtimeKit clause flagged |
| wrappers | a recorder-enabled twin fails the shells-off check; an extra main-binary wrapper fails the shells-on check; the shells-off config fails the shells-on check |
| ssh | `openFirewall`, port 22 open, untrusted `tailscale0`, sshd disabled, each flagged |
| crashdump | disabled crashDump flagged; 128M reservation flagged |
