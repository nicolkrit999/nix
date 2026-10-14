#!/usr/bin/env python3
"""Waybar contrast checker: see test-waybar-contrast-readme.md."""
import json
import re
import sys

TEXT_MIN = 4.5
ICON_MIN = 3.0
WHITE = (1.0, 1.0, 1.0)
BLACK = (0.0, 0.0, 0.0)

R, G, B, Y, X = "\033[0;31m", "\033[0;32m", "\033[1;33m", "\033[2m", "\033[0m"


class CssError(Exception):
    pass


def parse_color(v, defs=None):
    v = v.strip().lower()
    if v in ("transparent", "none"):
        return (0.0, 0.0, 0.0, 0.0)
    m = re.fullmatch(r"#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})", v)
    if m:
        h = m.group(1)
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
        return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a)
    m = re.fullmatch(r"rgba?\(([^)]*)\)", v)
    if m:
        p = [x.strip() for x in m.group(1).split(",")]
        if len(p) in (3, 4):
            ch = [float(x[:-1]) / 100 if x.endswith("%") else float(x) / 255 for x in p[:3]]
            a = float(p[3]) if len(p) == 4 else 1.0
            return (ch[0], ch[1], ch[2], a)
    m = re.fullmatch(r"alpha\((.*),\s*([0-9.]+)\)", v)
    if m:
        c = parse_color(m.group(1))
        return (c[0], c[1], c[2], c[3] * float(m.group(2)))
    raise CssError("unsupported color expression: " + v)


def lin(c):
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def lum(rgb):
    return 0.2126 * lin(rgb[0]) + 0.7152 * lin(rgb[1]) + 0.0722 * lin(rgb[2])


def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def over(top, under):
    a = top[3]
    return tuple(top[i] * a + under[i] * (1 - a) for i in range(3))


def hexof(rgba):
    return "#%02x%02x%02x" % tuple(round(max(0, min(1, c)) * 255) for c in rgba[:3])


class Css:
    def __init__(self, text):
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        self.defs = dict(re.findall(r"@define-color\s+(\w+)\s+([^;]+);", text))
        text = re.sub(r"@define-color\s+[^;]+;", "", text)
        self.rules = []
        for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", text):
            decls = {}
            for d in body.split(";"):
                if ":" in d:
                    k, val = d.split(":", 1)
                    decls[k.strip()] = re.sub(r"\s*!important", "", val).strip()
            for s in sel.split(","):
                s = s.strip()
                if s:
                    self.rules.append((s, decls, len(self.rules)))
        self.cache = {}

    def resolve(self, val):
        def sub(m):
            if m.group(1) not in self.defs:
                raise CssError("unresolved @" + m.group(1))
            return self.defs[m.group(1)]
        return re.sub(r"@(\w+)", sub, val)

    def tokens(self, sel):
        out, cur, depth = [], "", 0
        i = 0
        comb = " "
        parts = []
        for ch in sel:
            if ch == "(":
                depth += 1
            if ch == ")":
                depth -= 1
            if depth == 0 and ch in " >":
                if cur:
                    parts.append((comb, cur))
                    cur, comb = "", " "
                if ch == ">":
                    comb = ">"
                continue
            cur += ch
        if cur:
            parts.append((comb, cur))
        return parts

    def match_compound(self, comp, node):
        m = re.match(r"(\*|[a-zA-Z][\w-]*)?", comp)
        tag = m.group(1)
        rest = comp[m.end():]
        spec = [0, 0, 0]
        if tag and tag != "*":
            if node["tag"] != tag:
                return None
            spec[2] += 1
        while rest:
            m = re.match(r"#([\w-]+)", rest)
            if m:
                if node.get("id") != m.group(1):
                    return None
                spec[0] += 1
                rest = rest[m.end():]
                continue
            m = re.match(r"\.([\w-]+)", rest)
            if m:
                if m.group(1) not in node.get("classes", ()):
                    return None
                spec[1] += 1
                rest = rest[m.end():]
                continue
            m = re.match(r":not\(([^)]*)\)", rest)
            if m:
                inner = self.match_compound(m.group(1), node)
                if inner is not None:
                    return None
                rest = rest[m.end():]
                spec[1] += 1
                continue
            m = re.match(r":([\w-]+)", rest)
            if m:
                if m.group(1) not in ("hover", "active", "focus", "checked", "disabled"):
                    raise CssError("unsupported pseudo-class :" + m.group(1))
                if m.group(1) not in node.get("pseudo", ()):
                    return None
                spec[1] += 1
                rest = rest[m.end():]
                continue
            raise CssError("unsupported selector fragment: " + comp)
        return spec

    def match_chain(self, parts, idx, chain, pos):
        comb, comp = parts[idx]
        s = self.match_compound(comp, chain[pos])
        if s is None:
            return None
        if idx == 0:
            return s
        prev = idx - 1
        cands = [pos - 1] if comb == ">" else range(pos - 1, -1, -1)
        for p in cands:
            if p < 0:
                break
            r = self.match_chain(parts, prev, chain, p)
            if r is not None:
                return [s[i] + r[i] for i in range(3)]
        return None

    def style(self, chain, pos):
        key = (tuple(json.dumps(n, sort_keys=True, default=sorted) for n in chain[: pos + 1]),)
        if key in self.cache:
            return self.cache[key]
        hits = []
        for sel, decls, order in self.rules:
            r = self.match_chain(self.tokens(sel), len(self.tokens(sel)) - 1, chain, pos)
            if r is not None:
                hits.append((tuple(r), order, decls))
        hits.sort(key=lambda h: (h[0], h[1]))
        st = {}
        for _, _, decls in hits:
            for k, v in decls.items():
                st[k] = v
        self.cache[key] = st
        return st

    def fg(self, chain):
        for pos in range(len(chain) - 1, -1, -1):
            c = self.style(chain, pos).get("color")
            if c is not None:
                return parse_color(self.resolve(c))
        raise CssError("no color resolved")

    def bg_layers(self, chain):
        layers = []
        for pos in range(len(chain) - 1, -1, -1):
            st = self.style(chain, pos)
            if st.get("opacity") == "0":
                return None
            if "background-image" in st and st["background-image"] not in ("none",):
                raise CssError("background-image unsupported")
            val = st.get("background-color", st.get("background"))
            if val is None:
                continue
            c = parse_color(self.resolve(val))
            if c[3] <= 0:
                continue
            layers.append(c)
            if c[3] >= 1:
                break
        return list(reversed(layers))


