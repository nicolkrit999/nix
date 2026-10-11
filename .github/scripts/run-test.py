#!/usr/bin/env python3
"""Run discovered tests with a COMPLETE per-test log, a timeout, and the real exit code.

  run-test.py --group G --platform linux|darwin [--log-dir D]    CI: every ci=true test of one matrix leg
  run-test.py --test NAME [--fast] [--quiet] [--log-dir D]         one discovered test (run-tests.sh)
  run-test.py --name N --timeout MIN [--log-dir D] -- CMD...       ad-hoc command (unit tests, debugging)

For each test it writes, under --log-dir (default ./test-logs):
  <name>.log        "# key: value" header (repo, sha, subject, nixpkgs rev, runner, nix,
                    commands, timeout, start), the full ANSI-stripped + redacted output of
                    every command (multi-line PEM keys dropped by a stateful pass, and the
                    finished file redacted again as a whole), an EVIDENCE section (the full stderr of every failing nix
                    call, kept by templates/tests/lib/evidence.sh), and a footer (end,
                    duration_s, exit_code, status)
  <name>.meta.json  the same facts as JSON; written as status "running" BEFORE the test
                    starts, so a hard kill leaves "running" behind (= killed, no footer)
  _expected-<platform>-<group>.json  (group mode) the names this leg was meant to run,
                    which is how test-report.py tells "never ran" from "failed"

Why Python and not `bash | tee`: under GitHub's `bash -e` (no pipefail) `false | tee`
exits 0; macOS ships bash 3.2 and no GNU `timeout`; and only a supervising process can
still write the footer when the test times out or the step is cancelled.

Status: pass | fail | timeout (exit 124, our own per-test deadline) | killed (we got
SIGTERM/SIGINT, e.g. the step timeout or a cancel; later tests of the group are then
not started and show up as "never ran").
In GitHub Actions the echoed test output sits between ::stop-commands::<random> and
::<random>::, so a test line starting with `::` is never run as a workflow command.
Runner errors never stop a group: an evidence file the runner cannot read is noted
in the log and fails that test, and ANY other exception inside the runner while it
handles one test is caught by run_one_safe(): the child is killed, the traceback is
appended to that test's log (a fresh log if the old one cannot be opened), its meta
says status "fail", exit 70 (EX_SOFTWARE) and runner_error, and the next test starts.
Exit: the test's exit code; --group: 1 if any test did not pass, 0 otherwise.
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import shutil  # noqa: E402
import signal  # noqa: E402
import subprocess  # noqa: E402
import threading  # noqa: E402
import time  # noqa: E402
import traceback  # noqa: E402
from pathlib import Path  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import testlog_common as tc  # noqa: E402

EVIDENCE_FILE_CAP = 2 * 1024 * 1024  # per kept file; head + tail beyond this
KILL_GRACE_S = 5
RUNNER_ERROR_RC = 70  # EX_SOFTWARE: the runner itself failed while handling this test

_stop = {"sig": None, "proc": None, "resume": ""}


def _killpg(p, sig):
    try:
        os.killpg(p.pid, sig)
    except (ProcessLookupError, PermissionError):
        pass


def _terminate(p):
    _killpg(p, signal.SIGTERM)
    try:
        p.wait(timeout=KILL_GRACE_S)
    except subprocess.TimeoutExpired:
        _killpg(p, signal.SIGKILL)


def _on_signal(signum, _frame):
    # The step being cancelled / timing out signals US: stop the test, still write the footer.
    _stop["sig"] = signum
    p = _stop["proc"]
    if p is not None:
        threading.Thread(target=_terminate, args=(p,), daemon=True).start()


def _annotate(name, rc, status, text):
    if not tc.IN_GHA:
        return
    msg = tc.excerpt(text, 3000) or f"exit {rc}"
    msg = msg.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::error title=test {name}: {status} (exit {rc})::{msg}", flush=True)


def _merge_evidence(ev_dir: Path, f, errors: list):
    """Append every kept evidence file. A file the runner cannot read (the test left
    it mode 000, it vanished, ...) is noted in the log and added to `errors`, which
    fails the test; it never aborts the merge or the group (no-early-stop probe-b)."""
    if not ev_dir.is_dir():
        return

    def mtime(p):
        try:
            return p.stat().st_mtime
        except OSError:
            return 0.0

    files = sorted((p for p in ev_dir.iterdir() if p.is_file()), key=lambda p: (mtime(p), p.name))
    if files:
        f.write(("\n" + tc.EVIDENCE_MARK + "\n").encode())
        for p in files:
            try:
                data = p.read_bytes()
            except OSError as e:
                note = f"[run-test.py] runner error: cannot read evidence file {p.name}: {e}"
                errors.append(note)
                f.write(f"----- {p.name} -----\n{note}\n".encode())
                continue
            if len(data) > EVIDENCE_FILE_CAP:
                half = EVIDENCE_FILE_CAP // 2
                data = data[:half // 4] + b"\n[... evidence cut ...]\n" + data[-half:]
            f.write(f"----- {p.name} -----\n".encode())
            f.write(tc.redact(tc.ANSI.sub(b"", data)))
            if not data.endswith(b"\n"):
                f.write(b"\n")
    shutil.rmtree(ev_dir, ignore_errors=True)  # raw (unredacted) copies never reach an artifact


def run_one(name, commands, timeout_min, log_dir: Path, ctx, echo=True, extra_meta=None, cwd=None) -> int:
    log_dir.mkdir(parents=True, exist_ok=True)
    log, meta_p, ev_dir = log_dir / f"{name}.log", log_dir / f"{name}.meta.json", log_dir / f"{name}.d"
    shutil.rmtree(ev_dir, ignore_errors=True)
    started = tc.now()
    meta = {**ctx, **(extra_meta or {}), "name": name, "commands": commands, "timeout_min": timeout_min,
            "log_dir": str(log_dir), "start": started.isoformat(timespec="seconds"), "status": "running"}
    meta_p.write_text(json.dumps(meta, indent=1))
    env = {**os.environ, "TEST_LOG_DIR": str(ev_dir.resolve()), "FLAKE_ROOT": os.environ.get("FLAKE_ROOT", str(tc.ROOT))}
    # Full eval traces in the log. CI also sets show-trace in nix.conf (show-trace invariant).
    if "show-trace" not in env.get("NIX_CONFIG", ""):
        env["NIX_CONFIG"] = (env.get("NIX_CONFIG", "") + "\nshow-trace = true").lstrip("\n")
    deadline = time.monotonic() + timeout_min * 60
    timed_out = False
    rc = 0
    per_cmd = []
    tail = []
    runner_errors = []  # problems of the runner itself; any one fails the test

    with open(log, "wb") as f:
        hdr = "".join(f"# {k}: {v}\n" for k, v in meta.items() if k not in ("status", "commands", "log_dir"))
        hdr += "".join(f"# command {i + 1}/{len(commands)}: {c}\n" for i, c in enumerate(commands))
        f.write(tc.redact(hdr.encode()) + (tc.SEP + "\n").encode())
        f.flush()
        # Test output is untrusted on a fork PR: a stdout line starting with
        # `::` would run as a workflow command (::add-mask::, ::error::, ...).
        # Commands stay off while it is echoed (the scope is this step only);
        # our own annotation below comes after the resume.
        resume = tc.stop_commands() if echo else ""
        _stop["resume"] = resume  # run_one_safe resumes it if we crash before the resume below
        for i, cmd in enumerate(commands):
            if _stop["sig"] or timed_out:
                break
            if len(commands) > 1:
                banner = f"\n===== command {i + 1}/{len(commands)}: {cmd} =====\n".encode()
                f.write(banner)
                if echo:
                    sys.stdout.buffer.write(banner); sys.stdout.buffer.flush()
            t0 = time.monotonic()
            p = subprocess.Popen(["bash", "-c", cmd], cwd=cwd or tc.ROOT, env=env, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, start_new_session=True)
            _stop["proc"] = p

            def pump(p=p, sr=tc.StreamRedactor()):
                broken = False
                for raw in iter(p.stdout.readline, b""):
                    if broken:  # keep draining so the child never blocks on a full pipe
                        continue
                    try:
                        _pump_line(raw, sr)
                    except Exception as e:  # noqa: BLE001 - recorded, fails the test
                        broken = True
                        runner_errors.append(f"[run-test.py] runner error: output pump failed: {e!r}")

            def _pump_line(raw, sr):
                # Strip ANSI FIRST, then redact. Nix colours values
                # (`\x1b[35;1m`): the `m` before `ghs_...` kills the `\b`
                # the token regex needs, so redact-then-strip stored a
                # coloured token in the public artifact (review finding).
                # StreamRedactor also drops the body of a multi-line PEM
                # key, which no per-line regex can match (review F5).
                plain = tc.ANSI.sub(b"", raw)
                clean = sr.feed(plain)
                if echo:
                    # Keep colours on the live log unless the line held a
                    # secret; then echo the redacted plain line instead.
                    live = tc.redact(raw) if clean == plain else clean
                    sys.stdout.buffer.write(live); sys.stdout.buffer.flush()
                if not clean:
                    return
                f.write(clean)
                f.flush()
                tail.append(clean.decode("utf-8", "replace").rstrip("\n"))
                del tail[:-400]
            reader = threading.Thread(target=pump, daemon=True)
            reader.start()
            while True:
                try:
                    crc = p.wait(timeout=max(0.1, min(1.0, deadline - time.monotonic())))
                    break
                except subprocess.TimeoutExpired:
                    if time.monotonic() >= deadline and not timed_out:
                        timed_out = True
                        msg = f"\n[run-test.py] per-test timeout of {timeout_min} min reached - killing the test\n"
                        f.write(msg.encode()); f.flush()
                        if echo:
                            print(msg, flush=True)
                        _terminate(p)
            if crc < 0:  # killed by a signal: report it the shell way (128 + n), never negative
                crc = 128 - crc
            reader.join(timeout=10)  # an orphan holding the pipe must not hang us
            _stop["proc"] = None
            per_cmd.append({"command": cmd, "exit_code": crc, "duration_s": round(time.monotonic() - t0)})
            if crc != 0 and rc == 0:
                rc = crc
        tc.resume_commands(resume)
        _stop["resume"] = ""
        _merge_evidence(ev_dir, f, runner_errors)
        if timed_out:
            status, rc = "timeout", 124
        elif _stop["sig"]:
            status, rc = "killed", (rc or 128 + _stop["sig"])
        else:
            status = "pass" if rc == 0 and not runner_errors else "fail"
            if runner_errors and rc == 0:
                rc = RUNNER_ERROR_RC
        if runner_errors:
            meta["runner_error"] = "; ".join(runner_errors)
            f.write(("\n" + "\n".join(runner_errors) + "\n").encode())
            if echo:
                print("\n".join(runner_errors), flush=True)
        end = tc.now()
        meta.update(end=end.isoformat(timespec="seconds"), duration_s=round((end - started).total_seconds()),
                    exit_code=rc, status=status, per_command=per_cmd)
        f.write(("\n" + tc.SEP + "\n" + "".join(f"# {k}: {meta[k]}\n" for k in
                 ("end", "duration_s", "exit_code", "status"))).encode())
    # Belt and braces: redact the finished log as ONE text, so a secret the
    # line-by-line pass could not see (one spanning lines) is still caught.
    tc.redact_file(log)
    meta_p.write_text(json.dumps(meta, indent=1))
    if status != "pass":
        _annotate(name, rc, status, log.read_text(errors="replace"))
    return rc


def _record_runner_error(name, commands, timeout_min, log_dir: Path, ctx, extra_meta, tb: str) -> int:
    """run_one raised: record THIS test as failed with the traceback, never raise."""
    p = _stop["proc"]
    if p is not None:
        try:
            if p.poll() is None:
                _terminate(p)
        except Exception:  # noqa: BLE001
            pass
        _stop["proc"] = None
    if _stop.get("resume"):  # crashed while workflow commands were stopped: turn them back on
        tc.resume_commands(_stop["resume"])
        _stop["resume"] = ""
    status = "killed" if _stop["sig"] else "fail"
    rc = 128 + _stop["sig"] if _stop["sig"] else RUNNER_ERROR_RC
    text = tc.redact(tc.ANSI.sub(b"", tb.encode())).decode("utf-8", "replace")
    block = (f"\n===== RUNNER ERROR (run-test.py crashed while handling {name}; the test is recorded as "
             f"{status} and the group continues) =====\n{text}\n{tc.SEP}\n# end: {tc.now().isoformat(timespec='seconds')}"
             f"\n# exit_code: {rc}\n# status: {status}\n")
    print(block, flush=True)
    log_dir = Path(log_dir)
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass
    for target in (log_dir / f"{name}.log", log_dir / f"{name}.runner-error.log"):
        try:
            with open(target, "ab") as fh:
                fh.write(block.encode())
            break
        except OSError:
            continue
    meta = {**ctx, **(extra_meta or {}), "name": name, "commands": commands, "timeout_min": timeout_min,
            "log_dir": str(log_dir), "exit_code": rc, "status": status,
            "runner_error": text.strip().splitlines()[-1] if text.strip() else "unknown"}
    try:
        old = json.loads((log_dir / f"{name}.meta.json").read_text())
        meta = {**old, **meta}
    except Exception:  # noqa: BLE001 - no or unreadable meta: write ours
        pass
    try:
        (log_dir / f"{name}.meta.json").write_text(json.dumps(meta, indent=1))
    except OSError as e:
        print(f"[run-test.py] could not write {name}.meta.json either: {e}", flush=True)
    shutil.rmtree(log_dir / f"{name}.d", ignore_errors=True)  # raw evidence never reaches an artifact
    try:
        _annotate(name, rc, status, text)
    except Exception:  # noqa: BLE001
        pass
    return rc


def run_one_safe(name, commands, timeout_min, log_dir: Path, ctx, echo=True, extra_meta=None, cwd=None) -> int:
    """run_one, but an exception in the RUNNER fails this one test instead of the whole
    group (no-early-stop requirement): the remaining tests of the leg still run."""
    try:
        return run_one(name, commands, timeout_min, log_dir, ctx, echo=echo, extra_meta=extra_meta, cwd=cwd)
    except Exception:  # noqa: BLE001 - SystemExit/KeyboardInterrupt still propagate
        return _record_runner_error(name, commands, timeout_min, log_dir, ctx, extra_meta, traceback.format_exc())


def commands_for(t, fast=False):
    cmds = []
    for c in t["commands"]:
        if fast and t.get("fast_args") and c.startswith("bash "):
            c = f"{c} {t['fast_args']}"
        cmds.append(c)
    return cmds


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--group")
    ap.add_argument("--platform", choices=("linux", "darwin"))
    ap.add_argument("--test", help="one discovered test (name, folder or unique suffix)")
    ap.add_argument("--name")
    ap.add_argument("--timeout", type=float, default=10)
    ap.add_argument("--fast", action="store_true")
    ap.add_argument("--quiet", action="store_true", help="do not echo test output (log file only)")
    ap.add_argument("--log-dir", default=str(tc.ROOT / "test-logs"))
    ap.add_argument("--tests-root", help=argparse.SUPPRESS)  # unit tests: a fixture templates/tests tree
    ap.add_argument("cmd", nargs=argparse.REMAINDER)
    a = ap.parse_args()
    for s in (signal.SIGTERM, signal.SIGINT):
        signal.signal(s, _on_signal)
    log_dir = Path(a.log_dir).resolve()
    ctx = tc.context()
    troot = Path(a.tests_root).resolve() if a.tests_root else None
    cwd = troot.parents[1] if troot else tc.ROOT

    if a.group:
        if not a.platform:
            ap.error("--group needs --platform")
        try:
            tests = tc.discover.select(tc.discover.discover(troot), a.platform, ci_only=True, group=a.group)
        except tc.discover.DiscoveryError as e:
            print("TEST DISCOVERY FAILED:\n  - " + "\n  - ".join(e.problems), flush=True)
            return 2
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / f"_expected-{a.platform}-{a.group}.json").write_text(json.dumps([t["name"] for t in tests]))
        if not tests:
            print(f"::error::group {a.group!r} has no tests for platform {a.platform}", flush=True)
            return 2
        results = []
        for t in tests:
            if _stop["sig"]:
                print(f"- {t['name']}: not started (runner got signal {_stop['sig']})", flush=True)
                results.append((t["name"], None))
                continue
            print(f"::group::test {t['name']}" if tc.IN_GHA else f"━━━ {t['name']} ━━━", flush=True)
            rc = run_one_safe(t["name"], commands_for(t), t["timeout_min"], log_dir, {**ctx, "group": a.group},
                         extra_meta={"folder": t["folder"], "readme": t["readme"], "platform": a.platform}, cwd=cwd)
            if tc.IN_GHA:
                print("::endgroup::", flush=True)
            print(f"{'✓' if rc == 0 else '✗'} {t['name']} (exit {rc})", flush=True)
            results.append((t["name"], rc))
        bad = [n for n, rc in results if rc != 0]
        print(f"\n{len(results) - len(bad)}/{len(results)} passed in group {a.group}"
              + (f"; not passing: {' '.join(bad)}" if bad else ""), flush=True)
        return 1 if bad else 0

    if a.test:
        try:
            (t,) = tc.discover.select(tc.discover.discover(troot), only=a.test)
        except tc.discover.DiscoveryError as e:
            print("TEST DISCOVERY FAILED:\n  - " + "\n  - ".join(e.problems), file=sys.stderr)
            return 2
        return run_one_safe(t["name"], commands_for(t, a.fast), t["timeout_min"], log_dir, {**ctx, "group": t["group"]},
                       echo=not a.quiet, extra_meta={"folder": t["folder"], "readme": t["readme"]}, cwd=cwd)

    cmd = a.cmd[1:] if a.cmd[:1] == ["--"] else a.cmd
    if not a.name or not cmd:
        ap.error("need --group, --test, or --name N -- CMD")
    return run_one_safe(a.name, [" ".join(cmd)], a.timeout, log_dir, ctx, echo=not a.quiet)


if __name__ == "__main__":
    sys.exit(main())
