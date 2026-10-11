#!/usr/bin/env python3
"""Repo-specific invariants for the CI workflows.

Every check here encodes a bug that actually happened in this repository, with
the run number that exposed it. This is deliberately NOT a general-purpose
linter - actionlint already covers generic Actions mistakes. What it protects is
the one property those generic tools cannot know about:

    whatever CI manages to build MUST end up in the Cachix cache, and a failure
    to do so must never be silent.

Run:  python3 .github/scripts/check-workflow-invariants.py
Exit: 0 = clean, 1 = at least one invariant violated.
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

WORKFLOW_DIR = Path(__file__).resolve().parents[1] / "workflows"

# Workflows whose whole reason to exist is populating the binary cache. The
# push-specific invariants apply only to these; tests-*.yml and update-flake.yml
# are not cache producers.
CACHE_PRODUCERS = {"build.yml", "build-darwin.yml"}

# The templates/tests workflows. Their invariants (check_test_workflow) all come
# from I-06: from the day they were written until 2026-10-10 a failing test could
# NOT turn these runs red, and the only evidence they kept was 3 grep'd lines.
TEST_WORKFLOWS = {"tests-nixos.yml", "tests-darwin.yml"}
REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_REPORT = REPO_ROOT / ".github" / "scripts" / "test-report.py"
TESTS_ROOT = REPO_ROOT / "templates" / "tests"

failures = []
warnings = []
checked = 0


def fail(wf, job, step, check, msg):
    where = f"{wf} :: {job}"
    if step:
        where += f" :: {step}"
    failures.append(f"[{check}] {where}\n    {msg}")


def effective_env(wf_doc, job, step):
    """Env a step actually sees: workflow-level, then job, then step."""
    env = {}
    for src in (wf_doc.get("env") or {}, (job.get("env") or {}), (step.get("env") or {})):
        env.update(src)
    return env


def step_name(step, idx):
    return step.get("name") or step.get("uses") or f"step #{idx}"


def check_workflow(path):
    global checked
    wf = path.name
    doc = yaml.safe_load(path.read_text())
    if not doc or "jobs" not in doc:
        return

    for job_name, job in doc["jobs"].items():
        steps = job.get("steps") or []
        declared_ids = {s["id"] for s in steps if "id" in s}
        coe_ids = {
            s["id"] for s in steps
            if "id" in s and s.get("continue-on-error") is True
        }

        # Index of the first step that pushes to Cachix, for ordering checks.
        push_idx = None
        for i, s in enumerate(steps):
            if re.search(r"\bcachix\s+push\b", s.get("run") or ""):
                push_idx = i if push_idx is None else push_idx

        for i, step in enumerate(steps):
            name = step_name(step, i)
            run = step.get("run") or ""
            env = effective_env(doc, job, step)
            cond = str(step.get("if", ""))

            # 1. Anything invoking the cachix CLI to WRITE must have the variable
            #    the CLI actually reads. Run 1111: the prewarm push step set only
            #    CACHIX_TOKEN, cachix reads CACHIX_AUTH_TOKEN, so it failed with
            #    "Neither auth token nor signing key are present." on every leg of
            #    every run - and continue-on-error reported the step as SUCCESS.
            if re.search(r"\bcachix\s+(push|watch-exec)\b", run):
                checked += 1
                if "CACHIX_AUTH_TOKEN" not in env:
                    fail(wf, job_name, name, "cachix-auth",
                         "invokes `cachix push`/`watch-exec` but CACHIX_AUTH_TOKEN is not in "
                         "its effective env. cachix reads CACHIX_AUTH_TOKEN; a guard variable "
                         "such as CACHIX_TOKEN does not authenticate anything. (run 1111)")

            if wf in CACHE_PRODUCERS and re.search(r"\bcachix\s+push\b", run):
                # 2. Salvaging a broken run is the entire point: the push must run
                #    even when the build failed, timed out, or was cancelled.
                checked += 1
                if "always()" not in cond:
                    fail(wf, job_name, name, "push-always",
                         "pushes to Cachix but its `if:` does not use always(). Without a "
                         "status function the step is SKIPPED once the job has failed, which "
                         "is precisely when there is most to salvage.")

                # 3. Pushing is a secondary goal and must never fail the job.
                checked += 1
                if step.get("continue-on-error") is not True:
                    fail(wf, job_name, name, "push-non-fatal",
                         "pushes to Cachix but is not continue-on-error: true. A Cachix "
                         "outage must not turn a successful build into a failed job.")

            # 4. A reference to a step id that does not exist in the SAME job
            #    silently evaluates to the empty string - it does not error. That
            #    is how a notifier condition came to test a step nothing declared.
            # env values count too: `X: ${{ steps.y.outcome }}` is the usual way
            # a run script reads a step result.
            envs = " ".join(str(v) for v in (step.get("env") or {}).values())
            for ref in re.findall(r"steps\.([A-Za-z0-9_-]+)\.", run + " " + cond + " " + envs):
                checked += 1
                if ref not in declared_ids:
                    fail(wf, job_name, name, "step-ref",
                         f"references steps.{ref}.* but no step with id '{ref}' is declared "
                         f"in job '{job_name}'. Cross-job references evaluate to '' silently.")

            # 5. On a continue-on-error step .conclusion is ALWAYS 'success'.
            #    Testing it is dead code; .outcome carries the truth.
            for ref in re.findall(r"steps\.([A-Za-z0-9_-]+)\.conclusion", run + " " + cond + " " + envs):
                checked += 1
                if ref in coe_ids:
                    fail(wf, job_name, name, "outcome-not-conclusion",
                         f"tests steps.{ref}.conclusion, but '{ref}' is continue-on-error, so "
                         f"its conclusion is always 'success'. Use steps.{ref}.outcome.")

            # 6. GitHub runs these with `bash -e`, NOT `-o pipefail`. A pipe into
            #    tee or cachix therefore reports the LAST command's status and
            #    masks the real failure - the silent-success shape again.
            if run and re.search(r"\|\s*(tee|cachix)\b", run):
                checked += 1
                if "set -o pipefail" not in run and "set -eo pipefail" not in run:
                    fail(wf, job_name, name, "pipefail",
                         "pipes into tee/cachix without `set -o pipefail`. Under bash -e the "
                         "pipeline's exit status is the last command's, so an upstream failure "
                         "is masked and the step reports success having done nothing.")

            # 7. A single-quoted variable holding a command that is later handed to
            #    `bash -c` must not contain bare newlines: bash -c reads each line
            #    as a separate command. Caught once before it shipped, in the
            #    BUILD='nix build ...' variable.
            if "bash -c" in run:
                for var, body in re.findall(r"^\s*([A-Z_][A-Z0-9_]*)='([^']*)'", run, re.M):
                    if f'"${var}"' in run or f"${var}" in run:
                        checked += 1
                        if "\n" in body:
                            lines = [l.rstrip() for l in body.split("\n") if l.strip()]
                            if any(not l.endswith("\\") for l in lines[:-1]):
                                fail(wf, job_name, name, "bash-c-newline",
                                     f"${var} spans multiple lines without backslash "
                                     f"continuations and is passed to `bash -c`, which reads "
                                     f"each line as its own command.")

            # 8. Anything that walks the whole store before the push can eat the
            #    entire cancellation grace window. Run 1095: `du -sh /nix/store`
            #    took over ten minutes and was SIGTERM'd (exit 143) before the
            #    push could run. df reports the actionable number instantly.
            if push_idx is not None and i < push_idx:
                checked += 1
                if re.search(r"\bdu\s+-[a-z]*s[a-z]*\b.*/nix/store", run):
                    fail(wf, job_name, name, "grace-window",
                         "walks /nix/store with `du` BEFORE the Cachix push. On a cancelled "
                         "run this consumes the grace window and the push never happens. "
                         "Use `df -h /nix`. (run 1095)")

            # 9. Matrix legs share github.run_id and github.run_attempt, so a cache
            #    key that does not mention the matrix variable collides between
            #    legs of the same run and one leg's store is lost.
            # A restore-only step (cache-nix-action/restore) saves nothing, so legs
            # sharing one read-only key cannot collide - tests-nixos.yml's matrix
            # legs all restore build.yml's same-lock cache that way on purpose.
            uses = step.get("uses", "")
            if uses.startswith("nix-community/cache-nix-action") and "/restore@" not in uses:
                key = str((step.get("with") or {}).get("primary-key", ""))
                matrix = (job.get("strategy") or {}).get("matrix") or {}
                if matrix and key:
                    checked += 1
                    if not any(f"matrix.{k}" in key for k in matrix):
                        fail(wf, job_name, name, "matrix-cache-key",
                             f"job '{job_name}' is a matrix but its cache primary-key names no "
                             f"matrix variable. All legs of a run share run_id/run_attempt, so "
                             f"the keys collide.")

            # 10. A step that shells out to a package manager must declare
            #     timeout-minutes. continue-on-error and `|| true` cover a step
            #     FAILING; neither covers it HANGING. Run 1130: apt-get stalled on
            #     an unreachable mirror, the step sat 27+ minutes holding the job
            #     toward its cap, and it blocked every later run in the same
            #     concurrency group - and the runner was unreachable, so a manual
            #     Cancel could not be delivered either.
            # The verb may be separated from the command by any number of flags
            # or their values (`apt-get -y install`, `apt-get -o Acquire::Retries=3
            # update`), so intervening tokens are allowed - but bounded by shell
            # separators so a match cannot run past the end of the command.
            _PKG = r"(?:apt-get|apt|yum|dnf|brew|pacman|apk|zypper)"
            _VERB = r"(?:update|upgrade|install|add)"
            if re.search(rf"\b{_PKG}\b(?:\s+(?!{_VERB}\b)[^\s;|&]+)*\s+{_VERB}\b", run):
                checked += 1
                if step.get("timeout-minutes") is None:
                    fail(wf, job_name, name, "package-manager-timeout",
                         "shells out to a package manager without timeout-minutes. "
                         "continue-on-error and `|| true` cover failure, not hanging - a "
                         "stalled mirror can hold the job to its cap and block every later "
                         "run in the concurrency group. (run 1130)")

            # 11. A best-effort optimisation action must never be able to fail a
            #     job. nothing-but-nix frees disk; it is a speedup, not a
            #     correctness requirement. build.yml guarded it, tests-nixos.yml
            #     did not, and on 2026-08-19 it failed there and skipped all six
            #     tests - which the summary then reported as six FAILURES.
            if "wimpysworld/nothing-but-nix" in step.get("uses", ""):
                checked += 1
                if step.get("continue-on-error") is not True:
                    fail(wf, job_name, name, "besteffort-non-fatal",
                         "uses nothing-but-nix without continue-on-error: true. It frees "
                         "disk as an optimisation and must never fail a job on its own.")

            # 12. Every curl to a Discord webhook must use --fail. Without it curl
            #     exits 0 on an HTTP 4xx/5xx, so a rotated or revoked webhook token
            #     reports a delivered notification that never arrived.
            if "WEBHOOK_URL" in run and "curl" in run:
                checked += 1
                if not re.search(r"curl[^\n]*--fail", run):
                    fail(wf, job_name, name, "webhook-curl-fail",
                         "curls the Discord webhook without --fail. curl exits 0 on HTTP "
                         "4xx/5xx, so a rotated or revoked token is reported as a delivered "
                         "notification that in fact never arrived.")

            # 13. A notifier that can fire without a webhook configured spams
            #     errors; one that is not continue-on-error can fail the job for a
            #     Discord outage.
            if "discord.com/api/webhooks" in str(step.get("env", {})) or "WEBHOOK_URL" in run:
                checked += 1
                if step.get("continue-on-error") is not True:
                    fail(wf, job_name, name, "notify-non-fatal",
                         "posts to Discord but is not continue-on-error: true. A webhook "
                         "outage must not fail the job.")
                checked += 1
                if "WEBHOOK_ID" not in cond:
                    fail(wf, job_name, name, "notify-guard",
                         "posts to Discord without guarding on env.WEBHOOK_ID != ''. On a "
                         "fork with no secrets this curls a malformed URL every run.")


def check_cache_keys(path):
    """14. A restore prefix that matches no save key means the job silently always
    runs cold. Introduced for real by reordering a matrix variable into the middle
    of the save key while a sibling job still restored the old prefix - nothing
    errors, the cache simply never hits again.
    """
    global checked
    wf = path.name
    doc = yaml.safe_load(path.read_text())
    if not doc or "jobs" not in doc:
        return

    save_keys = []
    for job in doc["jobs"].values():
        for st in job.get("steps") or []:
            if st.get("uses", "").startswith("nix-community/cache-nix-action/save"):
                k = str((st.get("with") or {}).get("primary-key", ""))
                if k:
                    save_keys.append(k)
    if not save_keys:
        return

    for job_name, job in doc["jobs"].items():
        for i, st in enumerate(job.get("steps") or []):
            if not st.get("uses", "").startswith("nix-community/cache-nix-action/restore"):
                continue
            prefixes = str((st.get("with") or {}).get("restore-prefixes-first-match", ""))
            for pref in [p.strip() for p in prefixes.splitlines() if p.strip()]:
                checked += 1
                if not any(k.startswith(pref) for k in save_keys):
                    fail(wf, job_name, step_name(st, i), "cache-prefix-match",
                         f"restore prefix '{pref}' is not a prefix of ANY save key in this "
                         f"workflow, so it can never hit. The job will silently run cold "
                         f"forever. Save keys: {save_keys}")


def check_push_count(path):
    """15. `cachix push` prints a summary header line ("Pushing 14 paths (2089 are
    already present) ...") in addition to one "Pushing /nix/store/..." line per
    path. Counting with a bare '^Pushing ' therefore returns N+1 whenever anything
    was pushed. Run 1136's flake-check reported pushed=15 for exactly 14 uploaded
    paths, and that inflated number is what reaches Discord and the job summary.

    The zero case still behaved (cachix prints "Nothing to push ..." with no
    Pushing line at all), which is why the "0 pushed after a failed build" alarm
    never caught it and the bug survived several runs.
    """
    global checked
    wf = path.name
    if wf not in CACHE_PRODUCERS:
        return
    doc = yaml.safe_load(path.read_text())
    if not doc or "jobs" not in doc:
        return

    for job_name, job in doc["jobs"].items():
        for i, st in enumerate(job.get("steps") or []):
            run = st.get("run") or ""
            if "grep -c" not in run or "Pushing" not in run:
                continue
            for m in re.finditer(r"grep -c\s+(['\"])\^Pushing(.*?)\1", run):
                checked += 1
                if not m.group(2).startswith(" /nix/store/"):
                    fail(wf, job_name, step_name(st, i), "push-count-anchored",
                         f"counts pushed paths with '^Pushing{m.group(2)}' instead of "
                         f"anchoring on the store path. Only '^Pushing /nix/store/' counts "
                         f"exactly the per-path lines; a bare '^Pushing ' also matches "
                         f"cachix's summary header and overcounts by 1.")



# ── templates/tests workflows (tests-nixos.yml, tests-darwin.yml) ─────────────
def _is_discord_step(step):
    return "discord.com/api/webhooks" in str(step.get("env", {})) or "WEBHOOK_URL" in (step.get("run") or "")


def _runs_test_runner(step):
    return "run-test.py" in (step.get("run") or "")


def _mentions_tests(run):
    """A `run:` that executes something from the test suite (other than discovery)."""
    r = run.replace("templates/tests/lib/discover.py", "")
    return bool(re.search(r"templates/tests/|\bnix-tests\b|\bcheck-[\w-]+\.sh\b", r))


def _is_test_job(job):
    return any(_runs_test_runner(s) or _mentions_tests(s.get("run") or "") for s in job.get("steps") or [])


def _needs(job):
    n = job.get("needs") or []
    return [n] if isinstance(n, str) else list(n)


_DISC = {}


def _discovery():
    """(discover module, discovered tests) for TESTS_ROOT, or (module|None, None)
    when it cannot load / discover (check_discovery reports why)."""
    key = str(TESTS_ROOT)
    if key not in _DISC:
        sys.path.insert(0, str(REPO_ROOT / "templates" / "tests" / "lib"))
        sys.dont_write_bytecode = True
        try:
            import discover
        except Exception:  # pragma: no cover
            _DISC[key] = (None, None)
            return _DISC[key]
        try:
            _DISC[key] = (discover, discover.discover(TESTS_ROOT))
        except discover.DiscoveryError:
            _DISC[key] = (discover, None)
    return _DISC[key]


STEP_TIMEOUT_EXPR = re.compile(
    r"^\$\{\{\s*fromJSON\(\s*needs\.([\w-]+)\.outputs\.step_timeouts\s*\)\[\s*matrix\.group\s*\]\s*\}\}$")


def check_test_workflow(path):
    """16-32. The test-suite invariants. Origin: I-06 (2026-10-10); 28-32 come from
    the CI security review of the same day (71-ci-security-review.md).
    tests-nixos.yml / tests-darwin.yml had every test step AND the summary step
    continue-on-error, the only `exit 1` lived in the Discord step, so runs
    38081705833, 38007227840 and 37927344217 had failing tests and concluded
    SUCCESS - and without the webhook secret not even that step ran."""
    global checked
    wf = path.name
    if wf not in TEST_WORKFLOWS:
        return
    doc = yaml.safe_load(path.read_text())
    if not doc or "jobs" not in doc:
        return
    jobs = doc["jobs"]
    test_jobs = {n: j for n, j in jobs.items() if _is_test_job(j)}
    checked += 1
    if not test_jobs:
        fail(wf, "-", None, "test-runner-wrapper",
             "no job runs .github/scripts/run-test.py - the test suite is not run at all.")
        return

    discover_jobs = {n for n, j in jobs.items()
                     if any("templates/tests/lib/discover.py" in (s.get("run") or "") and "--matrix" in (s.get("run") or "")
                            for s in j.get("steps") or [])}
    plat = "linux" if wf == "tests-nixos.yml" else "darwin"

    # 28. test-trigger: pull_request_target / workflow_run run in the BASE repo's
    #     context with its secrets; on a test workflow that checks out and runs
    #     PR code, a fork PR would get the webhook secret (security review F6).
    on = doc.get("on", doc.get(True)) or {}
    triggers = [on] if isinstance(on, str) else list(on)
    checked += 1
    bad_trig = sorted(set(triggers) & {"pull_request_target", "workflow_run"})
    if bad_trig:
        fail(wf, "-", None, "test-trigger",
             f"trigger(s) {', '.join(bad_trig)} run fork-PR code with this repo's secrets and a "
             "write token. Test workflows use `pull_request` (read-only token, no secrets on forks).")

    # 29. test-job-unconditional: a job-level continue-on-error makes a red leg
    #     count as success in the run conclusion; a job-level if: can skip the
    #     legs (and with them the gate) - either turns failing tests green.
    for jn in sorted(set(test_jobs) | discover_jobs):
        job = jobs[jn]
        checked += 1
        problems = []
        if "continue-on-error" in job and job["continue-on-error"] is not False:
            problems.append("job-level continue-on-error (a red leg would not fail the run)")
        if "if" in job:
            problems.append(f"job-level `if: {job['if']}` (a skipped leg runs no gate)")
        if problems:
            fail(wf, jn, None, "test-job-unconditional",
                 "; ".join(problems) + ". The test and discover jobs must always run and always count.")

    # 30. checkout-no-persist: tests run arbitrary bash in the checkout, and
    #     persist-credentials (the default) leaves GITHUB_TOKEN base64-encoded in
    #     .git/config, a form no redaction pattern matches (security review F8).
    for jn, job in jobs.items():
        for i, st in enumerate(job.get("steps") or []):
            if str(st.get("uses", "")).startswith("actions/checkout@"):
                checked += 1
                if str((st.get("with") or {}).get("persist-credentials", "")).lower() != "false":
                    fail(wf, jn, step_name(st, i), "checkout-no-persist",
                         "actions/checkout must set `persist-credentials: false` in a test workflow.")

    # 31. stop-commands: printing a file (HANDOFF.md quotes test output, which a
    #     fork PR controls) runs any line starting with `::` as a workflow command.
    for jn, job in jobs.items():
        for i, st in enumerate(job.get("steps") or []):
            run = st.get("run") or ""
            if re.search(r"^\s*cat\s+[^|>]*$", run, re.M):
                checked += 1
                if "::stop-commands::" not in run:
                    fail(wf, jn, step_name(st, i), "stop-commands",
                         "prints a file into the job log without `::stop-commands::<token>` ... "
                         "`::<token>::` around it: a line starting with `::` in it would run as a "
                         "workflow command (::add-mask::, ::error::, ...).")

    # 26. test-discovery: the matrix comes from discovery, never a hand-written list.
    checked += 1
    if not discover_jobs:
        fail(wf, "-", None, "test-discovery",
             "no job runs `templates/tests/lib/discover.py --matrix`. The groups must come from "
             "discovery; a hand-maintained list drifted before (unstable-switch was registered "
             "locally and never run in CI).")
    for dn in discover_jobs:
        runs = " ".join(s.get("run") or "" for s in jobs[dn].get("steps") or [])
        checked += 1
        if f"--platform {plat}" not in runs or "--github-output" not in runs:
            fail(wf, dn, None, "test-discovery",
                 f"discover job must run discover.py --matrix --platform {plat} --github-output.")

    for jn, job in test_jobs.items():
        steps = job.get("steps") or []
        matrix = (job.get("strategy") or {}).get("matrix") or {}
        test_idx = [i for i, s in enumerate(steps) if _runs_test_runner(s)]

        # 17. test-runner-wrapper: every test execution goes through run-test.py.
        for i, st in enumerate(steps):
            run = st.get("run") or ""
            if _mentions_tests(run):
                checked += 1
                if not _runs_test_runner(st):
                    fail(wf, jn, step_name(st, i), "test-runner-wrapper",
                         "runs a test without .github/scripts/run-test.py, so it gets no complete "
                         "per-test log, no timeout, no evidence capture and is invisible to the report.")
        checked += 1
        if not test_idx:
            fail(wf, jn, None, "test-runner-wrapper", "test job has no step running run-test.py.")
            continue
        ti = test_idx[0]
        tstep = steps[ti]
        tid = tstep.get("id")

        # 26b. matrix from discovery
        if discover_jobs:
            checked += 1
            mval = " ".join(str(v) for v in matrix.values())
            if not any(f"needs.{d}.outputs" in mval for d in discover_jobs) or not set(discover_jobs) & set(_needs(job)):
                fail(wf, jn, None, "test-discovery",
                     "the test matrix must be `fromJSON(needs.<discover>.outputs.groups)` and the job "
                     "must `needs:` the discover job.")
            checked += 1
            if "--group" not in (tstep.get("run") or "") or f"--platform {plat}" not in (tstep.get("run") or ""):
                fail(wf, jn, step_name(tstep, ti), "test-discovery",
                     f"run-test.py must run a discovered group: --platform {plat} --group <matrix group>.")

        # 18. test-step-timeout: the test step's cap comes from discovery,
        #     `${{ fromJSON(needs.<discover>.outputs.step_timeouts)[matrix.group] }}`
        #     = the sum of the group's per-test caps + overhead (discover.py
        #     step_budget). A fixed 50 sat under the `nixos` group's 120 min of
        #     caps: a few slow tests and the step cap would SIGTERM the runner,
        #     and every later test of the leg would never run (no-early-stop).
        checked += 1
        jcap, scap = job.get("timeout-minutes"), tstep.get("timeout-minutes")
        m = STEP_TIMEOUT_EXPR.match(str(scap).strip()) if isinstance(scap, str) else None
        if not m or m.group(1) not in discover_jobs:
            fail(wf, jn, step_name(tstep, ti), "test-step-timeout",
                 f"test step timeout-minutes is {scap!r}; it must be "
                 "`${{ fromJSON(needs.<discover>.outputs.step_timeouts)[matrix.group] }}` so the step cap "
                 "always covers every per-test cap of the group (a fixed number lets the step timeout "
                 "kill the leg before later tests ever start).")
        for dn in discover_jobs:
            checked += 1
            dj = jobs[dn]
            out = str((dj.get("outputs") or {}).get("step_timeouts", ""))
            dids = [st.get("id") for st in dj.get("steps") or []
                    if "--matrix" in (st.get("run") or "") and "--github-output" in (st.get("run") or "")]
            if not any(d and f"steps.{d}.outputs.step_timeouts" in out for d in dids):
                fail(wf, dn, None, "test-step-timeout",
                     "the discover job must export `step_timeouts: ${{ steps.<id>.outputs.step_timeouts }}` "
                     "from its discover.py --matrix --github-output step.")

        # 34. test-step-continue: the test step itself must be continue-on-error,
        #     so a failing group still runs the upload and the excerpts as
        #     ordinary steps and the GATE (not the test step) is the verdict.
        checked += 1
        if tstep.get("continue-on-error") is not True:
            fail(wf, jn, step_name(tstep, ti), "test-step-continue",
                 "the test step must be `continue-on-error: true`: the Gate step carries the verdict, "
                 "and the steps between must not depend on always() alone to run.")

        # 35. test-job-needs: a leg may wait for discovery, nothing else. A
        #     `needs:` on another test job chains legs: one red leg then SKIPS the
        #     next leg entirely (no tests, no logs, no gate) - an early stop.
        checked += 1
        extra = [n for n in _needs(job) if n not in discover_jobs]
        if extra:
            fail(wf, jn, None, "test-job-needs",
                 f"test job `needs:` {', '.join(extra)}; only the discover job is allowed. Chained legs "
                 "are skipped when an earlier one fails, so their tests never run.")

        # 32. test-step-budget: every other step is bounded and the bounds fit
        #     the job cap. A job-cap kill skips every later step (upload, gate);
        #     a step cap does not. An unbounded setup step (cache restore, store
        #     verify) could eat the margin the upload and gate need (review F7).
        #     The test step's own bound is the LARGEST discovered group budget.
        checked += 1
        others = [s for i, s in enumerate(steps) if i != ti]
        unbounded = [step_name(s, i) for i, s in enumerate(steps) if i != ti and not isinstance(s.get("timeout-minutes"), int)]
        total = sum(s.get("timeout-minutes") for s in others if isinstance(s.get("timeout-minutes"), int))
        dmod, dtests = _discovery()
        budgets = dmod.step_budgets(dtests, plat) if dmod and dtests else {}
        biggest = max(budgets.values()) if budgets else 0
        worst = max(budgets, key=budgets.get) if budgets else "-"
        if unbounded:
            fail(wf, jn, None, "test-step-budget",
                 "every non-test step of a test job needs an integer timeout-minutes; unbounded: " + ", ".join(unbounded))
        elif not isinstance(jcap, int) or total + biggest > jcap - 5:
            fail(wf, jn, None, "test-step-budget",
                 f"the other steps' timeout-minutes ({total}) + the largest group's test-step timeout "
                 f"({biggest}, group {worst}) = {total + biggest} is more than job timeout-minutes ({jcap}) - 5: "
                 "the job cap could fire first and skip the upload and the gate. Split the group "
                 "(test.conf `group =`) or raise the job cap.")
        # ...and the budget really covers the caps: sum of the group's per-test
        # caps + at least 1 min per test of runner overhead.
        for g, b in budgets.items():
            checked += 1
            n = dmod.select(dtests, plat, True, g)
            need = sum(t["timeout_min"] for t in n) + len(n)
            if b < need:
                fail(wf, jn, None, "test-step-budget",
                     f"group {g}: step timeout {b} min < its per-test caps ({need - len(n)} min) + 1 min "
                     "overhead per test: the step cap could stop the leg before a test reached its own cap.")

        # 20. matrix-no-fail-fast
        if matrix:
            checked += 1
            if (job.get("strategy") or {}).get("fail-fast") is not False:
                fail(wf, jn, None, "matrix-no-fail-fast",
                     "test matrix must set `fail-fast: false`: the gate turns a leg red, and fail-fast "
                     "would cancel the other legs and lose their logs.")

        # 19. test-log-upload
        ups = [(i, s) for i, s in enumerate(steps) if str(s.get("uses", "")).startswith("actions/upload-artifact@")]
        checked += 1
        if not ups:
            fail(wf, jn, None, "test-log-upload", "no actions/upload-artifact step: the per-test logs are lost.")
        for i, st in ups:
            w = st.get("with") or {}
            name = str(w.get("name", ""))
            problems = []
            if not re.match(r"actions/upload-artifact@v\d+$", st["uses"]):
                problems.append("pin a major version (@vN), not a branch")
            if "always()" not in str(st.get("if", "")):
                problems.append("`if:` must use always() - a failed test step is exactly when the logs matter")
            if st.get("continue-on-error") is not True:
                problems.append("must be continue-on-error: true")
            if not w.get("retention-days"):
                problems.append("set retention-days")
            if "test-logs" not in str(w.get("path", "")):
                problems.append("path must be the test-logs dir")
            for need in ("github.run_id", "github.run_attempt"):
                if need not in name:
                    problems.append(f"name must contain {need} (artifact names are immutable within a run)")
            if matrix and not any(f"matrix.{k}" in name for k in matrix):
                problems.append("name must contain the matrix variable (legs share run_id)")
            if i < ti:
                problems.append("must come after the test step")
            checked += 1
            if problems:
                fail(wf, jn, step_name(st, i), "test-log-upload", "; ".join(problems))

        # 16. test-gate
        gates = []
        for i, st in enumerate(steps):
            run = st.get("run") or ""
            refs = run + " " + str(st.get("env", {}))
            if i > ti and "exit 1" in run and tid and f"steps.{tid}.outcome" in refs:
                gates.append((i, st))
        checked += 1
        if not tid:
            fail(wf, jn, step_name(tstep, ti), "test-gate", "the test step needs an `id:` so a gate can read its outcome.")
        elif not gates:
            fail(wf, jn, None, "test-gate",
                 f"no gate step after the test step (a step reading steps.{tid}.outcome that can `exit 1`). "
                 "Without it a failing test leaves the run green (I-06).")
        for i, st in gates:
            problems = []
            gif = re.sub(r"^\$\{\{\s*(.*?)\s*\}\}$", r"\1", str(st.get("if", "")).strip())
            if gif != "always()":
                problems.append("`if:` must be exactly always() (a failed earlier step must not skip the "
                                "verdict, and `always() && X` can skip it)")
            if not re.search(r"!=\s*[\"']success[\"']", st.get("run") or ""):
                problems.append("must fail on outcome `!= \"success\"` (a `= \"failure\"` test lets a "
                                "cancelled or skipped test step through)")
            if st.get("continue-on-error"):
                problems.append("must NOT be continue-on-error (it would report success after exit 1)")
            if "WEBHOOK_ID" in str(st.get("if", "")):
                problems.append("must NOT be guarded on WEBHOOK_ID (no secret = no verdict)")
            if _is_discord_step(st):
                problems.append("must not also post to Discord (notify-non-fatal forces continue-on-error there)")
            if ups and i < max(u for u, _ in ups):
                problems.append("must come after the log upload (persist before inform)")
            checked += 1
            if problems:
                fail(wf, jn, step_name(st, i), "test-gate", "; ".join(problems))

        # 22. no-secrets-in-tests
        def _no_secret(src, where):
            global checked
            checked += 1
            if "secrets." in str(src):
                fail(wf, jn, where, "no-secrets-in-tests",
                     "a secret is visible to the test job. GitHub masks secrets only in the live log, "
                     "not in the log FILES uploaded as artifacts / attached to Discord.")
        _no_secret(doc.get("env") or {}, "workflow env")
        _no_secret(job.get("env") or {}, "job env")
        for i, st in enumerate(steps):
            _no_secret(st.get("env") or {}, step_name(st, i))
            _no_secret(st.get("run") or "", step_name(st, i) + " (run)")
            _no_secret(st.get("if") or "", step_name(st, i) + " (if)")
            w = dict(st.get("with") or {})
            if "nix-installer-action" in str(st.get("uses", "")) and "extra-conf" in w:
                # The ONLY allowed secret: the read-only GITHUB_TOKEN as nix's
                # access-tokens (root-owned nix.conf, redacted from logs). Any
                # other secret added to extra-conf is still caught.
                w["extra-conf"] = re.sub(r"^\s*access-tokens = github\.com=\$\{\{ secrets\.GITHUB_TOKEN \}\}\s*$",
                                         "", str(w["extra-conf"]), flags=re.M)
            _no_secret(w, step_name(st, i))

        # 25. show-trace
        inst = [s for s in steps if "nix-installer-action" in str(s.get("uses", ""))]
        checked += 1
        if not inst or not re.search(r"^\s*show-trace\s*=\s*true\s*$", str((inst[0].get("with") or {}).get("extra-conf", "")), re.M):
            fail(wf, jn, "Install Nix", "show-trace",
                 "extra-conf must contain `show-trace = true`: without it every eval error in a test "
                 "log is one line with no trace.")

    # 21. test-notify-job + 23. notify-not-gate
    tj = set(test_jobs)
    notify = []
    for jn, job in jobs.items():
        if jn in tj:
            continue
        if any(_is_discord_step(s) for s in job.get("steps") or []):
            notify.append(jn)
    checked += 1
    if not notify:
        fail(wf, "-", None, "test-notify-job", "no job posts the test report to Discord.")
    for jn in notify:
        job = jobs[jn]
        problems = []
        if not tj <= set(_needs(job)):
            problems.append(f"must `needs:` every test job ({', '.join(sorted(tj))})")
        if discover_jobs and not discover_jobs <= set(_needs(job)):
            problems.append("must `needs:` the discover job (to report a discovery failure)")
        if "always()" not in str(job.get("if", "")):
            problems.append("needs job-level `if: always()` - it must run when a leg failed or its runner died (§6.4)")
        dl = [s for s in job.get("steps") or [] if str(s.get("uses", "")).startswith("actions/download-artifact@")]
        pat = " ".join(str((s.get("with") or {}).get("pattern", "")) for s in dl)
        if not dl or not re.search(r"\$\{\{ github\.run_id \}\}-\*$", pat.strip()):
            problems.append("must download every attempt of THIS run's test-logs-* artifacts (pattern ending "
                            "`-${{ github.run_id }}-*`): after \"Re-run failed jobs\" the legs that passed "
                            "earlier have no artifact under the new attempt; test-report.py keeps the highest "
                            "attempt per leg")
        checked += 1
        if problems:
            fail(wf, jn, None, "test-notify-job", "; ".join(problems))

        # 27. notify-report-fallback: the report step is continue-on-error, so a
        #     crash in test-report.py is invisible unless the Discord step reads
        #     its OUTCOME. Keying the fallback only on "messages.txt missing" let
        #     a crash after an early empty write read as "nothing to report".
        steps = job.get("steps") or []
        rep = [s for s in steps if "test-report.py" in (s.get("run") or "")
               and "--excerpts-only" not in (s.get("run") or "")]
        checked += 1
        if not rep:
            fail(wf, jn, None, "notify-report-fallback", "no step builds the report with test-report.py.")
            continue
        rid = rep[0].get("id")
        if not rid:
            fail(wf, jn, step_name(rep[0], steps.index(rep[0])), "notify-report-fallback",
                 "the report step needs an `id:` so the Discord step can test its outcome.")
            continue
        for i, st in enumerate(steps):
            if not _is_discord_step(st):
                continue
            checked += 1
            blob = (st.get("run") or "") + " " + " ".join(str(v) for v in (st.get("env") or {}).values())
            if f"steps.{rid}.outcome" not in blob:
                fail(wf, jn, step_name(st, i), "notify-report-fallback",
                     f"must read steps.{rid}.outcome and send the fallback message when it is not "
                     "'success': the report step is continue-on-error, so a crash in it is otherwise "
                     "silent whenever it already left a (possibly empty) messages.txt behind.")
    for jn, job in jobs.items():
        for i, st in enumerate(job.get("steps") or []):
            if _is_discord_step(st):
                checked += 1
                if re.search(r"^\s*exit\s+1\b", st.get("run") or "", re.M):
                    fail(wf, jn, step_name(st, i), "notify-not-gate",
                         "a Discord step must not carry the verdict (`exit 1`): it is continue-on-error "
                         "and webhook-guarded, so its exit 1 can never turn the run red (I-06). The gate "
                         "step in each test leg does that.")

    # 37. darwin-runner-aligned: the Darwin test legs run on the same macOS image
    #     as build-darwin.yml (macos-15 since 2026-06-24), so a test and the
    #     build see one macOS/Xcode/SDK. tests-darwin.yml sat on macos-14 while
    #     the build had moved on (found 2026-10-10).
    if plat == "darwin":
        bpath = path.parent / "build-darwin.yml"
        if bpath.is_file():
            bdoc = yaml.safe_load(bpath.read_text()) or {}
            build_imgs = {str(j.get("runs-on")) for j in (bdoc.get("jobs") or {}).values()
                          if str(j.get("runs-on", "")).startswith("macos")}
            for jn in test_jobs:
                checked += 1
                img = str(jobs[jn].get("runs-on"))
                if build_imgs and img not in build_imgs:
                    fail(wf, jn, None, "darwin-runner-aligned",
                         f"runs-on {img} but build-darwin.yml builds on {', '.join(sorted(build_imgs))}: "
                         "change both together (build-workflows.md §12.1).")


UNTRUSTED_EXPR = re.compile(r"\$\{\{[^}]*\b(github\.event\.|github\.head_ref\b|inputs\.)")


def check_untrusted_expr(path):
    """33. untrusted-expr-in-run: an expression expanded INTO a run: script is
    pasted into the shell source before bash parses it, so a PR title, branch
    name or commit message containing `"; curl ... #` runs. Pass such values
    through env: and quote "$VAR" (security review F6). All workflows."""
    global checked
    doc = yaml.safe_load(path.read_text())
    if not doc or "jobs" not in doc:
        return
    for jn, job in doc["jobs"].items():
        for i, st in enumerate(job.get("steps") or []):
            run = st.get("run") or ""
            if not run:
                continue
            checked += 1
            m = UNTRUSTED_EXPR.search(run)
            if m:
                fail(path.name, jn, step_name(st, i), "untrusted-expr-in-run",
                     f"`{m.group(0)}...` is expanded into the script text (script injection). Pass it "
                     "through the step's env: and use \"$VAR\".")


def check_test_report_hygiene():
    """24. discord-payload-hygiene: test-report.py must keep the payload rules
    that stop a log line from pinging @everyone, unfurling links, or exceeding
    Discord's 2000-char content limit (an HTTP 400 that --fail turns into a
    warning, i.e. a SILENT failure notice)."""
    global checked
    if not TEST_REPORT.is_file():
        return
    src = TEST_REPORT.read_text()
    checked += 1
    if "redact" not in src:
        fail(TEST_REPORT.name, "-", None, "discord-payload-hygiene",
             "every text and attachment must pass through redact().")
    # Behavioural, not grep: the docstring documents the same keys, so a grep
    # still passes after the code stops setting them (found by mutation test).
    import importlib.util
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(TEST_REPORT.resolve().parent))
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    try:
        spec = importlib.util.spec_from_file_location("_test_report_under_check", TEST_REPORT)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        pl = mod.payload("@everyone https://example.invalid/x")
    except Exception as e:
        fail(TEST_REPORT.name, "-", None, "discord-payload-hygiene", f"payload() is unusable: {e!r}")
        return
    checked += 1
    if pl.get("allowed_mentions") != {"parse": []}:
        fail(TEST_REPORT.name, "-", None, "discord-payload-hygiene",
             "payload() must set allowed_mentions {'parse': []} - a log line with @everyone would ping.")
    checked += 1
    if not (int(pl.get("flags", 0)) & 4):
        fail(TEST_REPORT.name, "-", None, "discord-payload-hygiene",
             "payload() must set flags 4 (SUPPRESS_EMBEDS) - links would unfurl into embed cards.")
    checked += 1
    try:
        mod.payload("x" * 2001)
        fail(TEST_REPORT.name, "-", None, "discord-payload-hygiene",
             "payload() accepted 2001 chars of content: Discord answers 400 above 2000 and the "
             "--fail branch turns that into a warning, i.e. a SILENT failure notice.")
    except AssertionError:
        pass


def check_discovery():
    """26c. The tests tree must discover cleanly (no folder that matches no
    pattern, no bad test.conf), with at least one CI group per platform. The
    discover job enforces this per run; this makes check-workflows.yml catch it
    on the PR that introduces it. (Whether a group's caps fit its leg is
    test-step-timeout / test-step-budget, per workflow.)"""
    global checked
    sys.path.insert(0, str(REPO_ROOT / "templates" / "tests" / "lib"))
    sys.dont_write_bytecode = True
    try:
        import discover
    except Exception as e:  # pragma: no cover
        fail("templates/tests/lib/discover.py", "-", None, "test-discovery", f"cannot import: {e}")
        return
    checked += 1
    try:
        tests = discover.discover(TESTS_ROOT)
    except discover.DiscoveryError as e:
        for prob in e.problems:
            fail("templates/tests", "-", None, "test-discovery", prob)
        return
    for plat in ("linux", "darwin"):
        checked += 1
        groups = discover.ci_groups(tests, plat)
        if not groups:
            fail("templates/tests", "-", None, "test-discovery", f"no CI test for platform {plat}: empty matrix.")
    check_harness_pinned(discover)


HARNESS_REF = re.compile(r"danielefongo/nix-tests(?P<rest>[^\s\"']*)")
PINNED_REST = re.compile(r"^/[0-9a-f]{40}$|^\?(?:.*&)?rev=[0-9a-f]{40}(?:&|$)")
# An executable use: `nix run|shell|build ... <flakeref ending in danielefongo/nix-tests...>`.
HARNESS_CALL = re.compile(r"\bnix\s+(?:run|shell|build|profile\s+install)\b[^\n]*?danielefongo/nix-tests"
                          r"(?P<rest>[^\s\"']*)")


def check_harness_pinned(discover):
    """36. harness-pinned: the external nix-tests harness runs at ONE exact,
    reviewed commit. Unpinned, every upstream push changed what all test runs
    executed (and its GitHub repo is archived: a force-push or deletion would
    break every harness test at once). discover.NIX_TESTS is the only invocation;
    any other executable reference under .github/ or the test scripts must be
    pinned as well. Markdown is documentation and is not scanned."""
    global checked
    checked += 1
    cmd = getattr(discover, "NIX_TESTS", "")
    m = HARNESS_REF.search(cmd)
    if not m or not PINNED_REST.match(m.group("rest")):
        fail("templates/tests/lib/discover.py", "-", None, "harness-pinned",
             f"NIX_TESTS = {cmd!r} does not pin the harness to a full 40-hex rev "
             "(github:danielefongo/nix-tests/<sha> or ...?rev=<sha>); see the bump note there.")
    checked += 1
    if "--inputs-from . --override-input nixpkgs nixpkgs" not in cmd:
        fail("templates/tests/lib/discover.py", "-", None, "harness-pinned",
             "NIX_TESTS must keep `--inputs-from . --override-input nixpkgs nixpkgs` (the harness's own "
             "nixpkgs cannot fetch its crates any more; see the comment there).")
    scan = [*REPO_ROOT.joinpath(".github").rglob("*"), *TESTS_ROOT.rglob("*")]
    for f in sorted(scan):
        if (not f.is_file() or f.suffix in (".md", ".pyc") or "__pycache__" in f.parts
                or f.resolve() == Path(__file__).resolve()):
            continue
        try:
            text = f.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        for mm in HARNESS_CALL.finditer(text):
            rest = mm.group("rest")
            if PINNED_REST.match(rest):
                continue
            checked += 1
            line = text.count("\n", 0, mm.start()) + 1
            fail(str(f.relative_to(REPO_ROOT)) if f.is_relative_to(REPO_ROOT) else str(f), "-", f"line {line}",
                 "harness-pinned",
                 f"unpinned nix-tests call `{mm.group(0)}`: run the harness through discovery "
                 "(discover.NIX_TESTS) or pin it to the same 40-hex rev.")


def main():
    global WORKFLOW_DIR, TEST_REPORT, TESTS_ROOT
    import argparse
    ap = argparse.ArgumentParser(description="CI workflow invariants")
    ap.add_argument("--workflows", help="workflow dir to check (mutation tests use a scratch copy)")
    ap.add_argument("--test-report", help="test-report.py to check (mutation tests)")
    ap.add_argument("--tests-root", help="templates/tests tree to discover (mutation tests)")
    a = ap.parse_args()
    if a.workflows:
        WORKFLOW_DIR = Path(a.workflows)
    if a.test_report:
        TEST_REPORT = Path(a.test_report)
    if a.tests_root:
        TESTS_ROOT = Path(a.tests_root)

    paths = sorted(WORKFLOW_DIR.glob("*.yml")) + sorted(WORKFLOW_DIR.glob("*.yaml"))
    if not paths:
        sys.exit(f"no workflow files found under {WORKFLOW_DIR}")

    for p in paths:
        check_workflow(p)
        check_cache_keys(p)
        check_push_count(p)
        check_test_workflow(p)
        check_untrusted_expr(p)
    check_test_report_hygiene()
    check_discovery()

    for w in warnings:
        print(f"warning: {w}")
    print(f"checked {checked} invariant(s) across {len(paths)} workflow file(s)\n")
    if failures:
        print(f"{len(failures)} violation(s):\n")
        for f in failures:
            print(f + "\n")
        return 1
    print("all workflow invariants hold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
