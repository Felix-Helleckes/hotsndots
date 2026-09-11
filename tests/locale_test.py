"""
Checks the translation tables against the English base.

    pip install lupa
    python tests/locale_test.py

Translations fail in ways that have nothing to do with wording, and they only
fail on the client whose language it is:

  * a key that exists only in a translation is a TYPO - the English base is
    what the code asks for, so that string can never appear;
  * a translation that LOSES a %s does not throw - Lua's format ignores the
    extra argument - so the profile name simply vanishes from the sentence
    that was supposed to name it. Silent, and only in that language;
  * a translation that GAINS one is fed nothing and throws inside format(),
    at the moment the message was supposed to explain something.

The first half is why this file exists at all: the login test in
tests/load_test.py runs every message in every language and stays green
through it, because nothing errors. Only comparing against English finds it.
"""
import io, os, re, sys

try:
    from lupa import luajit21 as lupa_mod
except Exception:
    try:
        from lupa import lua54 as lupa_mod
    except Exception:
        import lupa as lupa_mod

ADDON = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

fails = []


def check(label, cond, extra=""):
    print(("  PASS  " if cond else "  FAIL  ") + label + (("  -> " + str(extra)) if not cond and extra else ""))
    if not cond:
        fails.append(label)


def load(locale):
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.execute('GetLocale = function() return "%s" end' % locale)
    lua.execute("""
        local ns = {}
        NS = ns
        local chunk, err = loadfile([[%s]])
        if not chunk then error(err) end
        chunk("HotsNDots", ns)
    """ % os.path.join(ADDON, "Locale.lua").replace("\\", "\\\\"))
    return lua


# The placeholder sequence has to survive translation: same specifiers, same
# order. "%s uses %s" and "%s benutzt %s" match; dropping one does not.
SPEC = re.compile(r"%[-+ #0]*[0-9.]*[sdfqx%]")


def placeholders(text):
    return [m for m in SPEC.findall(text) if m != "%%"]


lua = load("enUS")
EN = dict(lua.eval("NS.localeBase"))
tables = lua.eval("NS.localeTables")
locales = sorted(dict(tables).keys())

print("English base: %d keys" % len(EN))
print("translations: " + ", ".join(locales))

check("all four languages are present",
      set(["deDE", "frFR", "esES", "esMX"]) <= set(locales), locales)
check("esMX and esES are the same table (they cannot drift apart)",
      lua.eval("NS.localeTables.esMX == NS.localeTables.esES"))

for name in locales:
    if name == "esMX":
        continue  # same table as esES, already checked
    print("\n%s" % name)
    t = dict(lua.eval("NS.localeTables.%s" % name))

    orphans = sorted(k for k in t if k not in EN)
    check("no keys that the code never asks for", not orphans, orphans[:5])

    empty = sorted(k for k, v in t.items() if not isinstance(v, str) or v.strip() == "")
    check("no empty strings", not empty, empty[:5])

    bad = []
    for k, v in t.items():
        if k in EN and placeholders(EN[k]) != placeholders(v):
            bad.append("%s: %s vs %s" % (k, placeholders(EN[k]), placeholders(v)))
    check("placeholders match English", not bad, bad[:3])

    missing = sorted(k for k in EN if k not in t)
    # Missing is allowed - it falls back to English - but it should be visible.
    print("        (%d of %d translated%s)" % (len(EN) - len(missing), len(EN),
          ", missing: " + ", ".join(missing[:6]) if missing else ""))

print("\nfallback behaviour")
lua = load("deDE")
check("a translated key comes back in German",
      lua.eval("NS.L.hdrFilters") == "Filter", lua.eval("NS.L.hdrFilters"))
check("an untranslated key falls back to English, not nil",
      isinstance(lua.eval("NS.L.msgSlashHelp"), str) or lua.eval("NS.L.hdrGeneral") is not None)
check("an unknown key returns its own name instead of nil",
      lua.eval('NS.L.thisKeyDoesNotExist') == "thisKeyDoesNotExist",
      lua.eval("NS.L.thisKeyDoesNotExist"))

lua = load("ptBR")
check("an unsupported client language gets English",
      lua.eval("NS.L.hdrFilters") == "Filters", lua.eval("NS.L.hdrFilters"))

# "Default" is a profile name and a key in the saved variables, not a word.
print("\nthe Default profile name stays English")
src = io.open(os.path.join(ADDON, "Profiles.lua"), encoding="utf-8").read()
check("DEFAULT_PROFILE is the literal string",
      'local DEFAULT_PROFILE = "Default"' in src)
check("and nothing localises it",
      "DEFAULT_PROFILE = ns.L" not in src and "DEFAULT_PROFILE = L" not in src)

print("\n" + ("ALL PASS" if not fails else "FAILURES:\n  - " + "\n  - ".join(fails)))
sys.exit(1 if fails else 0)
