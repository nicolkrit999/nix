# test-npu-npm-parsing

Table tests for two pieces of string parsing in `modules/common/programs/shells/`: the `npu` helper (`npu.py`: forge links to raw/archive URLs, `--name` sanitising for `nix-prefetch-url`) and the `npm.nix` activation script that maps `@scope/pkg@ver` / `name@ver` entries of `myconfig.programs.npm.packages` to their `node_modules` directory names to decide whether to reinstall.

Why: both are hand-written regex / shell parameter-expansion code with no other coverage. A wrong archive URL prefetches the wrong hash; an unsanitised `--name` makes `nix-prefetch-url` reject the store name; a wrong npm name means either a reinstall on every activation or a package that is never reinstalled after it was removed.

## Run

From the repo root:

```bash
bash templates/tests/run-tests.sh --only common-npu-npm-parsing
# or directly
bash templates/tests/common/test-npu-npm-parsing/check-common-npu-npm.sh
```

From inside the directory:

```bash
bash check-common-npu-npm.sh
```

## How it works

`02-npu-table.py` runs under `python3 -I`, stubs the `requests` module (any HTTP call raises `RequestException`, so nothing touches the network), sets `NIX_PREFETCH_URL` to a dummy before import (npu.py reads it at import time), then calls `npu.main()` per URL with `subprocess.run` replaced by a recorder and compares the exact `nix-prefetch-url` argv. It also tables `safe_store_name` directly and checks that the env var npu.py reads is the one `shell-aliases.nix` exports. It prints one `PASS`/`FAIL` line per row; a crash at import is reported as its own failing row.

`01-scenario-npm-activation.nix` builds `template-host-minimal.extendModules` with `programs.npm` enabled and the fixture packages `@scope/pkg@1.2.3 plain-name@4.5.6 bare @scope/other`, and returns the evaluated `npmGlobalPackages` activation text (plus whether an empty package list still adds the entry). `check-common-npu-npm.sh` evaluates it once, runs the extracted `case` block for the name table, then sources the whole activation text in a temp `HOME` with `run` stubbed to a logger (nothing is installed, no store path is executed) across several on-disk states. Runtime about 15 s warm. On Darwin (no `nixosConfigurations`) the npm part is skipped.

## Checks

### npu.py (`python3 -I`, no network)

| Check | Expected |
|-------|----------|
| npu github-blob-to-raw | `github.com/o/r/blob/main/dir/a.png` -> `raw.githubusercontent.com/o/r/main/dir/a.png`, no `--unpack` |
| npu github-commit-to-archive | `/commit/<sha>` -> `--unpack .../archive/<sha>.tar.gz` |
| npu github-tag-to-archive | `/releases/tag/<t>` -> `--unpack .../archive/refs/tags/<t>.tar.gz` |
| npu github-tree-to-archive | `/tree/<b>` -> `--unpack .../archive/refs/heads/<b>.tar.gz` |
| npu gitlab-blob-to-raw | `/-/blob/` -> `/-/raw/` |
| npu forgejo-src-to-raw | `/src/branch/` -> `/raw/branch/` |
| npu plain-media-unchanged | media URL passed through, no `--name` |
| npu page-unchanged-when-offline | page URL unchanged when the Open Graph fetch fails |
| npu encoded-name-sanitised | `My%20File%20(1).png` -> `--name My_File__1_.png` |
| npu encoded-non-ascii-sanitised | `%C3%A9t%C3%A9.jpg` -> `--name _t_.jpg` |
| npu encoded-blob-raw-name | encoded GitHub blob: raw URL plus sanitised `--name` |
| safe_store_name 'a b/c' | `a_b_c` |
| safe_store_name 'keep+._?=-AZaz09' | unchanged |
| safe_store_name 'x;rm -rf $(y)' | `x_rm_-rf___y_` |
| safe_store_name output charset | every result matches `[A-Za-z0-9+._?=-]+` |
| npu env var exported by shell-aliases.nix | npu.py reads only `NIX_PREFETCH_URL`; `shell-aliases.nix` exports it and runs `${./npu.py}` |

### npm.nix activation (eval)

| Check | Expected |
|-------|----------|
| npm packages = [] adds no activation entry | no `npmGlobalPackages` entry |
| activation loops over the configured packages | `for pkg in <all four>; do` |
| case block parses @scope/pkg@ver and name@ver | names `@scope/pkg plain-name bare @scope/other` |
| fresh home: installs every package once, writes stamp | one `npm install -g <all four>`, stamp file written |
| stamp current + parsed module dirs present: no install | no `run` call |
| scoped module dir missing: reinstalls | one install |
| dirs named with @version only: reinstalls | one install (unparsed names do not count) |
| stale stamp with dirs present: reinstalls | one install |
