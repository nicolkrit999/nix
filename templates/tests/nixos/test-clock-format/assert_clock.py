#!/usr/bin/env python3
"""Assertions on the BUILT outputs of 01-scenario-clock-format.nix.

Usage: python3 -I assert_clock.py <farm> <workdir>

<farm> is the built `all` link farm: meta.json, <scenario>.<kind> links to the built outputs and
ref.<name> links to the upstream references. <workdir> holds expectfail.<scenario>.{rc,err} for
the scenarios whose build must fail.
"""
import json
import os
import re
import sys

FARM = sys.argv[1]
WORK = sys.argv[2]
meta = json.load(open(os.path.join(FARM, "meta.json")))
S = meta["scenarios"]

results = []


def check(name, ok, detail=""):
    results.append((bool(ok), name, detail))


def built(name, kind):
    p = os.path.join(FARM, "%s.%s" % (name, kind))
    return os.path.realpath(p) if os.path.exists(p) else None


def built_ref(name):
    p = os.path.join(FARM, "ref.%s" % name)
    return os.path.realpath(p) if os.path.exists(p) else None


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


TD = "share/sddm/themes/sddm-astronaut-theme/Themes"
PX = "share/sddm/themes/pixie"
DATE_RE = re.compile(r"""date \+(['"])(.*?)\1""")


def key_lines(text, key):
    return [ln for ln in text.splitlines() if ln.startswith(key + "=")]


def hour_value(line):
    m = re.fullmatch(r'HourFormat="(.*)"', line)
    return m.group(1) if m else None


def has_ampm(fmt):
    return re.search(r"(?i)(?<![a-z])(ap|a)(?![a-z])", fmt) is not None


def changed_keys(a, b):
    la, lb = a.splitlines(), b.splitlines()
    if len(la) != len(lb):
        return ["<line count %d vs %d>" % (len(la), len(lb))]
    return [x.split("=")[0] for x, y in zip(la, lb) if x != y]


def conf_texts(conf, sec):
    cur, res = None, []
    for ln in conf.splitlines():
        if ln.startswith("# "):
            cur = ln[2:].strip()
        elif cur == sec and ln.startswith("  text = "):
            res.append(ln[len("  text = "):])
    return res


def date_fmt(text):
    m = DATE_RE.search(text)
    return m.group(2) if m else None


def token(lock24):
    return "$TIME" if lock24 else "$TIME12"


def cross_diff(conf, clocks, dates):
    probs = []
    ct, cd = conf_texts(conf, "TIME"), conf_texts(conf, "DATE")
    if len(ct) != 1 or len(cd) != 1 or len(clocks) != 1 or len(dates) != 1:
        return ["expected exactly one clock and one date in each variant, got conf %d/%d plain %d/%d"
                % (len(ct), len(cd), len(clocks), len(dates))]
    if ct[0] != clocks[0]:
        probs.append("clock token differs: catppuccin %r vs plain %r" % (ct[0], clocks[0]))
    fc, fp = date_fmt(cd[0]), date_fmt(dates[0])
    if fc is None or fp is None:
        probs.append("no date +'...' command found: catppuccin %r plain %r" % (cd[0], dates[0]))
    elif fc != fp:
        probs.append("date format differs: catppuccin %r vs plain %r" % (fc, fp))
    return probs


missing = []
for n, s in S.items():
    if n in meta["expectFail"]:
        continue
    for kind, drv in s["drv"].items():
        if drv and built(n, kind) is None:
            missing.append("%s.%s" % (n, kind))
for k in ("hyprland_kath", "cyberpunk", "rawLock"):
    if built_ref(k) is None:
        missing.append("ref.%s" % k)
check("scenario set is non-empty and every derivation built", S and not missing,
      "not built: %s" % ", ".join(missing[:12]))
check("fixture hosts do not mention use24HourClock, so 'unset' really means the module default",
      meta["fixtureSetsOption"] is False)

