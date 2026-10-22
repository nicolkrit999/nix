#!/usr/bin/env python3
import configparser
import filecmp
import json
import colorsys
import os
import re
import shutil
import subprocess
import sys
import tempfile

HEADER_TOKENS = ("container.extractedAccent", "container.fgColor")
LOCK_STEPS = ("0.4", "0.5", "0.6", "0.7", "0.8", "0.9")
LOGIN_DIM = 0.8
BACKING_ALPHA = 0.88
NAMED = {"white": "#ffffff", "black": "#000000", "gray": "#808080", "grey": "#808080"}
WORST_WALLS = (0.0, 0.2, 0.6)
MIN_ICON = 3.0
PROPS = ("baseColor", "surfaceColor", "surfaceVariantColor", "fgColor", "surfaceAccent", "textOnAccent", "errorCardColor")
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


def lighter(c, factor):
    h, s, v = colorsys.rgb_to_hsv(*c)
    v *= factor
    if v > 1:
        s, v = max(0.0, s - (v - 1)), 1.0
    return colorsys.hsv_to_rgb(h, s, v)


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


def darker(c, f):
    h, s, v = colorsys.rgb_to_hsv(*c)
    return colorsys.hsv_to_rgb(h, s, min(1.0, v / f))


def grey(w):
    return (w, w, w)


def top_index(e, ch):
    depth, quote = 0, False
    for i, c in enumerate(e):
        if c == '"':
            quote = not quote
        elif not quote:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif c == ch and depth == 0:
                return i
    return -1


def colon_index(e):
    depth, nest, quote = 0, 0, False
    for i, c in enumerate(e):
        if c == '"':
            quote = not quote
        elif not quote:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif depth == 0 and c == "?":
                nest += 1
            elif depth == 0 and c == ":":
                if nest == 0:
                    return i
                nest -= 1
    return -1


def unwrap(e):
    e = e.strip()
    while e.startswith("(") and e.endswith(")"):
        depth, ok = 0, True
        for i, c in enumerate(e):
            depth += c == "("
            depth -= c == ")"
            if depth == 0 and i < len(e) - 1:
                ok = False
                break
        if not ok:
            break
        e = e[1:-1].strip()
    return e


def block_after(text, pattern, start=0, end=None):
    mm = re.search(pattern, text[start:end])
    if not mm:
        return None
    return enclosing_block(text, start + mm.end() - 1)


class Pal:
    def __init__(self, main, conf):
        self.q = {k: rgb(v) for k, v in re.findall(r'property color (\w+):\s*"(#[0-9a-fA-F]{6})"', main)}
        self.conf = conf

    def hex(self, key):
        return "#" + "".join(f"{round(x * 255):02x}" for x in self.q[key])

    def complete(self):
        return all(k in self.q for k in PROPS)

    def term(self, tok):
        t = tok.strip()
        if re.fullmatch(r"-?[\d.]+", t):
            return float(t)
        if t == "transparent":
            return None
        if t.startswith('"'):
            v = t.strip('"')
            if v == "transparent":
                return None
            return rgb(v) if v.startswith("#") else rgb(NAMED[v])
        mm = re.fullmatch(r"(?:container\.)?(\w+)", t)
        if mm and mm.group(1) in self.q:
            return self.q[mm.group(1)]
        if t in ("container.extractedAccent", "config.accentColor"):
            return rgb(self.conf["accentColor"])
        if t == "config.textColor":
            return rgb(self.conf["textColor"])
        if t == "config.backgroundColor":
            return rgb(self.conf["backgroundColor"])
        mm = re.fullmatch(r"Qt\.(darker|lighter)\((.+),\s*([\d.]+)\)", t)
        if mm:
            inner = self.ev(mm.group(2), {})
            return (darker if mm.group(1) == "darker" else lighter)(inner, float(mm.group(3)))
        raise KeyError(f"unresolvable colour expression {t!r}")

    def cond(self, c, st):
        return any(all((not st.get(x.strip().lstrip("!").strip(), False)) if x.strip().startswith("!") else st.get(x.strip(), False)
                       for x in part.split("&&")) for part in unwrap(c).split("||"))

    def ev(self, expr, st):
        e = unwrap(expr.strip().rstrip(";"))
        q = top_index(e, "?")
        if q < 0:
            return self.term(e)
        rest = e[q + 1:]
        i = colon_index(rest)
        return self.ev(rest[:i] if self.cond(e[:q], st) else rest[i + 1:], st)


