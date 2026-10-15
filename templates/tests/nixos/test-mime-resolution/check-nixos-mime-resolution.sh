#!/usr/bin/env bash
# MIME default resolution checker: real-host evals plus a hermetic GIO / xdg-mime sandbox.
#
# Usage:
#   bash check-nixos-mime-resolution.sh

set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../../.." && pwd)"
export FLAKE_ROOT="${FLAKE_ROOT:-$REPO_ROOT}"
SCENARIO="$DIR/01-scenario-mime-resolution.nix"
HOSTS=(nixos-desktop nixos-laptop)

if [[ "${1:-}" == "--sandbox" ]]; then
  WORK="$2"
  shift 2
else
  WORK=""
fi

RED='\033[0;31m'; GREEN='\033[0;32m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

sandbox_inner() {
  local work="$1" host root list true_bin
  true_bin="$(type -P true)"
  for tool in gio xdg-mime update-desktop-database; do
    command -v "$tool" >/dev/null || { echo "missing sandbox tool: $tool" >&2; exit 2; }
  done

  record() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$work/sandbox.tsv"; }

  desktop() {
    local file="$1" name="$2" mimes="$3"
    mkdir -p "$(dirname "$file")"
    printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s %%f\nMimeType=%s\n' "$name" "$true_bin" "$mimes" >>"$file"
  }

  query() {
    local tool="$1" root="$2" type="$3"
    env -i PATH="$PATH" LANG=C HOME="$root/home" XDG_CONFIG_HOME="$root/cfg" XDG_CONFIG_DIRS= \
      XDG_DATA_HOME="$root/data" XDG_DATA_DIRS="$root/flatpak/share:$root/profile/share" \
      bash -c '
        if [ "$1" = xdg ]; then xdg-mime query default "$2"
        else gio mime "$2" | sed -n "1s/^[^:]*: //p"; fi' _ "$tool" "$type"
  }

  probe() {
    local tool="$1" root="$2" file="$3" mode="$4" bad="" t want got n=0
    while IFS='=' read -r t want; do
      want="${want%%;*}"
      got="$(query "$tool" "$root" "$t")"
      n=$((n + 1))
      if [[ "$mode" == defaults ]]; then
        [[ "$got" == "$want" ]] || bad+="$t -> '${got:-none}' (list says $want); "
      else
        [[ "$got" == "$(adversary_of "$t")" ]] || bad+="$t -> '${got:-none}' (expected the fake flatpak); "
      fi
    done <"$file"
    [[ $n -ge 20 ]] || bad+="only $n probe types; "
    echo "$bad"
  }

  adversary_of() {
    case "$1" in
      video/* | audio/*) echo ai.storyteller.filmcraft.desktop ;;
      image/*) echo ai.storyteller.photocraft.desktop ;;
      application/pdf) echo ai.storyteller.pdfcraft.desktop ;;
    esac
  }

  for host in "${HOSTS[@]}"; do
    root="$work/sb-$host"
    list="$work/$host.mimeapps"
    mkdir -p "$root/cfg" "$root/home" "$root/data" "$root/flatpak/share/applications" "$root/profile/share/applications"
    cp "$list" "$root/cfg/mimeapps.list"

    sed -n '/^\[Default Applications\]/,/^\[/p' "$list" | grep -E '^(video/|audio/|image/|application/pdf=)' >"$root/probe.txt"

    local id mimes
    while IFS=$'\t' read -r id mimes; do
      if [[ "$id" == ai.storyteller.* ]]; then
        desktop "$root/flatpak/share/applications/$id" "${id%.desktop}" "$mimes"
      else
        desktop "$root/profile/share/applications/$id" "${id%.desktop}" "$mimes"
      fi
    done < <(sed -n '/^\[Default Applications\]/,/^\[/p' "$list" | grep -E '^[a-z-]+/[^=]+=' \
      | awk -F= '{ sub(/;.*/, "", $2); m[$2] = m[$2] $1 ";" } END { for (i in m) printf "%s\t%s\n", i, m[i] }')

    local vtypes itypes ptypes atypes
    vtypes="$(cut -d= -f1 "$root/probe.txt" | grep -E '^(video|audio)/' | tr '\n' ';')"
    itypes="$(cut -d= -f1 "$root/probe.txt" | grep -E '^image/' | tr '\n' ';')"
    ptypes="application/pdf;"
    atypes="$vtypes"
    desktop "$root/flatpak/share/applications/ai.storyteller.filmcraft.desktop" Filmcraft "$atypes"
    desktop "$root/flatpak/share/applications/ai.storyteller.photocraft.desktop" Photocraft "$itypes"
    desktop "$root/flatpak/share/applications/ai.storyteller.pdfcraft.desktop" Pdfcraft "$ptypes"
    update-desktop-database "$root/flatpak/share/applications"
    update-desktop-database "$root/profile/share/applications"

    local adv bad
    adv="$(cut -d= -f2 "$root/probe.txt" | sed 's/;.*//' | grep -cE '^ai\.storyteller\.(filmcraft|photocraft|pdfcraft)\.desktop$')"
    if [[ "$adv" == 0 ]]; then
      record "$host: no video/audio/image/pdf default is a fake-flatpak competitor id" ok ""
    else
      record "$host: no video/audio/image/pdf default is a fake-flatpak competitor id" fail "$adv probed types point at filmcraft/photocraft/pdfcraft"
    fi

    for tool in xdg gio; do
      bad="$(probe "$tool" "$root" "$root/probe.txt" defaults)"
      if [[ -z "$bad" ]]; then
        record "$host: $tool resolves every video/audio/image/pdf type to the explicit default although the fake flatpak comes first" ok ""
      else
        record "$host: $tool resolves every video/audio/image/pdf type to the explicit default although the fake flatpak comes first" fail "$bad"
      fi
    done

    : >"$root/cfg/mimeapps.list"
    if [[ ! -s "$root/cfg/mimeapps.list" && -s "$list" ]]; then
      record "$host: control: emptied mimeapps.list differs from the generated one" ok ""
    else
      record "$host: control: emptied mimeapps.list differs from the generated one" fail "list not emptied or generated list empty"
    fi
    for tool in xdg gio; do
      bad="$(probe "$tool" "$root" "$root/probe.txt" adversary)"
      if [[ -z "$bad" ]]; then
        record "$host: control: without the explicit defaults the fake flatpak wins for every type ($tool)" ok ""
      else
        record "$host: control: without the explicit defaults the fake flatpak wins for every type ($tool)" fail "$bad"
      fi
    done
  done
}

