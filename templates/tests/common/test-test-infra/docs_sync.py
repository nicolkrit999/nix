#!/usr/bin/env python3
"""Docs-sync guard: the docs that enumerate tests must match discovery.

Source of truth: templates/tests/lib/discover.py (imported, not re-implemented).
Every problem is printed as `FAIL  <file>:<line>: <what to fix>`; exit 1 if any.

Usage: python3 -B docs_sync.py [--repo DIR]   (default: the repo holding this file)
"""
from __future__ import annotations

import argparse
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LIB = HERE.parents[1] / "lib" / "discover.py"
OVERVIEW = "Documentation/usage/tests/tests-overview.md"
WORKFLOWS = "Documentation/usage/ci/build-workflows.md"
CAT_LABEL = {"nixos": "NixOS", "common": "common", "darwin": "darwin"}
# Where test folders and `--only` names are referenced (tracked .md files only).
REF_SCOPES = ("Documentation", ".claude/skills", ".claude/agents", "CLAUDE.md", "templates/tests")


def load_discover():
    spec = importlib.util.spec_from_file_location("discover", LIB)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class Report:
    def __init__(self):
        self.fails = 0
        self.passes = 0

    def ok(self, msg):
        self.passes += 1
        print(f"  PASS  {msg}")

    def fail(self, where, msg):
        self.fails += 1
        print(f"  FAIL  {where}: {msg}")


def word(token: str) -> re.Pattern:
    return re.compile(rf"(?<![A-Za-z0-9_-]){re.escape(token)}(?![A-Za-z0-9_-])")


def short(t: dict) -> str:
    return t["name"][len(t["category"]) + 1:]


def check_readmes(repo: Path, tests, r: Report):
    bad = 0
    for t in tests:
        folder = repo / t["folder"]
        want = folder / f"{folder.name}-readme.md"
        found = sorted(p.name for p in folder.glob("*-readme.md"))
        if not want.is_file():
            bad += 1
            r.fail(f"{t['folder']}/", f"missing {want.name} (found: {', '.join(found) or 'none'}) - "
                                      f"the readme must be named <folder>-readme.md: git mv it to {want.name}")
        for extra in (n for n in found if n != want.name):
            bad += 1
            r.fail(f"{t['folder']}/{extra}", f"unexpected readme name - exactly one {want.name} per test folder")
        if want.is_file():
            text = want.read_text()
            if not re.search(r"^## Run", text, re.M):
                bad += 1
                r.fail(f"{t['folder']}/{want.name}:1", "no `## Run` section (how to run the test)")
            first = text.splitlines()[0] if text else ""
            if not re.fullmatch(rf"# {re.escape(folder.name)}(?: .*)?", first):
                bad += 1
                r.fail(f"{t['folder']}/{want.name}:1", f"title is {first!r}, must start with '# {folder.name}' "
                                                       f"(the folder name; rename the title after a folder rename)")
            for i, l in enumerate(text.splitlines(), 1):
                for m in re.finditer(r"(?<![A-Za-z0-9_/.-])(check-[A-Za-z0-9_-]+\.sh)", l):
                    if not (folder / m.group(1)).exists():
                        bad += 1
                        r.fail(f"{t['folder']}/{want.name}:{i}", f"names {m.group(1)}, which is not in this folder "
                                                                 f"(script renamed or removed? fix the Run commands)")
    for p in sorted((repo / "templates/tests").rglob("*")):
        if p.is_file() and p.name.lower() == "readme.md":
            bad += 1
            r.fail(p.relative_to(repo).as_posix(), "README.md is forbidden under templates/tests - "
                                                   "rename it to <folder>-readme.md")
    if not bad:
        r.ok(f"readmes: each of {len(tests)} test folders has exactly one <folder>-readme.md with '# <folder>' title, "
             f"## Run and only existing check-*.sh names, no README.md")


