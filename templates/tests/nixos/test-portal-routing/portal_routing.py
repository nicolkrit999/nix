#!/usr/bin/env python3
"""Helper for check-nixos-portal-routing.sh (stdlib only).

  write-config <portalConfig.json> <dir>      write xdg-desktop-portal/*.conf like the NixOS module
  desktops <sessionData-desktops-dir>         print one XDG_CURRENT_DESKTOP value per session file
  verdict <desktop> <sim-output-file>         print "ok" or the list of violations
  bleed-variant <in.json> <out.json>          reintroduce a bleed: kde in every default, all "none" routes dropped
"""
import json
import pathlib
import re
import sys

# desktop token (lowercase, first match wins) -> (FileChooser, Screenshot, ScreenCast); None = not asserted
EXPECT = {
    "hyprland": ("gtk", "hyprland", "hyprland"),
    "kde": ("kde", "kde", "kde"),
    "gnome": ("gnome", "gnome", "gnome"),
    "cosmic": ("cosmic", "cosmic", "cosmic"),
    "niri": ("gtk", "gnome", "gnome"),
    "mango": ("gtk", "wlr", "wlr"),
}
DEFAULT = ("gtk", None, None)
ALL = {"kde", "gnome", "cosmic", "wlr", "hyprland"}
OWN = {"hyprland": {"hyprland"}, "kde": {"kde"}, "gnome": {"gnome"}, "cosmic": {"cosmic"}, "niri": {"gnome"}, "mango": {"wlr"}}
ALWAYS_FOREIGN = {"kwallet"}
LINE = re.compile(r"^Using (\S+)\.portal for (\w+) \((interface specific|default) config\)")


def write_config(src, dst):
    cfg = json.load(open(src))
    out = pathlib.Path(dst) / "xdg-desktop-portal"
    out.mkdir(parents=True, exist_ok=True)
    for key, routes in cfg.items():
        name = "portals.conf" if key == "common" else f"{key}-portals.conf"
        body = "[preferred]\n" + "".join(f"{k}={v}\n" for k, v in routes.items())
        (out / name).write_text(body)


def desktops(root):
    seen = []
    for f in sorted(pathlib.Path(root).glob("share/*/*.desktop")):
        m = re.search(r"^DesktopNames=(.*)$", f.read_text(), re.M)
        if m:
            d = ":".join(x for x in m.group(1).split(";") if x)
            if d and d not in seen:
                seen.append(d)
    print("\n".join(seen))


def verdict(desktop, simfile):
    text = open(simfile).read().splitlines()
    chosen = {}
    for line in text:
        m = LINE.match(line)
        if m:
            chosen.setdefault(m.group(2), m.group(1))
    bad = []
    dep = [line for line in text if "via the deprecated UseIn" in line]
    if dep:
        bad.append(f"{len(dep)} deprecated-UseIn fallback(s), first: {dep[0]}")
    toks = [t.lower() for t in desktop.split(":")]
    exp = next((EXPECT[t] for t in toks if t in EXPECT), DEFAULT)
    for iface, want in zip(("FileChooser", "Screenshot", "ScreenCast"), exp):
        if want is not None and chosen.get(iface) != want:
            bad.append(f"{iface} -> {chosen.get(iface)} (want {want})")
    own = next((OWN[t] for t in toks if t in OWN), set())
    foreign = (ALL - own) | ALWAYS_FOREIGN | (set() if "kde" in toks else {"plasmanotify"})
    picked = set()
    for line in text:
        m = LINE.match(line)
        if m and m.group(1) in foreign:
            picked.add(f"{m.group(2)}->{m.group(1)}")
    if picked:
        bad.append("backend of another desktop selected: " + ",".join(sorted(picked)))
    if chosen.get("Secret") != "gnome-keyring":
        bad.append(f"Secret -> {chosen.get('Secret')} (want gnome-keyring)")
    if "FileChooser" not in chosen:
        bad.append("no backend line for FileChooser (xdp did not start or log format changed)")
    print("ok" if not bad else "; ".join(bad))


def bleed_variant(src, dst):
    cfg = json.load(open(src))
    out = {}
    for key, routes in cfg.items():
        r = {k: v for k, v in routes.items() if v != "none"}
        names = [b for b in r.get("default", "gtk").split(";") if b and b != "kde"]
        r["default"] = ";".join(["kde"] + names)
        out[key] = r
    json.dump(out, open(dst, "w"))


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"write-config": write_config, "desktops": desktops, "verdict": verdict, "bleed-variant": bleed_variant}[cmd](*args)
