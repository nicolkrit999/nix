# test-nix-cache-settings

Guards the binary-cache wiring (substituter/key pairing, attic netrc, cachix priority), the rebuild-alias push gating, the push tokens staying off process argv, the nix-sweep TOML and binary install, and the nh/GC settings on the real hosts and the standalone `homeConfigurations`.

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

`01-scenario-nix-cache-settings.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and exposes one `check-*` attr per check, each `"ok"` or `"FAIL: ..."`. The runner evaluates the whole attrset once (`builtins.toJSON`), prints a PASS/FAIL line per check and exits 1 on any failure. Eval only, no builds, about 20 s.

Hosts: `nixos-desktop`, `nixos-laptop`, `Krits-MacBook-Pro` (darwin), plus every `homeConfigurations.*` for the nix-sweep install checks (empty on Darwin, where those checks report `ok`). Nothing secret is hardcoded: keys, URLs and hosts are read from the config and compared against each other. TOML is parsed with `builtins.fromTOML`. Controls use `extendModules` to prove each check can fail. Push gating compares the `sw`/`upd` alias text (presence of `attic push ` / `cachix push `) and the `attic-push`/`cachix-push` aliases against each cache's `enable && push`; the push controls force each combination on the desktop so both directions of the gate are exercised regardless of what the hosts set. Token-on-argv: no alias may contain `attic login` or `env CACHIX_AUTH_TOKEN=`; with cachix push and an `authTokenPath`, every `cachix push ` must be preceded by `CACHIX_AUTH_TOKEN="$(cat <authTokenPath>)"` (a shell assignment prefix, never an argument); the HM `attic/config.toml` exists iff attic `enable && push` and its `servers.nas-push` holds only `endpoint` (= `serverUrl`) and `token-file` (= `authTokenPath`), read from the `pkgs.formats.toml` derivation's `value` attr without building it. nix-sweep is matched by `lib.getName`. A `fromTOML` error is not catchable by `tryEval`, so the TOML control uses a quoted `gcn` (parses fine, wrong type).

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
| push-alias-gating | `sw` and `upd` contain the attic/cachix push command iff that cache's `enable && push`; `attic-push`/`cachix-push` aliases exist iff the same |
| push-token-off-argv | no alias has `attic login` or `env CACHIX_AUTH_TOKEN=`; each `cachix push ` has the `CACHIX_AUTH_TOKEN="$(cat <authTokenPath>)"` prefix; `attic/config.toml` present iff attic `enable && push`, `nas-push` = only `endpoint` + `token-file` matching the options |
| nix-sweep-installed | if HM generates `nix-sweep/presets.toml`, `nix-sweep` is in `environment.systemPackages` or HM `home.packages` |

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

### Standalone homeConfigurations

| Check | Expected |
|-------|----------|
| homes-nix-sweep-installed | every home config that generates `nix-sweep/presets.toml` has `nix-sweep` in `home.packages` |
| homes-presets-nonempty | presets exist on at least one system host and (where `nixosConfigurations` exist) at least one home config, so the install checks do not run over nothing |

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
| push-both-on | attic and cachix `enable = push = true`: gating and token-off-argv hold, both push aliases exist |
| push-attic-off | attic `push = false`: gating and token-off-argv hold (no `attic/config.toml`), `sw` has no attic push |
| push-cachix-off | cachix `push = false`: gating and token-off-argv hold, `upd` has no cachix push |
| push-cachix-disabled-push-true | cachix `enable = false, push = true`: gating and token-off-argv hold, no `cachix-push` alias |
| push-both-off | both `push = false`: gating and token-off-argv hold, `sw` equals `sw` with both caches disabled |
| token-argv-detected | mutant aliases (`attic login ...`, `env CACHIX_AUTH_TOKEN=...`, bare `cachix push`) are each reported by push-token-off-argv |
| attic-config-token-detected | a mutant `attic/config.toml` with an inline `token` and no `token-file` is reported (extra key, token-file mismatch) |
| nix-sweep-missing-detected | dropping `nix-sweep` from desktop `environment.systemPackages` makes nix-sweep-installed report a problem |
| home-nix-sweep-missing-detected | dropping `nix-sweep` from a home config's `home.packages` makes homes-nix-sweep-installed report a problem |
