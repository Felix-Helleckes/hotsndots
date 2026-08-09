--=====================================================================
--  HotsNDots - Core
--  Shows ONLY the auras YOU applied:
--    * Debuffs (DoTs) on your enemies
--    * Buffs / HoTs on your friends
--
--  MIDNIGHT 12.0 "Secret Values":
--  Aura fields (duration, expirationTime, icon, name, applications,
--  sourceUnit, isHarmful, spellId ...) can be "secret": they must not be
--  compared, calculated with, used in an if-condition or string-formatted
--  by addons - doing so throws a Lua error. Everything below therefore
--  either passes secrets straight into a Blizzard widget, or asks the
--  C side a question (C_UnitAuras.*) instead of reading the value.
--=====================================================================

local ADDON_NAME, ns = ...
ns.name = "HotsNDots"

local BRAND = "|cff33ff99HotsNDots|r"
ns.BRAND = BRAND

--------------------------------------------------------------------
-- Midnight API surface (all optional -> the addon degrades instead of
-- erroring on older / future clients)
--------------------------------------------------------------------
local C_UnitAuras = C_UnitAuras
local GetAuraDataByIndex             = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local GetAuraDuration                = C_UnitAuras and C_UnitAuras.GetAuraDuration
local GetAuraApplicationDisplayCount = C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount
local IsAuraFilteredOut              = C_UnitAuras and C_UnitAuras.IsAuraFilteredOutByInstanceID

-- true when a value came back as a Midnight "secret" and may not be touched
local function isSecret(v)
    return issecretvalue and issecretvalue(v) or false
end
ns.IsSecret = isSecret

local function isReadable(v)
    return not isSecret(v)
end
ns.IsReadable = isReadable

-- StatusBar:SetTimerDuration enums (numeric fallbacks for safety)
local INTERP_IMMEDIATE = (Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate) or 0
local DIR_REMAINING    = (Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime) or 1

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
    onlyMine   = true,
    includePet = false,

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

-- Stable ordering via the readable (non-secret) auraInstanceID
function ns.SortByInstanceID(a, b)
    return (a.auraInstanceID or 0) < (b.auraInstanceID or 0)
end

--------------------------------------------------------------------
-- Remaining time
--  C_UnitAuras.GetAuraDuration(unit, auraInstanceID) hands back a live
--  Duration object built by the game itself. That object is the only
--  supported way to drive a countdown from a secret expiration time -
--  building one ourselves from aura.expirationTime silently fails,
--  which is what produced missing and stale timers before.
--  Returns nil for auras without a duration (permanent buffs).
--------------------------------------------------------------------
function ns.GetDuration(unit, aura)
    if not (GetAuraDuration and unit and aura and aura.auraInstanceID) then return nil end
    return GetAuraDuration(unit, aura.auraInstanceID)
end

-- Drive a Cooldown frame (swipe and/or built-in countdown number) from a
-- Duration object. Always clears when there is nothing to show, so a
-- recycled icon can never keep the previous aura's timer.
function ns.ApplyCooldown(cooldown, duration)
    if not cooldown then return end
    if duration and cooldown.SetCooldownFromDurationObject then
        cooldown:SetCooldownFromDurationObject(duration)
    else
        cooldown:Clear()
    end
end

-- Drive a StatusBar fill from a Duration object (empties as time runs out).
function ns.ApplyBarFill(bar, duration)
    if not bar then return end

    if duration and bar.SetTimerDuration then
        bar:SetTimerDuration(duration, INTERP_IMMEDIATE, DIR_REMAINING)
        bar.hndTimed = true
        return
    end

    -- No duration (permanent aura, or the bar is being recycled): stop the
    -- previous animation so it cannot keep draining, then show a full bar.
    -- Clearing via SetTimerDuration(nil) is the obvious way out but is not
    -- something any current addon relies on, so treat it as best-effort.
    if bar.hndTimed and bar.SetTimerDuration then
        pcall(bar.SetTimerDuration, bar, nil)
        bar.hndTimed = nil
    end
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
end

--------------------------------------------------------------------
-- Cooldown countdown number
--  Since Midnight we may not format a remaining time into a string
--  ourselves. The one text that still works is the Cooldown frame's own
--  built-in countdown - so we fish its FontString out of the frame and
--  style/position it like any other font string.
--------------------------------------------------------------------
function ns.GetCountdownFontString(cooldown)
    if not cooldown then return nil end
    if cooldown.hndText then return cooldown.hndText end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "FontString" then
            cooldown.hndText = region
            return region
        end
    end
    return nil
end

-- A Cooldown frame used purely as a countdown *number* (no swipe).
-- Kept separate from the swipe cooldown so the text can sit outside the
-- icon without being clipped by the swipe frame.
function ns.CreateTimerText(parent)
    local cd = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
    cd:SetDrawSwipe(false)
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(false)
    cd:EnableMouse(false)
    cd.noCooldownCount = true -- keep OmniCC & friends off our own text
    if cd.SetMinimumCountdownDuration then cd:SetMinimumCountdownDuration(0) end
    if cd.SetCountdownAbbrevThreshold then cd:SetCountdownAbbrevThreshold(60) end
    return cd
