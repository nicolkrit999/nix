#!/usr/bin/env python3
import configparser
import filecmp
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HEADER_TOKENS = ("container.extractedAccent", "config.textColor")
LOCK_STEPS = ("0.4", "0.5", "0.6", "0.7", "0.8", "0.9")
LOGIN_DIM = 0.8
BACKING_ALPHA = 0.88
MIN_TEXT = 4.5
MIN_ACCENT = 3.0
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lum(c):
    r, g, b = (lin(x) for x in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def over(fg, bg, alpha):
    return tuple(alpha * f + (1 - alpha) * b for f, b in zip(fg, bg))


def dimmed(wall, dim):
    return tuple(x * (1 - dim) for x in wall)


def strip_strings(line):
    return re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)


def enclosing_block(text, idx):
    depth, i = 0, idx
    while i >= 0:
        ch = text[i]
        if ch == "}":
            depth += 1
        elif ch == "{":
            if depth == 0:
                break
            depth -= 1
        i -= 1
    start, depth, j = i, 0, i
    while j < len(text):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                break
        j += 1
    return start, j + 1


def top_props(block):
    props, depth = {}, 0
    for line in block.split("\n"):
        code = strip_strings(line)
        if depth == 1:
            m = re.match(r"^\s*([A-Za-z_][\w.]*)\s*:\s*(.+?)\s*;?\s*$", line)
            if m and not code.rstrip().endswith("{"):
                props[m.group(1)] = m.group(2)
        depth += code.count("{") - code.count("}")
    return props


def type_of(text, block_start):
    m = re.search(r"(\w+)\s*$", text[:block_start])
    return m.group(1) if m else ""


class Out:
    def __init__(self, root):
        self.theme = os.path.join(root, "share/sddm/themes/pixie")
        self.main = open(os.path.join(self.theme, "Main.qml")).read()
        self.clock = open(os.path.join(self.theme, "components/Clock.qml")).read()
        self.conf = configparser.ConfigParser(interpolation=None)
        self.conf.optionxform = str
        self.conf.read(os.path.join(self.theme, "theme.conf"))
        self.c = self.conf["General"]