def on_ray(base, bg):
    for k in ((0, 0, 0), (1, 1, 1)):
        for n in range(0, 201):
            t = n / 200
            if all(abs(b - ((1 - t) * x + t * y)) <= 2.5 / 255 for b, x, y in zip(base, bg, k)):
                return True
    return False


class Out:
    def __init__(self, root):
        self.theme = os.path.join(root, "share/sddm/themes/pixie")
        self.main = open(os.path.join(self.theme, "Main.qml")).read()
        self.clock = open(os.path.join(self.theme, "components/Clock.qml")).read()
        self.conf = configparser.ConfigParser(interpolation=None)
        self.conf.optionxform = str
        self.conf.read(os.path.join(self.theme, "theme.conf"))
        self.c = self.conf["General"]


def lock_ok(c, floor):
    return contrast(c, grey(0.1)) >= floor


def check_scenario(meta, root, log, qmllint):
    res = []
    info = {"lock": None, "token": None, "ratios": {}}

    def add(name, ok, detail=""):
        res.append((name, bool(ok), "" if ok else detail))

    def rec(name, value, need):
        cur = info["ratios"].get(name)
        if cur is None or value < cur[0]:
            info["ratios"][name] = (value, need)
        return value >= need

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
    accent, text, back_conf = rgb(c["accentColor"]), rgb(c["textColor"]), rgb(c["backgroundColor"])

    bg_file = os.path.join(o.theme, "assets", os.path.basename(c.get("background", "")))
    add("background-is-wallpaper", os.path.isfile(bg_file) and filecmp.cmp(bg_file, meta["wallpaperPath"], shallow=False),
        f"{c.get('background')} differs from the wallpaper under test")

    pal = {v.lower() for k, v in meta["palette"].items()}
    neutrals = {meta["palette"][f"base0{i}"].lower() for i in range(8)}
    if meta["role"] in ("matrix", "extreme"):
        lightest = max(neutrals, key=lambda h: lum(rgb(h)))
        text_ok = c["textColor"][1:].lower() in neutrals or (c["textColor"].lower() == "#f0f0f0" and not lock_ok(rgb(lightest), 4.6))
        accent_ok = c["accentColor"][1:].lower() in pal or c["accentColor"].lower() == c["textColor"].lower()
        add("palette-from-scheme",
            text_ok and c["backgroundColor"][1:].lower() in neutrals and accent_ok,
            f"text/back/accent {c['textColor']}/{c['backgroundColor']}/{c['accentColor']} not drawn from scheme {meta['theme']} (text may fall back to #f0f0f0 only when the lightest neutral {lightest} is unreadable on the strongest-dimmed wallpaper)")
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

    P = Pal(m, c)
    add("extractedAccent-defaults-to-accent", "property color extractedAccent: config.accentColor" in m and P.complete(),
        "extractedAccent no longer bound to theme.conf, or a solved surface property is missing")
    if not P.complete():
        return res, info
    base, s1, s2, fg = P.q["baseColor"], P.q["surfaceColor"], P.q["surfaceVariantColor"], P.q["fgColor"]
    sacc, on_acc, err = P.q["surfaceAccent"], P.q["textOnAccent"], P.q["errorCardColor"]
    back = base

    ray_ok = on_ray(base, back_conf)
    rs = [rec("fg on card / field / selected surface", min(contrast(fg, x) for x in (base, s1, s2)), MIN_TEXT)]
    add("surfaces-solved", ray_ok and all(rs),
        f"base {P.q['baseColor']} must lie on the ray from backgroundColor {c['backgroundColor']} to black or white (on ray: {ray_ok}); fg vs base/surface/variant = {[round(contrast(fg, x), 2) for x in (base, s1, s2)]}, need {MIN_TEXT}")

    bad_lits = [ln.strip() for ln in m.split("\n")
                if re.match(r"\s*(?:color|border\.color)\s*:", ln) and re.search(r'"(?:white|gray|grey|#[0-9a-fA-F]{3,8})"', ln)]
    add("no-hardcoded-colours", not bad_lits, f"fixed colour literals left in Main.qml: {bad_lits}")

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

    ov = re.search(r'color:\s*"black"\s*\n\s*opacity:\s*loginState\.visible\s*\?\s*([\d.]+)\s*:\s*([\d.]+)', m)
    lock = login = None
    if ov:
        login, lock = float(ov.group(1)), float(ov.group(2))
        info["lock"] = lock
    add("dim-values", ov and login == LOGIN_DIM and ov.group(2) in LOCK_STEPS,
        f"overlay opacity login/lock = {ov.groups() if ov else None}")

    def cards(key="baseColor", with_error=False):
        walls = list(WORST_WALLS) + ([dimmed(wall, d)[0] for d in (lock, login)] if ov else [])
        keys = [key] + (["errorCardColor"] if with_error else [])
        return [over(P.q[k], grey(w), BACKING_ALPHA) for k in keys for w in walls]

    token_ok = tok_date in HEADER_TOKENS and tok_date == tok_power
    info["token"] = tok_date if token_ok else None
    add("header-token", token_ok, f"dateText color={tok_date!r}, PowerBar textColor={tok_power!r}")
    if token_ok:
        fg_hex = c["accentColor"] if tok_date == "container.extractedAccent" else P.q["fgColor"]
        hfg = accent if tok_date == "container.extractedAccent" else fg
        ratio = contrast(hfg, back)
        add("header-contrast", ratio >= MIN_TEXT, f"{tok_date} on {c['backgroundColor']} base {ratio:.2f}:1, need {MIN_TEXT}")
        acc_worst = min(contrast(accent, x) for x in cards())
        ok_rule = tok_date == "container.extractedAccent" if acc_worst >= 4.6 else (tok_date == "container.fgColor" if acc_worst < MIN_TEXT else True)
        add("header-selection-rule", ok_rule, f"accent contrast on the card is {acc_worst:.2f}:1 so the accent is {'required' if acc_worst >= 4.6 else 'forbidden'}, built {tok_date}")
    else:
        hfg = None

    if hfg is not None and ov:
        worst = min(contrast(hfg, over(back, dimmed(wall, d), BACKING_ALPHA)) for d in (lock, login))
        rec("header text on its backing", worst, MIN_TEXT)
        add("header-on-backing", worst >= MIN_TEXT, f"{worst:.2f}:1 over the dimmed wallpaper, need {MIN_TEXT}")
    else:
        add("header-on-backing", False, "needs header token and dim values")

    if ov:
        bgl = dimmed(wall, lock)
        bind = re.search(r"baseAccent:\s*([\w.]+)", m)
        add("clock-accent-binding", bind and bind.group(1) == "container.extractedAccent", f"baseAccent bound to {bind.group(1) if bind else None}")
        r = contrast(accent, bgl)
        rec("lock clock accent on dimmed wallpaper", r, MIN_ACCENT)
        add("clock-readable", r >= MIN_ACCENT, f"accent {c['accentColor']} on dimmed wallpaper {r:.2f}:1, need {MIN_ACCENT}")
        hs = re.search(r'text:\s*"Press any key to unlock"', m)
        hint_ok, detail = False, "hint text not found"
        if hs:
            hb = m[slice(*enclosing_block(m, hs.start()))]
            hp = top_props(hb)
            alpha = float(hp.get("opacity", "1"))
            hr = contrast(over(text, bgl, alpha), bgl)
            rec("lock hint on dimmed wallpaper", hr, MIN_TEXT)
            hint_ok = hp.get("color") == "config.textColor" and hr >= MIN_TEXT
            detail = f"hint colour {hp.get('color')} at opacity {alpha} on dimmed wallpaper {hr:.2f}:1, need {MIN_TEXT}"
        add("hint-readable", hint_ok, detail)

    def block_props(pattern, start=0, end=None):
        blk = block_after(m, pattern, start, end)
        return (blk, top_props(m[blk[0]:blk[1]])) if blk else (None, {})

    problems = []

    def need(label, value, floor):
        if not rec(label, value, floor):
            problems.append(f"{label}: {value:.2f}:1, need {floor}")

    try:
        lbl_blk = enclosing_block(m, re.search(r"id:\s*userNameLabel\b", m).start())
        lbl = P.ev(top_props(m[lbl_blk[0]:lbl_blk[1]])["color"], {})
        need("user name on the login card", min(contrast(lbl, x) for x in cards(with_error=True)), MIN_TEXT)

        pill = re.search(r"id:\s*sessionPill\b", m)
        pbs, pbe = enclosing_block(m, pill.start())
        pill_color = top_props(m[pbs:pbe])["color"]
        for tm in re.finditer(r"Text\s*\{", m[pbs:pbe]):
            tb = enclosing_block(m, pbs + tm.end() - 1)
            tprops = top_props(m[tb[0]:tb[1]])
            glyph = "󰟀" in tprops.get("text", "")
            for name, st in (("idle", {}), ("pressed", {"sessionClickArea.pressed": True}), ("popup open", {"sessionPopup.opened": True})):
                need("session pill icon" if glyph else "session pill text", contrast(P.ev(tprops["color"], st), P.ev(pill_color, st)), MIN_ICON if glyph else MIN_TEXT)

        pf = re.search(r"id:\s*passwordField\b", m)
        fbs, fbe = enclosing_block(m, pf.start())
        fprops = top_props(m[fbs:fbe])
        fbg = block_props(r"background:\s*Rectangle\s*\{", fbs, fbe)[1]
        field_fill = P.ev(fbg["color"], {})
        need("password text on the field", contrast(P.ev(fprops["color"], {}), field_fill), MIN_TEXT)
        for cardc in cards():
            need("password text on the field (disabled while logging in)", contrast(P.ev(fprops["color"], {}), over(field_fill, cardc, 0.5)), MIN_TEXT)

        lb = re.search(r"id:\s*loginButton\b", m)
        lbs, lbe = enclosing_block(m, lb.start())
        arrow = block_props(r"contentItem:\s*Text\s*\{", lbs, lbe)[1]
        bbg = block_props(r"background:\s*Rectangle\s*\{", lbs, lbe)[1]
        for busy in (False, True):
            for pressed in (False, True):
                st = {"container.isLoggingIn": busy, "loginButton.pressed": pressed}
                opa = P.ev(bbg.get("opacity", "1.0"), st)
                fill = P.ev(bbg["color"], st)
                for cardc in cards():
                    need("login arrow on its button", contrast(P.ev(arrow["color"], st), over(fill, cardc, opa)), MIN_TEXT)

        n_indic = re.search(r"id:\s*numLockIndicator\b", m)
        nprops = top_props(m[slice(*enclosing_block(m, n_indic.start()))])
        need("Num Lock notice on the card (incl. error card)", min(contrast(P.ev(nprops["color"], {}), x) for x in cards(with_error=True)), MIN_TEXT)
        if hfg is not None:
            need("header colour on the error card", min(contrast(hfg, x) for x in cards(with_error=True)), MIN_TEXT)

        av = re.search(r"id:\s*avatarFallback\b", m)
        abs_, abe = enclosing_block(m, av.start())
        afill = P.ev(top_props(m[abs_:abe])["color"], {})
        atb = block_props(r"Text\s*\{", abs_, abe)[1]
        need("avatar initial on its disc", contrast(P.ev(atb["color"], {}), afill), MIN_TEXT)
    except Exception as e:
        problems.append(f"login-card elements unreadable: {e!r}")
    add("card-text", not problems, "; ".join(problems))

    def popup_problems(pid):
        out = []
        try:
            pa = re.search(r"id:\s*" + pid + r"\b", m)
            ps_, pe_ = enclosing_block(m, pa.start())
            pbg = block_props(r"background:\s*Rectangle\s*\{", ps_, pe_)[1]
            popup_bg = P.ev(pbg["color"], {})
            if float(pbg.get("opacity", "1")) != 1.0:
                out.append(f"{pid} background opacity {pbg.get('opacity')} (must be opaque)")
            d_s, d_e = block_after(m, r"delegate:\s*ItemDelegate\s*\{", ps_, pe_)
            row_blk, row = block_props(r"background:\s*Rectangle\s*\{", d_s, d_e)
            bar = block_props(r"Rectangle\s*\{", row_blk[0] + 1, row_blk[1])[1]
            c_s, c_e = block_after(m, r"contentItem:\s*RowLayout\s*\{", d_s, d_e)
            kinds = ("idle", "hovered", "selected", "selected+hovered")
            for kind, st in zip(kinds, ({}, {"hovered": True}, {"isCurrent": True}, {"isCurrent": True, "hovered": True})):
                row_fill = P.ev(row["color"], st) or popup_bg
                if st.get("isCurrent"):
                    mk = contrast(P.ev(bar["color"], st), row_fill)
                    if not rec("selected-row marker bar vs row", mk, MIN_ICON):
                        out.append(f"{pid} marker {kind}: {mk:.2f}")
                for tm in re.finditer(r"Text\s*\{", m[c_s:c_e]):
                    tb = enclosing_block(m, c_s + tm.end() - 1)
                    tprops = top_props(m[tb[0]:tb[1]])
                    pr_s, pr_e = enclosing_block(m, tb[0] - 1)
                    fill = row_fill
                    role = "text"
                    if type_of(m, pr_s) == "Rectangle":
                        fill = P.ev(top_props(m[pr_s:pr_e])["color"], st) or row_fill
                        role = "initial"
                    elif "󰟀" in tprops.get("text", ""):
                        role = "icon"
                    r = contrast(P.ev(tprops["color"], st), fill)
                    floor = MIN_ICON if role == "icon" else MIN_TEXT
                    label = {"text": f"popup name, {kind}", "icon": f"popup icon, {kind}", "initial": f"popup initial, {kind}"}[role]
                    if not rec(label, r, floor):
                        out.append(f"{pid} {label}: {r:.2f}:1, need {floor}")
        except Exception as e:
            out.append(f"{pid} unreadable: {e!r}")
        return out

    popup_bad = popup_problems("userPopup") + popup_problems("sessionPopup")
    add("popup-contrast", not popup_bad, "; ".join(popup_bad))

    ph = re.search(r'text:\s*"Enter Password"', m)
    ph_ok, detail = False, "password placeholder not found"
    ph_alpha = None
    if ph:
        pp = top_props(m[slice(*enclosing_block(m, ph.start()))])
        ph_alpha = pp.get("opacity", "1")
        alpha = float(ph_alpha)
        pcol = P.ev(pp["color"], {})
        pr = contrast(over(pcol, s1, alpha), s1)
        rec("password placeholder on the field", pr, MIN_TEXT)
        ph_ok = pr >= MIN_TEXT
        detail = f"placeholder colour {pp.get('color')} at opacity {alpha} on the field surface {pr:.2f}:1, need {MIN_TEXT}"
    add("placeholder-readable", ph_ok, detail)

    nl = re.search(r"id:\s*numLockIndicator\b", m)
    nl_ok, detail = False, "numLockIndicator not found"
    if nl:
        ntok = top_props(m[slice(*enclosing_block(m, nl.start()))]).get("color")
        nl_ok = token_ok and ntok == tok_date
        detail = f"numLockIndicator colour {ntok!r}, header token {tok_date!r}"
        if nl_ok and ov:
            nr = contrast(hfg, over(back, dimmed(wall, login), BACKING_ALPHA))
            nl_ok = nr >= MIN_TEXT
            detail = f"{ntok} on the login card {nr:.2f}:1, need {MIN_TEXT}"
    add("numlock-readable", nl_ok, detail)

    surf_ok, detail = False, "avatar fallback or session pill not found"
    try:
        av = re.search(r"id:\s*avatarFallback\b", m)
        ab, ae = enclosing_block(m, av.start())
        atok = block_props(r"Text\s*\{", ab, ae)[1].get("color")
        pill = re.search(r"id:\s*sessionPill\b", m)
        pb_, pe_ = enclosing_block(m, pill.start())
        itok = None
        for tm in re.finditer(r"Text\s*\{", m[pb_:pe_]):
            tb = enclosing_block(m, pb_ + tm.end() - 1)
            tp = top_props(m[tb[0]:tb[1]])
            if "󰟀" in tp.get("text", ""):
                itok = tp.get("color")
        sr = min(contrast(sacc, x) for x in (s1, s2))
        rec("avatar initial / session icon (accent or text colour) on surfaces", sr, MIN_TEXT)
        surf_ok = atok == itok == "container.surfaceAccent" and sr >= MIN_TEXT and sacc in (accent, fg)
        detail = f"avatar initial / session icon colours {atok!r}/{itok!r}, surfaceAccent {P.q['surfaceAccent']} on surface/variant {sr:.2f}:1 (need {MIN_TEXT}, and the accent or the text colour)"
    except Exception as e:
        detail = repr(e)
    add("surface-fg", surf_ok, detail)

    clock_effect = "MultiEffect" in o.clock
    add("effects-imported", (not clock_effect or "import QtQuick.Effects" in o.clock) and "import QtQuick.Effects" in m,
        "MultiEffect used without import QtQuick.Effects")

    if log is None:
        res.append(("build-log", None, "no build log retained"))
    else:
        dl = re.search(r"sddm-pixie: lock dim=([\d.]+) login dim=([\d.]+) header fg=(\S+) surface fg=(\S+) placeholder alpha=([\d.]+) text=(#\w+) base=(#\w+)", log)
        okl = (bool(dl) and "no step passed" not in log and lock is not None and float(dl.group(1)) == lock and dl.group(3) == tok_date
               and (accent == fg or (dl.group(4) == "accent") == (P.q["surfaceAccent"] == accent))
               and dl.group(5) == ph_alpha and dl.group(6) == P.hex("fgColor") and dl.group(7) == P.hex("baseColor"))
        add("build-log", okl, f"log lock dim/login dim/header fg/surface fg/placeholder alpha/text/base = {dl.groups() if dl else None}; 'no step passed' present: {'no step passed' in log}")

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


