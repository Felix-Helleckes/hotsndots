--=====================================================================
--  HotsNDots - Bars
--  Freely movable bars for your own auras on the current target.
--
--  Like the nameplate icons, each bar is an AuraButton owned by the
--  game: we build the row (icon, status bar, name, seconds, stacks) and
--  register the pieces, and the game fills them in. The depleting fill
--  comes from CustomAuraButton:SetDurationBar, the seconds from
--  SetDurationText - neither needs us to know a remaining time.
--=====================================================================

local ADDON_NAME, ns = ...

local barAnchor, container
local styleList = {}   -- every row we built, so it can be restyled later

-- width reserved at the right edge of a bar for the countdown number
local TIME_COLUMN = 38

local GROUPS = {
    { key = "dots", kind = "HARMFUL", r = 0.70, g = 0.15, b = 0.15 },
    { key = "hots", kind = "HELPFUL", r = 0.15, g = 0.60, b = 0.25 },
}

--------------------------------------------------------------------
-- One bar
--  Called by the container right after it creates a button, and only
--  then: from here on the button belongs to the game.
--------------------------------------------------------------------
local function BuildBar(group, button)
    local cfg = ns.db.bars
    local style = { button = button, group = group }

    button:SetSize(cfg.width, cfg.height)
    button:EnableMouse(false)

    -- icon on the left, inside the row
    style.iconBorder = button:CreateTexture(nil, "BACKGROUND")
    style.iconBorder:SetColorTexture(0, 0, 0, 1)

    style.icon = button:CreateTexture(nil, "ARTWORK")
    style.icon:SetPoint("TOPLEFT", 0, 0)
    style.icon:SetSize(cfg.height, cfg.height)
    style.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    style.iconBorder:SetPoint("TOPLEFT", style.icon, "TOPLEFT", -1.5, 1.5)
    style.iconBorder:SetPoint("BOTTOMRIGHT", style.icon, "BOTTOMRIGHT", 1.5, -1.5)
    button:SetIcon(style.icon)

    -- the bar itself fills whatever is left of the row
    local bar = CreateFrame("StatusBar", nil, button)
    bar:SetPoint("TOPLEFT", style.icon, "TOPRIGHT", 2, 0)
    bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(group.r, group.g, group.b)
    style.bar = bar

    style.barBG = bar:CreateTexture(nil, "BACKGROUND")
    style.barBG:SetAllPoints()
    style.barBG:SetColorTexture(0, 0, 0, 0.6)

    button:SetDurationBar(bar, {
        direction     = ns.BAR_DIR_REMAINING,
        interpolation = ns.BAR_INTERP,
    })

    -- text above the bar texture
    local textLayer = CreateFrame("Frame", nil, button)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(bar:GetFrameLevel() + 1)
    style.textLayer = textLayer

    style.time = textLayer:CreateFontString(nil, "OVERLAY")
    style.time:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    style.time:SetJustifyH("RIGHT")
    ns.SetFont(style.time, cfg.fontSize)
    style.time:SetTextColor(1, 1, 1)
    button:SetDurationText(style.time)

    style.name = textLayer:CreateFontString(nil, "OVERLAY")
    style.name:SetPoint("LEFT", bar, "LEFT", 4, 0)
    style.name:SetPoint("RIGHT", bar, "RIGHT", -(TIME_COLUMN + 4), 0)
    style.name:SetJustifyH("LEFT")
    style.name:SetWordWrap(false)
    ns.SetFont(style.name, cfg.fontSize)
    style.name:SetTextColor(1, 1, 1)
    button:SetSpellName(style.name)

    -- stacks on the icon. Without a formatter the game only writes a
    -- number at 2 or more applications - real stacks only.
    style.count = textLayer:CreateFontString(nil, "OVERLAY")
    style.count:SetPoint("BOTTOMRIGHT", style.icon, "BOTTOMRIGHT", 1, -1)
    ns.SetFont(style.count, cfg.fontSize)
    style.count:SetTextColor(1, 1, 1)
    if cfg.showStacks then
        button:SetApplicationCount(style.count)
    end

    styleList[#styleList + 1] = style
end

--------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------
local function ApplyLayout()
    if not container then return end
    local cfg = ns.db.bars

    barAnchor:SetSize(cfg.width, cfg.height)

    -- The container's size is secret once it holds auras, so it is
    -- anchored by the corner the bars grow away from.
    container:ClearAllPoints()
    if cfg.growthUp then
        container:SetPoint("BOTTOMLEFT", barAnchor, "BOTTOMLEFT", 0, 0)
        container:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
        container:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Up)
    else
        container:SetPoint("TOPLEFT", barAnchor, "TOPLEFT", 0, 0)
        container:SetFlowLayoutAnchorPoint("TOPLEFT")
        container:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Down)
    end

    for _, group in ipairs(GROUPS) do
        container:SetAuraGroupLayout(group.key, {
            elementSpacing = cfg.spacing,
            elementWidth   = cfg.width,
            elementHeight  = cfg.height,
        })
        container:SetAuraGroupMaxFrameCount(group.key, ns.GroupMaxFrames(group.kind, cfg.maxBars))
        container:SetAuraGroupFilterString(group.key, ns.FilterString(group.kind))
        container:SetAuraGroupCandidateFilters(group.key, ns.CandidateFilters(group.kind))
    end

    container:SetEnabled(cfg.enabled and true or false)
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
-- Public interface
--------------------------------------------------------------------
-- Filters, growth and the bar cap changed: all container-level, always
-- allowed, no aura button is touched.
function ns.Bars_Update()
    ApplyLayout()
end

-- A new target does not necessarily fire UNIT_AURA, so nudge the
-- container to re-read the unit it is already watching.
function ns.Bars_OnUnitChanged()
    if container then container:UpdateAllAuras() end
end

-- Size and font changes have to reach the buttons themselves, which the
-- game only lets us touch while auras are not secret.
function ns.Bars_Restyle()
    local cfg = ns.db.bars

    ns.TryRestyle(function()
        for _, style in ipairs(styleList) do
            style.button:SetSize(cfg.width, cfg.height)
            style.icon:SetSize(cfg.height, cfg.height)
            ns.SetFont(style.name, cfg.fontSize)
            ns.SetFont(style.time, cfg.fontSize)
            ns.SetFont(style.count, cfg.fontSize)
            if cfg.showStacks then
                style.button:SetApplicationCount(style.count)
            else
                style.button:ClearApplicationCount()
                style.count:SetText("")
            end
        end
    end)

    ApplyLayout()
end

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

    container = CreateFrame("AuraContainer", nil, barAnchor, "CustomAuraContainerTemplate")
    ns.barContainer = container
    container:SetFlowLayoutAxis(ns.FlowAxis.Vertical)
    container:SetFlowLayoutMaximumLineSize(math.huge) -- one column; maxBars caps it

    for _, group in ipairs(GROUPS) do
        container:AddAuraGroup(group.key, ns.FilterString(group.kind), {
            maxFrameCount    = ns.GroupMaxFrames(group.kind, cfg.maxBars),
            candidateFilters = ns.CandidateFilters(group.kind),
            sortMethod       = ns.SortMethod.ExpirationOnly,
            sortDirection    = ns.SortDirection.Normal,
            initializeFrame  = function(button) BuildBar(group, button) end,
            layout = {
                elementSpacing = cfg.spacing,
                elementWidth   = cfg.width,
                elementHeight  = cfg.height,
            },
        })
    end

    container:SetUnit(cfg.unit)
    ApplyLayout()
    ns.Bars_UpdateLock()
end
