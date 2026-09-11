--=====================================================================
--  HotsNDots - Core
--  Shows ONLY the auras YOU applied:
--    * Debuffs (DoTs) on your enemies
--    * Buffs / HoTs on your friends
--
--  MIDNIGHT 12.1 "Secret Auras":
--  Addons may no longer look at aura data at all while it is secret
--  (combat, encounters, M+, rated PvP). Every C_UnitAuras call that
--  reaches an aura by index, slot or instance ID raises a Lua error
--  there, and UNIT_AURA carries a fully secret payload.
--
--  Blizzard's replacement is the AuraContainer widget: the game owns the
--  aura buttons, decides which auras go into them and fills in icon,
--  timer and stacks itself. The addon only describes what it wants (a
--  filter string plus candidate filters) and hands the game a set of
--  plain regions to draw into. That is what HotsNDots does since 1.4.0 -
--  it never sees a single aura value, so there is nothing left for the
--  client to refuse.
--=====================================================================

local ADDON_NAME, ns = ...
ns.name = "HotsNDots"

local BRAND = "|cff33ff99HotsNDots|r"
ns.BRAND = BRAND

-- Locale.lua is loaded before this file, and if it ISN'T - an update
-- installed while the game was running, where the .toc is still the old
-- one - then ns.L is nil, and every localised string in the addon is an
-- index of nil. Bars.lua reads it at FILE scope for the preset labels, so
-- that file would not even load. A stand-in that answers its own key is
-- ugly on screen and alive, which is the whole point of the degradation
-- path in ADDON_LOADED below.
ns.L = ns.L or setmetatable({}, { __index = function(_, k) return tostring(k) end })

--------------------------------------------------------------------
-- Capability check
--  AuraContainer and CustomAuraContainerTemplate arrived in 12.1.0.
--  Without them there is no supported way left to show auras, so the
--  addon says so once instead of failing in the dark.
--------------------------------------------------------------------
local function DetectAuraContainers()
    -- An unknown frame type does not fail: CreateFrame just hands back a
    -- plain Frame. The real methods only exist once the template applied,
    -- so those are what gets checked.
    if AuraContainerSortMethod == nil then return false end

    local ok, frame = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    if not ok or type(frame) ~= "table" then return false end
    if type(frame.AddAuraGroup) ~= "function" or type(frame.SetUnit) ~= "function" then
        return false
    end

    frame:Hide()
    ns.probeContainer = frame -- frames cannot be destroyed; park the probe
    return true
end

ns.hasAuraContainers = DetectAuraContainers()

--------------------------------------------------------------------
-- Enums used by the container API (guarded, so a missing one degrades
-- to a sane default instead of a nil index error)
--------------------------------------------------------------------
ns.FlowAxis = AnchorUtil and AnchorUtil.FlowLayoutAxis or { Horizontal = 0, Vertical = 1 }
ns.FlowDir  = AnchorUtil and AnchorUtil.FlowDirection or { Left = -1, Right = 1, Up = 1, Down = -1 }

ns.SortMethod    = AuraContainerSortMethod or { Default = 0, ExpirationOnly = 5 }
ns.SortDirection = AuraContainerSortDirection or { Normal = 0, Reverse = 1 }

ns.BAR_DIR_REMAINING = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime
ns.BAR_INTERP        = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate

--------------------------------------------------------------------
-- Fonts
--  STANDARD_TEXT_FONT is NOT a Blizzard global (some addons define it,
--  most notably ElvUI - so it silently exists on some setups and is nil
--  on others). SetFont(nil, ...) leaves the font string with no font at
--  all, which is why names and stacks could end up invisible. Derive the
--  path from a real Blizzard font object instead: that is also correct
--  for CJK/RU clients, where FRIZQT__.TTF cannot render the game's text.
--------------------------------------------------------------------
local FONT_PATH
do
    if GameFontNormal and GameFontNormal.GetFont then
        FONT_PATH = GameFontNormal:GetFont()
    end
    FONT_PATH = FONT_PATH or STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]]