astro = sorted(n for n, s in S.items() if s["kind"] == "astro" and s["variant"] == "plain")
for n in astro:
    s, exp = S[n], S[n]["exp"]
    check("%s: sddm-astronaut use24HourClock is %s" % (n, exp["astro"]), s["eff"]["astro"] == exp["astro"],
          "effective %s" % s["eff"]["astro"])
    out, ref_out = built(n, "theme"), built_ref(s["theme"])
    if out is None or ref_out is None:
        check("%s: patched theme and its upstream reference built" % n, False, "not built")
        continue
    lines = key_lines(read("%s/%s/%s.conf" % (out, TD, s["theme"])), "HourFormat")
    ref_lines = key_lines(read("%s/%s/%s.conf" % (ref_out, TD, s["theme"])), "HourFormat")
    if "override" in exp:
        want = 'HourFormat="%s"' % exp["override"]
    elif exp["astro"]:
        want = ref_lines[0] if len(ref_lines) == 1 else "<no single upstream line>"
    else:
        want = 'HourFormat="hh:mm AP"'
    check("%s: %s HourFormat is %s" % (n, s["theme"], want), lines == [want], "found %s" % lines)
    if "override" in exp:
        check("%s: themeConfig.HourFormat wins over use24HourClock=false" % n,
              lines != ['HourFormat="hh:mm AP"'] and lines == [want], "found %s" % lines)
    else:
        v = hour_value(lines[0]) if len(lines) == 1 else None
        check("%s: the format has an AM/PM marker exactly when 12-hour" % n,
              v is not None and has_ampm(v) == (not exp["astro"]), "format %r" % v)

for a, b in (("unset", "both24"), ("cyber-12h", "cyber-24h")):
    oa, ob = built(a, "theme"), built(b, "theme")
    if oa is None or ob is None:
        check("%s vs %s: only HourFormat differs" % (a, b), False, "not built")
        continue
    th = S[a]["theme"]
    ca, cb = read("%s/%s/%s.conf" % (oa, TD, th)), read("%s/%s/%s.conf" % (ob, TD, th))
    other = "astronaut" if th != "astronaut" else "black_hole"
    check("%s vs %s (%s): the 12-hour and 24-hour confs differ in the HourFormat line only" % (a, b, th),
          changed_keys(ca, cb) == ["HourFormat"], "changed %s" % changed_keys(ca, cb))
    check("%s vs %s: another embedded theme's conf is identical (only the active theme is patched)" % (a, b),
          read("%s/%s/%s.conf" % (oa, TD, other)) == read("%s/%s/%s.conf" % (ob, TD, other)))

stub_ok = built("stub-with-key", "theme")
check("guard control: a stub theme WITH an HourFormat line builds and is patched to hh:mm AP",
      stub_ok is not None
      and key_lines(read("%s/%s/hyprland_kath.conf" % (stub_ok, TD)), "HourFormat") == ['HourFormat="hh:mm AP"'],
      "stub-with-key output: %s" % stub_ok)
rc_f, err_f = [os.path.join(WORK, "expectfail.stub-missing-key.%s" % e) for e in ("rc", "err")]
rc = open(rc_f).read().strip() if os.path.exists(rc_f) else "?"
err = read(err_f) if os.path.exists(err_f) else ""
check('guard: a stub theme WITHOUT an HourFormat line fails the build with "HourFormat not applied"',
      rc not in ("0", "?") and "HourFormat not applied" in err,
      "exit %s, %s" % (rc, " ".join(err.split("\n")[-6:])[:240]))


def same_drv(a, b, kind):
    return S[a]["drv"][kind] == S[b]["drv"][kind] and S[a]["drv"][kind] is not None


def same_bytes(a, b, kind, rel):
    oa, ob = built(a, kind), built(b, kind)
    if oa is None or ob is None:
        return False
    return (read(os.path.join(oa, rel)) == read(os.path.join(ob, rel))) if rel else read(oa) == read(ob)


