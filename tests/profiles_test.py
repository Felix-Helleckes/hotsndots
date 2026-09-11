"""
Runs Core.lua + Profiles.lua under a real Lua interpreter against a stub WoW
API and exercises the profile layer: migrating an old flat save, per-spec
assignment, switching specs, create/copy/reset/delete.

    pip install lupa
    python tests/profiles_test.py

The profile layer is the one part of this addon that can silently eat
someone's settings, and it is also the part that cannot be tried out without
a spec change, a /reload and a second character. So it is tested outside the
game instead. The UI files are deliberately NOT loaded - they need a real
frame system, and nothing they do can lose data.

Whenever this test changes, break it on purpose once and watch it go red -
a green test that cannot fail is worse than no test.
"""
import io, os, sys

try:
    from lupa import luajit21 as lupa_mod
except Exception:
    try:
        from lupa import lua54 as lupa_mod
    except Exception:
        import lupa as lupa_mod

ADDON = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STUB = r"""
-- ---------------- minimal WoW API ----------------
local scripts = {}

local FrameMT = {}
FrameMT.__index = function(t, k)
    -- bookkeeping fields must stay nil, or "x.__events or {}" gets a function
    if type(k) == "string" and k:sub(1, 2) == "__" then return nil end
    -- every unknown frame method is a no-op that returns the frame
    local f = function(self, ...) return self end
    rawset(t, k, f)
    return f
end

function CreateFrame(kind, name, parent, template)
    local f = setmetatable({ __kind = kind, __scripts = {}, __events = {} }, FrameMT)
    f.SetScript = function(self, ev, fn) self.__scripts[ev] = fn; return self end
    f.GetScript = function(self, ev) return self.__scripts[ev] end
    f.RegisterEvent = function(self, ev) self.__events[ev] = true; return self end
    f.GetPoint = function(self) return "CENTER", nil, "CENTER", 0, 0 end
    f.GetWidth = function(self) return 100 end
    f.IsShown = function(self) return false end
    f.CreateTexture = function(self) return CreateFrame("Texture") end
    f.CreateFontString = function(self) return CreateFrame("FontString") end
    LAST_FRAMES[#LAST_FRAMES + 1] = f
    return f
end
LAST_FRAMES = {}

GameFontNormal = { GetFont = function() return "Fonts\\FRIZQT__.TTF" end }
STANDARD_TEXT_FONT = nil
AnchorUtil = nil
AuraContainerSortMethod = nil        -- => hasAuraContainers = false
AuraContainerSortDirection = nil
Enum = {}
C_Timer = { After = function(_, fn) PENDING[#PENDING + 1] = fn end }
PENDING = {}
InCombatLockdown = function() return false end
UnitName = function() return PLAYER_NAME end
GetRealmName = function() return REALM end
GetSpecialization = function() return SPEC_INDEX end
GetSpecializationInfo = function(i) return SPECS[i], SPEC_NAMES[i] end
GetLocale = function() return "enUS" end
GetSpecializationInfoByID = function(id)
    for i, v in ipairs(SPECS) do if v == id then return id, SPEC_NAMES[i] end end
end
GetNumSpecializations = function() return #SPECS end
format = string.format
date = function(fmt) return "2026-08-30 12:00:00" end

function strtrim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end
function strlower(s) return string.lower(s) end
PRINTED = {}
local realprint = print
function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    PRINTED[#PRINTED + 1] = table.concat(parts, " ")
end

function SERIALIZE(v)
    local t = type(v)
    if t == "table" then
        local out = {"{"}
        for k, val in pairs(v) do
            local key
            if type(k) == "string" then key = "[" .. string.format("%q", k) .. "]"
            else key = "[" .. tostring(k) .. "]" end
            out[#out + 1] = key .. "=" .. SERIALIZE(val) .. ","
        end
        out[#out + 1] = "}"
        return table.concat(out)
    elseif t == "string" then
        return string.format("%q", v)
    else
        return tostring(v)
    end
end

PLAYER_NAME = "Tester"
REALM = "Testrealm"
SPEC_INDEX = 1
SPECS = { 62, 63, 64 }            -- Arcane, Fire, Frost
SPEC_NAMES = { "Arcane", "Fire", "Frost" }
"""

