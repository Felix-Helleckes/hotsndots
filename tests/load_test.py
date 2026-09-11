"""
Loads the WHOLE addon under a real Lua interpreter against a stub WoW API and
drives the login sequence: ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD,
a nameplate appearing, a spec change.

    pip install lupa
    python tests/load_test.py

Why this exists: PLAYER_LOGIN runs Nameplates_Init, Bars_Init, Options_Init and
Minimap_Init in that order, from ONE event handler. A Lua error in any of them
skips everything after it - so a bug in the options screen presents itself as
"the minimap button is gone", and a bug in the bars presents itself as "the
whole addon is dead". Nothing says which one it was.

The stub is deliberately permissive: any method that is not defined here is a
no-op that returns the frame. That means this cannot check what things LOOK
like - only that no code path calls something that does not exist, indexes a
nil, or throws. That is precisely the class of bug that kills an addon at load.
"""
import io, os, sys, traceback

try:
    from lupa import luajit21 as lupa_mod
except Exception:
    try:
        from lupa import lua54 as lupa_mod
    except Exception:
        import lupa as lupa_mod

ADDON = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STUB = r"""
local FrameMT = {}

-- An unknown member has to be BOTH callable and indexable: real templates
-- carry sub-regions (a slider's .Low is a FontString, which the addon then
-- calls :SetText on), and a stub that hands back a plain function turns
-- that perfectly correct line into "attempt to index a function value" -
-- a failure that exists only in the test. So the auto-member is a callable
-- table that grows the same way.
local function AutoMember()
    local t = {}
    return setmetatable(t, {
        __call  = function(self, ...) return ... end,
        __index = FrameMT.__index,
    })
end

FrameMT.__index = function(t, k)
    if type(k) == "string" and k:sub(1, 2) == "__" then return nil end
    local m = AutoMember()
    rawset(t, k, m)
    return m
end

FRAMES = {}
CALLS  = {}     -- what the addon asked the game to do, for the assertions

function CreateFrame(kind, name, parent, template)
    local f = setmetatable({
        __kind = kind, __name = name, __template = template,
        __scripts = {}, __events = {}, __points = {}, __shown = true,
    }, FrameMT)

    f.SetScript = function(self, ev, fn) self.__scripts[ev] = fn; return self end
    f.GetScript = function(self, ev) return self.__scripts[ev] end
    f.HookScript = f.SetScript
    f.RegisterEvent = function(self, ev) self.__events[ev] = true; return self end
    f.SetPoint = function(self, ...) self.__points[#self.__points + 1] = { ... }; return self end
    f.ClearAllPoints = function(self) self.__points = {}; return self end
    f.GetPoint = function(self) return "CENTER", nil, "CENTER", 0, 0 end
    f.GetWidth = function(self) return 100 end
    f.GetHeight = function(self) return 20 end
    f.GetCenter = function(self) return 50, 50 end
    -- geometry answers numbers (or nil before layout), never a stub object
    f.GetLeft = function(self) return 10 end
    f.GetBottom = function(self) return 10 end
    f.GetRight = function(self) return 110 end
    f.GetTop = function(self) return 30 end
    f.GetEffectiveScale = function(self) return 1 end
    f.GetFrameLevel = function(self) return 1 end
    f.IsShown = function(self) return self.__shown end
    f.Show = function(self) self.__shown = true; return self end
    f.Hide = function(self) self.__shown = false; return self end
    f.CreateTexture = function(self) return CreateFrame("Texture", nil, self) end
    f.CreateFontString = function(self) return CreateFrame("FontString", nil, self) end
    f.GetStatusBarTexture = function(self) return self.__sbt end
    f.SetStatusBarTexture = function(self, path) self.__sbt = path; return self end
    f.SetFont = function(self, path, size, flags)
        -- the real one returns false for a font it cannot load
        self.__font = path
        return path ~= nil and path ~= "BROKEN"
    end

    -- An aura container hands each freshly created button to the addon's
    -- initializeFrame. That callback is where the bars and the nameplate
    -- icons are actually built, so a stub that skips it would test nothing.
    if kind == "AuraContainer" then
        -- Core probes for these two BY TYPE ("function"), which is how it
        -- decides whether this client can show auras at all.
        f.SetUnit = function(self, unit) self.__unit = unit; return self end
        f.AddAuraGroup = function(self, key, filter, opts)
            CALLS[#CALLS + 1] = "AddAuraGroup:" .. tostring(key)
            if opts and opts.initializeFrame then
                opts.initializeFrame(CreateFrame("Button", nil, self))
            end
            return self
        end
    end

    FRAMES[#FRAMES + 1] = f
    return f
end

UIParent = CreateFrame("Frame")
Minimap  = CreateFrame("Frame")

GameFontNormal = { GetFont = function() return "Fonts\\FRIZQT__.TTF" end }
AnchorUtil = {
    FlowLayoutAxis = { Horizontal = 0, Vertical = 1 },
    FlowDirection  = { Left = -1, Right = 1, Up = 1, Down = -1 },
}
AuraContainerSortMethod    = { Default = 0, ExpirationOnly = 5 }
AuraContainerSortDirection = { Normal = 0, Reverse = 1 }
Enum = {
    StatusBarTimerDirection = { RemainingTime = 1, ElapsedTime = 0 },
    StatusBarInterpolation  = { Immediate = 0 },
}

C_Timer = { After = function(_, fn) PENDING[#PENDING + 1] = fn end }
PENDING = {}
C_NamePlate = {
    GetNamePlates = function() return {} end,
    GetNamePlateForUnit = function(unit) return PLATE end,
}
PLATE = CreateFrame("Frame")

Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        CALLS[#CALLS + 1] = "category:" .. tostring(name)
        return { GetID = function() return 1 end }
    end,
    RegisterAddOnCategory = function() end,
    RegisterCanvasLayoutSubcategory = function(cat, panel, name)
        CALLS[#CALLS + 1] = "subcategory:" .. tostring(name)
        return {}, {}
    end,
    OpenToCategory = function() end,
}
StaticPopupDialogs = {}
StaticPopup_Show = function(which) CALLS[#CALLS + 1] = "popup:" .. tostring(which) end
StaticPopup_OnClick = function() end
ColorPickerFrame = CreateFrame("Frame")
ColorPickerFrame.GetColorRGB = function() return 0.2, 0.4, 0.6 end
ColorPickerFrame.SetupColorPickerAndShow = function(_, info) CPINFO = info end

ACCEPT, CANCEL, YES, NO = "Accept", "Cancel", "Yes", "No"
SlashCmdList = {}
InCombatLockdown = function() return false end
GetCursorPosition = function() return 10, 10 end
GetBuildInfo = function() return "12.1.0", "60000", nil, 120100 end
GetLocale = function() return "enUS" end
UnitName = function() return "Tester" end
GetRealmName = function() return "Testrealm" end
GetSpecialization = function() return SPEC_INDEX end
GetSpecializationInfo = function(i) return SPECS[i], SPEC_NAMES[i] end
GetSpecializationInfoByID = function(id)
    for i, v in ipairs(SPECS) do if v == id then return id, SPEC_NAMES[i] end end
end
GetNumSpecializations = function() return #SPECS end
SPEC_INDEX = 1
SPECS = { 62, 63, 64 }
SPEC_NAMES = { "Arcane", "Fire", "Frost" }

format = string.format
date = function(fmt) return "2026-08-30 12:00:00" end

function strtrim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end
function strlower(s) return string.lower(s) end

PRINTED = {}
function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    PRINTED[#PRINTED + 1] = table.concat(parts, " ")
end
"""

