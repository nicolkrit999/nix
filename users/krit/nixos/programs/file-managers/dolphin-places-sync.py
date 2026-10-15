"""Make a Dolphin places file (user-places.xbel) follow a declared bookmark order.

usage: dolphin-places-sync SEED TARGET [--last HREF]...

SEED is a complete xbel file: its bookmarks are the managed places, in the
declared order. TARGET is the live file.

- TARGET missing: it is created from SEED.
- Otherwise TARGET is rebuilt as the managed places (SEED order, each keeping
  its TARGET block when present, so Dolphin attributes survive), then every
  other TARGET bookmark in its current order, then the --last hrefs.
- TARGET keeps its own header (Dolphin metadata) and bookmark blocks verbatim.
- The result is validated as well-formed xbel, loses no TARGET bookmark and is
  written through a temp file; the previous file is saved once as TARGET.bak.
- Unchanged output touches nothing. Anything unexpected leaves TARGET as it is
  and exits non-zero.
"""
import html
import os
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET

BOOKMARK = re.compile(r"<bookmark\s[^>]*>.*?</bookmark>", re.S)
HREF = re.compile(r'<bookmark\s[^>]*?\bhref="([^"]*)"')
CLOSE = "</xbel>"


def die(msg):
    sys.stderr.write("dolphin-places-sync: %s\n" % msg)
    sys.exit(1)


def split(path):
    """Return (header, [(href, block)]) of an xbel file."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    try:
        ET.fromstring(text)
    except ET.ParseError as e:
        die("%s is not well-formed xbel (%s), left untouched" % (path, e))
    first = BOOKMARK.search(text)
    end = text.rfind(CLOSE)
    if end < 0:
        die("%s has no %s, left untouched" % (path, CLOSE))
    head_end = first.start() if first else end
    header = text[:head_end].rstrip()
    body = text[head_end:end]
    blocks = [m.group(0) for m in BOOKMARK.finditer(body)]
    if BOOKMARK.sub("", body).strip():
        die("%s has content between bookmarks that would be lost, left untouched" % path)
    entries = []
    for b in blocks:
        m = HREF.match(b)
        if not m:
            die("%s has a bookmark without href, left untouched" % path)
        entries.append((html.unescape(m.group(1)), b.strip()))
    return header, entries


def render(header, entries):
    lines = [header] + [" " + b for _, b in entries] + [CLOSE]
    return "\n".join(lines) + "\n"


def uniq(entries):
    seen, out = set(), []
    for href, b in entries:
        if href not in seen:
            seen.add(href)
            out.append((href, b))
    return out


def write_atomic(target, text):
    d = os.path.dirname(os.path.abspath(target))
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".user-places.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        ET.parse(tmp)
        if os.path.exists(target):
            os.chmod(tmp, os.stat(target).st_mode & 0o7777)
        else:
            os.chmod(tmp, 0o644)
        os.replace(tmp, target)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def main(argv):
    last, args, i = [], [], 0
    while i < len(argv):
        if argv[i] == "--last":
            if i + 1 >= len(argv):
                die("--last needs an href")
            last.append(argv[i + 1])
            i += 2
        else:
            args.append(argv[i])
            i += 1
    if len(args) != 2:
        die("usage: dolphin-places-sync SEED TARGET [--last HREF]...")
    seed, target = args

    seed_header, seed_entries = split(seed)
    seed_entries = uniq(seed_entries)

    if not os.path.exists(target):
        write_atomic(target, render(seed_header, seed_entries))
        return

    header, entries = split(target)
    entries = uniq(entries)
    have = dict(entries)
    wanted = dict(seed_entries)
    managed = [(h, have.get(h, b)) for h, b in seed_entries if h not in last]
    pinned = {h for h, _ in managed} | set(last)
    extras = [(h, b) for h, b in entries if h not in pinned]
    tail = [(h, have.get(h, wanted.get(h))) for h in last if h in have or h in wanted]
    result = managed + extras + tail

    if {h for h, _ in entries} - {h for h, _ in result}:
        die("rebuild would drop a bookmark, %s left untouched" % target)
    out = render(header, result)
    ET.fromstring(out)
    with open(target, encoding="utf-8") as f:
        if f.read() == out:
            return
    bak = target + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(target, bak)
    write_atomic(target, out)


if __name__ == "__main__":
    main(sys.argv[1:])
