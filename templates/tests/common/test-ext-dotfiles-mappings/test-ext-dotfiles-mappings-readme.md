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

The package tables (`packageLeaves`, `packagesPerHost`, `extraMappingsPerHost`, `syncBack`) are `let`-bound inside the modules. `01-scenario-ext-dotfiles-mappings.nix` extracts that `let` body from the real source files at eval time and re-evaluates it with the flake's nixpkgs `lib` in scope (the module's own `lib` argument), so no data is duplicated in the test. Each check returns `"ok"` or `"FAIL: ..."` and compares the parsed tables against the real `home.file` / `home.activation` of desktop, laptop (NixOS), `krit@Nicol-NAS` (home-only) and Krits-MacBook-Pro (Darwin). No secrets are involved.

`check-common-ext-dotfiles-mappings.sh` runs `nix eval --raw --impure` per check, then dumps each host's generated activation script, runs `bash -n` on it, and executes the real desktop script in a temporary fake home (the home prefix is substituted and a `run() { "$@"; }` prelude stands in for the home-manager `run` helper; the script uses absolute store paths, so no `PATH` handling is needed). Before the sandbox runs, every derivation in the desktop script's string context is realised with `nix build --no-link <drv>^<outputs>`: the eval only instantiates `pkgs.rsync`, and a CI runner whose restored store snapshot lacks it would otherwise run the script against a missing binary. A guard then checks that every `/nix/store/...` path in the script text exists; if one is missing it fails and the sandbox cases are skipped, so they cannot pass vacuously. The prelude's `run` also logs each wrapped command's exit code, and the cases that depend on `rsync` or `cp` assert that the real binary ran and exited with the expected code. Eval plus seconds, about 1 min. Read-only failure cases are skipped when run as root.

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

### start-actual-mcp launcher (desktop, laptop, mac)
The bare command `start-actual-mcp` is used by the project-scoped MCP server in `~/momentary/.mcp.json`, so it must resolve from `PATH` wherever it is linked. The effective `PATH` dirs come from the real config: on NixOS `environment.localBinInPath` (`$HOME/.local/bin`, `modules/nixos/toplevel/env.nix`) plus the home-manager `home.sessionPath`; on Darwin `home.sessionPath` (`modules/darwin/toplevel/home-darwin.nix`). The private repo is not read (not available in CI): only the mapping source string is compared.

| Check | Expected |
|-------|----------|
| launcher mapping | exactly one mapping has source `claude/common/binaries/start-actual-mcp`, and its key ends in `start-actual-mcp` |
| launcher on PATH | the home-relative directory of that key is one of the host's effective `PATH` dirs |
| control: bin/ twin | the same mappings with the key moved to `bin/start-actual-mcp` are flagged |
| control: PATH lacks dir | the real mappings against an empty `PATH` are flagged |
| control: wrong source | a twin with another source string is flagged by the mapping check |

### Claude home.file removals and activation links (desktop, laptop, nas, mac)
`.claude/projects`, `.claude/plans` and `.claude/settings.json` are no longer `home.file` mappings; two activation steps replace them. Expected encodings are computed in the scenario by an independent `/` and `.` to `-` replacement (not the module's own function), so a regression in the module's encoder is caught.

| Check | Expected |
|-------|----------|
| no claude home.file | `home.file` contains none of `.claude/projects`, `.claude/plans`, `.claude/settings.json` |
| memory script | `linkClaudeProjectMemory` has a `link_memory <encoded cwd> <repo name>` line for every shared project (`-home-krit-nix` on NixOS/NAS, `-Users-krit-nix` on mac, plus `-mnt-nicol-nas-webdav-owncloud-University` on non-Darwin only), no line with another platform's prefix, and `repo_root` / `dir` under the host's home |
| settings script | `linkClaudeSettings` has `src="<home>/dotfiles-private/claude/common/.claude/settings.json"`, `dst="<home>/.claude/settings.json"`, `ln -sfn "$src" "$dst"`, and neither path goes through `/nix/store` |
| activation order | both steps are ordered after `linkGeneration` |
| control: projects / settings mapping | a `home.file` twin with `.claude/projects` or `.claude/settings.json` added is flagged |
| control: wrong platform name | the mac script with `-Users-krit-nix` replaced by `-home-krit-nix` is flagged |
| control: missing NAS project | the desktop script with the NAS encoded name altered is flagged |
| control: NAS project on mac | the mac script with an extra `-mnt-nicol-nas-...` line is flagged |
| control: store dst | the desktop settings script with `dst` pointing into `/nix/store` is flagged |
| control: wrong src | the laptop settings script with `src` pointing at `mac/` is flagged |

### Controls
| Check | Expected |
|-------|----------|
| overlap detector | flags a synthetic shared leaf, quiet on disjoint |
| hostname typo | a misspelled hostname makes the host check fail |

### Generated activation script
| Check | Expected |
|-------|----------|
| `bash -n` | passes for all four hosts |
| function parity | `sync_back` body identical on desktop and mac after the permanent per-arch normalisation (see below): home paths unified and `/nix/store/<hash>-<pkg>/bin/` prefixes stripped, nothing else (no `run`, `--delete` or comment exemptions) |
| desktop absolute paths | the desktop function contains an absolute `/nix/store/<hash>-rsync*/bin/rsync -a --delete` call and the script has no `export PATH` |
| mac absolute paths | the same for the mac script (it cannot be realised on Linux, so this is checked on the text) |
| mac store-path commands | the ordered list of `<pkg>-<version>/bin/<cmd>` store-path commands in the mac function equals the desktop's and contains `rsync`, so the prefix strip cannot hide a bare command |
| control: bare rsync | a mac function with the rsync store prefix removed still passes the stripped parity comparison (proof that the strip hides it) but is rejected by the store-path-commands guard |
| control: bare rm -rf | a mac function with one `rm -rf` store prefix removed is rejected by the guard |
| sandbox: store paths realised | every store path the desktop script references exists after realising its context, and one of them is rsync; otherwise FAIL and the sandbox cases below are skipped |
| sandbox: file differs | copied into repo, live removed |
| sandbox: file identical | live removed, repo untouched |
| sandbox: symlink | left alone |
| sandbox: repo parent missing | live file kept |
| sandbox: dir differs | rsynced with `--delete` before the live dir is removed: live-only files copied in, repo-only files removed; rsync ran and exited 0 |
| sandbox: repo dir missing | live dir kept |
| sandbox: copy fails (read-only repo) | live file kept; `cp` ran and exited 1 |
| sandbox: rsync fails (unreadable live file) | live dir kept, nothing copied into the repo; rsync ran and exited 23 (a missing binary gives 127 and fails) (skipped as root) |
| sandbox: live file replaces non-empty repo dir (type clash) | `--delete` mirrors it: repo path becomes the file, repo-inner files gone, live dir removed; rsync ran and exited 0 |

### Per-arch store-path normalisation (permanent)

The desktop and mac activation scripts are the same text except for the home directory and the store hashes, because the darwin packages (`coreutils`, `diffutils`, `rsync`) have other hashes than the x86_64-linux ones. Before comparing the two `sync_back` bodies the test therefore unifies `/home/krit` and `/Users/krit` and strips `/nix/store/<hash>-<pkg>/bin/`. That strip alone would let a bare command (resolved through `PATH` at activation time) pass, which is what the "mac store-path commands" guard and its two controls exclude: the list of store-path commands must be identical, so a prefix cannot silently disappear.
