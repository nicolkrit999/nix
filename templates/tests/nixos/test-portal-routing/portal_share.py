#!/usr/bin/env python3
"""Portal data of a profile without building the profile (stdlib only).

Only share/xdg-desktop-portal, share/wayland-sessions and share/xsessions matter to the
simulation. Entries that cache.nixos.org serves are read from its NAR listings (.ls) and
single-file reads, so nothing of theirs is downloaded beyond those files. Repo-built entries
are either stand-ins (portal-common.nix) or trivial derivations (no src, no fixed-output
hash) that the check script builds; anything else is reported, never built.

  scan <out.json> <info.json>...           cached? + data-dir listing for every entry path
  classify <info.json> <scan.json>         print {"build": [...], "heavy": [...]} for uncached entries
  assemble <info.json> <scan.json> <sys|hm|sessions> <dir>
                                           merge the entries' data dirs like buildEnv (priority, first wins)
  will-build-heavy <dry-run-output>        print the non-trivial drvs a dry run would build
  real-files <real.json> <scan.json> <spec> print portal file paths of the spec's cached entries,
                                           and on stderr the uncached entries that could not be read
"""
import concurrent.futures as cf
import json
import os
import pathlib
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

CACHE = "https://cache.nixos.org"
DATA = ("share/xdg-desktop-portal", "share/wayland-sessions", "share/xsessions")
PORTAL = DATA[0]


def _nix(*args):
    return subprocess.run(["nix", *args], capture_output=True, text=True)


def _cached(path):
    h = pathlib.PurePath(path).name.split("-", 1)[0]
    for attempt in range(4):
        try:
            req = urllib.request.Request(f"{CACHE}/{h}.narinfo", method="HEAD")
            with urllib.request.urlopen(req, timeout=20) as r:
                return r.status == 200
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return False
        except OSError:
            pass
        time.sleep(1 + attempt)
    raise SystemExit(f"cache.nixos.org unreachable for {path}")


def _listing(path):
    out = {}
    for d in DATA:
        r = _nix("store", "ls", "--json", "-R", "--store", CACHE, f"{path}/{d}")
        if r.returncode != 0:
            if "does not exist" in r.stderr:
                continue
            raise SystemExit(f"nix store ls {path}/{d}: {r.stderr.strip()}")
        def walk(node, rel):
            if node["type"] == "directory":
                for k, v in node.get("entries", {}).items():
                    walk(v, f"{rel}/{k}")
            else:
                out[rel] = {"type": node["type"], "target": node.get("target")}
        walk(json.loads(r.stdout), d)
    return out


def _probe(path):
    if not _cached(path):
        return path, {"cached": False}
    return path, {"cached": True, "files": _listing(path)}


def _entries(info):
    return info.get("sys", []) + info.get("hm", []) + info.get("sessions", []) + info.get("entries", [])


def scan(out, *infos):
    paths = set()
    for f in infos:
        data = json.load(open(f))
        for info in ([data] if "sys" in data else data.values()):
            paths |= {e["path"] for e in _entries(info) if not e.get("standIn")}
    with cf.ThreadPoolExecutor(32) as ex:
        res = dict(ex.map(_probe, sorted(paths)))
    json.dump(res, open(out, "w"))


def _trivial(drv_json):
    env = {**drv_json.get("env", {}), **(drv_json.get("structuredAttrs") or {})}
    if "__json" in env:
        env = {**env, **json.loads(env["__json"])}
    if env.get("preferLocalBuild") in ("1", True):
        return True
    return not ({"src", "srcs", "outputHash", "cargoDeps", "urls", "url"} & set(env))


def _show(drvs):
    r = _nix("derivation", "show", *drvs)
    if r.returncode != 0:
        raise SystemExit(f"nix derivation show: {r.stderr.strip()}")
    d = json.loads(r.stdout)
    d = d.get("derivations", d)
    return {(k if k.startswith("/nix/store/") else f"/nix/store/{k}"): v for k, v in d.items()}


