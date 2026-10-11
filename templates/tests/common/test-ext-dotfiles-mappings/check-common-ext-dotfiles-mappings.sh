#!/usr/bin/env bash
set -euo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
FLAKE_ROOT="${FLAKE_ROOT:-$(cd "$DIR/../../../.." && pwd)}"
export FLAKE_ROOT

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()
WORK="$(mktemp -d)"
trap 'chmod -R u+w "$WORK" 2>/dev/null || true; rm -rf "$WORK"' EXIT

pass() { printf "${GREEN}PASS${NC}\n"; ((PASS++)) || true; }
fail() { printf "${RED}FAIL${NC}\n"; ((FAIL++)) || true; FAILURES+=("$1|CHECK FAILED|$2"); }

run_check() {
  local attr="$1" label="$2"
  printf "  %-62s " "$label"
  local result stderr_file
  stderr_file=$(mktemp)
  if result=$(nix eval --raw --impure --file "$DIR/01-scenario-ext-dotfiles-mappings.nix" "$attr" 2>"$stderr_file"); then
    if [[ "$result" == "ok" ]]; then pass; else fail "$label" "$result"; fi
  else
    printf "${RED}FAIL (eval error)${NC}\n"
    ((FAIL++)) || true
    FAILURES+=("$label|EVAL ERROR|$(grep -E 'error:|missing|undefined' "$stderr_file" | head -3 | tr '\n' '~')")
  fi
  rm -f "$stderr_file"
}

activation_expr() {
  case "$1" in
    desktop) echo "(f.nixosConfigurations.nixos-desktop.config.home-manager.users.krit.home)" ;;
    laptop) echo "(f.nixosConfigurations.nixos-laptop.config.home-manager.users.krit.home)" ;;
    nas) echo "(f.homeConfigurations.\"krit@Nicol-NAS\".config.home)" ;;
    mac) echo "(f.darwinConfigurations.Krits-MacBook-Pro.config.home-manager.users.krit.home)" ;;
  esac
}

dump_activation() {
  local h="$1"
  nix eval --raw --impure --expr \
    "let f = builtins.getFlake \"path:$FLAKE_ROOT\"; in $(activation_expr "$h").activation.syncBackDotfilesPrivate.data" \
    > "$WORK/act-$h.sh"
}

echo ""
echo -e "${BOLD}=== ext-dotfiles-private mappings ===${NC}"

for h in desktop laptop nas mac; do
  echo -e "\n${BOLD}$h${NC}"
  run_check "check-$h-leaves-unique"   "no leaf in two enabled packages"
  run_check "check-$h-extra-disjoint"  "extraMappings keys disjoint from package leaves"
  run_check "check-$h-hostname-known"  "hostname has a packagesPerHost entry"
  run_check "check-$h-packages-exist"  "every enabled package exists in packageLeaves"
  run_check "check-$h-links"           "home.file links match mappings (target, force)"
  run_check "check-$h-syncback-calls"  "activation sync_back calls match syncBack ∩ mappings"
done

echo -e "\n${BOLD}syncBack coverage${NC}"
run_check check-desktop-syncback-nonempty "desktop has active syncBack entries"
run_check check-laptop-syncback-nonempty  "laptop has active syncBack entries"
run_check check-mac-syncback-nonempty     "mac has active syncBack entries"
run_check check-nixos-syncback-known      "nixos syncBack paths are package leaves"
run_check check-darwin-syncback-known     "darwin syncBack paths are package leaves"

echo -e "\n${BOLD}host keys / dead packages${NC}"
run_check check-nixos-host-keys-real      "nixos per-host keys are real hostnames"
run_check check-darwin-host-keys-real     "darwin per-host keys are real hostnames"
run_check check-nixos-no-unused-package   "nixos packages all used"
run_check check-darwin-no-unused-package  "darwin packages all used"

echo -e "\n${BOLD}school-workspace naming${NC}"
run_check check-desktop-school-dot  "desktop uses .school-workspace"
run_check check-laptop-school-dot   "laptop uses .school-workspace"
run_check check-mac-school-nodot    "mac uses school-workspace (no dot)"
run_check check-nas-no-school       "NAS has no school-workspace links"

echo -e "\n${BOLD}controls${NC}"
run_check check-control-overlap-detected "overlap detector flags a shared leaf"
run_check check-control-overlap-clean    "overlap detector quiet on disjoint packages"
run_check check-control-typo-host-detected "hostname typo yields a failure"

echo -e "\n${BOLD}generated activation script${NC}"
for h in desktop laptop nas mac; do
  label="$h activation passes bash -n"
  printf "  %-62s " "$label"
  if dump_activation "$h" 2>"$WORK/err" && bash -n "$WORK/act-$h.sh" 2>"$WORK/err"; then pass
  else fail "$label" "$(head -3 "$WORK/err" | tr '\n' '~')"; fi
done

extract_fn() { awk '/^ *sync_back\(\) \{/{p=1} p{print} p&&/^ *\}$/{exit}' "$1" | sed 's/^ *//' ; }
label="sync_back function identical on desktop and mac"
printf "  %-62s " "$label"
if [[ -s "$WORK/act-desktop.sh" && "$(extract_fn "$WORK/act-desktop.sh" | sed 's#/home/krit#H#g')" == "$(extract_fn "$WORK/act-mac.sh" | sed 's#/Users/krit#H#g')" && -n "$(extract_fn "$WORK/act-mac.sh")" ]]; then pass
else fail "$label" "function bodies differ or not found"; fi

