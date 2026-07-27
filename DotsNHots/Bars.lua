--=====================================================================
--  DotsNHots - Bars  (Midnight 12.0 "Secret Values" compliant)
--  Freely movable bars for your own auras on the current target.
--  Fill: StatusBar:SetTimerDuration, number: Cooldown built-in countdown.
--=====================================================================

local ADDON_NAME, ns = ...

ns.bars = ns.bars or {}
local barAnchor

--------------------------------------------------------------------
-- Create a single bar
--------------------------------------------------------------------
local function CreateBar(i)
    local cfg = ns.db.bars
    local bar = CreateFrame("StatusBar", nil, barAnchor)
    bar:SetSize(cfg.width, cfg.height)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.6)

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetPoint("RIGHT", bar, "LEFT", -2, 0)
    bar.icon:SetSize(cfg.height, cfg.height)
    bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    bar.iconBorder = bar:CreateTexture(nil, "BACKGROUND")
    bar.iconBorder:SetPoint("TOPLEFT", bar.icon, "TOPLEFT", -1.5, 1.5)
    bar.iconBorder:SetPoint("BOTTOMRIGHT", bar.icon, "BOTTOMRIGHT", 1.5, -1.5)
    bar.iconBorder:SetColorTexture(0, 0, 0, 1)

    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetPoint("LEFT", 5, 0)
    bar.name:SetPoint("RIGHT", bar, "RIGHT", -40, 0)
    bar.name:SetJustifyH("LEFT")
    bar.name:SetWordWrap(false)
    bar.name:SetFont(STANDARD_TEXT_FONT, cfg.fontSize, "OUTLINE")

    -- countdown NUMBER at the right end via a Cooldown frame. This renders
    -- Blizzard's built-in localized number (e.g. "10"), because secret aura
    -- times can't be formatted into text ourselves. No swipe here.
    bar.timeCD = CreateFrame("Cooldown", nil, bar, "CooldownFrameTemplate")
    bar.timeCD:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    bar.timeCD:SetSize(cfg.height, cfg.height)
    bar.timeCD:SetDrawSwipe(false)
    bar.timeCD:SetDrawEdge(false)
    bar.timeCD:SetHideCountdownNumbers(false)

    bar.durset = ns.CreateDurationSet()

    return bar
end

local function GetBar(i)
    local bar = ns.bars[i]
    if not bar then
        bar = CreateBar(i)
        ns.bars[i] = bar
    end
    return bar
end

--------------------------------------------------------------------
-- Lock / unlock
--------------------------------------------------------------------
function ns.Bars_UpdateLock()
    if not barAnchor then return end
    local locked = ns.db.bars.locked
    barAnchor:EnableMouse(not locked)
    if locked then
        barAnchor.bg:Hide()
        barAnchor.label:Hide()
    else
        barAnchor.bg:Show()
        barAnchor.label:Show()
    end
end

--------------------------------------------------------------------
-- Rebuild the bars
--------------------------------------------------------------------
local barScan = {}
function ns.Bars_Update()
    if not barAnchor then return end
    local cfg = ns.db.bars

    if not cfg.enabled then
        for i = 1, #ns.bars do ns.bars[i]:Hide() end
        return
    end

    barAnchor:SetWidth(cfg.width)
    barAnchor:SetHeight(cfg.height)

    local list = ns.ScanUnit(cfg.unit, barScan)
    table.sort(list, ns.SortByInstanceID)

    local n = math.min(#list, cfg.maxBars)
    for i = 1, n do
        local aura = list[i]
        local bar  = GetBar(i)

        bar:SetSize(cfg.width, cfg.height)
        bar.icon:SetSize(cfg.height, cfg.height)
        bar.timeCD:SetSize(cfg.height, cfg.height)
        bar.name:SetFont(STANDARD_TEXT_FONT, cfg.fontSize, "OUTLINE")

        -- icon + name (secrets -> pass straight through)
        pcall(bar.icon.SetTexture, bar.icon, aura.icon)
        pcall(bar.name.SetText, bar.name, aura.name)

        -- color: red = debuff, green = buff/HoT (isHarmful is readable)
        if aura.isHarmful then
            bar:SetStatusBarColor(0.7, 0.15, 0.15)
        else
            bar:SetStatusBarColor(0.15, 0.6, 0.25)
        end

        bar:Show() -- show BEFORE applying the timers so the first paint sticks

        -- remaining time via Duration object: bar fill + built-in number
        ns.UpdateDurationSet(bar.durset, aura)
        if bar.durset.duration and bar.SetTimerDuration then
            -- (duration, interpolation = 0 immediate, direction = 1 = remaining time)
            pcall(bar.SetTimerDuration, bar, bar.durset.duration, 0, 1)
        end
        if bar.durset.duration and bar.timeCD.SetCooldownFromDurationObject then
            pcall(bar.timeCD.SetCooldownFromDurationObject, bar.timeCD, bar.durset.duration)
        end

        bar:ClearAllPoints()
        local yoff = (i - 1) * (cfg.height + cfg.spacing)
        if cfg.growthUp then
            bar:SetPoint("BOTTOMLEFT", barAnchor, "BOTTOMLEFT", 0, yoff)
        else
            bar:SetPoint("TOPLEFT", barAnchor, "TOPLEFT", 0, -yoff)
        end

        bar:Show()
    end

    for i = n + 1, #ns.bars do
        ns.bars[i]:Hide()
    end
end

--------------------------------------------------------------------
-- Init
--------------------------------------------------------------------
function ns.Bars_Init()
    local cfg = ns.db.bars

    barAnchor = CreateFrame("Frame", "DotsNHotsBarAnchor", UIParent)
    ns.barAnchor = barAnchor
    barAnchor:SetSize(cfg.width, cfg.height)
    barAnchor:SetPoint(cfg.point.point, UIParent, cfg.point.relPoint, cfg.point.x, cfg.point.y)
    barAnchor:SetMovable(true)
    barAnchor:SetClampedToScreen(true)
    barAnchor:RegisterForDrag("LeftButton")

    barAnchor:SetScript("OnDragStart", function(self)
        if not ns.db.bars.locked then self:StartMoving() end
    end)
    barAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.bars.point = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    barAnchor.bg = barAnchor:CreateTexture(nil, "BACKGROUND")
    barAnchor.bg:SetAllPoints()
    barAnchor.bg:SetColorTexture(0.1, 0.6, 0.4, 0.35)

    barAnchor.label = barAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    barAnchor.label:SetPoint("CENTER")
    barAnchor.label:SetText("DotsNHots  \226\128\148  drag to move")

    ns.Bars_UpdateLock()
    ns.Bars_Update()
end
