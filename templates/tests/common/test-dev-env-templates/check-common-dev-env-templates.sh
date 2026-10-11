#!/usr/bin/env bash
set -uo pipefail
# Full stderr of every failing nix call goes into the test log (CI artifact + local
# ~/.local/state/nix-tests/); a no-op unless run via run-test.py. See the file.
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../../../.." && pwd)"
TPL="$ROOT/templates/krit/dev-environments"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0
FAIL=0
declare -a FAILURES=()

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

REV="$(jq -r '.nodes.nixpkgs.locked.rev' "$ROOT/flake.lock")"
NIXPKGS="github:NixOS/nixpkgs/$REV"
SUMMARY_EXPR="$(cat "$DIR/01-scenario-dev-env-templates.nix")"
SUPPORTED=(x86_64-linux aarch64-linux aarch64-darwin)

TEMPLATES=(
  language-combined/cs-cheat-sheets
  language-combined/cs-notes
  language-combined/sql
  language-combined/web-development/fullstack
  language-specific/c-cpp
  language-specific/go
  language-specific/haskell
  language-specific/java
  language-specific/jupyter
  language-specific/latex
  language-specific/nix
  language-specific/node
  language-specific/php
  language-specific/python
  language-specific/r
  language-specific/rust
  language-specific/shell
  language-specific/swift
  language-specific/typst
)

declare -A EXPECT_URL=(
  [language-combined/web-development/fullstack]="github:nixos/nixpkgs/nixos-unstable"
)
DEFAULT_URL="https://flakehub.com/f/NixOS/nixpkgs/0.1"

declare -A EXPECT_PKGS=(
  [language-combined/cs-cheat-sheets]="typst typstyle tinymist tectonic-wrapped pandoc-cli pandoc-crossref poppler-utils imagemagick qpdf graphviz gnuplot python3"
  [language-combined/cs-notes]="typst typstyle tinymist tectonic-wrapped pandoc-cli pandoc-crossref graphviz plantuml gnuplot poppler-utils python3"
  [language-combined/sql]="python3 sqlite postgresql litecli pgcli usql sqlfluff csvkit jq"
  [language-combined/web-development/fullstack]="nodejs typescript python3 openjdk|zulu-ca-jdk kotlin maven gradle composer ruby dotnet-sdk go gopls postgresql mongosh sqlite"
  [language-specific/c-cpp]="clang-tools cmake cppcheck doxygen gtest lcov vcpkg"
  [language-specific/go]="go gopls gotools golangci-lint"
  [language-specific/haskell]="cabal-install ghc haskell-language-server ormolu"
  [language-specific/java]="openjdk|zulu-ca-jdk gradle maven lombok jdt-language-server"
  [language-specific/jupyter]="poetry python3 ruff ipykernel pip venv-shell-hook"
  [language-specific/latex]="latex2html pandoc-cli texlive-combined-full texlab tectonic-wrapped"
  [language-specific/nix]="nixd nixfmt statix nix-tests"
  [language-specific/node]="eslint nodejs pnpm prettier typescript typescript-language-server yarn"
  [language-specific/php]="php-with-extensions composer phpactor"
  [language-specific/python]="python3 black flake8 isort pip numpy venv-shell-hook pyright ruff"
  [language-specific/r]="R pandoc-cli texlive-combined-full"
  [language-specific/rust]="rust-mixed openssl pkg-config-wrapper cargo-deny cargo-edit cargo-watch rust-analyzer"
  [language-specific/shell]="ShellCheck shfmt bash-language-server"
  [language-specific/swift]="swift sourcekit-lsp"
  [language-specific/typst]="typst typstyle typstwriter tinymist prettypst utpm"
)

# lint_hook <text>: prints problems, empty output means clean
lint_hook() {
  local text="$1" f="$WORK/hook.sh" err
  printf '%s' "$text" > "$f"
  err="$(bash -n "$f" 2>&1)" || true
  [[ -n "$err" ]] && printf '%s\n' "$err"
  local line delim
  while IFS= read -r line; do
    if [[ "$line" =~ \<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*) ]]; then
      delim="${BASH_REMATCH[1]}"
      grep -qxF "$delim" "$f" || printf "heredoc terminator '%s' never appears at column 0\n" "$delim"
    fi
  done < "$f"
}

