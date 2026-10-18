# test-darwin-headroom-launchd

Eval-only test of the darwin branch of `modules/common/programs/headroom.nix` on the REAL `Krits-MacBook-Pro`: the home-manager launchd agent, its port, the `headroom-claude` wrapper and the platform split (no systemd unit, macOS wheel).

Covers gap #7. Linux coverage lives in `test-ai-tool-modules`. NOT covered: that the proxy really listens on `127.0.0.1:8787` (eval cannot start it). The proxy's bind address is not set by the agent, so the loopback claim is checked on the wrapper side only (it probes and targets `127.0.0.1:<agent port>`).

## Run

From the repo root:

```bash
bash templates/tests/darwin/test-darwin-headroom-launchd/check-darwin-headroom-launchd.sh
```

Or through the runner: `bash templates/tests/run-tests.sh --only darwin-headroom-launchd`.

From inside the directory:

```bash
bash check-darwin-headroom-launchd.sh
```

Runtime is well under a minute (lazy eval, no builds).

## How it works

`01-scenario-darwin-headroom-launchd.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads `darwinConfigurations.Krits-MacBook-Pro`, so config fixes are verified without a rebuild. Each `check-*` attribute is `"ok"` or `"FAIL: ..."`. `check-darwin-headroom-launchd.sh` runs `nix eval --raw --impure` per check and exits non-zero on any failure.

The wrapper script text is read from the derivation's `text` attribute (no build). The agent is looked up by name in the HM `launchd.agents`. A control disables `programs.headroom` and requires agent and wrapper to vanish.

## Checks

### launchd agent

| Check | Expected |
|-------|----------|
| `check-agent-declared` | home-manager launchd.agents.headroom-proxy exists and is enabled |
| `check-agent-label` | launchd Label |
| `check-agent-keepalive` | agent starts at login and is restarted (RunAtLoad + KeepAlive) |
| `check-agent-args-shape` | ProgramArguments = [<store>/bin/headroom proxy --port <n>] |
| `check-agent-port` | proxy port |

### wrapper and platform split

| Check | Expected |
|-------|----------|
| `check-wrapper-targets-loopback` | headroom-claude probes 127.0.0.1 (not localhost / ::1) on the agent's port and exports the same base URL |
| `check-wrapper-darwin-hint` | headroom-claude points at launchctl (not systemctl) when the proxy is down |
| `check-no-systemd-unit` | no systemd headroom-proxy unit on the darwin host |
| `check-wheel-is-darwin` | the headroom-ai package src is the macosx arm64 wheel |

### controls

| Check | Expected |
|-------|----------|
| `check-control-disabled` | control: with programs.headroom disabled the agent and wrapper vanish |
| `check-control-port-regex` | control: the port regex does not match a non-loopback probe |