def judge(fg, layers, minimum):
    if not layers:
        return "WARN", None, None
    worst = None
    for backdrop in (WHITE, BLACK):
        bg = backdrop
        for l in layers:
            bg = over(l, bg)
        f = over(fg, bg) if fg[3] < 1 else fg[:3]
        r = ratio(f, bg)
        if worst is None or r < worst[0]:
            worst = (r, bg)
    return ("PASS" if worst[0] >= minimum else "FAIL"), worst[1], worst[0]


def slot_names(palette):
    inv = {}
    for k, v in palette.items():
        inv.setdefault("#" + v.lower(), []).append(k)
    return inv


SPAN = re.compile(r"<span\s([^>]*)>")
ATTR = re.compile(r"(color|foreground|fgcolor|background|bgcolor)=[\"']?(#[0-9a-fA-F]{6,8})")


def spans_in(s):
    out = []
    for m in SPAN.finditer(s):
        a = {}
        for k, v in ATTR.findall(m.group(1)):
            a["bg" if k in ("background", "bgcolor") else "fg"] = v.lower()
        if "fg" in a or "bg" in a:
            out.append(a)
    return out


def strings(v):
    if isinstance(v, str):
        yield v
    elif isinstance(v, dict):
        for x in v.values():
            yield from strings(x)
    elif isinstance(v, list):
        for x in v:
            yield from strings(x)


def node(tag, id_=None, classes=(), pseudo=()):
    return {"tag": tag, "id": id_, "classes": sorted(classes), "pseudo": sorted(pseudo)}


def module_id(name):
    base = name.split("/", 1)[1] if name.split("/", 1)[0] in ("hyprland", "niri") else name
    return base.replace("/", "-")


def is_box(name):
    return name in ("hyprland/workspaces", "niri/workspaces", "hyprland/window", "niri/window")


