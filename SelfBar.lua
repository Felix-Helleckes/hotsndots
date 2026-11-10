--=====================================================================
--  HotsNDots - Self bar ("Your own HoTs")
--  Your own HoTs and buffs ON YOURSELF, in one of two looks:
--    icons - a row in the style of Blizzard's cooldown manager: icon,
--            cooldown swipe, the seconds in the middle, stacks in the
--            corner
--    bars  - a column of bars that look exactly like the HoT bars on
--            the "Bars" page (same width, height, texture, font, colour)
--
--  Same technique as the nameplate icons: an AuraContainer watching the
--  unit "player", whose buttons belong to the game. We build the regions
--  once in initializeFrame and the game fills them in - so this works in
--  combat, where aura data is secret, exactly like the rest of the addon.
--
--  The two looks are two containers, and only one is ever enabled. A
--  button can never be rebuilt once the game owns it, so switching the
--  look is a container-level change - which is allowed even in combat.
--=====================================================================

local ADDON_NAME, ns = ...

local anchor
local iconContainer, barContainer
local iconStyles = {}  -- every icon we built, so it can be restyled later
local barStyles  = {}  -- every bar row we built

local ICON_GROUP = { key = "self",     kind = "HELPFUL" }
local BAR_GROUP  = { key = "selfbars", kind = "HELPFUL" }
-- What a self bar row colours itself by: the HoT colour of the bars page.
local BAR_COLOR_GROUP = { key = "hots", kind = "HELPFUL", r = 0.15, g = 0.60, b = 0.25 }

local function AsBars()
    return ns.db.selfbar.display == "bars"
end

--------------------------------------------------------------------
-- One icon
--  Called by the container right after it creates a button, and only
--  then: from here on the button belongs to the game.
--------------------------------------------------------------------
local function ApplyIconStyle(style)
    local cfg = ns.db.selfbar
    style.button:SetSize(cfg.size, cfg.size)
    style.cooldown:SetDrawSwipe(cfg.showSwipe and true or false)
    ns.SetFont(style.timer, cfg.timerFontSize)
    ns.SetFont(style.count, cfg.stackFontSize)
end