def check_scenario(meta, root, log, qmllint):
    res = []
    info = {"lock": None, "token": None}

    def add(name, ok, detail=""):
        res.append((name, bool(ok), "" if ok else detail))

    try:
        o = Out(root)
    except Exception as e:
        return [("outputs-readable", False, repr(e))], info
    m, c = o.main, o.c
    wall = rgb(meta["wallpaperHex"])

    add("autoColor-off", c.get("autoColor") == "false", f"autoColor={c.get('autoColor')!r}")
    colors_ok = all(HEX.match(c.get(k, "")) for k in ("accentColor", "textColor", "backgroundColor"))
    add("conf-colors-hex", colors_ok, str({k: c.get(k) for k in ("accentColor", "textColor", "backgroundColor")}))
    if not colors_ok:
        return res, info
    accent, text, back = rgb(c["accentColor"]), rgb(c["textColor"]), rgb(c["backgroundColor"])

    bg_file = os.path.join(o.theme, "assets", os.path.basename(c.get("background", "")))
    add("background-is-wallpaper", os.path.isfile(bg_file) and filecmp.cmp(bg_file, meta["wallpaperPath"], shallow=False),
        f"{c.get('background')} differs from the wallpaper under test")

    pal = {v.lower() for k, v in meta["palette"].items()}
    neutrals = {meta["palette"][f"base0{i}"].lower() for i in range(8)}
    if meta["role"] == "matrix":
        add("palette-from-scheme",
            c["textColor"][1:].lower() in neutrals and c["backgroundColor"][1:].lower() in neutrals and c["accentColor"][1:].lower() in pal,
            f"text/back/accent {c['textColor']}/{c['backgroundColor']}/{c['accentColor']} not drawn from scheme {meta['theme']}")
    else:
        add("override-applied", all(c.get(k, "").lower() == v.lower() for k, v in meta["themeConfig"].items()),
            f"theme.conf lacks the override {meta['themeConfig']}")

    leftovers = []
    for f in (os.path.join(o.theme, "Main.qml"), os.path.join(o.theme, "components/Clock.qml"),
              os.path.join(o.theme, "components/PowerBar.qml"), os.path.join(o.theme, "theme.conf")):
        if "@" in open(f).read():
            leftovers.append(os.path.basename(f))
    add("no-placeholders", not leftovers, f"'@' left in {leftovers}")

    ex = re.search(r"id:\s*colorExtractor\b", m)
    guard_ok, guard_detail = False, "colorExtractor canvas not found"
    if ex:
        bs, be = enclosing_block(m, ex.start())
        canvas = m[bs:be]
        op = re.search(r"onPaint:\s*\{\s*\n([^\n]*)\n", canvas)
        first = op.group(1).strip() if op else ""
        gpos = bs + canvas.find(first) if first else -1
        assigns = [a.start() for a in re.finditer(r"container\.extractedAccent\s*=[^=]", m)]
        inside = [a for a in assigns if bs <= a < be]
        guard_ok = first == 'if (config.autoColor !== "true") return;' and assigns and len(inside) == len(assigns) and all(a > gpos for a in assigns)
        guard_detail = f"first onPaint statement {first!r}; {len(assigns)} extractedAccent assignments, {len(inside)} inside the extractor"
    add("extractor-guard", guard_ok, guard_detail)

    starts = [ln for ln in m.split("\n") if "colorDelay.start()" in ln]
    add("delay-start-conditional", starts and all('config.autoColor === "true"' in ln for ln in starts),
        f"colorDelay.start() lines: {starts}")

    add("extractedAccent-defaults-to-accent", "property color extractedAccent: config.accentColor" in m
        and "property color baseColor: config.backgroundColor" in m, "extractedAccent/baseColor no longer bound to theme.conf")

    pb = re.search(r"id:\s*headerPower\b", m)
    date = re.search(r"id:\s*dateText\b", m)
    tok_date = tok_power = None
    z_date = z_power = None
    if pb and date:
        ps, pe = enclosing_block(m, pb.start())
        ds, de = enclosing_block(m, date.start())
        pprops, dprops = top_props(m[ps:pe]), top_props(m[ds:de])
        add("headerPower-is-PowerBar", type_of(m, ps) == "PowerBar", f"id: headerPower sits in {type_of(m, ps)!r}")
        tok_power, tok_date = pprops.get("textColor"), dprops.get("color")
        z_power, z_date = pprops.get("z"), dprops.get("z")
    else:
        add("headerPower-is-PowerBar", False, "id: headerPower or id: dateText missing")

    backings = {}
    for fm in re.finditer(r"fill:\s*(dateText|headerPower)\b", m):
        a_s, _ = enclosing_block(m, fm.start())
        r_s, r_e = enclosing_block(m, a_s - 1)
        if type_of(m, r_s) != "Rectangle":
            continue
        pr = top_props(m[r_s:r_e])
        a = re.search(r"Qt\.rgba\(container\.baseColor\.r,\s*container\.baseColor\.g,\s*container\.baseColor\.b,\s*([\d.]+)\)", pr.get("color", ""))
        backings.setdefault(fm.group(1), []).append((pr.get("z"), float(a.group(1)) if a else None))
    backing_ok = (sorted(backings) == ["dateText", "headerPower"] and all(len(v) == 1 for v in backings.values())
                  and all(v[0][1] == BACKING_ALPHA for v in backings.values())
                  and z_date and z_power and all(v[0][0] and int(v[0][0]) < int(z) for v, z in ((backings.get("dateText", [(0, 0)]), z_date), (backings.get("headerPower", [(0, 0)]), z_power))))
    add("header-backings", backing_ok, f"backings {backings}, dateText z={z_date}, headerPower z={z_power}")

    token_ok = tok_date in HEADER_TOKENS and tok_date == tok_power
    info["token"] = tok_date if token_ok else None
    add("header-token", token_ok, f"dateText color={tok_date!r}, PowerBar textColor={tok_power!r}")
    if token_ok:
        fg_hex = c["accentColor"] if tok_date == "container.extractedAccent" else c["textColor"]
        fg = rgb(fg_hex)
        ratio = contrast(fg, back)
        add("header-contrast", ratio >= MIN_TEXT, f"{fg_hex} on {c['backgroundColor']} = {ratio:.2f}:1, need {MIN_TEXT}")
        want = "container.extractedAccent" if contrast(accent, back) >= MIN_TEXT else "config.textColor"
        add("header-selection-rule", tok_date == want, f"accent contrast {contrast(accent, back):.2f}:1 so expected {want}, built {tok_date}")
    else:
        fg = None

    ov = re.search(r'color:\s*"black"\s*\n\s*opacity:\s*loginState\.visible\s*\?\s*([\d.]+)\s*:\s*([\d.]+)', m)
    lock = login = None
    if ov:
        login, lock = float(ov.group(1)), float(ov.group(2))
        info["lock"] = lock
    add("dim-values", ov and login == LOGIN_DIM and ov.group(2) in LOCK_STEPS,
        f"overlay opacity login/lock = {ov.groups() if ov else None}")

    if fg is not None and ov:
        worst = min(contrast(fg, over(back, dimmed(wall, d), BACKING_ALPHA)) for d in (lock, login))
        add("header-on-backing", worst >= MIN_TEXT, f"{worst:.2f}:1 over the dimmed wallpaper, need {MIN_TEXT}")
    else:
        add("header-on-backing", False, "needs header token and dim values")

    if ov:
        bgl = dimmed(wall, lock)
        bind = re.search(r"baseAccent:\s*([\w.]+)", m)
        add("clock-accent-binding", bind and bind.group(1) == "container.extractedAccent", f"baseAccent bound to {bind.group(1) if bind else None}")
        r = contrast(accent, bgl)
        add("clock-readable", r >= MIN_ACCENT, f"accent {c['accentColor']} on dimmed wallpaper {r:.2f}:1, need {MIN_ACCENT}")
        hs = re.search(r'text:\s*"Press any key to unlock"', m)
        hint_ok, detail = False, "hint text not found"
        if hs:
            hb = m[slice(*enclosing_block(m, hs.start()))]
            hp = top_props(hb)
            alpha = float(hp.get("opacity", "1"))
            hr = contrast(over(text, bgl, alpha), bgl)
            hint_ok = hp.get("color") == "config.textColor" and hr >= MIN_TEXT
            detail = f"hint colour {hp.get('color')} at opacity {alpha} on dimmed wallpaper {hr:.2f}:1, need {MIN_TEXT}"
        add("hint-readable", hint_ok, detail)

    clock_effect = "MultiEffect" in o.clock
    add("effects-imported", (not clock_effect or "import QtQuick.Effects" in o.clock) and "import QtQuick.Effects" in m,
        "MultiEffect used without import QtQuick.Effects")

    if log is None:
        res.append(("build-log", None, "no build log retained"))
    else:
        dl = re.search(r"sddm-pixie: lock dim=([\d.]+) login dim=([\d.]+) header fg=(\S+)", log)
        okl = bool(dl) and "no step passed" not in log and lock is not None and float(dl.group(1)) == lock and dl.group(3) == tok_date
        add("build-log", okl, f"log lock dim/header fg = {dl.groups() if dl else None}; 'no step passed' present: {'no step passed' in log}")

    if qmllint:
        syn = lint_syntax(qmllint, o.theme)
        add("qmllint-syntax", not syn, f"syntax errors: {syn}")
    else:
        res.append(("qmllint-syntax", None, "qmllint not in the store"))
    return res, info


