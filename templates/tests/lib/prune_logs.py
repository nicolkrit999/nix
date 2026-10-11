#!/usr/bin/env python3
"""Prune the local test-log runs that run-tests.sh writes.

  prune_logs.py STATE_BASE [--dry-run]

STATE_BASE is ${XDG_STATE_HOME:-~/.local/state}/nix-tests. run-tests.sh calls this
at the start of every run (unless --keep-logs) BEFORE it creates the new run's
directory. Three independent limits, applied in this order, each one deleting
the OLDEST runs first:

  NIX_TESTS_KEEP_RUNS     (default 20)   keep at most this many runs
  NIX_TESTS_MAX_AGE_DAYS  (default 60)   delete runs older than this
  NIX_TESTS_MAX_MB        (default 500)  delete runs until the total is at most this

A value of 0 disables that limit. A value that is not a non-negative integer is
an error (exit 2) and nothing is deleted.

Safety:
- Only directories named exactly like the ones run-tests.sh creates are ever
  touched: `<YYYYmmddTHHMMSS>-<short sha | nogit>` (real directories, not
  symlinks). Anything else in STATE_BASE is left alone, whatever its size.
- The target of the `latest` symlink is never deleted, even when it is the
  oldest or the only thing over a limit. It still counts toward the size total.
- A run's age comes from the timestamp in its name (the time run-tests.sh made
  it), not from mtime, which a copy or a backup restore would reset.

Exit 0 on success (also when nothing needed pruning); the deleted runs are
listed on stdout.
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import os  # noqa: E402
import re  # noqa: E402
import shutil  # noqa: E402
from datetime import datetime, timedelta  # noqa: E402
from pathlib import Path  # noqa: E402

RUN_DIR = re.compile(r"^(?P<ts>\d{8}T\d{6})-(?:[0-9a-f]{4,40}|nogit)$")
DEFAULTS = {"NIX_TESTS_KEEP_RUNS": 20, "NIX_TESTS_MAX_AGE_DAYS": 60, "NIX_TESTS_MAX_MB": 500}


def limits(env=None) -> dict:
    env = os.environ if env is None else env
    out, bad = {}, []
    for k, d in DEFAULTS.items():
        raw = env.get(k, "")
        if raw.strip() == "":
            out[k] = d
            continue
        try:
            v = int(raw)
            if v < 0:
                raise ValueError
        except ValueError:
            bad.append(f"{k}={raw!r} is not a non-negative integer")
            continue
        out[k] = v
    if bad:
        raise ValueError("; ".join(bad))
    return out


def _size(p: Path) -> int:
    """Apparent size of every file (and symlink) under p; symlinks are not followed."""
    total = 0
    for dirpath, _dirnames, filenames in os.walk(p, followlinks=False):
        for n in filenames:
            try:
                total += os.lstat(os.path.join(dirpath, n)).st_size
            except OSError:
                continue
    return total


def runs(base: Path):
    """[(timestamp, path)] of every run dir run-tests.sh created, newest first."""
    out = []
    if not base.is_dir():
        return out
    for p in base.iterdir():
        m = RUN_DIR.match(p.name)
        if not m or p.is_symlink() or not p.is_dir():
            continue
        try:
            ts = datetime.strptime(m.group("ts"), "%Y%m%dT%H%M%S")
        except ValueError:
            continue
        out.append((ts, p))
    out.sort(key=lambda t: (t[0], t[1].name), reverse=True)
    return out


def plan(base: Path, lim: dict, now: datetime | None = None) -> list[tuple[Path, str]]:
    """[(run dir, reason)] to delete, oldest first. Pure: deletes nothing."""
    now = now or datetime.now()
    found = runs(base)
    latest = base / "latest"
    protected = None
    if latest.is_symlink():
        try:
            protected = latest.resolve(strict=False)
        except OSError:
            protected = None

    def is_protected(p):
        return protected is not None and p.resolve() == protected

    doomed: dict[Path, str] = {}
    keep = lim["NIX_TESTS_KEEP_RUNS"]
    if keep:
        for _ts, p in found[keep:]:
            if not is_protected(p):
                doomed[p] = f"more than {keep} runs"
    max_age = lim["NIX_TESTS_MAX_AGE_DAYS"]
    if max_age:
        cutoff = now - timedelta(days=max_age)
        for ts, p in found:
            if p not in doomed and ts < cutoff and not is_protected(p):
                doomed[p] = f"older than {max_age} days"
    max_mb = lim["NIX_TESTS_MAX_MB"]
    if max_mb:
        cap = max_mb * 1024 * 1024
        left = [(ts, p) for ts, p in found if p not in doomed]
        sizes = {p: _size(p) for _ts, p in left}
        total = sum(sizes.values())
        for _ts, p in reversed(left):  # oldest first
            if total <= cap:
                break
            if is_protected(p):
                continue
            doomed[p] = f"total over {max_mb} MB"
            total -= sizes[p]
    order = {p: ts for ts, p in found}
    return sorted(doomed.items(), key=lambda kv: (order[kv[0]], kv[0].name))


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    dry = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    if len(args) != 1:
        print(__doc__.split("\n\n")[1], file=sys.stderr)
        return 2
    base = Path(args[0])
    try:
        lim = limits()
    except ValueError as e:
        print(f"prune_logs.py: {e}; nothing pruned", file=sys.stderr)
        return 2
    doomed = plan(base, lim)
    for p, why in doomed:
        print(f"{'would prune' if dry else 'pruned'} old test logs {p.name} ({why})")
        if not dry:
            shutil.rmtree(p, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