LOADER = r"""
local ns = {}
NS = ns
for _, f in ipairs(FILES) do
    local chunk, err = loadfile(ADDON .. "\\" .. f)
    if not chunk then error("cannot load " .. f .. ": " .. tostring(err)) end
    chunk("HotsNDots", ns)
end

for _, f in ipairs(FRAMES) do
    if f.__scripts.OnEvent and f.__events.ADDON_LOADED then
        EVENT, FRAME = f.__scripts.OnEvent, f
    end
end

function fire(event, arg1)
    if not FRAME.__events[event] then
        error("addon never registered for " .. event, 2)
    end
    EVENT(FRAME, event, arg1)
end
function flush() local p = PENDING; PENDING = {}; for _, fn in ipairs(p) do fn() end end
"""

FILES = ["Locale.lua", "Core.lua", "Profiles.lua", "Media.lua", "Nameplates.lua",
         "Bars.lua", "Minimap.lua", "Options.lua"]

fails = []


def check(label, cond, extra=""):
    print(("  PASS  " if cond else "  FAIL  ") + label + (("  -> " + str(extra)) if not cond and extra else ""))
    if not cond:
        fails.append(label)


def step(lua, label, code):
    """Run one piece of the login sequence and report the Lua error verbatim."""
    try:
        lua.execute(code)
        print("  PASS  " + label)
        return True
    except Exception as e:
        msg = str(e).splitlines()[0]
        print("  FAIL  " + label + "  -> " + msg)
        fails.append(label + ": " + msg)
        return False


def newrt(files=FILES):
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ADDON = ADDON
    lua.execute(STUB)
    lua.execute("FILES = {" + ",".join('"%s"' % f for f in files) + "}")
    lua.execute(LOADER)
    return lua