LOADER = r"""
local ns = {}
NS = ns
local function loadfileInto(path)
    local chunk, err = loadfile(path)
    if not chunk then error(err) end
    return chunk("HotsNDots", ns)
end
FILES = FILES or { "Locale.lua", "Core.lua", "Profiles.lua", "Media.lua" }
for _, f in ipairs(FILES) do loadfileInto(ADDON .. "\\" .. f) end

-- Core registered its handler on the frame it created last
for _, f in ipairs(LAST_FRAMES) do
    if f.__scripts and f.__scripts.OnEvent and f.__events and f.__events.ADDON_LOADED then
        EVENT = f.__scripts.OnEvent
        FRAME = f
    end
end
-- Dispatching an event the addon never registered for would make this
-- harness test itself instead of the addon: the "PLAYER_ENTERING_WORLD
-- rescues a late spec" case passed happily with the RegisterEvent line
-- deleted, because the test called the handler directly.
function fire(event, arg1)
    if not FRAME.__events[event] then
        error("addon never registered for " .. event, 2)
    end
    EVENT(FRAME, event, arg1)
end
function flush() local p = PENDING; PENDING = {}; for _, fn in ipairs(p) do fn() end end
"""

fails = []
def check(label, cond, extra=""):
    print(("  PASS  " if cond else "  FAIL  ") + label + (("  -> " + str(extra)) if not cond and extra else ""))
    if not cond:
        fails.append(label)

def newrt(files=None):
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ADDON = ADDON
    lua.execute(STUB)
    if files is not None:
        lua.execute("FILES = {" + ",".join('"%s"' % f for f in files) + "}")
    lua.execute(LOADER)
    return lua

# ------------------------------------------------------------------
print("1. fresh install")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('fire("ADDON_LOADED", "HotsNDots")')
db = lua.globals().HotsNDotsDB
ns = lua.globals().NS
check("dbVersion is 4", db.dbVersion == 4, db.dbVersion)
check("Default profile exists", db.profiles["Default"] is not None)
check("active profile is Default", ns.activeProfile == "Default", ns.activeProfile)
check("ns.db is the Default table", lua.eval('NS.db == HotsNDotsDB.profiles.Default'))
check("defaults filled in", ns.db.nameplates.size == 30 and ns.db.bars.width == 220)
check("minimap is global, not in the profile",
      db["global"].minimap.angle == 220 and ns.db.minimap is None)
check("no profileKeys written for an untouched character",
      len(dict(db.profileKeys)) == 0, dict(db.profileKeys))

# ------------------------------------------------------------------
print("\n2. migrating a 1.4.x save (flat settings)")
lua = newrt()
lua.execute("""
HotsNDotsDB = {
    dbVersion = 3,
    filters = { showDebuffs = true, showBuffs = false, hideCrowdControl = true,
                hidePermanentBuffs = true, hidePermanentDebuffs = false },
    nameplates = { enabled = true, size = 48, timerFontSize = 22, maxIcons = 4 },
    bars = { enabled = true, width = 300, maxBars = 6,
             point = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 10, y = -20 } },
    minimap = { hide = true, angle = 95 },
}
fire("ADDON_LOADED", "HotsNDots")
""")
db, ns = lua.globals().HotsNDotsDB, lua.globals().NS
check("old settings landed in Default",
      ns.db.nameplates.size == 48 and ns.db.bars.width == 300 and ns.db.bars.maxBars == 6)
check("bar position survived", ns.db.bars.point.x == 10 and ns.db.bars.point.point == "TOPLEFT")
check("filters survived", ns.db.filters.showBuffs is False and ns.db.filters.hideCrowdControl is True)
check("missing keys got defaults", ns.db.nameplates.spacing == 4 and ns.db.bars.height == 24)
check("root is cleaned up", db.nameplates is None and db.bars is None and db.minimap is None)
check("minimap moved to global", db["global"].minimap.hide is True and db["global"].minimap.angle == 95)