def check_overview(repo: Path, tests, r: Report):
    path = repo / OVERVIEW
    lines = path.read_text().splitlines()
    by_cat = {c: [t for t in tests if t["category"] == c] for c in CAT_LABEL}
    by_name = {t["name"]: t for t in tests}
    default_timeout = load_discover().DEFAULT_TIMEOUT_MIN
    bad = 0

    # 1. count sentence
    rx = re.compile(r"(\d+) tests are discovered today.*?: (\d+) NixOS, (\d+) common and (\d+) darwin")
    hits = [(i, m) for i, l in enumerate(lines, 1) if (m := rx.search(l))]
    want = (len(tests), len(by_cat["nixos"]), len(by_cat["common"]), len(by_cat["darwin"]))
    if len(hits) != 1:
        bad += 1
        r.fail(f"{OVERVIEW}:1", f"expected one count sentence '<N> tests are discovered today ...: <X> NixOS, "
                                f"<Y> common and <Z> darwin', found {len(hits)}")
    else:
        i, m = hits[0]
        got = tuple(int(g) for g in m.groups())
        if got != want:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"count sentence says {got[0]} tests ({got[1]} NixOS, {got[2]} common, "
                                      f"{got[3]} darwin), discovery has {want[0]} ({want[1]} NixOS, {want[2]} common, "
                                      f"{want[3]} darwin)")

    # 2. one table row per test, in its category's section, folder and CI group right
    section_cat = None
    rows: dict[str, list[int]] = {}
    sec_line = {}
    for i, l in enumerate(lines, 1):
        if l.startswith("## "):
            m = re.search(r"`templates/tests/(nixos|common|darwin)/`", l)
            section_cat = m.group(1) if m else None
            if section_cat:
                sec_line[section_cat] = i
            continue
        if section_cat is None or not l.startswith("|") or set(l.replace("|", "").strip()) <= set("-: "):
            continue
        cells = [c.strip() for c in l.strip().strip("|").split("|")]
        if cells[0] == "Run name":
            continue
        m = re.fullmatch(r"`([^`]+)`", cells[0])
        if not m or len(cells) < 3:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", "table row whose first cell is not a `run-name` - cannot check it")
            continue
        name = m.group(1)
        rows.setdefault(name, []).append(i)
        t = by_name.get(name)
        if t is None:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"row for `{name}`, which discovery does not know - delete the row "
                                      f"or fix the name (see run-tests.sh --list)")
            continue
        if t["category"] != section_cat:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"`{name}` is a {t['category']} test but sits in the {section_cat} table")
        folder = t["folder"].rsplit("/", 1)[-1]
        if cells[1] != f"`{folder}`":
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"`{name}` folder cell is {cells[1]}, the folder is `{folder}`")
        if cells[2] != t["group"]:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"`{name}` CI group cell is {cells[2]!r}, test.conf/discovery says {t['group']!r}")
        caps = [int(c) for c in re.findall(r"\bcap (\d+) min", cells[-1])]
        want_caps = [] if t["timeout_min"] == default_timeout else [t["timeout_min"]]
        if caps != want_caps:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"`{name}` Runtime cell states cap {caps or 'none'}, test.conf timeout is "
                                      f"{t['timeout_min']} min (write 'cap N min' only when it is not the default "
                                      f"{default_timeout})")
    for name, at in rows.items():
        if len(at) > 1:
            bad += 1
            r.fail(f"{OVERVIEW}:{at[1]}", f"`{name}` has {len(at)} rows (lines {', '.join(map(str, at))}) - keep one")
    for t in tests:
        if t["name"] not in rows:
            bad += 1
            line = sec_line.get(t["category"], 1)
            r.fail(f"{OVERVIEW}:{line}", f"no table row for `{t['name']}` ({t['folder']}) - add one to the "
                                         f"{CAT_LABEL[t['category']]} tests table")

    # 3. "Linux groups today: ... Darwin: ..." matches the CI matrix
    d = load_discover()
    lin, dar = d.ci_groups(tests, "linux"), d.ci_groups(tests, "darwin")
    gl = [(i, l) for i, l in enumerate(lines, 1) if "Linux groups today:" in l]
    if len(gl) != 1:
        bad += 1
        r.fail(f"{OVERVIEW}:1", "expected one 'Linux groups today: ...' sentence (the CI legs) - if it was "
                                "reworded on purpose, update templates/tests/common/test-test-infra/docs_sync.py")
    else:
        i, l = gl[0]
        m = re.search(r"Linux groups today:(.*?)\.\s*Darwin:(.*?)(?:\.|$)", l)
        got_l = sorted(re.findall(r"`([a-z0-9-]+)`", m.group(1))) if m else []
        got_d = sorted(re.findall(r"`([a-z0-9-]+)`", m.group(2))) if m else []
        if got_l != lin or got_d != dar:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"CI legs listed as linux {got_l} / darwin {got_d}, discovery has "
                                      f"linux {lin} / darwin {dar}")
    # 4. the `--fast` flag row names exactly the tests that have fast_args
    fl = [(i, l) for i, l in enumerate(lines, 1) if l.startswith("| `--fast` |")]
    if len(fl) != 1:
        bad += 1
        r.fail(f"{OVERVIEW}:1", "expected one '| `--fast` |' row in the flags table")
    else:
        i, l = fl[0]
        named = {t["name"] for t in tests if word(t["name"]).search(l)}
        fast = {t["name"] for t in tests if t["fast_args"]}
        if named != fast:
            bad += 1
            r.fail(f"{OVERVIEW}:{i}", f"`--fast` row names {sorted(named)}, tests with fast_args in test.conf: "
                                      f"{sorted(fast)}")
    if not bad:
        r.ok(f"{OVERVIEW}: count sentence {want}, {len(tests)} rows (folder, CI group, timeout cap), CI leg list, "
             f"--fast row")


