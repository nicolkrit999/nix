# test-nix-cache-settings

Guards the binary-cache wiring (substituter/key pairing, attic netrc, cachix priority), the nix-sweep TOML and the nh/GC settings on the real hosts.

## Run

From the repo root:

```bash
bash templates/tests/common/test-nix-cache-settings/check-common-nix-cache-settings.sh
```

From inside the directory:

```bash
bash check-common-nix-cache-settings.sh
```

## How it works

`01-scenario-nix-cache-settings.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and exposes one `check-*` attr per check, each `"ok"` or `"FAIL: ..."`. The runner evaluates the whole attrset once (`builtins.toJSON`), prints a PASS/FAIL line per check and exits 1 on any failure. Eval only, no builds, about 15 s.

Hosts: `nixos-desktop`, `nixos-laptop`, `Krits-MacBook-Pro` (darwin). Nothing secret is hardcoded: keys, URLs and hosts are read from the config and compared against each other. TOML is parsed with `builtins.fromTOML`. Controls use `extendModules` to prove each check can fail. A `fromTOML` error is not catchable by `tryEval`, so the TOML control uses a quoted `gcn` (parses fine, wrong type).

## Checks

### Per host (desktop, laptop, darwin)

| Check | Expected |
|-------|----------|
| substituter-key-pairing | every substituter (`substituters` + `extra-substituters`) has a trusted key: `*.cachix.org`/`cache.nixos.org` -> `<host>-1:`; attic -> `<cacheName>:` |
| substituter-nonempty | at least 2 substituters (pairing check is not vacuous) |
| no-connect-timeout | no substituter URL contains `connect-timeout` |
| attic-priority | exactly one attic substituter, `?priority=10` |
| attic-key-prefix | attic `publicKey` starts with `<cacheName>:` |
| attic-netrc-host | `attic-netrc` has `machine nicol-nas.tail9b9ae8.ts.net password` (port stripped) |
| attic-netrc-file-set | `nix.settings.netrc-file` == the sops template path |
| nix-sweeps-toml | `keep-min` is an int equal to `gcn`; `remove-older` == `gcd`; default non-interactive, ask interactive |

### NixOS hosts only

| Check | Expected |
|-------|----------|
| cachix-pairing-and-priority | `https://<name>.cachix.org?priority=20` in `substituters`, `publicKey` trusted and prefixed `<name>.cachix.org-1:` |
| nh-flake | `programs.nh.flake == /home/krit/nix` |
| gc-exclusive-with-nh-clean | `nix.gc.automatic == false` while `programs.nh.clean.enable == true` |

### Darwin only

| Check | Expected |
|-------|----------|
| nh-flake | HM `programs.nh.flake == /Users/krit/nix` |
| nh-clean | HM `programs.nh.clean.enable == true` |

### Controls (desktop via `extendModules`)

| Check | Expected |
|-------|----------|
| wrong-key-detected | mismatched cachix/attic keys make the pairing check report problems |
| attic-netrc-port-stripped | `https://attic.example:8443` -> `machine attic.example`, no `8443` |
| attic-netrc-path-stripped | `https://attic.example/sub/path` -> `machine attic.example` |
| attic-empty-url-asserts | empty `serverUrl` fires the serverUrl/cacheName/publicKey assertion |
| attic-missing-secret-asserts | `authTokenPath` without a matching sops secret fires the second assertion |
| real-hosts-no-failed-attic-assertions | no attic assertion fails on real hosts |
| sweeps-gcn-tracks-option | `gcn = "7"` gives int `keep-min = 7` |
| sweeps-quoted-gcn-not-int | a quoted `gcn` yields a non-int, proving the int check bites |