record() {
  local label="$1" detail="$2"
  printf "  %-66s " "$label"
  if [[ -z "$detail" ]]; then
    printf "${GREEN}PASS${NC}\n"
    PASS=$((PASS + 1))
  else
    printf "${RED}FAIL${NC}\n"
    FAIL=$((FAIL + 1))
    FAILURES+=("$label|$detail")
  fi
}

eval_template() {
  local t="$1" out="$WORK/$(echo "$t" | tr '/' '_').json" err="$WORK/$(echo "$t" | tr '/' '_').err"
  nix eval --json --no-write-lock-file --override-input nixpkgs "$NIXPKGS" \
    "path:$TPL/$t#devShells" --apply "$SUMMARY_EXPR" > "$out" 2> "$err" || rm -f "$out"
}
json_of() { echo "$WORK/$(echo "$1" | tr '/' '_').json"; }
err_of() { echo "$WORK/$(echo "$1" | tr '/' '_').err"; }

sys_json() { printf '%s\n' "${SUPPORTED[@]}" | jq -R . | jq -sc .; }

echo ""
echo -e "${BOLD}=== dev-environment template flakes (nixpkgs ${REV:0:12}) ===${NC}"

echo -e "\n${BOLD}registry${NC}"
found="$(cd "$TPL" && find . -name flake.nix | sed 's|^\./||; s|/flake.nix$||' | sort)"
registered="$(printf '%s\n' "${TEMPLATES[@]}" | sort)"
detail=""
[[ "$found" == "$registered" ]] || detail="$(diff <(echo "$registered") <(echo "$found") | grep '^[<>]' | tr '\n' ' ')"
record "every template flake on disk is covered (and vice versa)" "$detail"

echo -e "\n${BOLD}nixpkgs input url${NC}"
for t in "${TEMPLATES[@]}"; do
  want="${EXPECT_URL[$t]:-$DEFAULT_URL}"
  got="$(grep -oE 'nixpkgs\.url = "[^"]+"' "$TPL/$t/flake.nix" | head -1 | sed -E 's/.*"([^"]+)"/\1/')"
  detail=""
  [[ "$got" == "$want" ]] || detail="nixpkgs url is '$got', expected '$want'"
  record "$t" "$detail"
done

echo -e "\n${BOLD}evaluating templates (override nixpkgs with locked rev)${NC}"
for t in "${TEMPLATES[@]}"; do
  eval_template "$t"
  if [[ -f "$(json_of "$t")" ]]; then
    echo -e "  ${DIM}evaluated $t${NC}"
  else
    echo -e "  ${DIM}evaluation FAILED $t${NC}"
  fi
done

echo -e "\n${BOLD}devShells instantiate on supported systems${NC}"
for t in "${TEMPLATES[@]}"; do
  j="$(json_of "$t")"
  if [[ ! -f "$j" ]]; then
    record "$t" "template eval error: $(grep -E 'error:' "$(err_of "$t")" | head -2 | tr '\n' ' ')"
    continue
  fi
  bad="$(jq -r --argjson s "$(sys_json)" '. as $r | $s[] as $sys | ($r[$sys] // {}) | to_entries[] | select(.value.drv.ok | not) | "\($sys)/\(.key)"' "$j" | tr '\n' ' ')"
  empty="$(jq -r --argjson s "$(sys_json)" '. as $r | $s[] | select(($r[.] // {}) == {})' "$j" | tr '\n' ' ')"
  detail=""
  [[ -n "$bad" ]] && detail="not instantiable: $bad"
  [[ -n "$empty" ]] && detail="$detail no devShells for: $empty"
  record "$t" "$detail"
done

echo -e "\n${BOLD}systems advertised by templates${NC}"
detail=""
for t in "${TEMPLATES[@]}"; do
  grep -q 'x86_64-darwin' "$TPL/$t/flake.nix" && detail="$detail $t"
  j="$(json_of "$t")"
  [[ -f "$j" ]] || continue
  jq -e 'has("x86_64-darwin") | not' "$j" > /dev/null || detail="$detail $t(devShells)"
