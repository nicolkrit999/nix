# test-ext-dotfiles-mappings

Integrity of the `ext-dotfiles-private` mappings (NixOS and Darwin modules) and safety of the generated `sync_back` activation script, which `rm -rf`s live GUI-written files after copying them into the repo.

## Run

```bash
bash templates/tests/common/test-ext-dotfiles-mappings/check-common-ext-dotfiles-mappings.sh
```

Or from inside the directory:

```bash
bash check-common-ext-dotfiles-mappings.sh
```

## How it works

The package tables (`packageLeaves`, `packagesPerHost`, `extraMappingsPerHost`, `syncBack`) are `let`-bound inside the modules. `01-scenario-ext-dotfiles-mappings.nix` extracts that `let` body from the real source files at eval time and re-evaluates it, so no data is duplicated in the test. Each check returns `"ok"` or `"FAIL: ..."` and compares the parsed tables against the real `home.file` / `home.activation` of desktop, laptop (NixOS), `krit@Nicol-NAS` (home-only) and Krits-MacBook-Pro (Darwin). No secrets are involved.

`check-common-ext-dotfiles-mappings.sh` runs `nix eval --raw --impure` per check, then dumps each host's generated activation script, runs `bash -n` on it, and executes the real desktop script in a temporary fake home (the home prefix is substituted, the `export PATH` line dropped). Eval plus seconds, about 1 min. Read-only failure cases are skipped when run as root.

## Checks

### Per host (desktop, laptop, nas, mac)
| Check | Expected |
|-------|----------|
| leaves unique | no leaf appears in two enabled packages (the `//` fold would silently drop one) |
| extra disjoint | `extraMappings` keys are not package leaves |
| hostname known | `constants.hostname` has a `packagesPerHost` entry (no silent `or []`) |
| packages exist | every enabled package is in `packageLeaves` |
| links | every mapping is a `home.file` entry, `force`, pointing at `<home>/dotfiles-private/<rel>` |
| syncback calls | the activation `sync_back` lines equal `syncBack` filtered by mappings |

### Cross-host
| Check | Expected |
|-------|----------|
| syncBack non-empty | desktop, laptop, mac each have an active syncBack entry |
| syncBack known | each `syncBack` path is a leaf of some package |
| host keys real | `packagesPerHost` / `extraMappingsPerHost` keys are real hostnames |
| no unused package | every package is used by at least one host |
| school-workspace | NixOS `.school-workspace/`, Darwin `school-workspace/`, NAS none |

### Controls
| Check | Expected |
|-------|----------|
| overlap detector | flags a synthetic shared leaf, quiet on disjoint |
| hostname typo | a misspelled hostname makes the host check fail |

### Generated activation script
| Check | Expected |
|-------|----------|
| `bash -n` | passes for all four hosts |
| function parity | `sync_back` body identical on desktop and mac |
| sandbox: file differs | copied into repo, live removed |
| sandbox: file identical | live removed, repo untouched |
| sandbox: symlink | left alone |
| sandbox: repo parent missing | live file kept |
| sandbox: dir differs | rsynced before delete, repo-only files kept |
| sandbox: repo dir missing | live dir kept |
| sandbox: copy fails (read-only repo) | live file kept |
| sandbox: rsync fails (file vs non-empty dir) | live dir kept |