def lint_syntax(qmllint, theme):
    qml_dir = os.path.join(os.path.dirname(os.path.dirname(qmllint)), "lib/qt-6/qml")
    bad = []
    for f in ("Main.qml", "components/Clock.qml"):
        p = subprocess.run([qmllint, "--ignore-settings", "--json", "-", "-I", qml_dir, os.path.join(theme, f)],
                           capture_output=True, text=True)
        try:
            files = json.loads(p.stdout)["files"]
        except Exception:
            bad.append(f"{f}: unreadable qmllint output")
            continue
        for fl in files:
            bad += [f"{f}:{w['line']} {w['message']}" for w in fl["warnings"] if w["id"] == "syntax"]
    return bad


def check_monotonic(dims):
    res = []
    for theme, d in sorted(dims.items()):
        if not all(k in d for k in ("white", "grey", "black")):
            res.append((theme, False, f"missing wallpapers: {sorted(d)}"))
            continue
        ok = d["black"] <= d["grey"] <= d["white"] and d["white"] > d["black"] and d["black"] == 0.4
        res.append((theme, ok, f"lock dim black/grey/white = {d['black']}/{d['grey']}/{d['white']}, need black=0.4 <= grey <= white and white > black"))
    return res


def mutate(root, tmp, fn):
    dst = os.path.join(tmp, "mut")
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(root, dst, symlinks=True)
    os.chmod(dst, 0o755)
    for dp, dn, fs in os.walk(dst):
        for x in dn + fs:
            os.chmod(os.path.join(dp, x), 0o755)
    th = os.path.join(dst, "share/sddm/themes/pixie")
    fn(th)
    return dst