def edit_in_block(path, anchor, pattern, repl):
    s = open(path).read()
    a = re.search(anchor, s)
    if not a:
        raise RuntimeError(f"mutation anchor not found: {anchor!r}")
    bs, be = enclosing_block(s, a.start())
    n = re.subn(pattern, repl, s[bs:be], count=1)
    if n[1] == 0:
        raise RuntimeError(f"mutation pattern not found in the {anchor!r} block: {pattern!r}")
    open(path, "w").write(s[:bs] + n[0] + s[be:])


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
    def prop(t, name):
        return re.search(name + r': "(#[0-9a-fA-F]{6})"', open(t + "/Main.qml").read()).group(1)

    def set_prop(name, value_of):
        return lambda t: edit(t + "/Main.qml", r"(" + name + r': )"#[0-9a-fA-F]{6}"', lambda mo: mo.group(1) + '"' + value_of(t) + '"')

    wanted += [
        ("hint opacity lowered", lambda t: edit_in_block(t + "/Main.qml", r'text:\s*"Press any key to unlock"', r"(\n\s*opacity:\s*)[\d.]+", r"\g<1>0.2"), "hint-readable"),
        ("placeholder opacity lowered", lambda t: edit_in_block(t + "/Main.qml", r'text:\s*"Enter Password"', r"(\n\s*opacity:\s*)[\d.]+", r"\g<1>0.2"), "placeholder-readable"),
        ("avatar initial painted in the card colour", lambda t: edit_in_block(t + "/Main.qml", r"font\.pixelSize:\s*48", r"(\n\s*color:\s*)[\w.]+", r"\g<1>container.baseColor"), "surface-fg"),
        ("num lock colour detached from the header token", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*numLockIndicator\b", r"(\n\s*color:\s*)[\w.]+", r"\g<1>container.baseColor"), "numlock-readable"),
        ("user popup name left on the popup background", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*userPopup\b", r"color: container\.fgColor(\s*font\.pixelSize: 15)", r"color: baseColor\1"), "popup-contrast"),
        ("selected user initial painted in its own disc colour", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*userPopup\b", r"isCurrent \? container\.textOnAccent", "isCurrent ? container.surfaceAccent"), "popup-contrast"),
        ("idle session icon painted in the field colour", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*sessionPopup\b", r"isCurrent \? container\.surfaceAccent : container\.fgColor", "isCurrent ? container.surfaceAccent : surfaceColor"), "popup-contrast"),
        ("popup made translucent", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*userPopup\b", r"(radius: 24\s*opacity: )1\.0", r"\g<1>0.8"), "popup-contrast"),
        ("selected row fill equal to the text colour", set_prop("surfaceVariantColor", lambda t: prop(t, "fgColor")), "popup-contrast"),
        ("hard-coded grey reintroduced", lambda t: edit(t + "/Main.qml", r'(id: userNameLabel.*?color: )container\.fgColor', r'\1"#AAAAAA"'), "no-hardcoded-colours"),
        ("arrow colour equal to its button", set_prop("textOnAccent", lambda t: prop(t, "surfaceAccent")), "card-text"),
        ("error card equal to the text colour", set_prop("errorCardColor", lambda t: prop(t, "fgColor")), "card-text"),
        ("session pill text hidden while the popup is open", lambda t: edit_in_block(t + "/Main.qml", r"id:\s*sessionPill\b", r"color: container\.fgColor(\s*font\.pixelSize: 13)", r"color: sessionPopup.opened ? surfaceVariantColor : container.fgColor\1"), "card-text"),
        ("card colour off the scheme", set_prop("baseColor", lambda t: "#335577"), "surfaces-solved"),
        ("surface accent equal to the selected fill", set_prop("surfaceAccent", lambda t: prop(t, "surfaceVariantColor")), "surface-fg"),
    ]
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
    dims, tokens, skipped, built, worst = {}, set(), set(), {}, {}

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
        for k, (v, n) in info["ratios"].items():
            if k not in worst or v < worst[k][0]:
                worst[k] = (v, n, sid)
        if meta["role"] in ("matrix", "extreme") and info["lock"] is not None:
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

    print("\nworst case per element across all scenarios (ratio, needed, scenario):")
    for k in sorted(worst):
        v, n, sid = worst[k]
        mark = "PASS" if v >= n else "FAIL"
        print(f"{mark} {k}: {v:.2f}:1 (need {n}) in {sid}")
        failed += v < n

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