if [[ -n "$WORK" ]]; then
  sandbox_inner "$WORK"
  exit 0
fi

PASS=0
FAIL=0
declare -a FAILURES=()

for tool in nix jq bash; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool"; exit 2; }
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for host in "${HOSTS[@]}"; do
  (
    for attr in results profileResults; do
      nix eval --impure --json --file "$SCENARIO" --argstr host "$host" "$attr" >"$WORK/$host.$attr.json" 2>"$WORK/$host.$attr.err" || echo 1 >"$WORK/$host.$attr.rc"
    done
    nix eval --impure --raw --file "$SCENARIO" --argstr host "$host" mimeappsList >"$WORK/$host.mimeapps" 2>"$WORK/$host.list.err" || echo 1 >"$WORK/$host.list.rc"
  ) &
done
wait

report() {
  local host="$1" attr="$2" json="$WORK/$1.$2.json" checks_attr=checks
  [[ "$attr" == profileResults ]] && checks_attr=profileChecks
  if [[ -e "$WORK/$host.$attr.rc" || ! -s "$json" ]]; then
    echo -e "  ${RED}✗ eval error ($attr)${NC}"
    ((FAIL++)) || true
    FAILURES+=("$host $attr evaluation|$(grep -E 'error:' "$WORK/$host.$attr.err" | head -3 | tr '\n' '~')")
    return
  fi
  while IFS=$'\t' read -r label result; do
    printf "  %-110s " "$label"
    if [[ "$result" == "ok" ]]; then
      printf "${GREEN}✓ ok${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ fail${NC}\n"
      ((FAIL++)) || true
      if [[ "$result" == "FAIL: eval error" ]]; then
        result="$result~$(CHECK_LABEL="$label" nix eval --impure --raw --file "$SCENARIO" --argstr host "$host" --apply 'cs: builtins.deepSeq cs.${builtins.getEnv "CHECK_LABEL"} "x"' "$checks_attr" 2>&1 | grep -E 'error:' | head -3 | tr '\n' '~')"
      fi
      FAILURES+=("$host: $label|$result")
    fi
  done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$json")
}

for host in "${HOSTS[@]}"; do
  echo ""
  echo -e "${BOLD}=== $host: eval layer ===${NC}"
  report "$host" results
  report "$host" profileResults
done

echo ""
echo -e "${BOLD}=== sandbox layer: generated mimeapps.list vs a fake flatpak export dir ahead of the profile ===${NC}"
LIST_OK=1
for host in "${HOSTS[@]}"; do
  if [[ -e "$WORK/$host.list.rc" || ! -s "$WORK/$host.mimeapps" ]]; then
    LIST_OK=0
    echo -e "  ${RED}✗ could not generate mimeapps.list for $host${NC}"
    ((FAIL++)) || true
    FAILURES+=("$host mimeapps.list|$(grep -E 'error:' "$WORK/$host.list.err" | head -3 | tr '\n' '~')")
  fi
done
if [[ $LIST_OK -eq 1 ]]; then
  : >"$WORK/sandbox.tsv"
  nix shell --inputs-from "$REPO_ROOT" nixpkgs#glib nixpkgs#xdg-utils nixpkgs#desktop-file-utils \
    -c bash "$DIR/$(basename "$0")" --sandbox "$WORK" >"$WORK/sandbox.out" 2>"$WORK/sandbox.err" || {
    echo -e "  ${RED}✗ sandbox run failed${NC}"
    ((FAIL++)) || true
    FAILURES+=("sandbox run|$(head -5 "$WORK/sandbox.err" | tr '\n' '~')")
  }
  while IFS=$'\t' read -r label status detail; do
    printf "  %-110s " "$label"
    if [[ "$status" == "ok" ]]; then
      printf "${GREEN}✓ ok${NC}\n"
      ((PASS++)) || true
    else
      printf "${RED}✗ fail${NC}\n"
      ((FAIL++)) || true
      FAILURES+=("$label|$detail")
    fi
  done <"$WORK/sandbox.tsv"
fi

echo ""
if [[ $((PASS + FAIL)) -lt 90 ]]; then
  echo -e "${RED}${BOLD}Only $((PASS + FAIL)) checks ran (expected at least 90); refusing to pass.${NC}"
  exit 1
fi
echo -e "${DIM}──────────────────────────────────────────────────────────────────────${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label detail <<<"$entry"
  echo -e "  ${RED}✗${NC} ${BOLD}$label${NC}"
  echo "$detail" | tr '~' '\n' | while IFS= read -r line; do
    [[ -n "$line" ]] && echo -e "      ${DIM}${line}${NC}" || true
  done
done
exit 1