check("(a)=(b) astronaut: unset and explicit false give the same derivation and the same conf",
      same_drv("unset", "explicit-default", "theme")
      and same_bytes("unset", "explicit-default", "theme", "%s/hyprland_kath.conf" % TD))
check("(a)=(b) hyprlock catppuccin: unset and explicit false give the same derivation and the same conf",
      same_drv("unset-cat", "explicit-default-cat", "lockConf")
      and same_bytes("unset-cat", "explicit-default-cat", "lockConf", ""))
check("(a)=(b) pixie: unset and explicit false give the same derivation and the same theme.conf",
      same_drv("pixie-unset", "pixie-explicit-default", "pixie")
      and same_bytes("pixie-unset", "pixie-explicit-default", "pixie", "%s/theme.conf" % PX))
check("control(a)=(b): a true value changes the astronaut, lock and pixie derivations",
      not same_drv("unset", "both24", "theme") and not same_drv("unset-cat", "both24-cat", "lockConf")
      and not same_drv("pixie-unset", "pixie24-lock12", "pixie"))
check("mixed scenarios really mix (astronaut 24h with lock 12h, and the reverse)",
      S["astro24-lock12"]["exp"]["astro"] and not S["astro24-lock12"]["exp"]["lock"]
      and not S["astro12-lock24"]["exp"]["astro"] and S["astro12-lock24"]["exp"]["lock"])

pix = sorted(n for n, s in S.items() if s["kind"] == "pixie")
for n in pix:
    s, exp = S[n], S[n]["exp"]
    check("%s: sddm-pixie use24HourClock is %s" % (n, exp["pixie"]), s["eff"]["pixie"] == exp["pixie"],
          "effective %s" % s["eff"]["pixie"])
    out = built(n, "pixie")
    if out is None:
        check("%s: sddm-pixie built" % n, False, "not built")
        continue
    want = exp.get("override", "true" if exp["pixie"] else "false")
    lines = key_lines(read("%s/%s/theme.conf" % (out, PX)), "use24HourClock")
    check("%s: theme.conf has use24HourClock=%s%s" % (n, want, " (themeConfig wins)" if "override" in exp else ""),
          lines == ["use24HourClock=%s" % want], "found %s" % lines)
    main = read("%s/%s/Main.qml" % (out, PX))
    check('%s: Main.qml date is day-first "dddd, d MMMM", not "dddd, MMMM d"' % n,
          main.count('"dddd, d MMMM"') == 1 and '"dddd, MMMM d"' not in main,
          'day-first %d, month-first %d' % (main.count('"dddd, d MMMM"'), main.count('"dddd, MMMM d"')))
    clock = read("%s/%s/components/Clock.qml" % (out, PX))
    check("%s: Clock.qml still switches on config.use24HourClock !== \"true\" (12-hour, no AM/PM marker)" % n,
          clock.count('if (config.use24HourClock !== "true") {') == 1 and "hours = hours % 12;" in clock
          and not re.search(r"\b(AM|PM|am|pm)\b", clock))

lock_plain = sorted(n for n, s in S.items() if s["variant"] == "plain" and s["kind"] != "stub")
for n in lock_plain:
    s, exp = S[n], S[n]["exp"]
    p = s["plain"]
    check("%s: hyprlock use24HourClock is %s" % (n, exp["lock"]), s["eff"]["lock"] == exp["lock"],
          "effective %s" % s["eff"]["lock"])
    check("%s: plain variant clock label is exactly %s" % (n, token(exp["lock"])),
          p["clocks"] == [token(exp["lock"])], "found %s" % p["clocks"])
    check("%s: plain variant has one date label with a date +'...' command" % n,
          len(p["dates"]) == 1 and date_fmt(p["dates"][0]) is not None, "found %s" % p["dates"])