def edit(path, pattern, repl, count=1):
    s = open(path).read()
    n = re.subn(pattern, repl, s, count=count, flags=re.S)
    if n[1] == 0:
        raise RuntimeError(f"mutation pattern not found: {pattern!r}")
    open(path, "w").write(n[0])


def controls(meta, root, log, qmllint):
    wanted = [
        ("autoColor=true", lambda t: edit(t + "/theme.conf", r"autoColor=false", "autoColor=true"), "autoColor-off"),
        ("extractor guard removed", lambda t: edit(t + "/Main.qml", r'if \(config\.autoColor !== "true"\) return;', ""), "extractor-guard"),
        ("guard moved below the first statement", lambda t: edit(t + "/Main.qml", r'(if \(config\.autoColor !== "true"\) return;)(\s*var ctx = getContext\("2d"\);)', r"\2\n\1"), "extractor-guard"),
        ("unconditional colorDelay.start()", lambda t: edit(t + "/Main.qml", r'if \(config\.autoColor === "true"\) colorDelay\.start\(\);', "colorDelay.start();"), "delay-start-conditional"),
        ("placeholder left behind", lambda t: edit(t + "/Main.qml", r"textColor:\s*container\.extractedAccent", "textColor: @HEADER_FG@"), "no-placeholders"),
        ("one backing rectangle dropped", lambda t: edit(t + "/Main.qml", r"fill:\s*dateText", "fill: parent"), "header-backings"),
        ("backing alpha lowered", lambda t: edit(t + "/Main.qml", r"container\.baseColor\.b,\s*0\.88\)", "container.baseColor.b, 0.3)"), "header-backings"),
        ("header token outside the allowed pair", lambda t: edit(t + "/Main.qml", r"color:\s*container\.extractedAccent(\s*z: 100)", r'color: "white"\1'), "header-token"),
        ("accent unreadable on the backing", lambda t: edit(t + "/theme.conf", r"accentColor=#[0-9a-fA-F]{6}", "accentColor=" + open(t + "/theme.conf").read().split("backgroundColor=")[1].split()[0]), "header-contrast"),
        ("lock dim under-dimmed", lambda t: edit(t + "/Main.qml", r"(loginState\.visible \? [\d.]+ : )[\d.]+(\s*\n\s*Behavior on opacity \{ NumberAnimation \{ duration: 400 \} \})", r"\g<1>0.4\2"), "clock-readable"),
        ("login dim changed", lambda t: edit(t + "/Main.qml", r"(color: \"black\"\s*\n\s*opacity: loginState\.visible \? )[\d.]+", r"\g<1>0.7"), "dim-values"),
        ("Effects import dropped", lambda t: edit(t + "/components/Clock.qml", r"import QtQuick\.Effects", ""), "effects-imported"),
    ]
    wanted.append(("hint opacity lowered", lambda t: edit(t + "/Main.qml", r"opacity: 0\.85", "opacity: 0.2"), "hint-readable"))
    if qmllint:
        wanted.append(("syntax broken", lambda t: edit(t + "/Main.qml", r"layer\.enabled: true", "layer.enabled: true }"), "qmllint-syntax"))
    out = []
    base = {n: ok for n, ok, _ in check_scenario(meta, root, log, qmllint)[0]}
    with tempfile.TemporaryDirectory() as tmp:
        for label, fn, trip in wanted:
            try:
                dst = mutate(root, tmp, fn)
                got = {n: ok for n, ok, _ in check_scenario(meta, dst, log, qmllint)[0]}
                out.append((label, trip, base.get(trip) is not False and got.get(trip) is False, got.get(trip)))
            except Exception as e:
                out.append((label, trip, False, f"mutation failed: {e}"))
        d = {"x": {"white": 0.4, "grey": 0.4, "black": 0.4}}
        out.append(("white not dimmed harder than black", "monotonic", check_monotonic(d)[0][1] is False, None))
        d = {"x": {"white": 0.7, "grey": 0.4, "black": 0.5}}
        out.append(("black dimmed more than needed", "monotonic", check_monotonic(d)[0][1] is False, None))
    return out


