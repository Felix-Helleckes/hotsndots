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
-- Bar styles
--  A preset only ever SHOWS, MOVES or RECOLOURS regions that already
--  exist. It may never add one: from the moment initializeFrame returns
--  the button belongs to the game, and a region created later would be a
--  new child on a frame we no longer own. So all four presets are
--  different arrangements of the same five pieces - which is also why
--  switching between them is a restyle and not a rebuild.
--------------------------------------------------------------------
-- The KEY is what gets stored and must never be translated; the label
-- is only ever shown. Both come from the same table, so the dropdown
-- can match on the label without the two drifting apart.
local PRESETS = {
    { key = "default",   label = ns.L.presetDefault,   icon = true,  iconRight = false, name = true  },
    { key = "compact",   label = ns.L.presetCompact,   icon = true,  iconRight = false, name = false },
    { key = "iconRight", label = ns.L.presetIconRight, icon = true,  iconRight = true,  name = true  },
    { key = "noIcon",    label = ns.L.presetNoIcon,    icon = false, iconRight = false, name = true  },
}
ns.BarPresets = PRESETS

function ns.BarPresetFor(key)
    for _, p in ipairs(PRESETS) do
        if p.key == key then return p end
    end
    return PRESETS[1]
end

-- The colour of a row is per profile now; the numbers on the group stay
-- as the fallback for a save that predates the setting.
function ns.BarColor(group)
    local cfg = ns.db.bars
    local c = (group.key == "hots") and cfg.colorHot or cfg.colorDot
    if type(c) ~= "table" then return group.r, group.g, group.b end
    return c.r or group.r, c.g or group.g, c.b or group.b
end

-- Media.lua can be missing for one session after an update that was
-- installed while the game was running (see the note in Core.lua). A row
-- that throws here would be built by the game's own container code, so
-- it is not a caught error - it is a bar that never appears.
local function TexturePath(name)
    if ns.TexturePath then return ns.TexturePath(name) end
    return [[Interface\TargetingFrame\UI-StatusBar]]
end

local function FontPath(name)
    if ns.FontPath then return ns.FontPath(name) end
    return ns.FONT_PATH
end

--------------------------------------------------------------------
-- The regions of one row
--  Split out of BuildBar so the options screen can build a PREVIEW row
--  from the same code. Two implementations of "what a bar looks like"
--  would drift, and the one that drifts is the preview - which is the
--  one the player believes.
--------------------------------------------------------------------
function ns.Bars_CreateRow(parent, group)
    local style = { button = parent, group = group }

    style.iconBorder = parent:CreateTexture(nil, "BACKGROUND")
    style.iconBorder:SetColorTexture(0, 0, 0, 1)

    style.icon = parent:CreateTexture(nil, "ARTWORK")
    style.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    style.iconBorder:SetPoint("TOPLEFT", style.icon, "TOPLEFT", -1.5, 1.5)
    style.iconBorder:SetPoint("BOTTOMRIGHT", style.icon, "BOTTOMRIGHT", 1.5, -1.5)

    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    style.bar = bar

    style.barBG = bar:CreateTexture(nil, "BACKGROUND")
    style.barBG:SetAllPoints()
    style.barBG:SetColorTexture(0, 0, 0, 0.6)

    -- text above the bar texture
    local textLayer = CreateFrame("Frame", nil, parent)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(bar:GetFrameLevel() + 1)
    style.textLayer = textLayer

    style.time = textLayer:CreateFontString(nil, "OVERLAY")
    style.time:SetTextColor(1, 1, 1)

    style.name = textLayer:CreateFontString(nil, "OVERLAY")
    style.name:SetWordWrap(false)
    style.name:SetTextColor(1, 1, 1)

    style.count = textLayer:CreateFontString(nil, "OVERLAY")
    style.count:SetTextColor(1, 1, 1)

    return style
end