def check_groups_table(repo: Path, tests, r: Report):
    path = repo / WORKFLOWS
    lines = path.read_text().splitlines()
    start = next((i for i, l in enumerate(lines, 1) if l.startswith("### 12.2 ")), None)
    if start is None:
        r.fail(f"{WORKFLOWS}:1", "section '### 12.2 ' (CI groups table) not found")
        return
    end = next((i for i, l in enumerate(lines, 1) if i > start and l.startswith("### ")), len(lines) + 1)
    groups = sorted({t["group"] for t in tests if t["ci"]})
    in_group = {g: [t for t in tests if t["ci"] and t["group"] == g] for g in groups}
    default_timeout = load_discover().DEFAULT_TIMEOUT_MIN
    bad = 0
    seen: dict[str, int] = {}
    header = start
    for i in range(start + 1, end):
        l = lines[i - 1]
        if not l.startswith("|"):
            continue
        cells = [c.strip() for c in l.strip().strip("|").split("|")]
        if cells[0] == "leg":
            header = i
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        m = re.match(r"`([a-z0-9-]+)`", cells[0])
        if not m or len(cells) < 2:
            bad += 1
            r.fail(f"{WORKFLOWS}:{i}", "§12.2 row whose first cell is not a `group` - cannot check it")
            continue
        g, cell = m.group(1), cells[1]
        if g in seen:
            bad += 1
            r.fail(f"{WORKFLOWS}:{i}", f"group `{g}` listed twice (also line {seen[g]})")
            continue
        seen[g] = i
        if g not in in_group:
            bad += 1
            r.fail(f"{WORKFLOWS}:{i}", f"§12.2 lists group `{g}`, but no CI test has that group - delete the row")
            continue
        members = in_group[g]
        dm = re.search(r"default for `?(nixos|common|darwin)/`? \((\d+) tests?\)", cell)
        if dm:
            cat, n = dm.group(1), int(dm.group(2))
            if g != cat:
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` says 'default for {cat}/', but the default group of {cat}/ is `{cat}`")
            if n != len(members):
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` says {n} tests, discovery puts {len(members)} in `{g}`: "
                                           f"{' '.join(t['name'] for t in members)}")
            continue
        for t in members:
            if not (word(t["name"]).search(cell) or word(short(t)).search(cell)):
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` does not name `{t['name']}` (test.conf group = {g}) - add it")
        for t in tests:
            if t in members:
                continue
            if word(t["name"]).search(cell) or word(short(t)).search(cell):
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` names `{t['name']}`, whose group is `{t['group']}` - "
                                           f"move it to that row")
        known = {t["name"] for t in tests} | {short(t) for t in tests}
        for tok in re.findall(r"(?<![A-Za-z0-9_.*/-])[a-z0-9]+(?:-[a-z0-9]+)+(?![A-Za-z0-9_.-])", cell):
            if tok not in known:
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` names `{tok}`, which is no discovered test "
                                           f"(renamed or deleted?) - fix or drop it")
        caps = sorted({int(c) for c in re.findall(r"\bcap (\d+)", cell)})
        want_caps = sorted({t["timeout_min"] for t in members if t["timeout_min"] != default_timeout})
        if caps != want_caps:
            bad += 1
            r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` states caps {caps}, test.conf timeouts other than the default "
                                       f"{default_timeout} in this group are {want_caps}")
        for n in re.findall(r"\((\d+) tests?\)", cell):
            if int(n) != len(members):
                bad += 1
                r.fail(f"{WORKFLOWS}:{i}", f"row `{g}` says {n} tests, discovery has {len(members)}")
    for g in groups:
        if g not in seen:
            bad += 1
            r.fail(f"{WORKFLOWS}:{header}", f"§12.2 table has no row for CI group `{g}` "
                                            f"({' '.join(t['name'] for t in in_group[g])})")
    if not bad:
        r.ok(f"{WORKFLOWS} §12.2: one row per CI group ({len(groups)}), members, counts and caps match test.conf")