end
ns.FONT_PATH = FONT_PATH

-- `path` lets a caller ask for a chosen font (the bars do). It falls back
-- the same way the default does, and for the same reason: a font that
-- cannot be set leaves the text with NO font at all, which reads as
-- "my timers disappeared" rather than as a bad font pick. A media
-- library that was uninstalled since the pick was made is exactly that
-- case, so it has to land somewhere sane rather than nowhere.
function ns.SetFont(fontString, size, outline, path)
    if not fontString then return end
    outline = outline or "OUTLINE"
    if path and path ~= FONT_PATH and fontString:SetFont(path, size, outline) then
        return
    end
    if not fontString:SetFont(FONT_PATH, size, outline) then
        -- last resort so the text is never invisible
        fontString:SetFont([[Fonts\FRIZQT__.TTF]], size, outline)
    end
end

--------------------------------------------------------------------
-- Default settings
--------------------------------------------------------------------
local defaults = {
    -- "What did I cast" is not the same as "what is worth watching".
    -- Every one of these is expressed as a filter the game applies for
    -- us, so no aura value is ever read here.
    filters = {
        showDebuffs      = true,  -- your DoTs on enemies
        showBuffs        = true,  -- your HoTs/buffs on friends
        hideCrowdControl = false, -- your Fear/Poly/... among the DoTs

        -- Auras with no timer at all, split by kind because the answer is
        -- not the same for both. Your own raid buffs (Fortitude, Intellect)
        -- are permanent and would sit in the capped slots forever, so they
        -- are hidden by default. A permanent DEBUFF is a different story -
        -- Absolute Corruption makes Corruption last until the target dies,
        -- and that is exactly a DoT you want on screen.
        hidePermanentBuffs   = true,
        hidePermanentDebuffs = false,
    },

    nameplates = {
        enabled       = true,
        below         = false, -- false = above the nameplate, true = below
        size          = 30,
        spacing       = 4,
        maxIcons      = 8,
        xOffset       = 0,
        yOffset       = 14,
        timerFontSize = 16,
        stackFontSize = 12,
        showStacks    = true,  -- only ever shows real stacks (2+)
        showSwipe     = true,
    },

    bars = {
        enabled    = true,
        locked     = false,
        width      = 220,
        height     = 24,
        spacing    = 2,
        maxBars    = 12,
        growthUp   = false,
        unit       = "target",
        fontSize   = 13,
        showStacks = true,     -- only ever shows real stacks (2+)
        point      = { point = "CENTER", relPoint = "CENTER", x = 320, y = 0 },

        -- Look of a bar row. The preset only rearranges the pieces that
        -- already exist (see BarStyles in Bars.lua); texture and font are
        -- names, not paths, so a LibSharedMedia pick survives a reload
        -- even if the library is loaded later - or not at all.
        style      = "default",
        texture    = "Blizzard",
        font       = "Default",
        colorDot   = { r = 0.70, g = 0.15, b = 0.15 },
        colorHot   = { r = 0.15, g = 0.60, b = 0.25 },
    },

    minimap = {
        hide  = false,
        angle = 220,
    },
}
ns.defaults = defaults

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------
local function copyDefaults(src, dst)
    dst = dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = copyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end
ns.copyDefaults = copyDefaults

--------------------------------------------------------------------
-- What the game should put into our containers
--
--  filterString     evaluated C-side before we ever see anything.
--                   "PLAYER" means "cast by you, your pet or your
--                   vehicle" - there is no separate pet filter any
--                   more, which is why the old "also count pet auras"
--                   option is gone.
--  candidateFilters a second, structured pass the container applies
--                   after the filter string. A non-nil maxDuration is
--                   documented as implicitly hiding permanent auras,
--                   which is exactly the "hide auras without a timer"
--                   option - math.huge caps nothing else.
--------------------------------------------------------------------
function ns.FilterString(base, extra)
    local filter = base .. "|PLAYER"
    if extra then
        filter = filter .. "|" .. extra
    end
    if ns.db and ns.db.filters.hideCrowdControl then
        filter = filter .. "|!CROWD_CONTROL"
    end
    return filter
