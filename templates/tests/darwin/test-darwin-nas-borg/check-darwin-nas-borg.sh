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
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-darwin-nas-borg.nix" "$attr" 2>"$stderr_file"); then
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
echo -e "${BOLD}=== Darwin NAS + borgmatic (Krits-MacBook-Pro, eval-only) ===${NC}"
echo ""

echo -e "${BOLD}NAS constants and host-key pin${NC}"
run_check check-mount-root                         "krit.services.nas.mountRoot on darwin"
run_check check-nas-user                           "krit.services.nas.user (NAS-side account)"
run_check check-nas-host-fqdn                      "krit.services.nas.host is a dotted FQDN, not a short alias"
run_check check-known-hosts-pin                    "programs.ssh.knownHosts.nicol-nas-tailnet pins host + tailnetIp with nas.hostKey"
run_check check-host-key-shape                     "nas.hostKey is a non-empty ssh-ed25519 public key line"

echo -e "${BOLD}borgmatic repository and excludes${NC}"
run_check check-repo-url                           "borgmatic repository path = ssh://<nas.user>@<nas.host>/<dir>/<hostName>"
run_check check-repo-single                        "borgmatic has exactly one repository"
run_check check-source-home                        "borgmatic source_directories"
run_check check-excludes-secrets                   "exclude_patterns hold .ssh, .config/sops, dotfiles-private"
run_check check-excludes-control                   "control: dropping .ssh from the list is detected"

echo -e "${BOLD}ssh host-key policy and credentials${NC}"
run_check check-ssh-command-strict                 "borgmatic ssh_command has no StrictHostKeyChecking / accept-new / UserKnownHostsFile override"
run_check check-no-accept-new-anywhere             "no accept-new / StrictHostKeyChecking in the whole borgmatic config or agent"
run_check check-ssh-policy-control                 "control: the host-key-policy predicate flags an accept-new ssh_command"
run_check check-ssh-identity                       "ssh_command uses the sops borg-private-key path with IdentitiesOnly"
run_check check-passcommand                        "encryption_passcommand reads the sops borg-passphrase path"

echo -e "${BOLD}launchd agent${NC}"
run_check check-schedule                           "StartCalendarInterval is 10:00, 14:00, 22:00"
run_check check-no-run-at-load                     "borgmatic agent has no RunAtLoad (a rebuild must not trigger a full backup)"
run_check check-agent-config-path                  "agent ProgramArguments --config points at the generated /etc file"

echo -e "${BOLD}activation script${NC}"
run_check check-smb-mkdir-in-activation            "postActivation (the only spliced slot) holds the smb mkdir and chown lines"
run_check check-smb-mkdir-control                  "control: with smb disabled the smb mkdir line disappears"
run_check check-other-shares-mkdir                 "control: enabling opencloud + sshfs puts their mkdir lines into postActivation"

echo -e "${BOLD}assertions${NC}"
run_check check-tailscale-assertion                "no failing assertions (tailnet provider present for the NAS modules)"

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
