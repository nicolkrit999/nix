#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

run_check() {
  local attr="$1" label="$2"
  printf "  %-72s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-darwin-headroom-launchd.nix" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}PASS${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}FAIL${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|CHECK FAILED|$result")
    fi
  else
    printf "${RED}FAIL (eval error)${NC}\n"
    ((FAIL++)) || true
    local excerpt
    excerpt=$(grep -E "error:|missing|not available|undefined variable" "$stderr_file" | head -3 | tr '\n' '~')
    FAILURES+=("$label|EVAL ERROR|$excerpt")
  fi
  rm -f "$stderr_file"
}

echo ""
echo -e "${BOLD}=== Darwin headroom launchd agent (minimal darwin fixture, eval-only) ===${NC}"
echo ""

echo -e "${BOLD}launchd agent${NC}"
run_check check-agent-declared                     "home-manager launchd.agents.headroom-proxy exists and is enabled"
run_check check-agent-label                        "launchd Label"
run_check check-agent-keepalive                    "agent starts at login and is restarted (RunAtLoad + KeepAlive)"
run_check check-agent-args-shape                   "ProgramArguments = [<store>/bin/headroom proxy --port <n>]"
run_check check-agent-port                         "proxy port"

echo -e "${BOLD}wrapper and platform split${NC}"
run_check check-wrapper-targets-loopback           "headroom-claude probes 127.0.0.1 (not localhost / ::1) on the agent's port and exports the same base URL"
run_check check-wrapper-darwin-hint                "headroom-claude points at launchctl (not systemctl) when the proxy is down"
run_check check-no-systemd-unit                    "no systemd headroom-proxy unit on the darwin host"
run_check check-wheel-is-darwin                    "the headroom-ai package src is the macosx arm64 wheel"

echo -e "${BOLD}controls${NC}"
run_check check-control-disabled                   "control: with programs.headroom left off the agent and wrapper vanish"
run_check check-control-port-regex                 "control: the port regex does not match a non-loopback probe"

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label kind err <<< "$entry"
  echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
  echo -e "    ${YELLOW}-> $kind${NC}"
  if [[ -n "$err" ]]; then
    echo "$err" | tr '~' '\n' | while IFS= read -r line; do
      [[ -n "$line" ]] && echo -e "      ${DIM}$line${NC}" || true
    done
  fi
done
echo ""
exit 1