print("1. a full login, fresh install")
lua = newrt()
lua.globals().HotsNDotsDB = None
step(lua, "ADDON_LOADED", 'fire("ADDON_LOADED", "HotsNDots")')
step(lua, "PLAYER_LOGIN (nameplates, bars, options, minimap)", 'fire("PLAYER_LOGIN")')
step(lua, "PLAYER_ENTERING_WORLD", 'fire("PLAYER_ENTERING_WORLD")')
step(lua, "a nameplate appears", 'fire("NAME_PLATE_UNIT_ADDED", "nameplate1")')
step(lua, "the target changes", 'fire("PLAYER_TARGET_CHANGED")')
step(lua, "the nameplate goes away", 'fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")')
step(lua, "a spec change", 'SPEC_INDEX = 2; fire("PLAYER_SPECIALIZATION_CHANGED", "player"); flush()')

calls = list(lua.globals().CALLS.values())
check("the settings category was registered", any(c.startswith("category:") for c in calls), calls)
check("the Bar style page was registered", "subcategory:Bar style" in calls, calls)
check("the Profiles page was registered", "subcategory:Profiles" in calls, calls)
check("bar rows were actually built", any(c == "AddAuraGroup:dots" for c in calls), calls)
# The minimap button is created LAST in PLAYER_LOGIN, so it is the canary for
# every error in the three inits before it.
check("the minimap button exists", lua.eval("NS.Minimap_UpdateShown ~= nil"))
check("and it is on the minimap",
      lua.eval("""(function()
          for _, f in ipairs(FRAMES) do
              for _, p in ipairs(f.__points) do
                  if p[2] == Minimap then return true end
              end
          end
          return false
      end)()"""))

print("\n2. the same login on an existing 1.4.x save")
lua = newrt()
lua.execute("""
HotsNDotsDB = {
    dbVersion = 3,
    filters = { showDebuffs = true, showBuffs = true },
    nameplates = { enabled = true, size = 30 },
    bars = { enabled = true, width = 220, locked = true },
    minimap = { hide = false, angle = 220 },
}
""")
step(lua, "ADDON_LOADED", 'fire("ADDON_LOADED", "HotsNDots")')
step(lua, "PLAYER_LOGIN", 'fire("PLAYER_LOGIN")')
check("the minimap setting came across",
      lua.eval("NS.global.minimap.hide == false and NS.global.minimap.angle == 220"))

print("\n3. every slash command")
for cmd in ["", "lock", "unlock", "bars", "nameplates", "minimap", "debug",
            "profiles", "profile", "profile Default", "newprofile Raid", "profile Raid"]:
    step(lua, "/hnd " + (cmd or "(no argument)"),
         'SlashCmdList["HOTSNDOTS"](%s)' % ('"%s"' % cmd))

print("\n4. the options pages actually redraw")
step(lua, "Options_RefreshUI", "NS.Options_RefreshUI()")
step(lua, "the Bar style page OnShow", """
    for _, f in ipairs(FRAMES) do
        if f.name == "Bar style" and f.__scripts.OnShow then f.__scripts.OnShow(f) end
    end
""")
step(lua, "the Profiles page OnShow", """
    for _, f in ipairs(FRAMES) do
        if f.name == "Profiles" and f.__scripts.OnShow then f.__scripts.OnShow(f) end
    end
""")
step(lua, "a restyle", "NS.Bars_Restyle(); NS.Nameplates_Restyle()")

print("\n5. update installed mid-session (Profiles.lua/Media.lua not loaded yet)")
lua = newrt(files=["Locale.lua", "Core.lua", "Nameplates.lua", "Bars.lua", "Minimap.lua", "Options.lua"])
lua.execute("HotsNDotsDB = { dbVersion = 3, minimap = { hide = false, angle = 220 } }")
step(lua, "ADDON_LOADED survives", 'fire("ADDON_LOADED", "HotsNDots")')
step(lua, "PLAYER_LOGIN survives", 'fire("PLAYER_LOGIN")')
printed = " ".join(list(lua.globals().PRINTED.values()))
check("it says to restart", "RESTART" in printed.upper(), printed[:100])
check("the minimap button still gets built",
      lua.eval("""(function()
          for _, f in ipairs(FRAMES) do
              for _, p in ipairs(f.__points) do
                  if p[2] == Minimap then return true end
              end
          end
          return false
      end)()"""))