def states_for(name, cfg):
    if name.endswith("/workspaces"):
        return [("default", (), ()), ("hover", (), ("hover",)), ("active", ("active",), ()),
                ("active+hover", ("active",), ("hover",)), ("urgent", ("urgent",), ()),
                ("focused", ("focused",), ())]
    if name == "battery":
        out = [("normal", (), ())]
        for s in cfg.get("states", {}):
            out.append((s, (s,), ()))
        out.append(("charging", ("charging",), ()))
        out.append(("critical+charging", ("critical", "charging"), ()))
        return out
    if name == "custom/coffee":
        return [("normal", (), ()), ("active", ("active",), ())]
    return [("normal", (), ())]


def format_keys(cfg, state_classes, states):
    keys = [k for k in cfg if k.startswith("format") and k != "format-icons"]
    if "charging" in state_classes and "format-charging" in cfg:
        return ["format-charging"]
    for sc in state_classes:
        if sc in states and "format-" + sc in cfg:
            return ["format-" + sc]
    return [k for k in keys if not any(k == "format-" + s for s in list(states) + ["charging"])]


def module_rows(css, name, cfg, slots):
    rows = []
    mid = module_id(name)
    extra = [cfg["class"]] if isinstance(cfg.get("class"), str) else list(cfg.get("class", [])) if isinstance(cfg.get("class"), list) else []
    side = [node("window", "waybar"), node("box"), node("box", None, ["modules-right"]), node("widget")]
    for label, classes, pseudo in states_for(name, cfg):
        if name.endswith("/workspaces"):
            chain = side + [node("box", mid), node("button", None, classes, pseudo), node("label")]
        elif is_box(name):
            chain = side + [node("box", mid, list(classes) + extra, pseudo), node("label")]
        else:
            chain = side + [node("label", mid, list(classes) + extra, pseudo)]
        el = f"{name}[{label}]"
        layers = css.bg_layers(chain)
        if layers is None:
            rows.append(("SKIP", el, "invisible (opacity 0)", None, None, None, ""))
            continue
        fg = css.fg(chain)
        rows.append(judged(el, "text", fg, layers, TEXT_MIN, slots))
        states = cfg.get("states", {}) if name == "battery" else {}
        keys = format_keys(cfg, list(classes), states) if classes or name == "battery" else format_keys(cfg, [], states)
        if not name.endswith("/workspaces"):
            keys = keys + [k for k in cfg if k in ("exec", "rewrite")]
        seen = set()
        for k in keys:
            for s in strings(cfg[k]):
                for sp in spans_in(s):
                    if "fg" not in sp:
                        continue
                    sl = layers
                    if "bg" in sp:
                        sl = [parse_color(sp["bg"])]
                    sig = (sp.get("fg"), sp.get("bg"))
                    if sig in seen:
                        continue
                    seen.add(sig)
                    rows.append(judged(f"{el} span({k})", "span", parse_color(sp["fg"]), sl, ICON_MIN, slots))
        for k in cfg:
            if k.startswith("tooltip-format"):
                tl = css.bg_layers(tooltip_chain())
                for s in strings(cfg[k]):
                    for sp in spans_in(s):
                        if "fg" in sp:
                            rows.append(judged(f"{el} tooltip-span({k})", "span", parse_color(sp["fg"]), tl, ICON_MIN, slots))
        if name == "custom/tags" and "awk" in str(cfg.get("exec", "")):
            rows += tag_rows(css, el, cfg["exec"], layers, slots)
    return rows


def tooltip_chain():
    return [node("tooltip", None, ["background"]), node("box"), node("label")]


def tag_rows(css, el, script, layers, slots):
    v = {k: val.lower() for k, val in re.findall(r"-v\s+(\w+)='(#[0-9a-fA-F]{6})'", script)}
    need = ("active_bg", "active_fg", "occupied", "empty")
    if any(k not in v for k in need):
        return [("FAIL", f"{el} tags-awk", "text", None, None, None, "cannot parse awk -v colors: " + ",".join(sorted(v)))]
    return [
        judged(f"{el} tag-active", "text", parse_color(v["active_fg"]), [parse_color(v["active_bg"])], TEXT_MIN, slots),
        judged(f"{el} tag-occupied", "text", parse_color(v["occupied"]), layers, TEXT_MIN, slots),
        judged(f"{el} tag-empty", "text", parse_color(v["empty"]), layers, TEXT_MIN, slots),
    ]


