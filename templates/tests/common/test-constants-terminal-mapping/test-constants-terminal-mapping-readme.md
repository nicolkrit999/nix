# test-constants-terminal-mapping

`constants.terminal.name` is a plain string that other modules turn into a package (`pkgs.<name>`), an executable (`<pkg>/bin/<name>`, e.g. neovim.nix and yazi.nix) and a `krit.programs.<name>` module. This test checks that every terminal the repo knows about resolves through that chain on both platforms. There are no separate exec or class constants to derive: if they are ever added to `constants.nix`, extend this test.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only common-constants-terminal-mapping` (name as shown by `--list`); the direct command is below.

From the repo root:

```bash
bash templates/tests/common/test-constants-terminal-mapping/check-common-constants-terminal-mapping.sh
```

Or from inside the directory:

```bash
bash check-common-constants-terminal-mapping.sh
```

Needs `nix`, `jq`, `bash`. Eval-only; no builds.

## How it works

`01-scenario-constants-terminal-mapping.nix` collects terminal names from the constants option default, the module stems in `users/krit/common/programs/terminal-emulators/` (read at test time) and the values on `nixos-desktop`, `nixos-laptop` and `Krits-MacBook-Pro`. For each it checks, on `x86_64-linux` and `aarch64-darwin`, that the nixpkgs attribute exists, is available there and has `meta.mainProgram` (or `pname`) equal to the name. It does not duplicate the `terminal.name` check of `test-darwin-host-contract`, which pins the Darwin host value.

## Checks

| Check | Expected |
|-------|----------|
| constants default / each terminal module / each host value: nixpkgs attr with `/bin/<name>` exe, on both platforms | resolves |
| module `<stem>`: `myconfig.krit.programs.<stem>` option on NixOS and Darwin | exists |
| terminal modules discovered | at least one |
| constants default is one of the terminal modules | yes |
| control: unknown terminal name | does not resolve |
| control: attr whose exe differs from its name (`ripgrep`) | does not resolve |
