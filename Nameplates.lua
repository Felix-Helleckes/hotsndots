--=====================================================================
--  DotsNHots - Nameplates  (Midnight 12.0 "Secret Values" compliant)
--  Shows your own auras large above the nameplate:
--  icon + cooldown swipe + Blizzard's built-in seconds number + stacks.
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

    -- The cooldown frame shows Blizzard's own built-in countdown NUMBER on the
    -- icon (localized short form like "10"), exactly like the default nameplate
    -- auras - plus the optional swipe.
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints()
    b.cooldown:SetDrawEdge(false)
    b.cooldown:SetHideCountdownNumbers(false) -- show Blizzard's built-in seconds
    b.cooldown:SetReverse(true)

    -- stack count in the bottom-right corner
    b.count = b:CreateFontString(nil, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", 2, -2)
    b.count:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    b.count:SetTextColor(1, 1, 1)

    -- reusable Duration object (drives the swipe + built-in numbers)
    b.durset = ns.CreateDurationSet()

    return b
end

local function GetContainer(nameplate)
    local c = nameplate.DotsNHots
    if not c then
        c = CreateFrame("Frame", nil, nameplate)
        c:SetFrameStrata("HIGH")
        c:SetSize(1, 1)
        c.icons = {}
        nameplate.DotsNHots = c
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

--------------------------------------------------------------------
-- Hide / replace the default Blizzard nameplate auras
--------------------------------------------------------------------
local function ApplyBlizzardVisibility(np)
    local uf = np and np.UnitFrame
    local bf = uf and uf.BuffFrame
    if not bf then return end

    local shouldHide = ns.db.nameplates.hideBlizzard and ns.db.nameplates.enabled

    -- one-time hook so it stays hidden when Blizzard tries to show it again
    if not bf.__dnhHook then
        bf.__dnhHook = true
        bf:HookScript("OnShow", function(self)
            if ns.db.nameplates.hideBlizzard and ns.db.nameplates.enabled then
                self:Hide()
            end
        end)
    end

    if shouldHide then
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
        for i = 1, #c.icons do c.icons[i]:Hide() end
        return
    end

    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if not np then return end

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
        ic:Show()

        -- icon (secret -> pass straight through to the texture)
        pcall(ic.icon.SetTexture, ic.icon, aura.icon)

        -- border color: red = debuff, green = buff/HoT (isHarmful is readable)
        if aura.isHarmful then
            ic.border:SetColorTexture(0.65, 0.1, 0.1, 1)
        else
            ic.border:SetColorTexture(0.1, 0.55, 0.15, 1)
        end

        -- live stack font size
        ic.count:SetFont(STANDARD_TEXT_FONT, cfg.stackFontSize, "OUTLINE")

        -- remaining time via Duration object (only pass secrets through)
        ns.UpdateDurationSet(ic.durset, aura)

        -- drive the cooldown: shows Blizzard's built-in countdown NUMBER on the
        -- icon (localized short form). The swipe is toggled separately.
        if ic.durset.duration and ic.cooldown.SetCooldownFromDurationObject then
            pcall(ic.cooldown.SetDrawSwipe, ic.cooldown, cfg.showSwipe and true or false)
            pcall(ic.cooldown.SetCooldownFromDurationObject, ic.cooldown, ic.durset.duration)
        else
            ic.cooldown:Clear()
        end

        -- stacks (secret -> pass straight through to the FontString)
        if cfg.showStacks then
            pcall(ic.count.SetText, ic.count, aura.applications)
            ic.count:Show()
        else
            ic.count:Hide()
        end

        ic:Show()
    end

    for i = n + 1, #c.icons do
        c.icons[i]:Hide()
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
        for i = 1, #c.icons do c.icons[i]:Hide() end
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
