# Test discovery and test.conf

Source of truth: `templates/tests/lib/discover.py` (docstring lists everything).

## Discovery rules

- Every directory directly under `templates/tests/{nixos,common,darwin}/` is one test.
- Entry points are found by pattern inside the folder:
  - `check-*.sh` anywhere -> `bash <script>` (sorted by path)
  - `*_test.nix` anywhere -> the nix-tests harness, run once on the folder
  - a folder may have both; commands run in order inside ONE test with ONE log
- A folder matching neither pattern, or any other non-hidden directory under
  `templates/tests/` (except `lib/`), makes discovery FAIL loudly. Do not leave
  stray folders there.
- Test name = category + folder name without the `test-` prefix, e.g.
  `nixos/test-arch-compat` -> `nixos-arch-compat`, `nixos/conflicting-modules` ->
  `nixos-conflicting-modules`. `run-tests.sh --only` also accepts the folder name
  or an unambiguous suffix (`--only arch-compat`).
- There is no registry. `run-tests.sh`, `run-test.py`, `test-report.py`, the
  invariant checker and the CI `discover` job all call `discover.py`.

## test.conf (optional, per folder)

`key = value` lines, `#` comments. Unknown keys are an error.

| Key | Meaning | Default |
|-----|---------|---------|
| `group` | CI matrix leg (slug `[a-z0-9-]+`) | `harness` if the folder has `*_test.nix`, else the category |
| `timeout` | per-test cap in minutes (enforced by `.github/scripts/run-test.py`) | 10 |
| `platforms` | `linux`, `darwin` or `linux,darwin` (linux = tests-nixos.yml, darwin = tests-darwin.yml) | `darwin` for `darwin/`, else `linux` |
| `ci` | `true`/`false`; false = local `run-tests.sh` only | `true` |
| `fast_args` | extra args passed to `check-*.sh` under `run-tests.sh --fast` | empty |

Example: `nixos/test-arch-compat/test.conf` uses `group = heavy-a`, `timeout = 30`,
`fast_args = --fast` (QEMU-backed aarch64 dry builds, the longest test). Give a
slow test its own group so a cold run cannot starve cheap tests. A CI leg's step
timeout is derived from its group (sum of caps plus overhead), so only raise
`timeout` when the test genuinely needs it.

## Useful commands

```bash
bash templates/tests/run-tests.sh --list                 # name, group, timeout, platforms, kind, folder
python3 -B templates/tests/lib/discover.py --json --ci   # machine-readable
bash templates/tests/run-tests.sh --only <name>[,<name>] # one or few tests
bash templates/tests/run-tests.sh --parallel [--fast]    # whole suite
```

Locally all platforms run (darwin tests are pure evals and work on Linux).
Darwin-folder tests default to the darwin CI leg.