def load_builds(work):
    outs, errs = {}, {}
    for name in sorted(os.listdir(work)):
        path = os.path.join(work, name)
        if name.startswith("build.") and name.endswith(".json"):
            try:
                for ent in json.load(open(path)):
                    outs[ent["drvPath"]] = ent["outputs"]["out"]
            except Exception:
                pass
        elif name.startswith("err."):
            errs[name[4:]] = open(path).read()
    return outs, errs


def main():
    meta_all = json.load(open(sys.argv[1]))
    work = sys.argv[2]
    matrix, tools = meta_all["matrix"], meta_all["tools"]
    outs, errs = load_builds(work)
    qmllint = tools.get("qmllint") if tools.get("qmllint") and os.access(tools["qmllint"], os.X_OK) else None
    failed = 0
    dims, tokens, skipped, built = {}, set(), set(), {}

    print(f"{len(matrix)} scenarios; qmllint: {qmllint or 'not in the store (syntax lint skipped)'}")
    for sid in sorted(matrix):
        meta = matrix[sid]
        out = outs.get(meta["drvPath"])
        if not out or not os.path.isdir(out):
            tail = "\n     ".join(l for l in errs.get(sid, "no build output").splitlines()[-12:])
            print(f"FAIL {sid}: build failed\n     {tail}")
            failed += 1
            continue
        logf = os.path.join(work, f"log.{sid}")
        log = open(logf).read() if os.path.isfile(logf) else None
        checks, info = check_scenario(meta, out, log, qmllint)
        bad = [x for x in checks if x[1] is False]
        built[sid] = (out, log, not bad)
        skip = [x for x in checks if x[1] is None]
        skipped |= {x[0] for x in skip}
        if info["token"]:
            tokens.add(info["token"])
        if meta["role"] == "matrix" and info["lock"] is not None:
            dims.setdefault(meta["theme"], {})[meta["wallpaper"]] = info["lock"]
        print(f"{'FAIL' if bad else 'PASS'} {sid}: {len(checks) - len(bad) - len(skip)}/{len(checks)} checks, lock dim {info['lock']}, header {info['token']}")
        for n, _, d in bad:
            print(f"     FAIL {n}: {d}")
        failed += bool(bad)

    print("\nlock dim per theme (black / grey / white wallpaper):")
    for theme, ok, d in check_monotonic(dims):
        print(f"{'PASS' if ok else 'FAIL'} {theme}: {d if not ok else ' / '.join(str(dims[theme][w]) for w in ('black', 'grey', 'white'))}")
        failed += not ok

    real = {}
    for mt in matrix.values():
        if mt["role"] == "matrix":
            p = mt["palette"]
            real[mt["theme"]] = (mt["polarity"], lum(rgb(p["base00"])) > lum(rgb(p["base05"])))
    labels_ok = all((pol == "light") == bright for pol, bright in real.values()) and {"light", "dark"} <= {pol for pol, _ in real.values()}
    print(f"{'PASS' if labels_ok else 'FAIL'} matrix covers light and dark base16 schemes (base00 vs base05 luminance matches the polarity label): {real}")
    failed += not labels_ok
    both = set(HEADER_TOKENS) <= tokens
    print(f"{'PASS' if both else 'FAIL'} both header-colour branches exercised: {sorted(tokens)}")
    failed += not both

    print("\ncontrols (each mutation of a good build must trip the named check):")
    picks = [s for s in sorted(built) if matrix[s]["role"] == "matrix" and matrix[s]["wallpaper"] == "white" and matrix[s]["polarity"] == "dark" and built[s][2]][:1]
    if not picks:
        print("FAIL no passing white-wallpaper dark scenario to mutate")
        failed += 1
    for s in picks:
        out, log, _ = built[s]
        print(f"baseline: {s}")
        for label, trip, tripped, got in controls(matrix[s], out, log, qmllint):
            print(f"{'PASS' if tripped else 'FAIL'} control '{label}' trips {trip}" + ("" if tripped else f" (got {got})"))
            failed += not tripped

    if skipped:
        print(f"\nSKIPPED (tool or log unavailable): {sorted(skipped)}")
    print(f"\n{'FAIL' if failed else 'PASS'}: {failed} failing item(s)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
