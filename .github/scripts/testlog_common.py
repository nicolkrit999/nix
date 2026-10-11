"""Shared by run-test.py and test-report.py: redaction, run context, discovery import.

Security (public repo): GitHub masks `secrets.*` only in the live job log, NOT in
files. Everything written to test-logs/ (artifacts) or sent to Discord passes
through redact(), and context() collects whitelisted facts only - never the
environment, `nix config show` / `nix show-config` (they print the
`access-tokens = github.com=<GITHUB_TOKEN>` line the workflow writes into nix.conf)
or /etc/nix/nix.conf.
"""
from __future__ import annotations

import datetime as dt
import json
import os
import platform
import re
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # never leave __pycache__ dirs in the repo tree

ROOT = Path(__file__).resolve().parents[2]
REPO_SLUG_DEFAULT = "nicolkrit999/nix"
IN_GHA = os.environ.get("GITHUB_ACTIONS") == "true"

sys.path.insert(0, str(ROOT / "templates" / "tests" / "lib"))
import discover  # noqa: E402  (templates/tests/lib/discover.py)

ANSI = re.compile(rb"\x1b\[[0-9;?]*[ -/]*[@-~]")
REDACT = [
    (re.compile(rb"\b(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})"), b"[REDACTED-GH-TOKEN]"),
    (re.compile(rb"AGE-SECRET-KEY-1[0-9A-Z]{50,}"), b"[REDACTED-AGE-KEY]"),
    (re.compile(rb"https://(?:canary\.|ptb\.)?discord(?:app)?\.com/api/webhooks/\d+/[\w-]+"), b"[REDACTED-WEBHOOK]"),
    (re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.S),
     b"[REDACTED-PRIVATE-KEY]"),
    (re.compile(rb"(access-tokens\s*=\s*)\S+"), rb"\1[REDACTED]"),
    (re.compile(rb"(CACHIX_AUTH_TOKEN\s*[=:]\s*)\S+"), rb"\1[REDACTED]"),
    (re.compile(rb"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}"), b"[REDACTED-JWT]"),
]


def redact(b: bytes) -> bytes:
    for rx, rep in REDACT:
        b = rx.sub(rep, b)
    return b


def redact_text(s: str) -> str:
    return redact(s.encode("utf-8", "replace")).decode("utf-8", "replace")


# ── streaming redaction (line by line) ───────────────────────────────────────
# The PEM pattern above needs the whole block (re.S), so a line-by-line pump
# could never match it: the key body reached the artifact and the live log
# (security review F5). StreamRedactor carries "inside a PEM block" across
# lines and drops the body; redact_file() re-redacts the finished log as a whole.
PEM_BEGIN = re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----")
PEM_END = re.compile(rb"-----END [A-Z ]*PRIVATE KEY-----")
PEM_MAX_LINES = 200  # an RSA-16384 body is ~180 lines; past this, assume no END is coming


class StreamRedactor:
    """feed(one ANSI-stripped line) -> the redacted bytes to write (possibly b"")."""

    def __init__(self):
        self.in_pem = 0  # lines swallowed so far in the current block; 0 = not in one

    def feed(self, line: bytes) -> bytes:
        if self.in_pem:
            m = PEM_END.search(line)
            if m:
                self.in_pem = 0
                rest = line[m.end():]
                return redact(rest) if rest.strip() else b""
            if self.in_pem > PEM_MAX_LINES:  # swallowed PEM_MAX_LINES already
                self.in_pem = 0
                return b"[REDACTION: PEM block without END line - stopped suppressing output]\n" + redact(line)
            self.in_pem += 1
            return b""
        b = PEM_BEGIN.search(line)
        if b and not PEM_END.search(line, b.end()):
            self.in_pem = 1
            return redact(line[:b.start()]) + b"[REDACTED-PRIVATE-KEY]\n"
        return redact(line)


def redact_file(path: Path) -> bool:
    """Redact a finished log as ONE text (catches what crossed lines). True if changed."""
    try:
        data = path.read_bytes()
    except OSError:
        return False
    clean = redact(data)
    if clean == data:
        return False
    tmp = path.with_name(path.name + ".redact.tmp")
    tmp.write_bytes(clean)
    os.replace(tmp, path)
    return True


# ── workflow-command injection ───────────────────────────────────────────────
# The runner executes any stdout line starting with `::` as a workflow command
# (::add-mask::, ::error::, ::stop-commands:: ...). Test output and HANDOFF.md
# are untrusted on a fork PR, so whatever echoes them wraps the output in
# `::stop-commands::<random>` ... `::<random>::` (security review nit).
def stop_commands() -> str:
    """Print the stop marker (in GitHub Actions only) and return the resume token ('' outside)."""
    if not IN_GHA:
        return ""
    import secrets
    token = secrets.token_hex(16)
    sys.stdout.flush()
    print(f"::stop-commands::{token}", flush=True)
    return token


def resume_commands(token: str):
    if token:
        sys.stdout.flush()
        print(f"::{token}::", flush=True)


def pr_is_untrusted(ctx: dict) -> bool:
    """A pull_request run whose head is not this repository (a fork, or a deleted
    head repo): its code, output and commit subject are attacker-controlled."""
    if not str(ctx.get("event", "")).startswith("pull_request"):
        return False
    return (ctx.get("pr_head_repo") or "") != ctx.get("repo")