# The four inits run from one event handler. Before they were isolated the
# FIRST error skipped the rest - and because the minimap button is built
# last, any bug at all presented itself as "the minimap icon is gone".
print("\n6. one broken init does not take the others with it")
lua = newrt()
lua.globals().HotsNDotsDB = None
lua.execute('fire("ADDON_LOADED", "HotsNDots")')
lua.execute('NS.Options_Init = function() error("something in the options screen") end')
step(lua, "PLAYER_LOGIN survives a broken Options_Init", 'fire("PLAYER_LOGIN")')
check("the minimap button was still built",
      lua.eval("""(function()
          for _, f in ipairs(FRAMES) do
              for _, p in ipairs(f.__points) do
                  if p[2] == Minimap then return true end
              end
          end
          return false
      end)()"""))
check("the failure was recorded for later",
      lua.eval('HotsNDotsDB.lastError ~= nil and HotsNDotsDB.lastError.where == "Options"'),
      lua.eval("HotsNDotsDB.lastError and HotsNDotsDB.lastError.where"))
check("and it names the actual error",
      "something in the options screen" in str(lua.eval("HotsNDotsDB.lastError.message")))
printed = " ".join(list(lua.globals().PRINTED.values()))
check("the player is told, not left guessing", "failed" in printed, printed[-120:])
step(lua, "/hnd debug prints the stored failure", 'SlashCmdList["HOTSNDOTS"]("debug")')
printed = " ".join(list(lua.globals().PRINTED.values()))
check("/hnd debug repeats it", "last failure" in printed)

# What this catches is a translation that ERRORS: a gained placeholder, a
# label that is nil, a page that cannot build. It does NOT catch a lost
# placeholder - Lua's format ignores extra arguments, so that one is silent
# and belongs to tests/locale_test.py. Two halves, two tests.
print("\n7. the same login in every supported language")
for locale, expect in [("deDE", "Filter"), ("frFR", "Filtres"),
                       ("esES", "Filtros"), ("esMX", "Filtros"),
                       ("ptBR", "Filters")]:
    print("  -- " + locale)
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ADDON = ADDON
    lua.execute(STUB)
    lua.execute('GetLocale = function() return "%s" end' % locale)
    lua.execute("FILES = {" + ",".join('"%s"' % f for f in FILES) + "}")
    lua.execute(LOADER)
    lua.globals().HotsNDotsDB = None
    ok = step(lua, locale + ": ADDON_LOADED + PLAYER_LOGIN",
              'fire("ADDON_LOADED", "HotsNDots"); fire("PLAYER_LOGIN")')
    if not ok:
        continue
    check(locale + ": the UI speaks that language",
          lua.eval("NS.L.hdrFilters") == expect, lua.eval("NS.L.hdrFilters"))
    for cmd in ["lock", "unlock", "bars", "nameplates", "minimap",
                "profiles", "profile", "newprofile Raid", "profile Raid",
                "profile Nope", "debug"]:
        step(lua, locale + ": /hnd " + cmd, 'SlashCmdList["HOTSNDOTS"]("%s")' % cmd)
    step(lua, locale + ": both option pages redraw", """
        for _, f in ipairs(FRAMES) do
            if f.__scripts.OnShow then f.__scripts.OnShow(f) end
        end
        NS.Options_RefreshUI()
    """)
    step(lua, locale + ": profile create/copy/reset/delete", """
        NS.Profiles_Create("Zwei")
        NS.Profiles_AssignCurrentSpec("Zwei")
        NS.Profiles_Copy("Default")
        NS.Profiles_Reset()
        NS.Profiles_Delete("Zwei")
    """)

# Locale.lua is loaded FIRST and read at FILE scope (Bars.lua builds its
# preset labels from it). Without the stand-in in Core.lua that file would
# not even load - the same mid-session update trap as section 5, one file
# earlier and one degree worse.
print("\n8. update mid-session, with Locale.lua missing too")
lua = newrt(files=["Core.lua", "Nameplates.lua", "Bars.lua", "Minimap.lua", "Options.lua"])
lua.execute("HotsNDotsDB = { dbVersion = 3, minimap = { hide = false, angle = 220 } }")
step(lua, "ADDON_LOADED survives", 'fire("ADDON_LOADED", "HotsNDots")')
step(lua, "PLAYER_LOGIN survives", 'fire("PLAYER_LOGIN")')
check("labels degrade to their key name, never to nil",
      isinstance(lua.eval("NS.L.hdrFilters"), str), lua.eval("NS.L.hdrFilters"))
check("the minimap button still gets built",
      lua.eval("""(function()
          for _, f in ipairs(FRAMES) do
              for _, p in ipairs(f.__points) do
                  if p[2] == Minimap then return true end
              end
          end
          return false
      end)()"""))
step(lua, "and the slash commands do not throw", 'SlashCmdList["HOTSNDOTS"]("bars")')

print("\n" + ("ALL PASS" if not fails else "FAILURES:\n  - " + "\n  - ".join(fails)))
sys.exit(1 if fails else 0)
