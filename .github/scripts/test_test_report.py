#!/usr/bin/env python3
"""Unit tests for the CI test-logging pipeline (run by check-workflows.yml):
templates/tests/lib/discover.py, .github/scripts/run-test.py, .github/scripts/test-report.py.

Every Discord payload must stay <= 2000 chars with <= 10 files and <= 8 MiB of
attachments, secrets must be redacted, mentions must never ping, a pass-only run must
send nothing, and discovery must fail loudly on a folder that matches no pattern.

Run:  python3 .github/scripts/test_test_report.py
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import importlib.util  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import random  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import unittest  # noqa: E402
from pathlib import Path  # noqa: E402

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import testlog_common as tc  # noqa: E402

_spec = importlib.util.spec_from_file_location("test_report", HERE / "test-report.py")
tr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tr)
discover = tc.discover

CTX = {"repo": "o/r", "sha": "a" * 40, "tested_sha": "a" * 40, "subject": "subj", "ref": "develop",
       "event": "push", "pr": "", "workflow": "NixOS Tests", "run_id": "123", "run_attempt": "1",
       "job": "tests", "runner": "ubuntu24 X64", "nix": "nix 2.x", "nixpkgs_rev": "b" * 40,
       "nixpkgs_date": "2026-10-08"}
SECRET = "ghp_" + "A" * 36
HOOK = "https://discord.com/api/webhooks/123456/abcDEF-token_xyz"


def mk_test(name, group="g1"):
    return {"name": name, "group": group, "folder": f"templates/tests/nixos/test-{name}", "readme": "",
            "commands": [f"bash templates/tests/nixos/test-{name}/check.sh"], "platforms": ["linux"], "ci": True}


def write_leg(art: Path, group, results, log_size=0, random_log=False, attempt=1):
    """results: {name: status}; status 'running' = hard kill, None = expected but never started."""
    d = art / f"test-logs-nixos-{group}-123-{attempt}"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"_expected-linux-{group}.json").write_text(json.dumps(list(results)))
    for name, st in results.items():
        if st is None:
            continue
        meta = {"name": name, "status": st, "exit_code": 0 if st == "pass" else 1, "duration_s": 42,
                "commands": [f"bash x/{name}.sh"], "group": group}
        (d / f"{name}.meta.json").write_text(json.dumps(meta))
        body = f"some output\nFAILURES (1 of 3):\n  ✗ check x\n  {SECRET} @everyone {HOOK}\n```fence```\n"
        if random_log:
            rnd = random.Random(7)
            body += "".join(chr(rnd.randrange(33, 0x2000)) for _ in range(log_size))
        elif log_size:
            body += ("nix log line with some text that compresses well\n" * (log_size // 50))
        foot = f"{tc.SEP}\n# status: {st}\n" if st != "running" else ""
        (d / f"{name}.log").write_text(f"# name: {name}\n{tc.SEP}\n{body}{foot}")
    return d


def assert_commands_stopped(case, out, inner):
    """`inner` must sit between ::stop-commands::<token> and ::<token>:: (32 hex)."""
    lines = out.splitlines()
    starts = [i for i, l in enumerate(lines) if l.startswith("::stop-commands::")]
    case.assertTrue(starts, out[:500])
    tok = lines[starts[0]].split("::")[2]
    case.assertRegex(tok, r"^[0-9a-f]{32}$")
    end = lines.index(f"::{tok}::")
    pos = next(i for i, l in enumerate(lines) if inner in l)
    case.assertTrue(starts[0] < pos < end, (starts[0], pos, end))
    return end


class ReportCase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="test-report-"))
        self.art, self.out = self.tmp / "artifacts", self.tmp / "report"
        os.environ["RUN_URL"] = "https://github.com/o/r/actions/runs/123"

    def run_report(self, tests, needs=None, errors=(), ctx=CTX):
        metas, expected = tr.collect(self.art)
        rows = tr.classify(tests, metas, expected, needs or {"tests": {"result": "failure"}})
        msgs = tr.write_report(rows, "NixOS tests", ctx, "linux", self.out, list(errors), needs or {})
        return rows, msgs

    def assert_payloads_ok(self):
        ids = (self.out / "messages.txt").read_text().split()
        for mid in ids:
            p = json.loads((self.out / f"{mid}.json").read_text())
            self.assertLessEqual(len(p["content"]), 2000)
            self.assertEqual(p["allowed_mentions"], {"parse": []})
            self.assertEqual(p["flags"], 4)
            self.assertNotIn(SECRET, p["content"])
            self.assertNotIn("abcDEF-token_xyz", p["content"])
            files = [l.split("\t")[0] for l in (self.out / f"{mid}.files").read_text().splitlines() if l]
            self.assertLessEqual(len(files), 10)
            self.assertLessEqual(sum(Path(f).stat().st_size for f in files), tr.ATTACH_BUDGET + 64 * 1024)
            for f in files:
                raw = Path(f).read_bytes()
                if not f.endswith((".gz",)):
                    self.assertNotIn(SECRET.encode(), raw)
        return ids

    def test_pass_only_sends_nothing(self):
        write_leg(self.art, "g1", {"a": "pass", "b": "pass"})
        _, msgs = self.run_report([mk_test("a"), mk_test("b")], {"tests": {"result": "success"}})
        self.assertEqual(msgs, [])
        self.assertEqual((self.out / "messages.txt").read_text(), "")

    def test_one_fail(self):
        write_leg(self.art, "g1", {"a": "pass", "b": "fail"})
        rows, msgs = self.run_report([mk_test("a"), mk_test("b")])
        ids = self.assert_payloads_ok()
        self.assertEqual(len(ids), 2)  # header + one per failing test
        head = json.loads((self.out / "00.json").read_text())["content"]
        for want in ("aaaaaaaaaaaa", "bbbbbbbbbbbb", "<https://github.com/o/r/actions/runs/123>",
                     "gh run download 123 -R o/r", "HANDOFF", "✗ b"):
            self.assertIn(want, head)
        m1 = json.loads((self.out / "01.json").read_text())["content"]
        self.assertIn("FAILURES (1 of 3)", m1)
        self.assertNotIn("```fence```", m1)  # fences escaped so the code block cannot break
        self.assertIn("b.log", (self.out / "01.files").read_text())
        handoff = (self.out / "HANDOFF.md").read_text()
        self.assertIn("run-tests.sh --only b", handoff)
        self.assertNotIn(SECRET, handoff)

    def test_forty_fails_cap_and_tarball(self):
        names = [f"t{i:02d}-a-rather-long-test-folder-name" for i in range(40)]
        write_leg(self.art, "g1", {n: "fail" for n in names})
        _, msgs = self.run_report([mk_test(n) for n in names])
        ids = self.assert_payloads_ok()
        self.assertEqual(len(ids), 1 + tr.MAX_TEST_MESSAGES + 1)
        self.assertIn("remaining-failures.tar.gz", (self.out / ids[-1]).with_suffix(".files").read_text())
        self.assertIn("more (see HANDOFF.md)", json.loads((self.out / "00.json").read_text())["content"])

    def test_big_log_is_gzipped(self):
        write_leg(self.art, "g1", {"big": "fail"}, log_size=30 * 1024 * 1024)
        self.run_report([mk_test("big")])
        self.assert_payloads_ok()
        self.assertIn("big.log.gz\tapplication/gzip", (self.out / "01.files").read_text())

    def test_incompressible_log_is_truncated(self):
        write_leg(self.art, "g1", {"rnd": "fail"}, log_size=12 * 1024 * 1024, random_log=True)
        self.run_report([mk_test("rnd")])
        self.assert_payloads_ok()
        self.assertIn("rnd.truncated.log", (self.out / "01.files").read_text())

    def test_killed_never_ran_and_lost_leg(self):
        write_leg(self.art, "g1", {"k": "running", "n": None})
        rows, _ = self.run_report([mk_test("k"), mk_test("n"), mk_test("lost", group="g2")])
        st = {r["name"]: r["state"] for r in rows}
        self.assertEqual(st, {"k": "killed", "n": "never-ran", "lost": "leg-lost"})
        self.assert_payloads_ok()
        self.assertIn("uploaded NO logs", (self.out / "HANDOFF.md").read_text())

    def test_cancelled_run_is_silent(self):
        _, msgs = self.run_report([mk_test("a"), mk_test("b", "g2")], {"tests": {"result": "cancelled"}})
        self.assertEqual(msgs, [])

    def test_discovery_error_is_reported(self):
        _, msgs = self.run_report([], {"discover": {"result": "failure"}}, errors=["x/: matches no test pattern"])
        self.assertTrue(msgs)
        self.assertIn("DISCOVERY FAILED", json.loads((self.out / "00.json").read_text())["content"])
        self.assert_payloads_ok()

    def test_crashed_report_leaves_no_messages_txt(self):
        # A crash after the old early empty write left messages.txt empty, which
        # the Notify step reads as "nothing to report": a failing run went silent.
        write_leg(self.art, "g1", {"a": "fail"})
        self.out.mkdir(parents=True)
        (self.out / "messages.txt").write_text("")  # stale from an earlier report
        real = tr.build_messages

        def boom(*a, **k):
            raise AssertionError("simulated _assert_len failure")
        tr.build_messages = boom
        try:
            with self.assertRaises(AssertionError):
                self.run_report([mk_test("a")])
        finally:
            tr.build_messages = real
        self.assertFalse((self.out / "messages.txt").exists())
        self.assertFalse((self.out / ".messages.txt.tmp").exists())

    def test_fork_pr_gets_untrusted_banner(self):
        # HANDOFF.md is handed to a Claude session; on a fork PR every line of
        # test output in it was written by the fork's code (review F4).
        write_leg(self.art, "g1", {"a": "fail"})
        fork = {**CTX, "event": "pull_request", "pr": "7", "pr_head_repo": "evil/r"}
        self.run_report([mk_test("a")], ctx=fork)
        handoff = (self.out / "HANDOFF.md").read_text()
        self.assertIn("UNTRUSTED CONTENT", handoff)
        self.assertIn("evil/r", handoff)
        self.assertLess(handoff.index("UNTRUSTED CONTENT"), handoff.index("Excerpt:"))
        head = json.loads((self.out / "00.json").read_text())["content"]
        self.assertTrue(head.startswith("⚠️ **fork PR from `evil/r`: untrusted content**"), head[:120])
        self.assert_payloads_ok()
        for ctx, want in (({**CTX, "event": "pull_request", "pr": "7", "pr_head_repo": "o/r"}, False),
                          ({**CTX, "event": "pull_request", "pr": "7", "pr_head_repo": ""}, True),  # deleted fork
                          (CTX, False)):
            self.assertEqual(tc.pr_is_untrusted(ctx), want, ctx)
            self.run_report([mk_test("a")], ctx=ctx)
            self.assertEqual("UNTRUSTED CONTENT" in (self.out / "HANDOFF.md").read_text(), want)

    def test_rerun_keeps_highest_attempt_per_leg(self):
        # "Re-run failed jobs": g1 passed in attempt 1 and is not re-run; g2 failed
        # in attempts 1 and 2 and passed in 10. The old attempt-scoped download
        # reported g1 as "leg lost"; a lexical sort would pick attempt 2 over 10.
        write_leg(self.art, "g1", {"a": "pass"}, attempt=1)
        for att, st in ((1, "fail"), (2, "fail"), (10, "pass")):
            write_leg(self.art, "g2", {"b": st}, attempt=att)
        rows, msgs = self.run_report([mk_test("a"), mk_test("b", "g2")], {"tests": {"result": "success"}},
                                     ctx={**CTX, "run_attempt": "10"})
        self.assertEqual({r["name"]: (r["state"], r["attempt"]) for r in rows}, {"a": ("pass", 1), "b": ("pass", 10)})
        self.assertEqual(msgs, [])
        self.assertEqual(tr.artifact_attempt("test-logs-nixos-heavy-a-123-10"), 10)

    def test_red_run_with_only_stale_green_logs_is_not_silent(self):
        # Attempt 2 re-ran g1, whose runner died (no attempt-2 artifact): only
        # attempt 1's green logs remain, but the run is red. Must not be silent.
        write_leg(self.art, "g1", {"a": "pass"}, attempt=1)
        _, msgs = self.run_report([mk_test("a")], {"tests": {"result": "failure"}}, ctx={**CTX, "run_attempt": "2"})
        self.assertTrue(msgs)
        handoff = (self.out / "HANDOFF.md").read_text()
        self.assertIn("Run anomaly", handoff)
        self.assertIn("earlier attempt", handoff)
        self.assertIn("leg g1 come from attempt 1", handoff)
        self.assert_payloads_ok()

    def test_excerpts_only_disables_workflow_commands(self):
        write_leg(self.art, "g1", {"a": "fail"})
        leg = self.art / "test-logs-nixos-g1-123-1"
        log = leg / "a.log"
        # Inside the FAILURES block, which is what the excerpt prints.
        log.write_text(log.read_text().replace("FAILURES (1 of 3):\n", "FAILURES (1 of 3):\n::add-mask::x\n::error::pwned\n"))
        r = subprocess.run([sys.executable, str(HERE / "test-report.py"), "--excerpts-only", str(leg)],
                           capture_output=True, text=True, env={**os.environ, "GITHUB_ACTIONS": "true"})
        assert_commands_stopped(self, r.stdout, "::error::pwned")
        r = subprocess.run([sys.executable, str(HERE / "test-report.py"), "--excerpts-only", str(self.tmp / "none")],
                           capture_output=True, text=True)
        self.assertIn("no test logs", r.stdout)

    def test_redact(self):
        s = tc.redact_text(f"a {SECRET} b {HOOK} access-tokens = github.com=xyz AGE-SECRET-KEY-1" + "Q" * 58)
        for leak in (SECRET, "abcDEF", "github.com=xyz", "QQQQQQ"):
            self.assertNotIn(leak, s)


class DiscoveryCase(unittest.TestCase):
    def tree(self):
        root = Path(tempfile.mkdtemp(prefix="disc-")) / "templates" / "tests"
        for cat in ("nixos", "common", "darwin"):
            (root / cat).mkdir(parents=True)
        (root / "nixos" / "test-a").mkdir()
        (root / "nixos" / "test-a" / "check-a.sh").write_text("exit 0\n")
        (root / "nixos" / "test-b" / "sub").mkdir(parents=True)
        (root / "nixos" / "test-b" / "sub" / "x_test.nix").write_text("{}\n")
        (root / "darwin" / "test-a").mkdir()
        (root / "darwin" / "test-a" / "check-a.sh").write_text("exit 0\n")
        return root

    def test_discovers_patterns_and_defaults(self):
        tests = {t["name"]: t for t in discover.discover(self.tree())}
        self.assertEqual(set(tests), {"nixos-a", "nixos-b", "darwin-a"})
        self.assertEqual(tests["nixos-b"]["group"], "harness")
        self.assertEqual(tests["nixos-b"]["kind"], "nix-tests")
        self.assertEqual(tests["darwin-a"]["platforms"], ["darwin"])
        self.assertEqual(discover.ci_groups(list(tests.values()), "linux"), ["harness", "nixos"])

    def test_unmatched_folder_fails(self):
        root = self.tree()
        (root / "nixos" / "test-empty").mkdir()
        (root / "nixos" / "test-empty" / "notes.md").write_text("x")
        with self.assertRaises(discover.DiscoveryError) as cm:
            discover.discover(root)
        self.assertIn("matches no test pattern", "\n".join(cm.exception.problems))

    def test_unknown_conf_key_and_dir_fail(self):
        root = self.tree()
        (root / "nixos" / "test-a" / "test.conf").write_text("groop = x\n")
        (root / "stray").mkdir()
        with self.assertRaises(discover.DiscoveryError) as cm:
            discover.discover(root)
        text = "\n".join(cm.exception.problems)
        self.assertIn("unknown key 'groop'", text)
        self.assertIn("unknown directory", text)

    def test_only_selector(self):
        tests = discover.discover(self.tree())
        self.assertEqual([t["name"] for t in discover.select(tests, only="nixos-a")], ["nixos-a"])
        with self.assertRaises(discover.DiscoveryError):
            discover.select(tests, only="a")  # ambiguous: nixos-a and darwin-a
        self.assertEqual([t["name"] for t in discover.select(tests, platform="linux", only="a")], ["nixos-a"])

    def test_step_budget_covers_every_cap(self):
        # The CI test step's timeout is derived from the group: a fixed step cap
        # under the group's summed caps could kill the leg before later tests ran.
        root = self.tree()
        (root / "nixos" / "test-a" / "test.conf").write_text("group = harness\ntimeout = 25\n")
        tests = discover.discover(root)
        b = discover.step_budgets(tests, "linux")
        self.assertEqual(set(b), {"harness"})
        self.assertGreaterEqual(b["harness"], 25 + 10 + 2)  # both caps + >= 1 min overhead per test
        self.assertEqual(b["harness"], discover.step_budget(tests, "linux", "harness"))

    def test_harness_is_pinned_to_a_rev(self):
        self.assertRegex(discover.NIX_TESTS_REV, r"^[0-9a-f]{40}$")
        self.assertIn(f"/{discover.NIX_TESTS_REV} --inputs-from . --override-input nixpkgs nixpkgs --",
                      discover.NIX_TESTS)
        tests = {t["name"]: t for t in discover.discover(self.tree())}
        self.assertTrue(tests["nixos-b"]["commands"][0].startswith(discover.NIX_TESTS + " "))

    def test_real_tree_discovers(self):
        tests = discover.discover()
        self.assertTrue(discover.ci_groups(tests, "linux"))
        self.assertTrue(discover.ci_groups(tests, "darwin"))


class RunTestCase(unittest.TestCase):
    def test_exit_code_timeout_and_redaction(self):
        d = Path(tempfile.mkdtemp(prefix="run-test-"))
        rt = str(HERE / "run-test.py")
        r = subprocess.run([sys.executable, rt, "--name", "f", "--log-dir", str(d), "--quiet", "--",
                            f"echo {SECRET}; exit 7"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 7)
        self.assertNotIn(SECRET, (d / "f.log").read_text())
        # Nix colours values: `\x1b[35;1m` + token. The `m` kills the regex's
        # `\b`, so redacting before stripping ANSI stored the token unredacted.
        tok = "ghs_" + "A" * 36
        r = subprocess.run([sys.executable, rt, "--name", "c", "--log-dir", str(d), "--",
                            "printf '\\033[35;1m%s\\033[0m\\n' \"$TOK\""], capture_output=True,
                           env={**os.environ, "TOK": tok})
        self.assertEqual(r.returncode, 0)
        self.assertNotIn(tok, (d / "c.log").read_text())
        self.assertIn("[REDACTED-GH-TOKEN]", (d / "c.log").read_text())
        self.assertNotIn(tok.encode(), r.stdout)  # the live echo too
        self.assertEqual(json.loads((d / "f.meta.json").read_text())["status"], "fail")
        r = subprocess.run([sys.executable, rt, "--name", "t", "--timeout", "0.02", "--log-dir", str(d),
                            "--quiet", "--", "sleep 30"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 124)
        self.assertEqual(json.loads((d / "t.meta.json").read_text())["status"], "timeout")


    def test_multiline_pem_is_redacted(self):
        # The pump redacts line by line, so the re.S PEM pattern never matched
        # and the key body reached the artifact and the live log (review F5).
        d = Path(tempfile.mkdtemp(prefix="run-test-"))
        body = ["b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW",
                "QyNTUxOQAAACBzZWNyZXRrZXlib2R5bGluZXR3b3NlY3JldGtleWJvZHkAAAAA"]
        script = ("echo before; echo '-----BEGIN OPENSSH PRIVATE KEY-----'; "
                  + "; ".join(f"echo {b}" for b in body)
                  + "; echo '-----END OPENSSH PRIVATE KEY-----'; echo after")
        r = subprocess.run([sys.executable, str(HERE / "run-test.py"), "--name", "pem", "--log-dir", str(d), "--",
                            script], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        log = (d / "pem.log").read_text()
        for b in body:
            self.assertNotIn(b, log)
            self.assertNotIn(b, r.stdout)
        self.assertIn("[REDACTED-PRIVATE-KEY]", log)
        self.assertIn("before", log)
        self.assertIn("after", log)

    def test_stream_redactor_and_whole_file_pass(self):
        sr = tc.StreamRedactor()
        out = b"".join(sr.feed(l) for l in [b"x -----BEGIN RSA PRIVATE KEY-----\n", b"SECRETBODY\n",
                                             b"-----END RSA PRIVATE KEY----- tail\n", b"next\n"])
        self.assertEqual(out, b"x [REDACTED-PRIVATE-KEY]\n tail\nnext\n")
        # A BEGIN with no END stops suppressing after PEM_MAX_LINES, with a marker.
        sr = tc.StreamRedactor()
        lines = [b"-----BEGIN PRIVATE KEY-----\n"] + [b"L\n"] * (tc.PEM_MAX_LINES + 3)
        out = b"".join(sr.feed(l) for l in lines)
        self.assertIn(b"stopped suppressing", out)
        self.assertEqual(out.count(b"L\n"), 3)
        # redact_file: the final pass over the finished log as one text.
        f = Path(tempfile.mkdtemp(prefix="rf-")) / "x.log"
        f.write_bytes(b"a\n-----BEGIN EC PRIVATE KEY-----\nSECRETBODY\n-----END EC PRIVATE KEY-----\nb\n")
        self.assertTrue(tc.redact_file(f))
        self.assertEqual(f.read_bytes(), b"a\n[REDACTED-PRIVATE-KEY]\nb\n")
        self.assertFalse(tc.redact_file(f))

    def test_workflow_commands_stopped_around_test_output(self):
        # A fork PR's test could print `::add-mask::` / `::error::` / `::set-output`
        # lines; GitHub runs any stdout line starting with `::`.
        d = Path(tempfile.mkdtemp(prefix="run-test-"))
        r = subprocess.run([sys.executable, str(HERE / "run-test.py"), "--name", "inj", "--log-dir", str(d), "--",
                            "echo '::add-mask::x'; echo '::error::pwned'; exit 3"], capture_output=True, text=True,
                           env={**os.environ, "GITHUB_ACTIONS": "true"})
        self.assertEqual(r.returncode, 3)
        end = assert_commands_stopped(self, r.stdout, "::error::pwned")
        ann = next(i for i, l in enumerate(r.stdout.splitlines()) if l.startswith("::error title=test inj"))
        self.assertGreater(ann, end)  # our own annotation still works

    def test_group_mode_expected_and_gate_exit(self):
        root = Path(tempfile.mkdtemp(prefix="grp-")) / "templates" / "tests"
        for cat in ("nixos", "common", "darwin"):
            (root / cat).mkdir(parents=True)
        for name, rc in (("ok", 0), ("bad", 1)):
            (root / "nixos" / f"test-{name}").mkdir()
            (root / "nixos" / f"test-{name}" / f"check-{name}.sh").write_text(f"echo running {name}\nexit {rc}\n")
        (root / "darwin" / "test-d").mkdir()
        (root / "darwin" / "test-d" / "check-d.sh").write_text("exit 0\n")
        d = Path(tempfile.mkdtemp(prefix="grp-logs-"))
        r = subprocess.run([sys.executable, str(HERE / "run-test.py"), "--platform", "linux", "--group", "nixos",
                            "--tests-root", str(root), "--log-dir", str(d)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)  # one test failed -> the leg's step fails
        self.assertEqual(json.loads((d / "_expected-linux-nixos.json").read_text()), ["nixos-bad", "nixos-ok"])
        self.assertEqual(json.loads((d / "nixos-ok.meta.json").read_text())["status"], "pass")
        self.assertIn("running bad", (d / "nixos-bad.log").read_text())
        self.assertFalse((d / "darwin-d.meta.json").exists())


    def _group(self, scripts):
        """A fixture tree with one nixos test per (name, script); returns (rc, stdout, log dir)."""
        root = Path(tempfile.mkdtemp(prefix="grp-")) / "templates" / "tests"
        for cat in ("nixos", "common", "darwin"):
            (root / cat).mkdir(parents=True)
        for name, body in scripts:
            (root / "nixos" / f"test-{name}").mkdir()
            (root / "nixos" / f"test-{name}" / f"check-{name}.sh").write_text(body)
        d = Path(tempfile.mkdtemp(prefix="grp-logs-"))
        r = subprocess.run([sys.executable, str(HERE / "run-test.py"), "--platform", "linux", "--group", "nixos",
                            "--tests-root", str(root), "--log-dir", str(d)], capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr, d

    @unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0, "root can read a mode-000 file")
    def test_unreadable_evidence_file_fails_that_test_and_group_continues(self):
        # no-early-stop probe-b: a test that leaves an unreadable file in
        # TEST_LOG_DIR used to raise PermissionError out of the group loop, so
        # every later test of the leg never ran.
        rc, out, d = self._group([
            ("a-unreadable", 'mkdir -p "$TEST_LOG_DIR"; echo raw > "$TEST_LOG_DIR/ev.stderr"\n'
                             'chmod 000 "$TEST_LOG_DIR/ev.stderr"; echo did-a\nexit 0\n'),
            ("b-after", "echo ran-after-a\nexit 0\n")])
        self.assertEqual(rc, 1, out)
        meta = json.loads((d / "nixos-a-unreadable.meta.json").read_text())
        self.assertEqual(meta["status"], "fail")
        self.assertEqual(meta["exit_code"], 70)
        self.assertIn("cannot read evidence file ev.stderr", meta["runner_error"])
        log = (d / "nixos-a-unreadable.log").read_text()
        self.assertIn("cannot read evidence file ev.stderr", log)
        self.assertIn("# status: fail", log)
        self.assertFalse((d / "nixos-a-unreadable.d").exists())  # raw evidence never kept
        self.assertEqual(json.loads((d / "nixos-b-after.meta.json").read_text())["status"], "pass")
        self.assertIn("ran-after-a", (d / "nixos-b-after.log").read_text())
        self.assertIn("1/2 passed in group nixos", out)

    def test_runner_exception_is_recorded_and_group_continues(self):
        # ANY exception in the runner while it handles one test: that test is
        # failed with the traceback in its log, and the next test still runs.
        # Here the test turns its own meta.json into a directory, so the
        # runner's final meta write raises IsADirectoryError.
        rc, out, d = self._group([
            ("a-crash", 'mkdir -p "$TEST_LOG_DIR"; m="$TEST_LOG_DIR/../nixos-a-crash.meta.json"; rm -f "$m"; mkdir "$m"\nexit 0\n'),
            ("b-after", "echo ran-after-crash\nexit 0\n")])
        self.assertEqual(rc, 1, out)
        log = (d / "nixos-a-crash.log").read_text()
        self.assertIn("RUNNER ERROR", log)
        self.assertIn("Traceback", log)
        self.assertIn("IsADirectoryError", log)
        self.assertIn("# status: fail", log)
        self.assertEqual(json.loads((d / "nixos-b-after.meta.json").read_text())["status"], "pass")
        self.assertIn("ran-after-crash", (d / "nixos-b-after.log").read_text())
        self.assertIn("1/2 passed in group nixos; not passing: nixos-a-crash", out)


if __name__ == "__main__":
    unittest.main(verbosity=1)