end

--------------------------------------------------------------------
-- Stacks
--  C_UnitAuras.GetAuraApplicationDisplayCount(unit, id, min, max)
--  answers "what should the stack text say" on the C side and returns
--  nothing when the aura has fewer than `min` applications. That is what
--  keeps a plain 1-application DoT (Unstable Affliction, Agony at 1, ...)
--  from being labelled "1" while a real 5-stack still shows "5".
--------------------------------------------------------------------
local STACK_MIN, STACK_MAX = 2, 999

function ns.SetStackText(fontString, unit, aura)
    if not fontString then return end
    if not (unit and aura and aura.auraInstanceID) then
        fontString:SetText("")
        return
    end

    if GetAuraApplicationDisplayCount then
        -- returns nil / empty below STACK_MIN -> nothing is drawn
        fontString:SetText(GetAuraApplicationDisplayCount(unit, aura.auraInstanceID, STACK_MIN, STACK_MAX))
        return
    end

    -- Pre-Midnight fallback: applications is a plain number there.
    local n = aura.applications
    if isReadable(n) and type(n) == "number" and n >= STACK_MIN then
        fontString:SetText(n)
    else
        fontString:SetText("")
    end
end

--------------------------------------------------------------------
-- Harmful / helpful
--  aura.isHarmful can be secret, and putting a secret into an
--  if-condition raises an error. Ask the C side instead.
--------------------------------------------------------------------
function ns.IsHarmful(unit, aura)
    if isReadable(aura.isHarmful) then
        return aura.isHarmful and true or false
    end
    if IsAuraFilteredOut and unit and aura.auraInstanceID then
        return not IsAuraFilteredOut(unit, aura.auraInstanceID, "HARMFUL")
    end
    return false
end

--------------------------------------------------------------------
-- Aura scanner
--  Returns every aura on 'unit' that was applied by the player
--  (optionally pet) - harmful AND helpful.
--  "Was it cast by me?" is answered by the C-side PLAYER filter through
--  IsAuraFilteredOutByInstanceID, never by comparing sourceUnit.
--------------------------------------------------------------------
local function collectAuras(unit, baseFilter, includePet, out)
    if not GetAuraDataByIndex then return end

    local playerFilter = baseFilter .. "|PLAYER"
    -- Without pet we can let the C side do the filtering while enumerating.
    local scanFilter = includePet and baseFilter or playerFilter

    for i = 1, 60 do
        local aura = GetAuraDataByIndex(unit, i, scanFilter)
        if not aura or not aura.auraInstanceID then break end

        local keep = true
        if includePet then
            keep = false
            if IsAuraFilteredOut and not IsAuraFilteredOut(unit, aura.auraInstanceID, playerFilter) then
                keep = true -- cast by us
            elseif isReadable(aura.isFromPlayerOrPlayerPet) and aura.isFromPlayerOrPlayerPet then
                keep = true -- cast by our pet (readable flag only; never a secret)
            end
        end

        if keep then
            out[#out + 1] = aura
        end
    end
end

function ns.ScanUnit(unit, out)
    out = out or {}
    wipe(out)
    if not ns.db then return out end
    if not unit or not UnitExists(unit) then return out end

    local includePet = ns.db.includePet
    collectAuras(unit, "HARMFUL", includePet, out) -- DoTs / debuffs (enemies)
    collectAuras(unit, "HELPFUL", includePet, out) -- HoTs / buffs (friends)
    return out
end

--------------------------------------------------------------------
-- Central event dispatch
--------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
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
                ns.db.dbVersion = 1
            end

            -- 1.1.0: "hide default Blizzard auras" is no longer a choice -
            -- our nameplate icons always replace them.
            ns.db.nameplates.hideBlizzard = nil
        end

    elseif event == "PLAYER_LOGIN" then
        if ns.Nameplates_Init then ns.Nameplates_Init() end
        if ns.Bars_Init      then ns.Bars_Init()      end
        if ns.Options_Init   then ns.Options_Init()   end
        if ns.Minimap_Init   then ns.Minimap_Init()   end

    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        if ns.Bars_Update then ns.Bars_Update() end

    elseif event == "UNIT_AURA" then
        if ns.Nameplates_OnUnitAura then ns.Nameplates_OnUnitAura(arg1) end
        if ns.db and arg1 == ns.db.bars.unit and ns.Bars_Update then
            ns.Bars_Update()
        end

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if ns.Nameplates_OnAdded then ns.Nameplates_OnAdded(arg1) end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if ns.Nameplates_OnRemoved then ns.Nameplates_OnRemoved(arg1) end
    end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

-- Note: no custom OnUpdate timer needed - the Cooldown countdown, the
-- swipe and the StatusBar fill all tick C-side from the Duration object.