def judged(el, kind, fg, layers, minimum, slots):
    st, bg, r = judge(fg, layers, minimum)
    names = slots.get(hexof(fg), [])
    note = "/".join(names)
    if st == "WARN":
        return (st, el, kind, hexof(fg), "transparent", None, note)
    bgn = "/".join(slots.get(hexof(bg), []))
    return (st, el, kind, hexof(fg), hexof(bg), r, f"{note} on {bgn}".strip())


def analyse(css_text, cfg_text, palette):
    css = Css(css_text)
    bars = json.loads(cfg_text)
    bars = bars if isinstance(bars, list) else [bars]
    bar = bars[0]
    slots = slot_names(palette)
    rows = []
    mods = bar.get("modules-left", []) + bar.get("modules-center", []) + bar.get("modules-right", [])
    for name in mods:
        rows += module_rows(css, name, bar.get(name, {}), slots)
    tl = css.bg_layers(tooltip_chain())
    rows.append(judged("tooltip", "text", css.fg(tooltip_chain()), tl, TEXT_MIN, slots))
    return css, rows, len(mods)


def line(status, scheme, wm, el, kind, fg, bg, r, note):
    col = {"PASS": G, "FAIL": R, "WARN": Y, "SKIP": Y}[status]
    rs = "-" if r is None else f"{r:5.2f}"
    return f"  {col}{status:4}{X} {scheme:17} {wm:9} {el:58} {kind:5} fg={fg or '-':8} bg={bg or '-':11} {rs}  {note}"


def synth(text_fg, span_fg, bg="#ffffff"):
    css = f"@define-color pill {bg};\nwindow#waybar {{ background-color: transparent; color: #000000; }}\n#clock {{ background-color: @pill; color: {text_fg}; }}\ntooltip {{ background-color: #ffffff; color: #000000; }}"
    cfg = json.dumps({"modules-right": ["clock"], "clock": {"format": f"<span color='{span_fg}'>x</span> t"}})
    _, rows, _ = analyse(css, cfg, {})
    pick = lambda kind: [r[0] for r in rows if r[1].startswith("clock") and r[2] == kind]
    return pick("text"), pick("span")


def controls():
    res = []

    def chk(name, cond, detail=""):
        res.append((name, cond, detail))

    chk("ratio black/white is 21", abs(ratio((0, 0, 0), (1, 1, 1)) - 21) < 0.01)
    chk("ratio of equal colors is 1", abs(ratio((0.5, 0.5, 0.5), (0.5, 0.5, 0.5)) - 1) < 1e-9)
    s, _, r = judge((1, 1, 1, 1), [(0, 0, 0, 0.5)], TEXT_MIN)
    chk("alpha bg over white backdrop is the worst case and fails 4.5", s == "FAIL" and 3.5 < r < 4.2, f"{s} {r}")
    s, _, r = judge((1, 1, 1, 1), [(0, 0, 0, 1.0)], TEXT_MIN)
    chk("opaque black bg with white fg passes", s == "PASS" and r > 20)
    s, _, _ = judge((1, 1, 1, 1), [], TEXT_MIN)
    chk("no opaque background layer gives WARN", s == "WARN")
    mini = Css("@define-color a #111111; @define-color b #eeeeee;\n#x { color: @a; } .y { color: @b; } * { color: #888888; }\n.z:hover { color: #010101; } .w:not(.v) { color: #020202; }")
    n = [node("label", "x", ["y"])]
    chk("cascade: id beats class beats universal", mini.fg(n) == parse_color("#111111"))
    chk("cascade: class beats universal", mini.fg([node("label", None, ["y"])]) == parse_color("#eeeeee"))
    chk("pseudo-class only matches when set", mini.fg([node("label", None, ["z"])]) == parse_color("#888888") and mini.fg([node("label", None, ["z"], ["hover"])]) == parse_color("#010101"))
    chk(":not() excludes", mini.fg([node("label", None, ["w", "v"])]) == parse_color("#888888") and mini.fg([node("label", None, ["w"])]) == parse_color("#020202"))
    chk("same-specificity later rule wins", Css("* { color: #111111; } * { color: #222222; }").fg([node("label")]) == parse_color("#222222"))
    cases = [
        ("text fg == bg fails", synth("#ffffff", "#000000")[0], ["FAIL"]),
        ("span fg == bg fails", synth("#000000", "#ffffff")[1], ["FAIL"]),
        ("text at 4.4:1 fails", synth("#787878", "#000000")[0], ["FAIL"]),
        ("text at 4.6:1 passes", synth("#757575", "#000000")[0], ["PASS"]),
        ("span at 2.9:1 fails", synth("#000000", "#979797")[1], ["FAIL"]),
        ("span at 3.1:1 passes", synth("#000000", "#929292")[1], ["PASS"]),
        ("span at 4.4:1 passes (icon threshold is 3:1)", synth("#000000", "#787878")[1], ["PASS"]),
    ]
    for name, got, want in cases:
        chk(f"synthetic css/config through analyse(): {name}", got == want, f"got {got}")
    return res