raw_out = built_ref("rawLock")
raw_time = conf_texts(read(raw_out), "TIME") if raw_out else None
lock_cat = sorted(n for n, s in S.items() if s["variant"] == "cat")
for n in lock_cat:
    s, exp = S[n], S[n]["exp"]
    out = built(n, "lockConf")
    if out is None or raw_time is None:
        check("%s: generated catppuccin lock conf built" % n, False, "not built")
        continue
    conf = read(out)
    texts = conf_texts(conf, "TIME")
    check("%s: catppuccin conf TIME text is exactly %s" % (n, token(exp["lock"])), texts == [token(exp["lock"])],
          "found %s" % texts)
    check("%s: catppuccin conf TIME text equals the theme's own exactly when 24-hour" % n,
          (texts == raw_time) == exp["lock"], "generated %s theme %s" % (texts, raw_time))
    cd = conf_texts(conf, "DATE")
    check("%s: catppuccin conf has one DATE command with date +\"...\"" % n,
          len(cd) == 1 and date_fmt(cd[0]) is not None, "found %s" % cd)

for n in sorted(k for k in S if (k + "-cat") in S):
    out = built(n + "-cat", "lockConf")
    if out is None:
        check("%s: clock token and date format equal in both hyprlock variants" % n, False, "not built")
        continue
    probs = cross_diff(read(out), S[n]["plain"]["clocks"], S[n]["plain"]["dates"])
    check("%s: clock token and date format equal in both hyprlock variants" % n, not probs, "; ".join(probs))

c12, c24 = built("unset-cat", "lockConf"), built("both24-cat", "lockConf")
if c12 and c24:
    conf12 = read(c12)
    plain12, plain24 = S["unset"]["plain"], S["both24"]["plain"]
    good = cross_diff(conf12, plain12["clocks"], plain12["dates"])
    fmt = date_fmt(conf_texts(conf12, "DATE")[0])
    doctored = conf12.replace(fmt, "%A, %B %d") if fmt else conf12
    check("control(cross): a 12-hour catppuccin conf against the 24-hour plain clock is reported",
          good == [] and cross_diff(conf12, plain24["clocks"], plain12["dates"]) != [])
    check("control(cross): a catppuccin conf with a month-first DATE command is reported",
          fmt is not None and doctored != conf12 and cross_diff(doctored, plain12["clocks"], plain12["dates"]) != [])
    check("control(cross): a plain date label with a month-first format is reported",
          fmt is not None and cross_diff(conf12, plain12["clocks"], [plain12["dates"][0].replace("%d %B", "%B %d")]) != [])
    check("control(cross): both clock states occur in both variants of the matrix",
          {token(S[n]["exp"]["lock"]) for n in lock_plain} == {"$TIME", "$TIME12"}
          and {token(S[n]["exp"]["lock"]) for n in lock_cat} == {"$TIME", "$TIME12"})
else:
    check("control(cross): the 12-hour and 24-hour catppuccin confs built", False, "not built")

check("control(format helper): hh:mm AP has an AM/PM marker, HH:mm and HH:mm:ss do not",
      has_ampm("hh:mm AP") and not has_ampm("HH:mm") and not has_ampm("HH:mm:ss"))
check("control(diff helper): a second changed line is seen, not only HourFormat",
      changed_keys('Font="a"\nHourFormat="x"\n', 'Font="b"\nHourFormat="y"\n') == ["Font", "HourFormat"])

width = max(len(name) for _, name, _ in results)
failed = [r for r in results if not r[0]]
for ok, name, detail in results:
    print("  %-*s  %s%s" % (width, name, "PASS" if ok else "FAIL", "" if ok or not detail else "  (" + detail + ")"))
print("")
if failed:
    print("FAILURES (%d of %d):" % (len(failed), len(results)))
    for _, name, detail in failed:
        print("  x %s\n      %s" % (name, detail))
    sys.exit(1)
print("All %d checks passed." % len(results))
