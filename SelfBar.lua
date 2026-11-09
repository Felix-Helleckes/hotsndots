--=====================================================================
--  HotsNDots - Self bar ("Your own HoTs")
--  Your own HoTs and buffs ON YOURSELF, as a movable row of icons in the
--  style of Blizzard's cooldown manager: icon, cooldown swipe, the
--  seconds in the middle, real stacks in the corner.
--
--  Same technique as the nameplate icons: an AuraContainer watching the
--  unit "player", whose buttons belong to the game. We build the regions
--  once in initializeFrame and the game fills them in - so this works in
--  combat, where aura data is secret, exactly like the rest of the addon.
--=====================================================================

local ADDON_NAME, ns = ...

local anchor, container
local styleList = {}   -- every icon we built, so it can be restyled later

local GROUP = { key = "self", kind = "HELPFUL", r = 0.15, g = 0.60, b = 0.25 }

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

    styleList[#styleList + 1] = style
end

--------------------------------------------------------------------
-- Layout
--  The container's size is secret once it holds auras, so it is anchored
--  by the corner the row grows away from - never centred.
--------------------------------------------------------------------
local function ApplyLayout()
    if not container then return end
    local cfg = ns.db.selfbar

    anchor:SetSize(cfg.size, cfg.size)

    container:ClearAllPoints()
    if cfg.growLeft then
        container:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
        container:SetFlowLayoutAnchorPoint("TOPRIGHT")
        container:SetFlowLayoutGrowthDirection(ns.FlowDir.Left, ns.FlowDir.Down)
    else
        container:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
        container:SetFlowLayoutAnchorPoint("TOPLEFT")
        container:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Down)
    end

    container:SetAuraGroupLayout(GROUP.key, {
        elementSpacing = cfg.spacing,
        elementWidth   = cfg.size,
        elementHeight  = cfg.size,
    })
    container:SetAuraGroupMaxFrameCount(GROUP.key, cfg.maxIcons)
    container:SetAuraGroupFilterString(GROUP.key, ns.FilterString(GROUP.kind))
    container:SetAuraGroupCandidateFilters(GROUP.key, ns.CandidateFilters(GROUP.kind))

    container:SetEnabled(cfg.enabled and true or false)
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
    anchor:EnableMouse(showHandle and true or false)
    if showHandle then
        anchor.bg:Show()
        anchor.label:Show()
    else
        anchor.bg:Hide()
        anchor.label:Hide()
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

-- Size, font, swipe and stacks reach the buttons themselves, which the
-- game only lets us touch while auras are not secret.
function ns.SelfBar_Restyle()
    if not container then return end
    local cfg = ns.db.selfbar

    ns.TryRestyle(function()
        for _, style in ipairs(styleList) do
            ApplyIconStyle(style)
            if cfg.showStacks then
                style.button:SetApplicationCount(style.count)
            else
                style.button:ClearApplicationCount()
                style.count:SetText("")
            end
        end
    end)

    ApplyLayout()
    ns.SelfBar_UpdateLock()
end

function ns.SelfBar_Debug()
    local cfg = ns.db.selfbar
    print(ns.BRAND .. ": self bar " .. (cfg.enabled and "ON" or "OFF")
        .. ", " .. #styleList .. " icons built"
        .. ", container " .. (container and "yes" or "MISSING")
        .. ", " .. (cfg.locked and "locked" or "unlocked")
        .. ", max " .. tostring(cfg.maxIcons))
end

function ns.SelfBar_Init()
    local cfg = ns.db.selfbar

    anchor = CreateFrame("Frame", "HotsNDotsSelfAnchor", UIParent)
    ns.selfAnchor = anchor
    anchor:SetSize(cfg.size, cfg.size)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:RegisterForDrag("LeftButton")
    ns.SelfBar_ApplyPosition()

    anchor:SetScript("OnDragStart", function(self)
        if not ns.db.selfbar.locked then self:StartMoving() end
    end)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.selfbar.point = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.bg:SetAllPoints()
    anchor.bg:SetColorTexture(0.1, 0.6, 0.4, 0.35)

    -- The handle is one icon wide, so the label sits next to it rather
    -- than being squeezed into it.
    anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    anchor.label:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    anchor.label:SetText(ns.L.selfAnchorLabel)

    container = CreateFrame("AuraContainer", nil, anchor, "CustomAuraContainerTemplate")
    ns.selfContainer = container
    container:SetFlowLayoutAxis(ns.FlowAxis.Horizontal)
    container:SetFlowLayoutMaximumLineSize(math.huge) -- one row; maxIcons caps it

    container:AddAuraGroup(GROUP.key, ns.FilterString(GROUP.kind), {
        maxFrameCount    = cfg.maxIcons,
        candidateFilters = ns.CandidateFilters(GROUP.kind),
        sortMethod       = ns.SortMethod.ExpirationOnly,
        sortDirection    = ns.SortDirection.Normal,
        initializeFrame  = BuildIcon,
        layout = {
            elementSpacing = cfg.spacing,
            elementWidth   = cfg.size,
            elementHeight  = cfg.size,
        },
    })

    container:SetUnit("player")
    ApplyLayout()
    ns.SelfBar_UpdateLock()
end