end

-- "Hide auras without a timer" is expressed through maxDuration, which the
-- game evaluates as
--     duration > maxDuration or duration == 0  ->  rejected
-- so math.huge caps nothing and only the "or duration == 0" half bites:
-- it drops exactly the permanent auras. Buffs and debuffs get their own
-- switch because the sensible answer differs between them.
function ns.CandidateFilters(kind)
    local f = ns.db and ns.db.filters
    if not f then return {} end

    -- deliberately not an and/or chain: `x and false or y` would fall
    -- through to y and silently apply the wrong switch
    local hidePermanent
    if kind == "HELPFUL" then
        hidePermanent = f.hidePermanentBuffs
    else
        hidePermanent = f.hidePermanentDebuffs
    end

    if hidePermanent then
        return { maxDuration = math.huge }
    end
    return {}
end

-- Aura groups cannot be removed once they exist, so "do not show buffs"
-- is expressed as "this group may fill zero frames".
function ns.GroupMaxFrames(kind, configured)
    local f = ns.db.filters
    if kind == "HARMFUL" and not f.showDebuffs then return 0 end
    if kind == "HELPFUL" and not f.showBuffs   then return 0 end
    return configured
end

--------------------------------------------------------------------
-- Deferred restyling
--  Aura buttons are access restricted: once the game owns them they may
--  only be touched by us while auras are NOT secret. Restyling after an
--  options change is therefore attempted, and rescheduled to the end of
--  combat when the client refuses.
--------------------------------------------------------------------
local pendingRestyle = false

function ns.TryRestyle(fn, ...)
    if pcall(fn, ...) then return true end
    pendingRestyle = true
    return false
end

function ns.RestyleAll()
    if ns.Nameplates_Restyle then ns.Nameplates_Restyle() end
    if ns.Bars_Restyle      then ns.Bars_Restyle()      end
end