done
record "no template advertises x86_64-darwin" "${detail:+x86_64-darwin still present in:$detail}"

echo -e "\n${BOLD}expected tools present (x86_64-linux, aarch64-linux, aarch64-darwin)${NC}"
for t in "${TEMPLATES[@]}"; do
  j="$(json_of "$t")"
  [[ -f "$j" ]] || { record "$t" "template eval error"; continue; }
  missing="$(jq -r --arg want "${EXPECT_PKGS[$t]}" --argjson s "$(sys_json)" '
    . as $r | ($want | split(" ")) as $w
    | $s[] as $sys
    | ($r[$sys].default.pkgs.v // []) as $have
    | $w[] | select(. as $n | ($n | split("|")) as $alts | any($alts[]; . as $a | $have | index($a)) | not) | "\($sys):\(.)"' "$j" | tr '\n' ' ')"
  record "$t" "${missing:+missing: $missing}"
done

echo -e "\n${BOLD}shellHook / postShellHook are valid bash (x86_64-linux)${NC}"
for t in "${TEMPLATES[@]}"; do
  j="$(json_of "$t")"
  [[ -f "$j" ]] || { record "$t" "template eval error"; continue; }
  detail=""
  while IFS= read -r shell; do
    for attr in shellHook postShellHook; do
      text="$(jq -r --arg sh "$shell" --arg a "$attr" '.["x86_64-linux"][$sh][$a].v // ""' "$j")"
      [[ -z "$text" ]] && continue
      probs="$(lint_hook "$text")"
      [[ -n "$probs" ]] && detail="$detail [$shell.$attr: $(echo "$probs" | head -2 | tr '\n' ' ')]"
    done
  done < <(jq -r '.["x86_64-linux"] | keys[]' "$j")
  record "$t" "$detail"
done

echo -e "\n${BOLD}hook lint controls${NC}"
good=$'f() {\n  cat <<EOF\nx\nEOF\n}\nf\n'
bad=$'f() {\n  cat <<EOF\n  x\n  EOF\n}\nf\n'
record "lint accepts a heredoc closed at column 0" "$(lint_hook "$good")"
detail=""
[[ -n "$(lint_hook "$bad")" ]] || detail="lint did not flag an indented heredoc terminator"
record "lint flags an indented heredoc terminator" "$detail"

echo -e "\n${BOLD}python${NC}"
pj="$(json_of language-specific/python)"
if [[ -f "$pj" ]]; then
  for pair in default:3.15 py-stable:3.13 py-lts:3.12; do
    shell="${pair%%:*}" want="${pair##*:}"
    got="$(jq -r --arg sh "$shell" '.["x86_64-linux"][$sh].postShellHook.v // "" | capture("rebuild for version (?<v>[^\\s]+)").v // ""' "$pj")"
    detail=""
    [[ "$got" == "$want"* && -n "$got" ]] || detail="version in hook is '$got', expected prefix $want"
    record "devShells.$shell targets python $want" "$detail"
  done
  detail="$(jq -r '.["x86_64-linux"] | keys | map(select(test("311"))) | join(",")' "$pj")"
  record "no py311 shell" "${detail:+unexpected shell: $detail}"
else
  record "python template" "template eval error"
fi

echo -e "\n${BOLD}sql${NC}"
sj="$(json_of language-combined/sql)"
if [[ -f "$sj" ]]; then
  detail="$(jq -r '.["x86_64-linux"].default as $d
    | if (($d.firstPkg.v.name != "python3") or ($d.firstPkg.v.paths | index("pandas") | not)) then "first package is not the python env with pandas (first: \($d.firstPkg.v.name))" else empty end' "$sj")"
  record "python env with pandas is first in packages" "$detail"
  detail="$(jq -r '.["x86_64-linux"].default.pkgs.v as $p
    | if ($p | index("litecli")) == null or ($p | index("pgcli")) == null then "litecli/pgcli (which drag in bare python3) no longer present, ordering contract is moot" else empty end' "$sj")"
  record "control: tools that propagate bare python3 still follow the env" "$detail"
else
  record "sql template" "template eval error"
fi

echo -e "\n${BOLD}gdb guard (c-cpp, rust)${NC}"
for t in language-specific/c-cpp language-specific/rust; do
  j="$(json_of "$t")"
  [[ -f "$j" ]] || { record "$t" "template eval error"; continue; }
  detail=""
  jq -e '.["aarch64-darwin"].default.pkgs.v | index("gdb") | not' "$j" > /dev/null || detail="gdb present on aarch64-darwin"
  jq -e '.["x86_64-linux"].default.pkgs.v | index("gdb")' "$j" > /dev/null || detail="$detail gdb missing on x86_64-linux"
  jq -e '.["aarch64-linux"].default.pkgs.v | index("gdb")' "$j" > /dev/null || detail="$detail gdb missing on aarch64-linux"
  record "$t" "$detail"
done

echo -e "\n${BOLD}go${NC}"
gj="$(json_of language-specific/go)"
if [[ -f "$gj" ]]; then
  for sys in "${SUPPORTED[@]}"; do
    got="$(jq -r --arg s "$sys" '.[$s].default.goVersion.v | join(",")' "$gj")"
    detail=""
    [[ "$got" == 1.26.* ]] || detail="go version is '$got', expected 1.26.*"
    record "go on $sys is 1.26" "$detail"
  done
else
  record "go template" "template eval error"
fi

echo -e "\n${BOLD}java${NC}"
jj="$(json_of language-specific/java)"
if [[ -f "$jj" ]]; then
  for sys in x86_64-linux aarch64-darwin; do
    want="$(nix eval --raw --no-write-lock-file "$NIXPKGS#legacyPackages.$sys.jdk25.home" 2>/dev/null)"
    got="$(jq -r --arg s "$sys" '.[$s].default.javaHome.v' "$jj")"
    detail=""
    [[ -n "$want" && "$got" == "$want" ]] || detail="JAVA_HOME '$got' != jdk25.home '$want'"
    record "JAVA_HOME == jdk25.home on $sys" "$detail"
    opts="$(jq -r --arg s "$sys" '.[$s].default.javaToolOptions.v' "$jj")"
    lombok="$(jq -r --arg s "$sys" '.[$s].default.lombokOut.v[0] // ""' "$jj")"
    detail=""
    [[ "$opts" == -javaagent:*lombok.jar ]] || detail="JAVA_TOOL_OPTIONS lacks -javaagent:...lombok.jar ('$opts')"
    [[ -n "$lombok" && "$opts" == "-javaagent:$lombok/share/java/lombok.jar" ]] || detail="$detail agent does not point at the lombok package in packages"
    record "JAVA_TOOL_OPTIONS loads the shell's lombok on $sys" "$detail"
  done
else
  record "java template" "template eval error"
fi

echo -e "\n${BOLD}rust${NC}"
rj="$(json_of language-specific/rust)"
if [[ -f "$rj" ]]; then
  for sys in "${SUPPORTED[@]}"; do
    got="$(jq -r --arg s "$sys" '.[$s].default.rustSrcPath.v' "$rj")"
    detail=""
    [[ "$got" == /nix/store/*/lib/rustlib/src/rust/library ]] || detail="RUST_SRC_PATH is '$got'"
    record "RUST_SRC_PATH layout on $sys" "$detail"
  done
fi
detail=""
jq -e '.nodes.fenix.inputs.nixpkgs | type == "array"' "$TPL/language-specific/rust/flake.lock" > /dev/null 2>&1 || detail="fenix does not follow the template's nixpkgs in flake.lock"
record "fenix input follows nixpkgs (lock)" "$detail"
detail=""
jq -e '.nodes."nix-tests".inputs.nixpkgs | type == "array"' "$TPL/language-specific/nix/flake.lock" > /dev/null 2>&1 || detail="nix-tests does not follow the template's nixpkgs in flake.lock"
record "nix template: nix-tests input follows nixpkgs (lock)" "$detail"

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All $PASS checks passed.${NC}"
  exit 0
fi

echo -e "${RED}${BOLD}FAILURES ($FAIL of $((PASS + FAIL))):${NC}"
for entry in "${FAILURES[@]}"; do
  IFS="|" read -r label err <<< "$entry"
  echo -e "  ${RED}x${NC} ${BOLD}$label${NC}"
  echo -e "      ${DIM}$err${NC}"
done
exit 1
