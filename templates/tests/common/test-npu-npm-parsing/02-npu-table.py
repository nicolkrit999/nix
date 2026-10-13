import importlib.util
import os
import re
import sys
import types

NPU_PATH, ALIASES_PATH = sys.argv[1], sys.argv[2]
DUMMY_PREFETCH = "/nonexistent/nix-prefetch-url"

requests_stub = types.ModuleType("requests")


class RequestException(Exception):
    pass


def _no_network(*_args, **_kwargs):
    raise RequestException("network disabled in test")


requests_stub.RequestException = RequestException
requests_stub.get = _no_network
sys.modules["requests"] = requests_stub
os.environ["NIX_PREFETCH_URL"] = DUMMY_PREFETCH

spec = importlib.util.spec_from_file_location("npu", NPU_PATH)
npu = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(npu)
except Exception as exc:
    print(f"FAIL\tnpu.py imports with only NIX_PREFETCH_URL set\t{exc!r}")
    sys.exit(1)

results = []


def record(name, ok, detail=""):
    results.append((name, ok, detail))


def run_main(url):
    captured = {}

    class Done:
        returncode = 0
        stdout = "0000\n"
        stderr = ""

    def fake_run(args, **_kwargs):
        captured["args"] = list(args)
        return Done()

    real_run, real_argv, real_stdout = npu.subprocess.run, sys.argv, sys.stdout
    npu.subprocess.run = fake_run
    sys.argv = ["npu", url]
    sys.stdout = open(os.devnull, "w")
    try:
        rc = npu.main()
    finally:
        sys.stdout.close()
        npu.subprocess.run, sys.argv, sys.stdout = real_run, real_argv, real_stdout
    return rc, captured.get("args")


GH = "https://github.com/owner/repo"
URL_CASES = [
    ("github-blob-to-raw", f"{GH}/blob/main/dir/a.png",
     [DUMMY_PREFETCH, "https://raw.githubusercontent.com/owner/repo/main/dir/a.png"]),
    ("github-commit-to-archive", f"{GH}/commit/abc123",
     [DUMMY_PREFETCH, "--unpack", f"{GH}/archive/abc123.tar.gz"]),
    ("github-tag-to-archive", f"{GH}/releases/tag/v1.2.3",
     [DUMMY_PREFETCH, "--unpack", f"{GH}/archive/refs/tags/v1.2.3.tar.gz"]),
    ("github-tree-to-archive", f"{GH}/tree/dev",
     [DUMMY_PREFETCH, "--unpack", f"{GH}/archive/refs/heads/dev.tar.gz"]),
    ("gitlab-blob-to-raw", "https://gitlab.com/group/proj/-/blob/main/x.png",
     [DUMMY_PREFETCH, "https://gitlab.com/group/proj/-/raw/main/x.png"]),
    ("forgejo-src-to-raw", "https://codeberg.org/u/r/src/branch/main/f.png",
     [DUMMY_PREFETCH, "https://codeberg.org/u/r/raw/branch/main/f.png"]),
    ("plain-media-unchanged", "https://example.com/img/a.png",
     [DUMMY_PREFETCH, "https://example.com/img/a.png"]),
    ("page-unchanged-when-offline", "https://example.com/some/page",
     [DUMMY_PREFETCH, "https://example.com/some/page"]),
    ("encoded-name-sanitised", "https://example.com/img/My%20File%20(1).png",
     [DUMMY_PREFETCH, "--name", "My_File__1_.png", "https://example.com/img/My%20File%20(1).png"]),
    ("encoded-non-ascii-sanitised", "https://example.com/%C3%A9t%C3%A9.jpg",
     [DUMMY_PREFETCH, "--name", "_t_.jpg", "https://example.com/%C3%A9t%C3%A9.jpg"]),
    ("encoded-blob-raw-name", f"{GH}/blob/main/My%20Pic.png",
     [DUMMY_PREFETCH, "--name", "My_Pic.png", "https://raw.githubusercontent.com/owner/repo/main/My%20Pic.png"]),
    ("encoded-leading-dot-stripped", "https://example.com/img/%2Ehidden.png",
     [DUMMY_PREFETCH, "--name", "hidden.png", "https://example.com/img/%2Ehidden.png"]),
]

for name, url, expected in URL_CASES:
    try:
        rc, args = run_main(url)
    except Exception as exc:
        rc, args = repr(exc), None
    record(f"npu {name}", rc == 0 and args == expected, f"got rc={rc} args={args}, expected {expected}")

NAME_CASES = [
    ("a b/c", "a_b_c"),
    ("keep+._?=-AZaz09", "keep+._?=-AZaz09"),
    ("x;rm -rf $(y)", "x_rm_-rf___y_"),
    (".hidden.png", "hidden.png"),
    ("..", "download"),
    ("", "download"),
]
for raw, expected in NAME_CASES:
    got = npu.safe_store_name(raw)
    record(f"safe_store_name {raw!r}", got == expected, f"got {got!r}, expected {expected!r}")

all_names = [npu.safe_store_name(raw) for raw, _ in NAME_CASES]
record("safe_store_name output charset",
       all(re.fullmatch(r"[A-Za-z0-9+._?=-]+", n) and not n.startswith(".") for n in all_names), f"got {all_names}")

with open(NPU_PATH, encoding="utf-8") as fh:
    env_vars = re.findall(r'os\.environ\["([A-Z_]+)"\]', fh.read())
with open(ALIASES_PATH, encoding="utf-8") as fh:
    aliases_text = fh.read()
record("npu env var exported by shell-aliases.nix",
       env_vars == ["NIX_PREFETCH_URL"] and f'export {env_vars[0]}="' in aliases_text and "${./npu.py}" in aliases_text,
       f"npu.py reads {env_vars}; shell-aliases.nix must export it and run ${{./npu.py}}")

failed = 0
for name, ok, detail in results:
    print(f"{'PASS' if ok else 'FAIL'}\t{name}\t{'' if ok else detail}")
    failed += 0 if ok else 1
sys.exit(1 if failed or not results else 0)