--------------------------------------------------------------------
-- Apply the current style to one row
--  Touches nothing but our own regions, so the options screen can call
--  it on a preview row and the restyle path on a real one.
--------------------------------------------------------------------
function ns.Bars_ApplyRowStyle(style)
    local cfg    = ns.db.bars
    local preset = ns.BarPresetFor(cfg.style)
    local font   = FontPath(cfg.font)

    style.button:SetSize(cfg.width, cfg.height)

    -- icon
    style.icon:ClearAllPoints()
    style.icon:SetSize(cfg.height, cfg.height)
    if preset.icon then
        local corner = preset.iconRight and "TOPRIGHT" or "TOPLEFT"
        style.icon:SetPoint(corner, style.button, corner, 0, 0)
        style.icon:Show()
        style.iconBorder:Show()
    else
        -- The game keeps writing the icon texture in; it is simply not
        -- drawn. Hiding beats un-registering: SetIcon happens once, on a
        -- button we are only allowed to touch that one time.
        style.icon:SetPoint("TOPLEFT", style.button, "TOPLEFT", 0, 0)
        style.icon:Hide()
        style.iconBorder:Hide()
    end

    -- the bar takes whatever the icon leaves
    style.bar:ClearAllPoints()
    if not preset.icon then
        style.bar:SetPoint("TOPLEFT", style.button, "TOPLEFT", 0, 0)
        style.bar:SetPoint("BOTTOMRIGHT", style.button, "BOTTOMRIGHT", 0, 0)
    elseif preset.iconRight then
        style.bar:SetPoint("TOPLEFT", style.button, "TOPLEFT", 0, 0)
        style.bar:SetPoint("BOTTOMRIGHT", style.icon, "BOTTOMLEFT", -2, 0)
    else
        style.bar:SetPoint("TOPLEFT", style.icon, "TOPRIGHT", 2, 0)
        style.bar:SetPoint("BOTTOMRIGHT", style.button, "BOTTOMRIGHT", 0, 0)
    end

    -- Texture FIRST, then colour: SetStatusBarTexture replaces the
    -- texture object, and a colour set before it goes with the old one.
    style.bar:SetStatusBarTexture(TexturePath(cfg.texture))
    style.bar:SetStatusBarColor(ns.BarColor(style.group))

    -- texts
    style.name:ClearAllPoints()
    style.time:ClearAllPoints()
    style.count:ClearAllPoints()
    if preset.name then
        style.name:Show()
        style.name:SetPoint("LEFT", style.bar, "LEFT", 4, 0)
        style.name:SetPoint("RIGHT", style.bar, "RIGHT", -(TIME_COLUMN + 4), 0)
        style.name:SetJustifyH("LEFT")
        style.time:SetPoint("RIGHT", style.bar, "RIGHT", -3, 0)
        style.time:SetJustifyH("RIGHT")
    else
        -- With no name the seconds are the only thing on the bar, and a
        -- number pinned to the far right of an otherwise empty bar reads
        -- as left over rather than as the point of the row.
        style.name:Hide()
        style.time:SetPoint("CENTER", style.bar, "CENTER", 0, 0)
        style.time:SetJustifyH("CENTER")
    end

    -- Stacks live on the icon, and have to move when there is none: a
    -- region anchored to a hidden icon still sits where the icon would
    -- be, which is on top of the bar.
    if preset.icon then
        style.count:SetPoint("BOTTOMRIGHT", style.icon, "BOTTOMRIGHT", 1, -1)
    else
        style.count:SetPoint("RIGHT", style.time, "LEFT", -4, 0)
    end

    ns.SetFont(style.name,  cfg.fontSize, nil, font)
    ns.SetFont(style.time,  cfg.fontSize, nil, font)
    ns.SetFont(style.count, cfg.fontSize, nil, font)
end