# ------------------------------------------------------------------
print("\n3. migrating an ancient save (pre-1.4, one hidePermanent switch)")
lua = newrt()
lua.execute("""
HotsNDotsDB = {
    watch = { "Corruption" }, includePet = true, onlyMine = true,
    filters = { showDebuffs = true, hidePermanent = true },
    nameplates = { size = 40, showStacks = false, hideBlizzard = true },
    bars = { showStacks = false },
    minimap = { hide = false, angle = 220 },
}
fire("ADDON_LOADED", "HotsNDots")
""")
db, ns = lua.globals().HotsNDotsDB, lua.globals().NS
check("hidePermanent split into buffs/debuffs",
      ns.db.filters.hidePermanentBuffs is True and ns.db.filters.hidePermanentDebuffs is False)
check("old hidePermanent removed", ns.db.filters.hidePermanent is None)
check("showStacks opt-in re-applied",
      ns.db.nameplates.showStacks is True and ns.db.bars.showStacks is True)
check("dead keys dropped",
      ns.db.watch is None and ns.db.includePet is None and ns.db.nameplates.hideBlizzard is None)
check("kept what it should", ns.db.nameplates.size == 40)

# ------------------------------------------------------------------
print("\n4. one profile per spec")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('fire("ADDON_LOADED", "HotsNDots"); fire("PLAYER_LOGIN")')
ns = lua.globals().NS
db = lua.globals().HotsNDotsDB

lua.execute('NS.Profiles_Create("Raid")')
lua.execute('NS.Profiles_AssignCurrentSpec("Raid")')          # spec 1 = Arcane (62)
check("assigning switches immediately", ns.activeProfile == "Raid", ns.activeProfile)
lua.execute('NS.db.bars.width = 333; NS.db.nameplates.size = 55')

# a different arrangement on the other spec
lua.execute('NS.Profiles_AssignSpec(63, "Default")')
check("assigning another spec does not switch now", ns.activeProfile == "Raid")

