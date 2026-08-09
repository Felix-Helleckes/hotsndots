--=====================================================================
--  HotsNDots - Bars  (Midnight 12.0 "Secret Values" compliant)
--  Freely movable bars for your own auras on the current target.
--  Fill: StatusBar:SetTimerDuration, number: Cooldown countdown text.
--=====================================================================

local ADDON_NAME, ns = ...

ns.bars = ns.bars or {}
local barAnchor

-- width reserved at the right edge of a bar for the countdown number
local TIME_COLUMN = 38

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

    -- stack count on the icon, only ever filled for real stacks (2+)
    bar.count = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.count:SetPoint("BOTTOMRIGHT", bar.icon, "BOTTOMRIGHT", 1, -1)
    ns.SetFont(bar.count, cfg.fontSize)
    bar.count:SetTextColor(1, 1, 1)

    -- Countdown NUMBER at the right edge, drawn by a swipe-less Cooldown
    -- frame. Blizzard's built-in countdown is the only text that can show
    -- a secret remaining time, so this frame is the bar's "time column".
    bar.timeCD = ns.CreateTimerText(bar)
    bar.timeCD:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    bar.timeCD:SetSize(TIME_COLUMN, cfg.height)
    bar.time = ns.GetCountdownFontString(bar.timeCD)
    if bar.time then
        bar.time:ClearAllPoints()
        bar.time:SetPoint("RIGHT", bar.timeCD, "RIGHT", 0, 0)
        bar.time:SetJustifyH("RIGHT")
    end

    -- Name fills the space left of the time column. Anchored to the bar
    -- (not to the cooldown frame) so its width never depends on another
    -- frame's layout pass.
    bar.name = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.name:SetPoint("LEFT", bar, "LEFT", 5, 0)
    bar.name:SetPoint("RIGHT", bar, "RIGHT", -(TIME_COLUMN + 4), 0)
    bar.name:SetJustifyH("LEFT")
    bar.name:SetWordWrap(false)
    ns.SetFont(bar.name, cfg.fontSize)

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

local function HideBar(bar)
    bar.timeCD:Clear()
    bar:Hide()
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
    local cfg  = ns.db.bars
    local unit = cfg.unit

    if not cfg.enabled then
        for i = 1, #ns.bars do HideBar(ns.bars[i]) end
        return
    end

    barAnchor:SetWidth(cfg.width)
    barAnchor:SetHeight(cfg.height)

    local list = ns.ScanUnit(unit, barScan)
    table.sort(list, ns.SortByInstanceID)

    local n = math.min(#list, cfg.maxBars)
    for i = 1, n do
        local aura = list[i]
        local bar  = GetBar(i)

        bar:SetSize(cfg.width, cfg.height)
        bar.icon:SetSize(cfg.height, cfg.height)
        ns.SetFont(bar.name, cfg.fontSize)
        ns.SetFont(bar.count, cfg.fontSize)
        bar.timeCD:SetSize(TIME_COLUMN, cfg.height)

        -- icon + name (secrets -> passed straight through)
        bar.icon:SetTexture(aura.icon)
        bar.name:SetText(aura.name)

        -- color: red = debuff, green = buff/HoT
        if ns.IsHarmful(unit, aura) then
            bar:SetStatusBarColor(0.7, 0.15, 0.15)
        else
            bar:SetStatusBarColor(0.15, 0.6, 0.25)
        end

        -- remaining time: one live Duration object drives the number and
        -- the fill, and both are reset when the aura has no duration
        local duration = ns.GetDuration(unit, aura)
        ns.ApplyCooldown(bar.timeCD, duration)
        ns.ApplyBarFill(bar, duration)
        -- font goes on AFTER the cooldown starts: the engine picks a font
        -- of its own when a countdown begins and would overwrite ours
        if bar.time then
            ns.SetFont(bar.time, cfg.fontSize)
            bar.time:SetTextColor(1, 1, 1)
        end

        -- stacks: only real ones (2+), decided C-side so no secret is read
        if cfg.showStacks then
            ns.SetStackText(bar.count, unit, aura)
            bar.count:Show()
        else
            bar.count:SetText("")
            bar.count:Hide()
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
        HideBar(ns.bars[i])
    end
end

--------------------------------------------------------------------
-- Init
--------------------------------------------------------------------
function ns.Bars_Init()
    local cfg = ns.db.bars

    barAnchor = CreateFrame("Frame", "HotsNDotsBarAnchor", UIParent)
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
    barAnchor.label:SetText("HotsNDots  \226\128\148  drag to move")

    ns.Bars_UpdateLock()
    ns.Bars_Update()
end