def main(path):
    data = json.load(open(path))
    fails = 0
    matrix = {}
    order = [k for k in data if data[k]["role"] == "control"] + [k for k in data if data[k]["role"] in ("scenario", "edge")]
    print("\nChecker controls")
    for name, ok, detail in controls():
        print(f"  {G + 'PASS' if ok else R + 'FAIL'}{X} {name} {detail if not ok else ''}")
        fails += 0 if ok else 1
    wms = ["hyprland", "niri", "mango"]
    for sk in order:
        s = data[sk]
        flat = s["role"] == "edge"
        print(f"\n=== {sk} ({s['role']}, polarity {s['polarity']}, base00 #{s['palette']['base00']}, base05 #{s['palette']['base05']}) ===")
        if not s["polarityApplied"]:
            print(f"  {R}FAIL{X} stylix.polarity override did not apply")
            fails += 1
        for wm in wms:
            b = s["bars"][wm]
            counts = {"PASS": 0, "FAIL": 0, "WARN": 0, "SKIP": 0}
            if not b["css"] or not b["config"]:
                print(f"  {R}FAIL{X} {wm}: waybar css/config not generated")
                counts["FAIL"] += 1
                matrix[(sk, wm)] = counts
                fails += 1
                continue
            try:
                css, rows, nmods = analyse(b["css"], b["config"], s["palette"])
            except CssError as e:
                print(f"  {R}FAIL{X} {wm}: {e}")
                counts["FAIL"] += 1
                matrix[(sk, wm)] = counts
                fails += 1
                continue
            bad = [k for k in s["palette"] if css.defs.get(k, "").lower() != "#" + s["palette"][k].lower()]
            if bad:
                print(f"  {R}FAIL{X} {wm}: palette not applied to @define-color: {bad}")
                counts["FAIL"] += 1
                fails += 1
            if len(rows) < 12 or nmods < 5:
                print(f"  {R}FAIL{X} {wm}: only {len(rows)} elements from {nmods} modules, extraction is vacuous")
                counts["FAIL"] += 1
                fails += 1
            for row in rows:
                st = row[0]
                counts[st] += 1
                print(line(st, sk, wm, row[1], row[2], row[3], row[4], row[5], row[6]))
            matrix[(sk, wm)] = counts
            fails += counts["FAIL"] - (1 if bad else 0) - (1 if len(rows) < 12 or nmods < 5 else 0)
            if flat:
                texts = [r for r in rows if r[2] == "text" and r[0] == "PASS"]
                fb = [r for r in texts if r[3] in ("#000000", "#ffffff")]
                ok = bool(texts) and len(fb) == len(texts)
                print(f"  {G + 'PASS' if ok else R + 'FAIL'}{X} flat fallback {wm}: every passing text element resolved to #000000/#ffffff ({len(fb)}/{len(texts)})")
                fails += 0 if ok else 1
    print("\nSummary matrix (PASS/FAIL/WARN rows per scheme x waybar)")
    print(f"  {'scheme':18}" + "".join(f"{w:>18}" for w in wms))
    for sk in order:
        cells = ""
        for wm in wms:
            c = matrix[(sk, wm)]
            col = R if c["FAIL"] else G
            cells += col + f"{c['PASS']}/{c['FAIL']}/{c['WARN']}".rjust(18) + X
        print(f"  {sk:18}{cells}")
    print(f"\n{'FAILED: ' + str(fails) + ' problem(s)' if fails else 'all contrast checks passed'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