def git(repo: Path, *args) -> list[str]:
    out = subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True, text=True).stdout
    return [l for l in out.split("\0" if "-z" in args else "\n") if l]


def check_refs(repo: Path, tests, r: Report, select):
    files = [f for f in git(repo, "ls-files", "-z", "--", *REF_SCOPES) if f.endswith(".md")]
    bad = 0
    path_rx = re.compile(r"templates/tests/(?:nixos|common|darwin)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*(?![A-Za-z0-9_.<*-])")
    only_rx = re.compile(r"run-tests\.sh --only ([A-Za-z0-9_,-]+)(?![A-Za-z0-9_<-])")
    n = 0
    for f in files:
        p = repo / f
        if not p.is_file():
            continue
        for i, l in enumerate(p.read_text(errors="replace").splitlines(), 1):
            for m in path_rx.finditer(l):
                ref = m.group(0).rstrip(".")
                n += 1
                if not (repo / ref).exists():
                    bad += 1
                    r.fail(f"{f}:{i}", f"references {ref}, which does not exist")
            for m in only_rx.finditer(l):
                n += 1
                try:
                    select(tests, only=m.group(1))
                except Exception as e:  # DiscoveryError
                    bad += 1
                    r.fail(f"{f}:{i}", f"`run-tests.sh --only {m.group(1)}` does not resolve: {e}")
    if not bad:
        r.ok(f"references: {n} test paths / --only names in {len(files)} tracked .md files all resolve")


def check_untracked(repo: Path, r: Report):
    left = git(repo, "ls-files", "--others", "--exclude-standard", "--", "templates/tests")
    if left:
        for f in left:
            r.fail(f, "untracked - flakes, CI and the docs guard only see tracked files: git add it")
    else:
        r.ok("no untracked files under templates/tests")


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=str(HERE.parents[3]))
    a = ap.parse_args(argv)
    repo = Path(a.repo).resolve()
    d = load_discover()
    r = Report()
    try:
        tests = d.discover(repo / "templates" / "tests")
    except d.DiscoveryError as e:
        for p in e.problems:
            r.fail("templates/tests", f"discovery failed: {p}")
        return 1
    check_untracked(repo, r)
    check_readmes(repo, tests, r)
    check_overview(repo, tests, r)
    check_groups_table(repo, tests, r)
    check_refs(repo, tests, r, d.select)
    print(f"docs-sync: {r.passes} passed, {r.fails} problem(s)")
    return 1 if r.fails else 0


if __name__ == "__main__":
    sys.exit(main())