def classify(info_f, scan_f):
    info, sc = json.load(open(info_f)), json.load(open(scan_f))
    todo = {e["drv"]: e for e in _entries(info) if not e.get("standIn") and not sc[e["path"]]["cached"]}
    shown = _show(sorted(todo)) if todo else {}
    build = [e["path"] for d, e in todo.items() if _trivial(shown[d])]
    heavy = [f"{e['name']} ({e['path']})" for d, e in todo.items() if not _trivial(shown[d])]
    print(json.dumps({"build": sorted(set(build)), "heavy": sorted(set(heavy))}))


def _cat(path):
    """Contents of a store file, following symlinks, from the local store or the cache."""
    for _ in range(10):
        p = pathlib.Path(path)
        if p.is_symlink() or p.exists():
            return p.read_bytes()
        r = _nix("store", "ls", "--json", "--store", CACHE, path)
        node = json.loads(r.stdout) if r.returncode == 0 else {}
        if node.get("type") == "symlink":
            t = node["target"]
            path = t if t.startswith("/") else str(p.parent / t)
            continue
        r = subprocess.run(["nix", "store", "cat", "--store", CACHE, path], capture_output=True)
        if r.returncode != 0:
            raise SystemExit(f"cannot read {path}: {r.stderr.decode().strip()}")
        return r.stdout
    raise SystemExit(f"symlink loop at {path}")


def _local_files(root):
    out = {}
    for d in DATA:
        base = pathlib.Path(root, d)
        if base.exists():
            for f in base.rglob("*"):
                if f.is_file() or (f.is_symlink() and not f.is_dir()):
                    out[str(f.relative_to(root))] = {"local": str(f)}
    return out


def assemble(info_f, scan_f, which, dest):
    info, sc = json.load(open(info_f)), json.load(open(scan_f))
    entries = sorted(enumerate(info[which]), key=lambda ie: (ie[1]["priority"], ie[0]))
    jobs, seen = [], set()
    for _, e in entries:
        if e.get("standIn"):
            files = _local_files(e["standIn"])
        elif sc[e["path"]]["cached"]:
            files = sc[e["path"]]["files"]
        else:
            files = _local_files(e["path"])
            if not pathlib.Path(e["path"]).exists():
                raise SystemExit(f"{e['name']} was neither cached, a stand-in nor built: {e['path']}")
        for rel, meta in files.items():
            if rel in seen:
                continue
            seen.add(rel)
            jobs.append((rel, meta.get("local") or f"{e['path']}/{rel}"))
    with cf.ThreadPoolExecutor(16) as ex:
        for rel, data in zip([j[0] for j in jobs], ex.map(_cat, [j[1] for j in jobs])):
            t = pathlib.Path(dest, rel)
            t.parent.mkdir(parents=True, exist_ok=True)
            t.write_bytes(data)
    pathlib.Path(dest, PORTAL).mkdir(parents=True, exist_ok=True)


def will_build_heavy(dry_out):
    text = open(dry_out).read()
    m = re.search(r"will be built:\n((?:  /nix/store/\S+\n?)+)", text)
    drvs = re.findall(r"/nix/store/\S+\.drv", m.group(1)) if m else []
    if not drvs:
        return
    shown = _show(drvs)
    for d in drvs:
        if not _trivial(shown[d]):
            print(re.sub(r"^/nix/store/[a-z0-9]{32}-", "", d))


def real_files(real_f, scan_f, spec):
    real, sc = json.load(open(real_f)), json.load(open(scan_f))
    files, unread = set(), []
    for e in real[spec]["entries"]:
        if e.get("standIn"):
            continue
        s = sc[e["path"]]
        if s["cached"]:
            files |= {r for r in s["files"] if r.startswith(PORTAL)}
        else:
            unread.append(e["name"])
    print("\n".join(sorted(files)))
    print(" ".join(sorted(set(unread))), file=sys.stderr)


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"scan": scan, "classify": classify, "assemble": assemble,
     "will-build-heavy": will_build_heavy, "real-files": real_files}[cmd](*args)
