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

function ns.SetFont(fontString, size, outline)
    if not fontString then return end
    if not fontString:SetFont(FONT_PATH, size, outline or "OUTLINE") then
        -- last resort so the text is never invisible
        fontString:SetFont([[Fonts\FRIZQT__.TTF]], size, outline or "OUTLINE")
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
        HotsNDotsDB = copyDefaults(defaults, HotsNDotsDB or {})
        ns.db = HotsNDotsDB

        -- 1.1.0: "show stacks" changed meaning. It used to print the raw
        -- number on every aura (so a plain DoT read "1") and was therefore
        -- off by default; it now shows real stacks only. The stored value
        -- no longer describes the same option, so opt everyone back in once.
        if (ns.db.dbVersion or 0) < 1 then
            ns.db.nameplates.showStacks = true
            ns.db.bars.showStacks = true
        end

        -- 1.4.0: the display belongs to the game now. Settings that only
        -- made sense for the old hand-rolled scanner are dropped.
        if (ns.db.dbVersion or 0) < 2 then
            ns.db.watch      = nil -- learned spell names of the by-name fallback
            ns.db.includePet = nil -- "PLAYER" always covers pet/vehicle now
            ns.db.onlyMine   = nil -- was never anything but true
            ns.db.nameplates.hideBlizzard = nil
            ns.db.dbVersion = 2
        end

        -- 1.4.1: one "hide auras without a timer" switch became two. The
        -- old one only ever hid raid buffs on purpose; applying it to
        -- debuffs as well swallowed permanent DoTs like Absolute
        -- Corruption, so debuffs start out visible regardless.
        if (ns.db.dbVersion or 0) < 3 then
            if ns.db.filters.hidePermanent ~= nil then
                ns.db.filters.hidePermanentBuffs = ns.db.filters.hidePermanent
                ns.db.filters.hidePermanent = nil
            end
            ns.db.filters.hidePermanentDebuffs = false
            ns.db.dbVersion = 3
        end

    elseif event == "PLAYER_LOGIN" then
        if ns.hasAuraContainers then
            if ns.Nameplates_Init then ns.Nameplates_Init() end
            if ns.Bars_Init      then ns.Bars_Init()      end
        else
            print(BRAND .. ": this client has no AuraContainer widget (needs 12.1.0),")
            print(BRAND .. ": so the aura display stays off. Please update the game.")
        end
        if ns.Options_Init then ns.Options_Init() end
        if ns.Minimap_Init then ns.Minimap_Init() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- auras stop being secret here, so anything the client refused
        -- to restyle mid-fight can be applied now
        if pendingRestyle then
            pendingRestyle = false
            ns.RestyleAll()
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
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