echo -e "\n${BOLD}sandbox run of the real desktop activation${NC}"
run_sandbox() {
  local sb="$1"
  sed -e '/^export PATH=/d' -e "s#/home/krit#$sb#g" "$WORK/act-desktop.sh" > "$WORK/run.sh"
  PATH="$PATH" bash -eu "$WORK/run.sh"
}
new_sb() {
  SB="$WORK/sb$1"; rm -rf "$SB"
  mkdir -p "$SB/.config" "$SB/dotfiles-private/claude/common/.config/x"
  mkdir -p "$SB/dotfiles-private/vicinae" "$SB/dotfiles-private/openlogi"
}
settings_repo() { echo "$SB/dotfiles-private/$(sed -n "s/^sync_back '\?\.config\/vicinae\/settings.json'\? \(.*\)$/\1/p" "$WORK/act-desktop.sh" | tr -d "'")"; }
openlogi_repo() { echo "$SB/dotfiles-private/$(sed -n "s/^sync_back '\?\.config\/openlogi'\? \(.*\)$/\1/p" "$WORK/act-desktop.sh" | tr -d "'")"; }

if [[ ! -s "$WORK/act-desktop.sh" ]] || ! grep -q '^sync_back .config/vicinae/settings.json' "$WORK/act-desktop.sh"; then
  fail "sandbox prerequisites" "desktop activation lacks the vicinae sync_back call"
else
  t() { local label="$1"; shift; printf "  %-62s " "$label"; if "$@" 2>"$WORK/err"; then pass; else fail "$label" "$(head -3 "$WORK/err" | tr '\n' '~')"; fi; }

  case_file_copied() {
    new_sb 1; local repo; repo=$(settings_repo)
    mkdir -p "$(dirname "$repo")" "$SB/.config/vicinae"
    echo old > "$repo"; echo live > "$SB/.config/vicinae/settings.json"
    run_sandbox "$SB"
    [[ "$(cat "$repo")" == live && ! -e "$SB/.config/vicinae/settings.json" && ! -e "$repo.syncback.tmp" ]]
  }
  case_file_identical() {
    new_sb 2; local repo; repo=$(settings_repo)
    mkdir -p "$(dirname "$repo")" "$SB/.config/vicinae"
    echo same > "$repo"; echo same > "$SB/.config/vicinae/settings.json"
    run_sandbox "$SB"
    [[ "$(cat "$repo")" == same && ! -e "$SB/.config/vicinae/settings.json" ]]
  }
  case_symlink_untouched() {
    new_sb 3; local repo; repo=$(settings_repo)
    mkdir -p "$(dirname "$repo")" "$SB/.config/vicinae"
    echo old > "$repo"; ln -s "$repo" "$SB/.config/vicinae/settings.json"
    run_sandbox "$SB"
    [[ -L "$SB/.config/vicinae/settings.json" && "$(cat "$repo")" == old ]]
  }
  case_file_repo_parent_missing() {
    new_sb 4
    mkdir -p "$SB/.config/vicinae"; echo live > "$SB/.config/vicinae/settings.json"
    run_sandbox "$SB"
    [[ "$(cat "$SB/.config/vicinae/settings.json")" == live ]]
  }
  case_dir_rsynced() {
    new_sb 5; local repo; repo=$(openlogi_repo)
    mkdir -p "$repo" "$SB/.config/openlogi"
    echo keep > "$repo/repo-only"; echo new > "$SB/.config/openlogi/live-only"
    run_sandbox "$SB"
    [[ "$(cat "$repo/live-only")" == new && -e "$repo/repo-only" && ! -e "$SB/.config/openlogi" ]]
  }
  case_dir_repo_missing() {
    new_sb 6
    mkdir -p "$SB/.config/openlogi"; echo new > "$SB/.config/openlogi/live-only"
    run_sandbox "$SB"
    [[ -e "$SB/.config/openlogi/live-only" ]]
  }
  case_file_copy_fails() {
    new_sb 7; local repo; repo=$(settings_repo)
    mkdir -p "$(dirname "$repo")" "$SB/.config/vicinae"
    echo old > "$repo"; echo live > "$SB/.config/vicinae/settings.json"
    chmod a-w "$(dirname "$repo")"
    run_sandbox "$SB"; local rc=$?
    chmod u+w "$(dirname "$repo")"
    [[ "$(cat "$SB/.config/vicinae/settings.json")" == live && "$(cat "$repo")" == old ]]
  }
  case_dir_rsync_fails() {
    new_sb 8; local repo; repo=$(openlogi_repo)
    mkdir -p "$repo/clash" "$SB/.config/openlogi"
    echo keep > "$repo/clash/inner"; echo file > "$SB/.config/openlogi/clash"
    run_sandbox "$SB"
    [[ "$(cat "$SB/.config/openlogi/clash")" == file && -e "$repo/clash/inner" ]]
  }

  t "live file differs: copied back, then live removed" case_file_copied
  t "live file identical: removed, repo untouched" case_file_identical
  t "live symlink: left alone" case_symlink_untouched
  t "repo parent missing: live file kept" case_file_repo_parent_missing
  t "live dir differs: rsynced before delete, repo-only kept" case_dir_rsynced
  t "repo dir missing: live dir kept" case_dir_repo_missing
  if [[ "$(id -u)" == 0 ]]; then
    echo -e "  ${DIM}skipping read-only failure cases (running as root)${NC}"
  else
    t "copy fails (read-only repo): live file kept" case_file_copy_fails
    t "rsync fails (file vs non-empty dir clash): live dir kept" case_dir_rsync_fails
  fi
fi

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
exit 1