def _sh(*cmd) -> str:
    try:
        return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=20).stdout.strip()
    except Exception:
        return ""


def nixpkgs_lock() -> dict:
    """The ROOT nixpkgs input (it is node `nixpkgs_N`, resolve through root.inputs)."""
    try:
        nodes = json.loads((ROOT / "flake.lock").read_text())["nodes"]
        key = nodes["root"]["inputs"]["nixpkgs"]
        locked = nodes[key if isinstance(key, str) else key[0]]["locked"]
        return {
            "nixpkgs_rev": locked.get("rev", ""),
            "nixpkgs_date": dt.datetime.fromtimestamp(locked.get("lastModified", 0), dt.timezone.utc).strftime("%Y-%m-%d"),
        }
    except Exception:
        return {"nixpkgs_rev": "", "nixpkgs_date": ""}


def context() -> dict:
    e = os.environ.get
    sha = e("PR_HEAD_SHA") or e("GITHUB_SHA") or _sh("git", "rev-parse", "HEAD")
    return {
        "repo": e("GITHUB_REPOSITORY", REPO_SLUG_DEFAULT),
        "sha": sha,
        "tested_sha": e("GITHUB_SHA") or sha,  # on a PR: the merge commit actually checked out
        "subject": _sh("git", "log", "-1", "--format=%s"),
        "ref": e("GITHUB_HEAD_REF") or e("GITHUB_REF_NAME") or _sh("git", "rev-parse", "--abbrev-ref", "HEAD"),
        "event": e("GITHUB_EVENT_NAME", "local"),
        "pr": e("PR_NUMBER", ""),
        "pr_head_repo": e("PR_HEAD_REPO", ""),  # != repo on a fork PR (pr_is_untrusted)
        "workflow": e("GITHUB_WORKFLOW", ""),
        "run_id": e("GITHUB_RUN_ID", ""),
        "run_attempt": e("GITHUB_RUN_ATTEMPT", ""),
        "job": e("GITHUB_JOB", ""),
        "runner": f'{e("ImageOS", platform.system())} {e("ImageVersion", "")} {e("RUNNER_ARCH", platform.machine())}'.replace("  ", " ").strip(),
        "nix": _sh("nix", "--version"),
        **nixpkgs_lock(),
    }


def now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


# ── log layout + excerpts ─────────────────────────────────────────────────────
# <name>.log = header ("# key: value" lines, SEP) + test output + optional
#              EVIDENCE_MARK section + SEP + footer. run-test.py writes it;
#              test-report.py and the in-job excerpt step read it.
SEP = "# " + "-" * 70
EVIDENCE_MARK = "===== EVIDENCE: full stderr of failing nix calls / kept files ====="
TRUNC_MARK = "[... {n} lines cut - the complete log is in the CI artifact / local log dir ...]"


def split_log(text: str):
    """-> (body_lines, evidence_lines). Header and footer are removed."""
    lines = text.splitlines()
    seps = [i for i, l in enumerate(lines) if l == SEP]
    if len(seps) >= 2:
        lines = lines[seps[0] + 1:seps[-1]]
    elif len(seps) == 1:
        lines = lines[seps[0] + 1:]
    if EVIDENCE_MARK in lines:
        i = lines.index(EVIDENCE_MARK)
        return lines[:i], lines[i + 1:]
    return lines, []


def _fit(lines, budget):
    """Drop lines from the top until the joined text fits `budget` chars."""
    out = list(lines)
    while out and len("\n".join(out)) > budget:
        out.pop(0)
    if not out and lines:  # a single line longer than the budget: keep its end
        return ["[...]" + str(lines[-1])[-(budget - 5):]]
    if out != list(lines) and out:
        out[0] = "[...]"
    return out


def excerpt(text: str, budget: int = 1600) -> str:
    """The part of a failing test's log a human needs first, at most `budget` chars:
    1. the script's own final `FAILURES (...)` block (every check-*.sh prints one),
    2. else the first `error:` line + 10 after it, `...`, and the last <= 40 lines,
    3. plus, if room remains, the head of the first evidence block (full nix error).
    """
    body, evidence = split_log(text)
    body = [l.rstrip() for l in body]
    idx = max((i for i, l in enumerate(body) if "FAILURES (" in l), default=None)
    if idx is not None:
        chosen = body[idx:idx + 60]
    else:
        err = next((i for i, l in enumerate(body) if "error:" in l or re.search(r"\bFAIL(ED)?\b", l)), None)
        tail = body[-40:]
        if err is not None and err < len(body) - 40:
            chosen = body[err:err + 11] + ["..."] + tail
        else:
            chosen = tail
    chosen = _fit(chosen, budget)
    used = len("\n".join(chosen))
    if evidence and budget - used > 300:
        ev = [l.rstrip() for l in evidence if l.strip()][:25]
        ev = ["--- first nix error (evidence) ---"] + ev
        while ev and used + 1 + len("\n".join(ev)) > budget:
            ev.pop()
        if len(ev) > 1:
            chosen += ev
    return "\n".join(chosen)
