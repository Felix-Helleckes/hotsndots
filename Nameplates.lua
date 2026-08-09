--=====================================================================
--  HotsNDots - Nameplates  (Midnight 12.0 "Secret Values" compliant)
--  Shows your own auras large above the nameplate:
--  icon + cooldown swipe + big seconds countdown + real stacks.
--
--  The seconds are drawn by a second, swipe-less Cooldown frame sitting
--  above the icon: Blizzard's built-in countdown is the only text that
--  may still display a secret remaining time.
--=====================================================================

local ADDON_NAME, ns = ...

-- plates[unitToken] = container frame
local plates = {}
ns.nameplateContainers = plates

--------------------------------------------------------------------
-- Create a single aura icon
--------------------------------------------------------------------
local function CreateIcon(parent)
    local b = CreateFrame("Frame", nil, parent)
    b:SetFrameStrata("HIGH")

    b.border = b:CreateTexture(nil, "BACKGROUND")
    b.border:SetPoint("TOPLEFT", -1.5, 1.5)
    b.border:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
    b.border:SetColorTexture(0, 0, 0, 1)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- swipe only - its own countdown text stays off
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints()
    b.cooldown:SetDrawEdge(false)
    b.cooldown:SetHideCountdownNumbers(true)
    b.cooldown:SetReverse(true)
    b.cooldown:EnableMouse(false)
    b.cooldown.noCooldownCount = true

    -- big seconds above the icon (Blizzard's built-in countdown number)
    b.timeCD = ns.CreateTimerText(b)
    b.timeCD:SetPoint("BOTTOM", b, "TOP", 0, 0)
    b.timer = ns.GetCountdownFontString(b.timeCD)
    if b.timer then
        b.timer:ClearAllPoints()
        b.timer:SetPoint("CENTER", b.timeCD, "CENTER", 0, 0)
        b.timer:SetJustifyH("CENTER")
    end

    -- stack count in the bottom-right corner
    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", 2, -2)
    ns.SetFont(b.count, 12)
    b.count:SetTextColor(1, 1, 1)

    return b
end

local function GetContainer(nameplate)
    local c = nameplate.HotsNDots
    if not c then
        c = CreateFrame("Frame", nil, nameplate)
        c:SetFrameStrata("HIGH")
        c:SetSize(1, 1)
        c.icons = {}
        nameplate.HotsNDots = c
    end
    return c
end

local function GetIcon(c, i)
    local ic = c.icons[i]
    if not ic then
        ic = CreateIcon(c)
        c.icons[i] = ic
    end
    return ic
end

local function HideIcon(ic)
    -- always wipe the timer state too, otherwise a recycled icon keeps
    -- showing the previous aura's countdown
    ic.cooldown:Clear()
    ic.timeCD:Clear()
    ic:Hide()
end

--------------------------------------------------------------------
-- Hide / replace the default Blizzard nameplate auras
--  Our icons ALWAYS replace the default ones - there is no point in
--  drawing both. The container is not called the same thing on every
--  build, so find it instead of hard-coding a field name.
--------------------------------------------------------------------
local AURA_CONTAINER_KEYS = {
    "BuffFrame", "buffFrame", "AuraFrame", "AurasFrame",
    "Auras", "BuffContainer", "AuraContainer", "DebuffFrame",
}

local function FindBlizzardAuraFrame(np)
    local uf = np and np.UnitFrame
    if not uf then return nil end

    -- cached per unit frame; `false` means "looked, found nothing"
    if uf.hndAuraFrame ~= nil then
        return uf.hndAuraFrame or nil
    end

    local found, foundKey
    for _, key in ipairs(AURA_CONTAINER_KEYS) do
        local f = rawget(uf, key)
        if type(f) == "table" and type(f.Hide) == "function" and type(f.SetAlpha) == "function" then
            found, foundKey = f, key
            break
        end
    end

    if not found and uf.GetChildren then
        -- fall back to a child frame that names itself after buffs/auras
        for _, child in ipairs({ uf:GetChildren() }) do
            local n = child.GetName and child:GetName()
            if n and (n:find("Buff") or n:find("Aura")) then
                found, foundKey = child, n
                break
            end
        end
    end

    uf.hndAuraFrame = found or false
    uf.hndAuraFrameKey = foundKey
    return found
end

-- /hnd debug: report what we actually found on this client, so a build
-- that renamed the aura container can be identified without guessing.
function ns.Nameplates_Debug()
    local n = 0
    for unit in pairs(plates) do
        n = n + 1
        local np = C_NamePlate.GetNamePlateForUnit(unit)
        local uf = np and np.UnitFrame
        if not uf then
            print(ns.BRAND .. ": " .. unit .. " -> no UnitFrame (custom nameplate addon?)")
        else
            local bf = FindBlizzardAuraFrame(np)
            if bf then
                print(ns.BRAND .. ": " .. unit .. " -> default auras = '" ..
                      tostring(uf.hndAuraFrameKey) .. "', shown = " .. tostring(bf:IsShown()))
            else
                local names = {}
                for _, child in ipairs({ uf:GetChildren() }) do
                    names[#names + 1] = tostring(child.GetName and child:GetName() or "<unnamed>")
                end
                print(ns.BRAND .. ": " .. unit .. " -> aura container NOT found. Children: " ..
                      (table.concat(names, ", "):sub(1, 400)))
            end
        end
    end
    if n == 0 then
        print(ns.BRAND .. ": no nameplates visible - target something first.")
    end
end

local function ApplyBlizzardVisibility(np)
    local bf = FindBlizzardAuraFrame(np)
    if not bf then return end

    -- One-time hook. HookScript("OnShow") alone was not enough: it only
    -- fires on a hidden->shown transition, so a nameplate recycled with an
    -- already-visible aura frame kept its default icons. Hooking Show()
    -- itself catches every attempt, including the redundant ones.
    if not bf.__hndHook then
        bf.__hndHook = true
        hooksecurefunc(bf, "Show", function(self)
            if ns.db and ns.db.nameplates.enabled then
                self:Hide()
                self:SetAlpha(0)
            end
        end)
    end

    if ns.db.nameplates.enabled then
        bf:Hide()
        bf:SetAlpha(0)
    else
        bf:SetAlpha(1)
        bf:Show()
    end
end

function ns.Nameplates_ApplyBlizzardAll()
    for unit in pairs(plates) do
        local np = C_NamePlate.GetNamePlateForUnit(unit)
        if np then ApplyBlizzardVisibility(np) end
    end
end

--------------------------------------------------------------------
-- Rebuild all icons of one nameplate
--------------------------------------------------------------------
local scan = {}
local function RefreshUnit(unit)
    local c = plates[unit]
    if not c then return end

    local cfg = ns.db.nameplates
    if not cfg.enabled then
        for i = 1, #c.icons do HideIcon(c.icons[i]) end
        return
    end

    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if not np then return end

    -- self-healing: Blizzard re-shows its own auras on aura updates, so
    -- re-assert on every refresh rather than only when the plate appears
    ApplyBlizzardVisibility(np)

    local list = ns.ScanUnit(unit, scan)
    table.sort(list, ns.SortByInstanceID)

    local size    = cfg.size
    local spacing = cfg.spacing
    local n       = math.min(#list, cfg.maxIcons)

    c:ClearAllPoints()
    if cfg.below then
        c:SetPoint("TOP", np, "BOTTOM", cfg.xOffset, -cfg.yOffset)
    else
        c:SetPoint("BOTTOM", np, "TOP", cfg.xOffset, cfg.yOffset)
    end
    c:SetSize(math.max(1, n * size + math.max(0, n - 1) * spacing), size)

    for i = 1, n do
        local aura = list[i]
        local ic   = GetIcon(c, i)

        ic:SetSize(size, size)
        ic:ClearAllPoints()
        ic:SetPoint("LEFT", c, "LEFT", (i - 1) * (size + spacing), 0)

        -- icon (secret -> passed straight through to the texture)
        ic.icon:SetTexture(aura.icon)

        -- border color: red = debuff, green = buff/HoT
        if ns.IsHarmful(unit, aura) then
            ic.border:SetColorTexture(0.65, 0.1, 0.1, 1)
        else
            ic.border:SetColorTexture(0.1, 0.55, 0.15, 1)
        end

        -- remaining time: one live Duration object drives both the swipe
        -- and the number, and both get cleared when there is no duration
        local duration = ns.GetDuration(unit, aura)

        ic.timeCD:SetSize(math.max(size, cfg.timerFontSize * 2.2), cfg.timerFontSize * 1.4)
        ns.ApplyCooldown(ic.timeCD, duration)
        -- font goes on AFTER the cooldown starts: the engine picks a font
        -- of its own when a countdown begins and would overwrite ours
        if ic.timer then
            ns.SetFont(ic.timer, cfg.timerFontSize)
            ic.timer:SetTextColor(1, 1, 1)
        end

        ic.cooldown:SetDrawSwipe(cfg.showSwipe and true or false)
        ns.ApplyCooldown(ic.cooldown, cfg.showSwipe and duration or nil)

        -- stacks: only real ones (2+), decided C-side so no secret is read
        if cfg.showStacks then
            ns.SetFont(ic.count, cfg.stackFontSize)
            ns.SetStackText(ic.count, unit, aura)
            ic.count:Show()
        else
            ic.count:SetText("")
            ic.count:Hide()
        end

        ic:Show()
    end

    for i = n + 1, #c.icons do
        HideIcon(c.icons[i])
    end
end

--------------------------------------------------------------------
-- Public interface
--------------------------------------------------------------------
function ns.Nameplates_OnAdded(unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if not np then return end
    local c = GetContainer(np)
    c.unit = unit
    plates[unit] = c
    ApplyBlizzardVisibility(np)
    RefreshUnit(unit)
end

function ns.Nameplates_OnRemoved(unit)
    local c = plates[unit]
    if c then
        for i = 1, #c.icons do HideIcon(c.icons[i]) end
        c.unit = nil
        plates[unit] = nil
    end
end

function ns.Nameplates_OnUnitAura(unit)
    if plates[unit] then
        RefreshUnit(unit)
    end
end

function ns.Nameplates_RefreshAll()
    for unit in pairs(plates) do
        RefreshUnit(unit)
    end
end

function ns.Nameplates_Init()
    for _, np in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = np.namePlateUnitToken or (np.UnitFrame and np.UnitFrame.unit)
        if unit then
            ns.Nameplates_OnAdded(unit)
        end
    end
end