local function BuildIcon(button)
    local cfg = ns.db.selfbar
    local style = { button = button }

    button:EnableMouse(false)

    style.border = button:CreateTexture(nil, "BACKGROUND")
    style.border:SetPoint("TOPLEFT", -1.5, 1.5)
    style.border:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
    style.border:SetColorTexture(0, 0, 0, 1)

    style.icon = button:CreateTexture(nil, "ARTWORK")
    style.icon:SetAllPoints()
    style.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- The swipe always exists, so switching it on later never needs a new
    -- region on a button we no longer own.
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true) -- we draw our own, bigger
    cooldown:SetReverse(true)
    cooldown:EnableMouse(false)
    cooldown.noCooldownCount = true        -- keep OmniCC off our icons
    style.cooldown = cooldown

    -- text above the swipe, or it would be drawn under it
    local textLayer = CreateFrame("Frame", nil, button)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    style.textLayer = textLayer

    -- seconds in the middle of the icon, like the cooldown manager
    style.timer = textLayer:CreateFontString(nil, "OVERLAY")
    style.timer:SetPoint("CENTER", button, "CENTER", 0, 0)
    style.timer:SetJustifyH("CENTER")
    style.timer:SetTextColor(1, 1, 1)

    style.count = textLayer:CreateFontString(nil, "OVERLAY")
    style.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    style.count:SetTextColor(1, 1, 1)

    -- Style FIRST, then hand the regions over (see Bars.lua).
    ApplyIconStyle(style)

    button:SetIcon(style.icon)
    button:SetDurationCooldown(cooldown)
    button:SetDurationText(style.timer)
    -- Without a formatter the game only writes a number at 2+ stacks.
    if cfg.showStacks then
        button:SetApplicationCount(style.count)
    end

    iconStyles[#iconStyles + 1] = style
end

--------------------------------------------------------------------
-- One bar
--  Built from the very same code as the rows on the "Bars" page, so the
--  two can never look different.
--------------------------------------------------------------------
local function BuildBar(button)
    local cfg = ns.db.selfbar
    local style = ns.Bars_CreateRow(button, BAR_COLOR_GROUP)

    button:EnableMouse(false)

    ns.Bars_ApplyRowStyle(style)

    button:SetIcon(style.icon)
    button:SetDurationBar(style.bar, {
        direction     = ns.BAR_DIR_REMAINING,
        interpolation = ns.BAR_INTERP,
    })
    button:SetDurationText(style.time)
    button:SetSpellName(style.name)
    if cfg.showStacks then
        button:SetApplicationCount(style.count)
    end

    barStyles[#barStyles + 1] = style
end

--------------------------------------------------------------------
-- Layout
--  A container's size is secret once it holds auras, so it is anchored
--  by the corner it grows away from - never centred.
--------------------------------------------------------------------
local function GroupLayout(w, h)
    return { elementSpacing = ns.db.selfbar.spacing, elementWidth = w, elementHeight = h }
end

local function ApplyFilters(container, key)
    local cfg = ns.db.selfbar
    container:SetAuraGroupMaxFrameCount(key, cfg.maxIcons)
    container:SetAuraGroupFilterString(key, ns.FilterString("HELPFUL"))
    container:SetAuraGroupCandidateFilters(key, ns.CandidateFilters("HELPFUL"))
end

local function ApplyLayout()
    if not iconContainer then return end
    local cfg  = ns.db.selfbar
    local bars = AsBars()

    if bars and barContainer then
        anchor:SetSize(ns.db.bars.width, ns.db.bars.height)
    else
        anchor:SetSize(cfg.size, cfg.size)
    end

    -- icons: one row, left or right
    iconContainer:ClearAllPoints()
    if cfg.growLeft then
        iconContainer:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
        iconContainer:SetFlowLayoutAnchorPoint("TOPRIGHT")
        iconContainer:SetFlowLayoutGrowthDirection(ns.FlowDir.Left, ns.FlowDir.Down)
    else
        iconContainer:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
        iconContainer:SetFlowLayoutAnchorPoint("TOPLEFT")
        iconContainer:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Down)
    end
    iconContainer:SetAuraGroupLayout(ICON_GROUP.key, GroupLayout(cfg.size, cfg.size))
    ApplyFilters(iconContainer, ICON_GROUP.key)
    iconContainer:SetEnabled((cfg.enabled and not bars) and true or false)

    -- bars: one column, downwards
    if barContainer then
        barContainer:ClearAllPoints()
        barContainer:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
        barContainer:SetFlowLayoutAnchorPoint("TOPLEFT")
        barContainer:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Down)
        barContainer:SetAuraGroupLayout(BAR_GROUP.key, GroupLayout(ns.db.bars.width, ns.db.bars.height))
        ApplyFilters(barContainer, BAR_GROUP.key)
        barContainer:SetEnabled((cfg.enabled and bars) and true or false)
    end
end

--------------------------------------------------------------------
-- Position / lock (both part of the profile, like the bars)
--------------------------------------------------------------------
function ns.SelfBar_ApplyPosition()
    if not anchor then return end
    local pt = ns.db.selfbar.point or ns.defaults.selfbar.point
    anchor:ClearAllPoints()
    anchor:SetPoint(pt.point, UIParent, pt.relPoint, pt.x, pt.y)
end

function ns.SelfBar_UpdateLock()
    if not anchor then return end
    local cfg = ns.db.selfbar
    -- An unlocked but disabled row would leave a green box nobody can
    -- explain, so the handle only shows while the row is in use.
    local showHandle = not cfg.locked and cfg.enabled
    local handle = anchor.handle
    if showHandle then
        -- Grab area: the first icon / bar plus the label above it, so
        -- there is something comfortable to hold even while a HoT shows.
        local w = tonumber(anchor:GetWidth()) or cfg.size
        local h = tonumber(anchor:GetHeight()) or cfg.size
        local labelW = tonumber(anchor.label:GetStringWidth()) or 0
        handle:SetSize(math.max(w, labelW + 4), h + 16)
        handle:Show()
    else
        handle:Hide()
    end
end

--------------------------------------------------------------------
-- Public interface
--------------------------------------------------------------------
-- Container-level changes: always allowed, no aura button is touched.
function ns.SelfBar_Update()
    ApplyLayout()
    ns.SelfBar_UpdateLock()
end

local function RestyleStacks(style, show)
    if show then
        style.button:SetApplicationCount(style.count)
    else
        style.button:ClearApplicationCount()
        style.count:SetText("")
    end
end