lua.execute('SPEC_INDEX = 2; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
check("spec change switched profile", ns.activeProfile == "Default", ns.activeProfile)
check("and with it the layout", ns.db.bars.width == 220 and ns.db.nameplates.size == 30)

lua.execute('SPEC_INDEX = 1; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
check("switching back restores the other layout",
      ns.activeProfile == "Raid" and ns.db.bars.width == 333 and ns.db.nameplates.size == 55)

check("only the non-default assignment is stored",
      dict(db.profileKeys["Tester - Testrealm"]) == {62: "Raid"},
      dict(db.profileKeys["Tester - Testrealm"]))

# an unassigned third spec follows Default
lua.execute('SPEC_INDEX = 3; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
check("unassigned spec follows Default", ns.activeProfile == "Default")

# ------------------------------------------------------------------
print("\n5. edits stay inside their profile")
lua.execute('SPEC_INDEX = 1; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
lua.execute('NS.db.filters.showBuffs = false')
lua.execute('SPEC_INDEX = 2; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
check("Default untouched by an edit made on Raid", ns.db.filters.showBuffs is True)

# ------------------------------------------------------------------
print("\n6. create from a copy is a deep copy, not a link")
lua.execute('SPEC_INDEX = 1; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')
lua.execute('NS.Profiles_Create("Raid2", "Raid")')
check("copy carried the values", db.profiles["Raid2"].bars.width == 333)
lua.execute('NS.db.bars.width = 111')   # edit Raid
check("editing the source leaves the copy alone", db.profiles["Raid2"].bars.width == 333,
      db.profiles["Raid2"].bars.width)

# ------------------------------------------------------------------
print("\n7. copy / reset / delete")
lua.execute('NS.Profiles_Copy("Default")')
check("copy-from overwrote the active profile", ns.db.bars.width == 220)
check("and it is still the same table ns.db points at", lua.eval('NS.db == HotsNDotsDB.profiles.Raid'))

lua.execute('NS.db.bars.height = 40; NS.Profiles_Reset()')
check("reset restored defaults", ns.db.bars.height == 24)
check("reset kept the identity of the table", lua.eval('NS.db == HotsNDotsDB.profiles.Raid'))

check("Default cannot be deleted", lua.eval('(NS.Profiles_Delete("Default")) == nil'))
check("Default is still there", lua.eval('HotsNDotsDB.profiles.Default ~= nil'))

lua.execute('NS.Profiles_Delete("Raid")')
check("deleted profile is gone", db.profiles["Raid"] is None)
check("its spec fell back to Default", ns.activeProfile == "Default", ns.activeProfile)
check("dangling assignment cleaned up",
      dict(db.profileKeys["Tester - Testrealm"]) == {},
      dict(db.profileKeys["Tester - Testrealm"]))

check("duplicate name is refused", lua.eval('(NS.Profiles_Create("Raid2")) == nil'))
check("empty name is refused", lua.eval('(NS.Profiles_Create("   ")) == nil'))

# ------------------------------------------------------------------
print("\n8. a character with no specialization")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('SPEC_INDEX = nil; fire("ADDON_LOADED", "HotsNDots"); fire("PLAYER_LOGIN")')
ns = lua.globals().NS
check("no spec resolves to Default", ns.activeProfile == "Default")
lua.execute('NS.Profiles_Create("Leveling"); NS.Profiles_AssignCurrentSpec("Leveling")')
check("spec-less character can still have its own profile", ns.activeProfile == "Leveling")
check("stored under spec id 0",
      dict(lua.globals().HotsNDotsDB.profileKeys["Tester - Testrealm"]) == {0: "Leveling"})

# ------------------------------------------------------------------
print("\n9. profile lists and reloads")
lua.execute('NS.Profiles_Create("aaa"); NS.Profiles_Create("Zzz")')
order = list(lua.eval("NS.Profiles_List()").values())
check("Default sorts first, rest alphabetically",
      order == ["Default", "aaa", "Leveling", "Zzz"], order)

# reload the way WoW does it: through the SavedVariables file, i.e. as
# Lua source, not as a shared table.
saved = lua.eval("SERIALIZE(HotsNDotsDB)")
lua2 = newrt()
lua2.execute("HotsNDotsDB = " + saved)
lua2.execute('SPEC_INDEX = nil; fire("ADDON_LOADED", "HotsNDots"); fire("PLAYER_LOGIN")')
check("assignment survives a reload", lua2.globals().NS.activeProfile == "Leveling",
      lua2.globals().NS.activeProfile)

# ------------------------------------------------------------------
print("\n10. the spec was not readable yet at login")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('fire("ADDON_LOADED", "HotsNDots")')
lua.execute('NS.Profiles_Create("Fire"); NS.Profiles_AssignSpec(63, "Fire")')
# log in with the API still answering nil, the way a slow load does
lua.execute('SPEC_INDEX = nil; fire("PLAYER_LOGIN")')
ns = lua.globals().NS
check("comes up on Default while the spec is unknown", ns.activeProfile == "Default")
lua.execute('SPEC_INDEX = 2; fire("PLAYER_ENTERING_WORLD")')
check("PLAYER_ENTERING_WORLD picks up the real spec", ns.activeProfile == "Fire",
      ns.activeProfile)

# ------------------------------------------------------------------
print("\n11. media names resolve, and an unknown one falls back")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('fire("ADDON_LOADED", "HotsNDots")')
ns = lua.globals().NS

textures = list(lua.eval("NS.TextureList()").values())
check("built-in textures are listed",
      set(["Blizzard", "Solid", "Blizzard Raid Bar"]) <= set(textures), textures)
check("the default sorts first", textures[0] == "Blizzard", textures[0])
check("a known name resolves to its path",
      lua.eval('NS.TexturePath("Solid")') == r"Interface\Buttons\WHITE8X8",
      lua.eval('NS.TexturePath("Solid")'))
# The names are LSM's, so a pick made with a media pack installed still
# resolves after it is gone - and vice versa.
check("a built-in client font resolves without any library",
      lua.eval('NS.FontPath("Arial Narrow")') == r"Fonts\ARIALN.TTF",
      lua.eval('NS.FontPath("Arial Narrow")'))
# This is the failure that would be INVISIBLE in game: a dead path draws
# no bar at all, and nothing says why.
check("an unknown texture falls back instead of returning nothing",
      lua.eval('NS.TexturePath("SomeUninstalledPack")') == lua.eval('NS.TexturePath("Blizzard")'))
check("nil texture falls back too", lua.eval("NS.TexturePath(nil)") == lua.eval('NS.TexturePath("Blizzard")'))
check("Default font is the addon font", lua.eval('NS.FontPath("Default")') == ns.FONT_PATH)
check("an unknown font falls back to the addon font",
      lua.eval('NS.FontPath("Comic Sans From A Deleted Addon")') == ns.FONT_PATH)

print("\n12. with LibSharedMedia loaded by some other addon")
lua = newrt()
lua.execute("""
-- the smallest thing that behaves like LSM
local media = {
    statusbar = { ["Details D'ora"] = "Interface\\\\AddOns\\\\Details\\\\bar.tga" },
    font      = { ["Accidental Presidency"] = "Interface\\\\AddOns\\\\WeakAuras\\\\font.ttf" },
}
local lib = {
    List  = function(_, kind)
        local out = {}
        for name in pairs(media[kind] or {}) do out[#out + 1] = name end
        return out
    end,
    Fetch = function(_, kind, name, noDefault)
        local hit = (media[kind] or {})[name]
        if hit then return hit end
        if noDefault then return nil end
        return "LSM-DEFAULT"   -- what Fetch answers WITHOUT the flag
    end,
}
LibStub = function(name, silent) if name == "LibSharedMedia-3.0" then return lib end end
HotsNDotsDB = nil
fire("ADDON_LOADED", "HotsNDots")
""")
ns = lua.globals().NS
textures = list(lua.eval("NS.TextureList()").values())
check("library textures show up next to the built-ins",
      "Details D'ora" in textures and "Blizzard" in textures, textures)
check("a library texture resolves through the library",
      lua.eval("""NS.TexturePath("Details D'ora")""") == r"Interface\AddOns\Details\bar.tga")
check("a library font resolves through the library",
      lua.eval('NS.FontPath("Accidental Presidency")') == r"Interface\AddOns\WeakAuras\font.ttf")
# Fetch without the no-default flag would hand back LSM's OWN default here,
# which looks like success and silently ignores the player's pick.
check("an unknown name does not become the library's default",
      lua.eval('NS.TexturePath("Gone")') == lua.eval('NS.TexturePath("Blizzard")'),
      lua.eval('NS.TexturePath("Gone")'))

# ------------------------------------------------------------------
# This is the failure that actually happened: an addon manager (or a
# copy over a running client) replaces the files mid-session. /reload
# re-runs the Lua the game already knows, but does NOT re-read the .toc,
# so the new Core.lua runs while Profiles.lua and Media.lua are still
# unknown. Before the guard that was a nil call at ADDON_LOADED - the
# addon simply died and nothing was drawn.
print("\n13. update installed while the game was running (no Profiles.lua yet)")
lua = newrt(files=["Locale.lua", "Core.lua"])
lua.execute("""
HotsNDotsDB = {
    dbVersion = 3,
    nameplates = { enabled = true, size = 44 },
    bars = { enabled = true, width = 260 },
    filters = { showDebuffs = true },
    minimap = { hide = false, angle = 130 },
}
fire("ADDON_LOADED", "HotsNDots")
""")
ns = lua.globals().NS
check("ADDON_LOADED does not throw without Profiles.lua", ns.db is not None)
check("the old flat settings stay usable",
      ns.db.nameplates.size == 44 and ns.db.bars.width == 260)
check("missing keys are still filled in", ns.db.bars.height == 24)
check("the minimap still resolves", lua.eval("NS.global ~= nil and NS.global.minimap.angle == 130"))
check("the save is left alone for the restart to migrate",
      lua.globals().HotsNDotsDB.dbVersion == 3, lua.globals().HotsNDotsDB.dbVersion)
printed = " ".join(list(lua.globals().PRINTED.values()))
check("and it says to restart", "RESTART" in printed.upper(), printed[:80])
# PLAYER_LOGIN must not throw either - it is what builds the display
lua.execute('fire("PLAYER_LOGIN")')
check("PLAYER_LOGIN survives it too", True)

print("\n" + ("ALL PASS" if not fails else "FAILURES: " + ", ".join(fails)))
sys.exit(1 if fails else 0)
