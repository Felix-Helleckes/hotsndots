--=====================================================================
--  DotsNHots - Core
--  Shows ONLY the auras YOU applied:
--    * Debuffs (DoTs) on your enemies
--    * Buffs / HoTs on your friends
--
--  MIDNIGHT 12.0 "Secret Values":
--  Aura fields (duration, expirationTime, icon, name, applications,
--  sourceUnit, spellId ...) are now "secret" and must NOT be compared,
--  calculated or string-formatted by addons. We only ever PASS them
--  through to the dedicated Blizzard widgets (Duration objects,
--  Cooldown, StatusBar, SetTexture / SetText).
--=====================================================================

local ADDON_NAME, ns = ...
ns.name = "DotsNHots"

--------------------------------------------------------------------
-- Feature detection for the new Midnight duration APIs
--------------------------------------------------------------------
ns.HAS_DURATION = (C_DurationUtil and C_DurationUtil.CreateDuration) and true or false

--------------------------------------------------------------------
-- Default settings
--------------------------------------------------------------------
local defaults = {
    onlyMine   = true,
    includePet = false,

    nameplates = {
        enabled       = true,
        hideBlizzard  = true,  -- hide/replace the default Blizzard nameplate auras
        below         = false, -- false = above the nameplate, true = below
        size          = 30,
        spacing       = 4,
        maxIcons      = 8,
        xOffset       = 0,
        yOffset       = 14,
        stackFontSize = 12,
        showStacks    = false, -- Midnight: single stacks can no longer be filtered out
        showSwipe     = true,
    },

    bars = {
        enabled   = true,
        locked    = false,
        width     = 220,
        height    = 24,
        spacing   = 2,
        maxBars   = 12,
        growthUp  = false,
        unit      = "target",
        fontSize  = 13,
        point     = { point = "CENTER", relPoint = "CENTER", x = 320, y = 0 },
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
-- Duration object (Midnight compliant)
--  One reusable Duration object per icon/bar. It drives the Blizzard
--  Cooldown swipe + built-in countdown NUMBERS and the StatusBar fill.
--  We only ever pass the secret aura times through - never read them.
--  No custom text: the built-in cooldown numbers render "10" in the
--  correct localized short form, exactly like Blizzard's own auras.
--------------------------------------------------------------------
function ns.CreateDurationSet()
    local set = {}
    if ns.HAS_DURATION then
        set.duration = C_DurationUtil.CreateDuration()
    end
    return set
end

function ns.UpdateDurationSet(set, aura)
    if set and set.duration then
        -- SetTimeFromEnd(endTime, duration [, modRate])
        pcall(set.duration.SetTimeFromEnd, set.duration,
              aura.expirationTime, aura.duration, aura.timeMod)
    end
end

--------------------------------------------------------------------
-- Aura scanner
--  Returns every aura on 'unit' that was applied by the player
--  (optionally pet) - harmful AND helpful. No secret field is ever
--  compared: we use the C-side "PLAYER" filter, or the readable
--  boolean isFromPlayerOrPlayerPet.
--------------------------------------------------------------------
function ns.ScanUnit(unit, out)
    out = out or {}
    wipe(out)
    if not ns.db then return out end
    if not unit or not UnitExists(unit) then return out end

    local includePet = ns.db.includePet

    local function collect(baseFilter)
        -- Without pet: fast "PLAYER" filter (player-cast only).
        -- With pet: scan everything and filter by the readable boolean.
        local filter = includePet and baseFilter or (baseFilter .. "|PLAYER")
        AuraUtil.ForEachAura(unit, filter, nil, function(aura)
            if aura then
                if includePet then
                    if aura.isFromPlayerOrPlayerPet then
                        out[#out + 1] = aura
                    end
                else
                    out[#out + 1] = aura
                end
            end
        end, true) -- packed aura
    end

    collect("HARMFUL") -- DoTs / debuffs (enemies)
    collect("HELPFUL") -- HoTs / buffs (friends)
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
            DotsNHotsDB = copyDefaults(defaults, DotsNHotsDB or {})
            ns.db = DotsNHotsDB
        end

    elseif event == "PLAYER_LOGIN" then
        -- Blizzard's built-in cooldown NUMBERS (the seconds on the icons)
        -- require this display option to be enabled.
        pcall(function()
            if GetCVar and SetCVar and GetCVar("countdownForCooldowns") == "0" then
                SetCVar("countdownForCooldowns", "1")
            end
        end)
        if ns.Nameplates_Init then ns.Nameplates_Init() end
        if ns.Bars_Init      then ns.Bars_Init()      end
        if ns.Options_Init   then ns.Options_Init()   end
        if ns.Minimap_Init   then ns.Minimap_Init()   end

    elseif event == "PLAYER_TARGET_CHANGED" then
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
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

-- Note: no custom OnUpdate timer needed - the Cooldown (swipe + built-in
-- numbers) and the StatusBar refresh their display C-side.