--------------------------------------------------------------------
-- Isolated start-up
--  Nameplates, bars, options and the minimap button are four unrelated
--  things started from ONE event handler. A Lua error in any of them
--  aborts the handler, so everything after it never runs - and since the
--  minimap button is built last, a bug anywhere presents itself as "the
--  minimap icon is gone", with nothing saying which part actually broke.
--
--  Each one therefore runs on its own now. The error is printed AND kept
--  in the saved variables, because the interesting one happens at login,
--  scrolls away, and is gone by the time anyone looks - and an error you
--  cannot read afterwards costs a full session to reproduce.
--------------------------------------------------------------------
local function SafeInit(label, fn)
    if not fn then return end

    local ok, err = xpcall(fn, function(e)
        return tostring(e) .. "\n" .. (debugstack and debugstack(2) or "")
    end)
    if ok then return end

    HotsNDotsDB = HotsNDotsDB or {}
    HotsNDotsDB.lastError = {
        where   = label,
        message = tostring(err),
        at      = date and date("%Y-%m-%d %H:%M:%S") or "",
        version = (C_AddOns and C_AddOns.GetAddOnMetadata
                   and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")) or "?",
    }
    ns.lastError = HotsNDotsDB.lastError

    print(BRAND .. ": |cffff4444" .. format(ns.L.msgInitFailed, label) .. "|r")
    print(BRAND .. ": " .. (tostring(err):gsub("\n.*", "")))
    print(BRAND .. ": " .. ns.L.msgDebugHint)
end
ns.SafeInit = SafeInit

--------------------------------------------------------------------
-- Central event dispatch
--  UNIT_AURA is deliberately not registered any more: every container
--  subscribes itself and refreshes its own buttons C-side.
--------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end

        -- carry settings over from the old DotsNHots name if they are still around
        if HotsNDotsDB == nil and type(DotsNHotsDB) == "table" then
            HotsNDotsDB = DotsNHotsDB
        end
        HotsNDotsDB = HotsNDotsDB or {}

        -- A file that is NEW in the .toc only arrives after a full
        -- client restart: /reload re-runs the Lua the game already knows
        -- about, but it does not re-read the file list. An update
        -- installed while the game is running - which is exactly what an
        -- addon manager does - therefore reaches this file before it
        -- reaches Profiles.lua, and a nil call here would take the whole
        -- addon down with a Lua error and no display at all.
        --
        -- So degrade instead: keep the flat table as the active settings,
        -- which is precisely the shape this build's predecessor used, and
        -- say what is going on. Everything keeps working; only profiles
        -- are missing, and they arrive with the restart.
        if not ns.Profiles_Setup then
            ns.db = copyDefaults(defaults, HotsNDotsDB)
            ns.global = ns.db  -- in the old shape the minimap lives here
            print(BRAND .. ": " .. ns.L.msgUpdate1)
            print(BRAND .. ": " .. ns.L.msgUpdate2)
            print(BRAND .. ": " .. ns.L.msgUpdate3)
            return
        end

        -- Everything about the shape of the save, including every
        -- migration that used to live here, is now Profiles' business:
        -- the old flat settings become the "Default" profile and the
        -- per-version fixups run on each profile instead of once.
        -- ns.db points at the ACTIVE profile from here on.
        ns.Profiles_Setup(HotsNDotsDB)

    elseif event == "PLAYER_LOGIN" then
        -- ADDON_LOADED is too early for GetSpecialization(): it can still
        -- answer nil there, which would put every character on Default
        -- for the rest of the session. Resolve again now, before anything
        -- is built, so the display comes up on the right profile.
        --
        -- Guarded for the same reason as the setup call above: this line
        -- sits BEFORE everything that builds the display, so without the
        -- guard a half-installed update takes the whole display with it -
        -- which is exactly how it presents itself: "nothing shows up".
        if ns.Profiles_ApplyForSpec then ns.Profiles_ApplyForSpec(true) end

        if ns.hasAuraContainers then
            SafeInit("Nameplates", ns.Nameplates_Init)
            SafeInit("Bars",       ns.Bars_Init)
        else
            print(BRAND .. ": " .. ns.L.msgNoContainer1)
            print(BRAND .. ": " .. ns.L.msgNoContainer2)
        end
        SafeInit("Options", ns.Options_Init)
        SafeInit("Minimap", ns.Minimap_Init)

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- auras stop being secret here, so anything the client refused
        -- to restyle mid-fight can be applied now
        if pendingRestyle then
            pendingRestyle = false
            ns.RestyleAll()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Second chance at the spec. GetSpecialization() can still answer
        -- nil at PLAYER_LOGIN on a slow load, and a character that came up
        -- on the wrong profile would stay there until it changed spec -
        -- the same "only ever resolved once at startup" trap that keeps
        -- catching everything else. Re-resolving costs nothing when the
        -- answer is the same.
        if ns.Profiles_ApplyForSpec then ns.Profiles_ApplyForSpec(true) end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Fires for group members too, so it has to be OUR spec - and it
        -- fires before the new spec is readable often enough that the
        -- lookup is deferred by a frame. Re-resolving is cheap and lands
        -- on the same profile when nothing changed.
        if arg1 == nil or arg1 == "player" then
            C_Timer.After(0, function()
                if ns.Profiles_ApplyForSpec then ns.Profiles_ApplyForSpec() end
            end)
        end

    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        if ns.Bars_OnUnitChanged then ns.Bars_OnUnitChanged() end

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if ns.Nameplates_OnAdded then ns.Nameplates_OnAdded(arg1) end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if ns.Nameplates_OnRemoved then ns.Nameplates_OnRemoved(arg1) end
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
