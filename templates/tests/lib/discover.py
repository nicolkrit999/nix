#!/usr/bin/env python3
"""Auto-discovery of the templates/tests suite - the ONLY test registry.

There is no hand-maintained list. Every directory directly under
templates/tests/{nixos,common,darwin}/ is one test, and its entry points are
found by pattern:

  check-*.sh anywhere in the folder   -> `bash <script>` (sorted by path)
  *_test.nix anywhere in the folder   -> the nix-tests harness, run once on the folder

A folder may have both (test-nixos-wallpapers: nix-tests files plus the bash
companion asserts/check-nixos-wallpapers-asserts.sh); its commands then run in
order inside ONE test with ONE log. A folder matching NEITHER pattern is an
error, and so is any other non-hidden directory under templates/tests/ (except
lib/): discovery fails loudly instead of silently not running something.

Optional per-folder `test.conf` (key=value lines, `#` comments):

  group     = CI matrix leg            default: harness if the folder has *_test.nix,
                                                else the category (nixos|common|darwin)
  timeout   = per-test cap in minutes  default: 10 (enforced by .github/scripts/run-test.py)
  platforms = linux | darwin | linux,darwin
                                       default: darwin for darwin/, linux otherwise
                                       (linux = tests-nixos.yml, darwin = tests-darwin.yml)
  ci        = true | false             default: true (false = local run-tests.sh only)
  fast_args = extra args for check-*.sh when run-tests.sh --fast is given

Unknown keys are an error (a typo must not silently fall back to a default).

Used by: templates/tests/run-tests.sh, .github/scripts/run-test.py,
.github/scripts/test-report.py, .github/scripts/check-workflow-invariants.py and
the `discover` job of tests-nixos.yml / tests-darwin.yml (dynamic matrix).

CLI:
  discover.py --list [--platform P] [--ci]       human-readable table
  discover.py --json [--platform P] [--ci]       machine-readable list
  discover.py --matrix --platform P              JSON list of CI groups (P = linux|darwin)
              [--github-output]                  ...also written as `groups=` to $GITHUB_OUTPUT,
                                                 plus `step_timeouts=` ({group: minutes},
                                                 see step_budget) for the test step's timeout
  discover.py --tests-root DIR ...               discover a different tree (mutation tests)
Exit: 0 ok, 2 discovery error (every problem is printed, not just the first).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
TESTS_ROOT = REPO_ROOT / "templates" / "tests"
CATEGORIES = ("nixos", "common", "darwin")
# Directories under templates/tests/ that are not test categories.
NON_TEST_DIRS = {"lib"}

# The nix-tests harness is an external flake whose own nixpkgs pin is older than
# the nixpkgs fix for crates.io's User-Agent block (crates.io returns HTTP 403 on
# the URL older `importCargoLock` used). Forcing it onto OUR locked nixpkgs is what
# lets the harness build at all. Run from the repo root.
#
# PINNED to one exact commit: this constant is the ONLY place the harness is
# invoked (run-tests.sh, run-test.py and both test workflows all get their
# commands from discovery), so an upstream push can no longer change or break
# every test run overnight. The `harness-pinned` invariant in
# .github/scripts/check-workflow-invariants.py fails if this stops being a full
# 40-hex rev or if anything under .github/ or templates/tests/ calls the harness
# some other way.
#
# How to bump: pick the new commit (`git ls-remote <repo> HEAD`), read its
# changes, put the 40-hex sha in NIX_TESTS_REV, then run
#   bash templates/tests/run-tests.sh --only conflicting-modules,custom-shells,mango-option-names,nixos-wallpapers
# (every harness test) before committing. Keep `--inputs-from . --override-input
# nixpkgs nixpkgs` (see above).
#
# The GitHub repo was archived on 2026-06-20 with "Moved to codeberg"
# (https://codeberg.org/danielefongo/nix-tests). 866429d2 is its last commit and
# only edits README.md; the code is that of 5f79ae12 (2026-01-28, "support
# process interruption"), i.e. exactly what the unpinned runs used. A bump to a
# newer release means switching the URL to the codeberg repo
# (git+https://codeberg.org/danielefongo/nix-tests?rev=<sha>) - check that the
# `nix run` attribute and CLI are unchanged when doing so.
NIX_TESTS_REPO = "github:danielefongo/nix-tests"
NIX_TESTS_REV = "866429d23a6ebf6e03837434f18e4cace9c37bc5"
NIX_TESTS = f"nix run {NIX_TESTS_REPO}/{NIX_TESTS_REV} --inputs-from . --override-input nixpkgs nixpkgs --"

DEFAULT_TIMEOUT_MIN = 10
# A CI leg's test step gets a timeout DERIVED from its group (step_budget): the sum
# of the group's per-test caps, plus this much runner overhead per test (kill
# grace, evidence merge, the final redaction pass) and per leg (discovery,
# imports). The step cap therefore can never fire before every test has had its
# own full cap - which used to be possible (the `nixos` group's caps summed to
# 120 min under a fixed 50-min step cap): a step-cap kill SIGTERMs run-test.py
# and every later test of the leg shows as "never ran" (no-early-stop check).
STEP_OVERHEAD_PER_TEST_MIN = 1
STEP_OVERHEAD_PER_LEG_MIN = 2
PLATFORMS = ("linux", "darwin")
CONF_KEYS = {"group", "timeout", "platforms", "ci", "fast_args"}
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")


class DiscoveryError(Exception):
    def __init__(self, problems):
        super().__init__("\n".join(problems))
        self.problems = problems


def _is_hidden(p: Path, base: Path) -> bool:
    return any(part.startswith(".") for part in p.relative_to(base).parts)


def _files(folder: Path, pattern: str):
    return sorted(p for p in folder.rglob(pattern) if p.is_file() and not _is_hidden(p, folder))


def _parse_conf(path: Path, problems: list) -> dict:
    conf = {}
    for n, raw in enumerate(path.read_text().splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if "=" not in line:
            problems.append(f"{path}:{n}: expected key=value, got {raw!r}")
            continue
        k, v = (s.strip() for s in line.split("=", 1))
        if k not in CONF_KEYS:
            problems.append(f"{path}:{n}: unknown key {k!r} (allowed: {', '.join(sorted(CONF_KEYS))})")
            continue
        conf[k] = v
    return conf


def test_name(category: str, folder: str) -> str:
    """nixos/test-arch-compat -> nixos-arch-compat; darwin/test-darwin-home-paths ->
    darwin-home-paths; nixos/conflicting-modules -> nixos-conflicting-modules."""
    base = folder[len("test-"):] if folder.startswith("test-") else folder
    return base if base.startswith(category + "-") else f"{category}-{base}"


def discover(tests_root: Path | None = None) -> list[dict]:
    """Return every test, sorted by name. Raises DiscoveryError listing ALL problems."""
    root = Path(tests_root) if tests_root else TESTS_ROOT
    problems: list[str] = []
    tests: list[dict] = []
    # The paths a command uses are relative to the repo root that contains `root`.
    repo = root.parents[1] if root.name == "tests" and root.parent.name == "templates" else REPO_ROOT

    if not root.is_dir():
        raise DiscoveryError([f"tests root {root} does not exist"])
    for d in sorted(root.iterdir()):
        if d.is_dir() and not d.name.startswith(".") and d.name not in CATEGORIES and d.name not in NON_TEST_DIRS:
            problems.append(f"{d.relative_to(repo)}/: unknown directory under templates/tests/ - "
                            f"tests live in {{{','.join(CATEGORIES)}}}/<folder>/ (shared code in lib/)")

    for cat in CATEGORIES:
        cdir = root / cat
        if not cdir.is_dir():
            continue
        for folder in sorted(cdir.iterdir()):
            if not folder.is_dir() or folder.name.startswith("."):
                continue
            rel = folder.relative_to(repo).as_posix()
            scripts = _files(folder, "check-*.sh")
            nix_tests = _files(folder, "*_test.nix")
            if not scripts and not nix_tests:
                problems.append(f"{rel}/: matches no test pattern - it needs a check-*.sh or "
                                f"*_test.nix file (a test folder that runs nothing is a test that "
                                f"silently never runs)")
                continue
            conf_path = folder / "test.conf"
            conf = _parse_conf(conf_path, problems) if conf_path.is_file() else {}

            group = conf.get("group") or ("harness" if nix_tests else cat)
            if not SLUG.match(group):
                problems.append(f"{rel}/test.conf: group {group!r} is not slug-safe ([a-z0-9-]+)")
            try:
                timeout = int(conf.get("timeout", DEFAULT_TIMEOUT_MIN))
                if timeout <= 0:
                    raise ValueError
            except ValueError:
                problems.append(f"{rel}/test.conf: timeout {conf.get('timeout')!r} is not a positive integer (minutes)")
                timeout = DEFAULT_TIMEOUT_MIN
            plats = [p.strip() for p in conf.get("platforms", "darwin" if cat == "darwin" else "linux").split(",") if p.strip()]
            bad = [p for p in plats if p not in PLATFORMS]
            if bad or not plats:
                problems.append(f"{rel}/test.conf: platforms {conf.get('platforms')!r} - allowed: {', '.join(PLATFORMS)}")
            ci = conf.get("ci", "true").lower()
            if ci not in ("true", "false"):
                problems.append(f"{rel}/test.conf: ci must be true or false, got {ci!r}")

            commands = [f"bash {shlex.quote(s.relative_to(repo).as_posix())}" for s in scripts]
            if nix_tests:
                commands.append(f"{NIX_TESTS} {shlex.quote(rel)}")
            readmes = sorted(p.relative_to(repo).as_posix() for p in folder.glob("*-readme.md"))
            tests.append({
                "name": test_name(cat, folder.name),
                "category": cat,
                "folder": rel,
                "kind": "mixed" if scripts and nix_tests else ("bash" if scripts else "nix-tests"),
                "commands": commands,
                "scripts": [s.relative_to(repo).as_posix() for s in scripts],
                "group": group,
                "timeout_min": timeout,
                "platforms": plats,
                "ci": ci == "true",
                "fast_args": conf.get("fast_args", ""),
                "readme": readmes[0] if readmes else "",
            })

    seen: dict[str, str] = {}
    for t in tests:
        if not SLUG.match(t["name"]):
            problems.append(f"{t['folder']}/: derived test name {t['name']!r} is not slug-safe")
        if t["name"] in seen:
            problems.append(f"{t['folder']}/ and {seen[t['name']]}/ both derive the test name {t['name']!r}")
        seen[t["name"]] = t["folder"]
    if not tests:
        problems.append(f"no tests found under {root}")
    if problems:
        raise DiscoveryError(problems)
    return sorted(tests, key=lambda t: t["name"])


def select(tests, platform=None, ci_only=False, group=None, only=None):
    """Filter. `only` = comma list; each item matches a name, the folder basename,
    the folder path, or a unique name suffix (so `arch-compat` finds nixos-arch-compat)."""
    out = [t for t in tests
           if (platform in (None, "all") or platform in t["platforms"])
           and (not ci_only or t["ci"])
           and (group is None or t["group"] == group)]
    if not only:
        return out
    picked, problems = [], []
    for want in [w.strip().rstrip("/") for w in only.split(",") if w.strip()]:
        exact = [t for t in out if want in (t["name"], t["folder"], t["folder"].rsplit("/", 1)[-1])]
        hits = exact or [t for t in out if t["name"].endswith("-" + want)]
        if len(hits) == 1:
            if hits[0] not in picked:
                picked.append(hits[0])
        elif not hits:
            problems.append(f"--only {want!r}: no such test (see --list)")
        else:
            problems.append(f"--only {want!r} is ambiguous: {', '.join(t['name'] for t in hits)}")
    if problems:
        raise DiscoveryError(problems)
    return picked


def ci_groups(tests, platform):
    return sorted({t["group"] for t in select(tests, platform=platform, ci_only=True)})


def step_budget(tests, platform, group) -> int:
    """Minutes the CI test step of one leg may run: every per-test cap + overhead."""
    n = select(tests, platform, True, group)
    return sum(t["timeout_min"] for t in n) + STEP_OVERHEAD_PER_TEST_MIN * len(n) + STEP_OVERHEAD_PER_LEG_MIN


def step_budgets(tests, platform) -> dict:
    return {g: step_budget(tests, platform, g) for g in ci_groups(tests, platform)}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--json", action="store_true")
    mode.add_argument("--matrix", action="store_true")
    ap.add_argument("--platform", choices=("linux", "darwin", "all"), default="all")
    ap.add_argument("--ci", action="store_true", help="only tests with ci=true")
    ap.add_argument("--only")
    ap.add_argument("--github-output", action="store_true")
    ap.add_argument("--tests-root")
    a = ap.parse_args(argv)
    try:
        tests = discover(a.tests_root)
        if a.matrix:
            if a.platform == "all":
                ap.error("--matrix needs --platform linux or darwin")
            groups = ci_groups(tests, a.platform)
            if not groups:
                raise DiscoveryError([f"no CI test for platform {a.platform} - the matrix would be empty"])
            out = json.dumps(groups)
            budgets = step_budgets(tests, a.platform)
            print(out)
            for g in groups:
                n = select(tests, a.platform, True, g)
                print(f"  {g}: {len(n)} test(s), per-test caps sum {sum(t['timeout_min'] for t in n)} min, "
                      f"step timeout {budgets[g]} min: {' '.join(t['name'] for t in n)}", file=sys.stderr)
            if a.github_output and os.environ.get("GITHUB_OUTPUT"):
                with open(os.environ["GITHUB_OUTPUT"], "a") as f:
                    f.write(f"groups={out}\n")
                    f.write(f"step_timeouts={json.dumps(budgets, separators=(',', ':'))}\n")
            return 0
        sel = select(tests, a.platform, a.ci, None, a.only)
        if a.json:
            print(json.dumps(sel, indent=1))
        else:
            w = max(len(t["name"]) for t in sel) if sel else 4
            print(f"{'name':<{w}}  {'group':<9} {'min':>3}  {'platforms':<12} ci    kind       folder")
            for t in sel:
                print(f"{t['name']:<{w}}  {t['group']:<9} {t['timeout_min']:>3}  {','.join(t['platforms']):<12} "
                      f"{'yes' if t['ci'] else 'no ':<5} {t['kind']:<10} {t['folder']}")
            print(f"\n{len(sel)} test(s)")
        return 0
    except DiscoveryError as e:
        print("TEST DISCOVERY FAILED:", file=sys.stderr)
        for p in e.problems:
            print(f"  - {p}", file=sys.stderr)
            if os.environ.get("GITHUB_ACTIONS") == "true":
                print(f"::error title=test discovery::{p}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