--------------------------------------------------------------------
-- One bar
--  Called by the container right after it creates a button, and only
--  then: from here on the button belongs to the game.
--------------------------------------------------------------------
local function BuildBar(group, button)
    local cfg = ns.db.bars
    local style = ns.Bars_CreateRow(button, group)

    button:EnableMouse(false)

    -- Style FIRST, then hand the regions over. The predecessor of this
    -- build sized and fonted every region before registering it, and a
    -- font string that is handed to the game without a font is not a
    -- difference worth risking on a button we may not touch again.
    ns.Bars_ApplyRowStyle(style)

    -- This is the only moment we may register, so everything the game
    -- might ever have to fill goes over now - including the pieces the
    -- current style hides.
    button:SetIcon(style.icon)
    button:SetDurationBar(style.bar, {
        direction     = ns.BAR_DIR_REMAINING,
        interpolation = ns.BAR_INTERP,
    })
    button:SetDurationText(style.time)
    button:SetSpellName(style.name)

    -- stacks. Without a formatter the game only writes a number at 2 or
    -- more applications - real stacks only.
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
-- Anchor position
--  The bar position is part of the profile, so a profile switch has to
--  move the anchor as well - that is the whole point of having a layout
--  per specialization. Split out of Bars_Init for exactly that reason.
--------------------------------------------------------------------
function ns.Bars_ApplyPosition()
    if not barAnchor then return end
    local pt = ns.db.bars.point or ns.defaults.bars.point
    barAnchor:ClearAllPoints()
    barAnchor:SetPoint(pt.point, UIParent, pt.relPoint, pt.x, pt.y)
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
            ns.Bars_ApplyRowStyle(style)
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

--------------------------------------------------------------------
-- /hnd debug
--  "The bars are gone" has half a dozen causes that look identical from
--  the outside: the group is capped at zero by a filter, the container
--  is disabled, the anchor was dragged off screen, the style hid the
--  piece being looked for. This prints the ones that are answerable
--  without seeing the screen.
--------------------------------------------------------------------
function ns.Bars_Debug()
    local cfg = ns.db.bars
    print(ns.BRAND .. ": bars " .. (cfg.enabled and "ON" or "OFF")
        .. ", " .. #styleList .. " rows built"
        .. ", container " .. (container and "yes" or "MISSING")
        .. ", anchor " .. (barAnchor and "yes" or "MISSING")
        .. ", " .. (cfg.locked and "locked" or "unlocked"))

    if barAnchor then
        local point, _, relPoint, x, y = barAnchor:GetPoint()
        -- An anchor dragged past the edge is invisible and looks exactly
        -- like "the addon is broken".
        local onScreen = "on screen"
        -- GetLeft answers nil until the frame has been laid out once, so
        -- this is a check for "is it a number yet", not paranoia.
        local left, bottom = tonumber(barAnchor:GetLeft()), tonumber(barAnchor:GetBottom())
        if left and bottom then
            local w, h = tonumber(UIParent:GetWidth()) or 0, tonumber(UIParent:GetHeight()) or 0
            if left > w or bottom > h or left < -cfg.width or bottom < -cfg.height then
                onScreen = "|cffff4444OFF SCREEN|r"
            end
        end
        print(ns.BRAND .. ": anchor " .. tostring(point) .. "/" .. tostring(relPoint)
            .. " at " .. math.floor(tonumber(x) or 0) .. "," .. math.floor(tonumber(y) or 0)
            .. " (" .. onScreen .. ")")
    end

    print(ns.BRAND .. ": style " .. tostring(cfg.style)
        .. ", texture " .. tostring(cfg.texture)
        .. " -> " .. tostring(TexturePath(cfg.texture))
        .. ", font " .. tostring(cfg.font))
    print(ns.BRAND .. ": caps dots=" .. tostring(ns.GroupMaxFrames("HARMFUL", cfg.maxBars))
        .. " hots=" .. tostring(ns.GroupMaxFrames("HELPFUL", cfg.maxBars))
        .. " (0 means a filter switched that half off)")
end

function ns.Bars_Init()
    local cfg = ns.db.bars

    barAnchor = CreateFrame("Frame", "HotsNDotsBarAnchor", UIParent)
    ns.barAnchor = barAnchor
    barAnchor:SetSize(cfg.width, cfg.height)
    ns.Bars_ApplyPosition()
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
    barAnchor.label:SetText(ns.L.barAnchorLabel)

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
