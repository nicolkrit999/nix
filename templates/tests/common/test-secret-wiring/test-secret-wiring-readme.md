# test-secret-wiring

Evaluates the real nixos-desktop, nixos-laptop, Krits-MacBook-Pro and krit@Nicol-NAS configs and checks that every sops secret name, path, owner and consumer lines up.

## Run

From the repo root:

```bash
bash templates/tests/common/test-secret-wiring/check-common-secret-wiring.sh
```

From inside the directory:

```bash
bash check-common-secret-wiring.sh
```

## How it works

`01-scenario-secret-wiring.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and exposes one `check-*` attr per check, evaluating to `"ok"` or `"FAIL: ..."`. The script runs `nix eval --raw --impure` per attr and prints PASS/FAIL, exiting 1 on any failure. Eval only, no builds. NixOS hosts are skipped when the flake hides `nixosConfigurations` (Darwin IFD guard).

No secret values are read: the sops yamls are only scanned for top-level key names (values are encrypted anyway). Expected paths are derived independently (`/run/secrets/<name>`, `/home|/Users/<user>/.ssh/...`) from what the modules declare.

Note: on integrated hosts (NixOS/Darwin) the `claude` MCP wrapper is installed only for `moduleSystem == "home"` (claude-code.nix). Nothing in the repo exports the MCP env vars there; external dotfiles (e.g. `start-actual-mcp`) read `/run/secrets/<name>` directly, so the contract asserted for those hosts is "secret declared, owned by the user, at `/run/secrets/<name>`". The wrapper is asserted only on the NAS home build.

## Checks

| Check | Expected |
|-------|----------|
| mcp-envvars-unique | `mcpSecrets` envVar values non-empty and unique on all hosts and the NAS |
| mcp-secrets-declared | every `mcpSecrets[].sopsSecret` is in `sops.secrets` with owner = user, path `/run/secrets/<name>`, common sops file (catches Darwin's static list drifting from the default list) |
| mcp-secrets-in-yaml | each such key exists in the common yaml |
| mcp-nas-home-wrapper | NAS: `claude` wrapper in `home.packages`, every secret in HM `sops.secrets`, wrapper exports each envVar from the secret path |
| cache-token-secrets | cachix/attic `authTokenPath` basename is a declared secret at that path and in its yaml; attic key starts with `<cacheName>:`; cachix key with `<name>.cachix.org-`; `netrc-file` is the `attic-netrc` template embedding the attic placeholder |
| attic-assertion-bites | control: pointing the token at an undeclared secret makes the attic assertion fail |
| github-pat-include | `nix.extraOptions` `!include`s the declared PAT secret path; key in yaml |
| github-pat-mode-consistent | PAT secret mode equal across NixOS and Darwin hosts |
| yaml-key-lookup-bites | control: key scanner finds a known key, rejects a bogus one |
| sopsfiles-and-keys | every declared secret's sopsFile exists and contains its key |
| davfs-secrets-template | NixOS hosts: template `root`, `0600`, both opencloud placeholders |
| nas-wiring-nixos | sshfs/smb/borg/opencloud/tailscale paths equal declared secret or template paths |
| nas-secrets-darwin | each enabled Darwin NAS module has its secrets declared (fails if no module enabled) |
| thunderbird-forced | thunderbird forced on every host: template path per platform, owner user, secret owners/sopsFile/yaml keys, at most one primary |
| ssh-key-paths | github/school ssh key + pub secrets under `<home>/.ssh/id_*` per platform |
