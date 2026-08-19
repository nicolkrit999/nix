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

failures = []
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
            for ref in re.findall(r"steps\.([A-Za-z0-9_-]+)\.", run + " " + cond):
                checked += 1
                if ref not in declared_ids:
                    fail(wf, job_name, name, "step-ref",
                         f"references steps.{ref}.* but no step with id '{ref}' is declared "
                         f"in job '{job_name}'. Cross-job references evaluate to '' silently.")

            # 5. On a continue-on-error step .conclusion is ALWAYS 'success'.
            #    Testing it is dead code; .outcome carries the truth.
            for ref in re.findall(r"steps\.([A-Za-z0-9_-]+)\.conclusion", run + " " + cond):
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
            if step.get("uses", "").startswith("nix-community/cache-nix-action"):
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


def main():
    paths = sorted(WORKFLOW_DIR.glob("*.yml")) + sorted(WORKFLOW_DIR.glob("*.yaml"))
    if not paths:
        sys.exit(f"no workflow files found under {WORKFLOW_DIR}")

    for p in paths:
        check_workflow(p)
        check_cache_keys(p)

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