-- The bar rows follow the "Bars" page, so Bars_Restyle calls this too.
function ns.SelfBar_RestyleBars()
    if not barContainer then return end
    local cfg = ns.db.selfbar
    ns.TryRestyle(function()
        for _, style in ipairs(barStyles) do
            ns.Bars_ApplyRowStyle(style)
            RestyleStacks(style, cfg.showStacks)
        end
    end)
    ApplyLayout()
    ns.SelfBar_UpdateLock()
end

-- Size, font, swipe and stacks reach the buttons themselves, which the
-- game only lets us touch while auras are not secret.
function ns.SelfBar_Restyle()
    if not iconContainer then return end
    local cfg = ns.db.selfbar

    ns.TryRestyle(function()
        for _, style in ipairs(iconStyles) do
            ApplyIconStyle(style)
            RestyleStacks(style, cfg.showStacks)
        end
    end)

    ns.SelfBar_RestyleBars()
    ApplyLayout()
    ns.SelfBar_UpdateLock()
end

function ns.SelfBar_Debug()
    local cfg = ns.db.selfbar
    print(ns.BRAND .. ": self bar " .. (cfg.enabled and "ON" or "OFF")
        .. " as " .. (AsBars() and "bars" or "icons")
        .. ", " .. #iconStyles .. " icons / " .. #barStyles .. " bars built"
        .. ", containers " .. (iconContainer and "icons" or "-")
        .. "+" .. (barContainer and "bars" or "-")
        .. ", " .. (cfg.locked and "locked" or "unlocked")
        .. ", max " .. tostring(cfg.maxIcons))
end

--------------------------------------------------------------------
-- Init
--------------------------------------------------------------------
local function NewContainer(axis, key, initializeFrame, w, h)
    local cfg = ns.db.selfbar
    local c = CreateFrame("AuraContainer", nil, anchor, "CustomAuraContainerTemplate")
    c:SetFlowLayoutAxis(axis)
    c:SetFlowLayoutMaximumLineSize(math.huge) -- one line; maxIcons caps it
    c:AddAuraGroup(key, ns.FilterString("HELPFUL"), {
        maxFrameCount    = cfg.maxIcons,
        candidateFilters = ns.CandidateFilters("HELPFUL"),
        sortMethod       = ns.SortMethod.ExpirationOnly,
        sortDirection    = ns.SortDirection.Normal,
        initializeFrame  = initializeFrame,
        layout           = GroupLayout(w, h),
    })
    return c
end

function ns.SelfBar_Init()
    local cfg = ns.db.selfbar

    anchor = CreateFrame("Frame", "HotsNDotsSelfAnchor", UIParent)
    ns.selfAnchor = anchor
    anchor:SetSize(cfg.size, cfg.size)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    ns.SelfBar_ApplyPosition()

    -- The icons sit exactly where the anchor is, and the containers are
    -- its children - so the first icon covered the anchor and swallowed
    -- every drag. The handle is therefore its own frame on a higher
    -- strata, above the icons, and only shown while the row is unlocked.
    local handle = CreateFrame("Frame", nil, anchor)
    anchor.handle = handle
    handle:SetFrameStrata("HIGH")
    handle:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 0)
    handle:SetSize(cfg.size, cfg.size + 16)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:Hide()

    handle:SetScript("OnDragStart", function()
        if not ns.db.selfbar.locked then anchor:StartMoving() end
    end)
    handle:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        local point, _, relPoint, x, y = anchor:GetPoint()
        ns.db.selfbar.point = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    handle.bg = handle:CreateTexture(nil, "BACKGROUND")
    handle.bg:SetAllPoints()
    handle.bg:SetColorTexture(0.1, 0.6, 0.4, 0.35)

    anchor.label = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    anchor.label:SetPoint("TOPLEFT", handle, "TOPLEFT", 2, -2)
    anchor.label:SetText(ns.L.selfAnchorLabel)

    iconContainer = NewContainer(ns.FlowAxis.Horizontal, ICON_GROUP.key, BuildIcon,
        cfg.size, cfg.size)
    ns.selfContainer = iconContainer
    iconContainer:SetUnit("player")

    -- The bar look borrows its rows from Bars.lua. Should that file be
    -- missing (see Core.lua), the icons keep working on their own.
    if ns.Bars_CreateRow and ns.Bars_ApplyRowStyle then
        barContainer = NewContainer(ns.FlowAxis.Vertical, BAR_GROUP.key, BuildBar,
            ns.db.bars.width, ns.db.bars.height)
        ns.selfBarContainer = barContainer
        barContainer:SetUnit("player")
    end

    ApplyLayout()
    ns.SelfBar_UpdateLock()
end
