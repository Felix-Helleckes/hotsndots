--=====================================================================
--  HotsNDots - Nameplates
--  Your own auras, large above (or below) the nameplate:
--  icon + cooldown swipe + big seconds countdown + real stacks.
--
--  Every icon is an AuraButton owned by the game. We create the regions
--  (icon texture, border, countdown text, stack text) and register them
--  with the button; the game decides which aura goes where and writes
--  the values in. HotsNDots never reads aura data, and it never touches
--  the Blizzard nameplate itself - the container hangs off our own
--  holder frame and is only anchored to the plate.
--
--  That last part matters: writing fields onto the nameplate's UnitFrame
--  or hiding its aura frame used to taint it, and since 12.1 a tainted
--  nameplate cannot even update its own mana bar
--  ("attempt to compare local 'currValue' (a secret number value)").
--  So we leave Blizzard's nameplate strictly alone, which also means the
--  default nameplate auras are no longer hidden - see the changelog.
--=====================================================================

local ADDON_NAME, ns = ...

local displays  = {}   -- every display we ever built
local byUnit    = {}   -- [unitToken] = display currently in use
local freeList  = {}   -- displays not attached to a nameplate right now
local styleList = {}   -- every icon we built, so it can be restyled later

local GROUPS = {
    { key = "dots", kind = "HARMFUL", r = 0.65, g = 0.10, b = 0.10 },
    { key = "hots", kind = "HELPFUL", r = 0.10, g = 0.55, b = 0.15 },
}

--------------------------------------------------------------------
-- One aura icon
--  Called by the container right after it creates a button, and only
--  then: from this point on the button belongs to the game and may not
--  be touched by us while auras are secret.
--------------------------------------------------------------------
local function BuildIcon(group, button)
    local cfg = ns.db.nameplates
    local style = { button = button, group = group }

    button:SetSize(cfg.size, cfg.size)
    button:EnableMouse(false)

    style.border = button:CreateTexture(nil, "BACKGROUND")
    style.border:SetPoint("TOPLEFT", -1.5, 1.5)
    style.border:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
    style.border:SetColorTexture(group.r, group.g, group.b, 1)

    style.icon = button:CreateTexture(nil, "ARTWORK")
    style.icon:SetAllPoints()
    style.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetIcon(style.icon)

    -- swipe. The cooldown always exists so the swipe can be switched on
    -- later without needing to build a region on a button we no longer own.
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true) -- we draw our own, bigger
    cooldown:SetReverse(true)
    cooldown:EnableMouse(false)
    cooldown.noCooldownCount = true        -- keep OmniCC off our icons
    cooldown:SetDrawSwipe(cfg.showSwipe and true or false)
    style.cooldown = cooldown
    button:SetDurationCooldown(cooldown)

    -- text sits on its own frame above the swipe, or it would be drawn under it
    local textLayer = CreateFrame("Frame", nil, button)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    style.textLayer = textLayer

    -- big seconds above (or below) the icon
    style.timer = textLayer:CreateFontString(nil, "OVERLAY")
    style.timer:SetPoint("BOTTOM", button, "TOP", 0, 0)
    style.timer:SetJustifyH("CENTER")
    ns.SetFont(style.timer, cfg.timerFontSize)
    style.timer:SetTextColor(1, 1, 1)
    button:SetDurationText(style.timer)

    -- stacks in the bottom-right corner. Without a formatter the game
    -- only writes a number at 2 or more applications, which is exactly
    -- the "only real stacks" behaviour.
    style.count = textLayer:CreateFontString(nil, "OVERLAY")
    style.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    ns.SetFont(style.count, cfg.stackFontSize)
    style.count:SetTextColor(1, 1, 1)
    if cfg.showStacks then
        button:SetApplicationCount(style.count)
    end

    styleList[#styleList + 1] = style
end

--------------------------------------------------------------------
-- Layout of one display
--------------------------------------------------------------------
local function ApplyLayout(display)
    local cfg = ns.db.nameplates
    local c = display.container

    -- The container sizes itself from the auras it holds, and that size
    -- is secret - so it can only be anchored by a corner, never centred.
    -- Growing right from half an icon left of the plate centre keeps a
    -- single icon centred, which is the common case.
    c:ClearAllPoints()
    if cfg.below then
        c:SetPoint("TOPLEFT", display.holder, "TOPLEFT", 0, 0)
        c:SetFlowLayoutAnchorPoint("TOPLEFT")
        c:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Down)
    else
        c:SetPoint("BOTTOMLEFT", display.holder, "BOTTOMLEFT", 0, 0)
        c:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
        c:SetFlowLayoutGrowthDirection(ns.FlowDir.Right, ns.FlowDir.Up)
    end

    for _, group in ipairs(GROUPS) do
        c:SetAuraGroupLayout(group.key, {
            elementSpacing = cfg.spacing,
            elementWidth   = cfg.size,
            elementHeight  = cfg.size,
        })
        c:SetAuraGroupMaxFrameCount(group.key, ns.GroupMaxFrames(group.kind, cfg.maxIcons))
        c:SetAuraGroupFilterString(group.key, ns.FilterString(group.kind, "INCLUDE_NAME_PLATE_ONLY"))
        c:SetAuraGroupCandidateFilters(group.key, ns.CandidateFilters(group.kind))
    end
end

--------------------------------------------------------------------
-- Build a display (holder + container + groups)
--------------------------------------------------------------------
local function CreateDisplay()
    local cfg = ns.db.nameplates

    -- Our own frame, so that moving the display around never means
    -- anchoring anything to the container (whose size is secret).
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(1, 1)
    holder:SetFrameStrata("HIGH")
    holder:Hide()

    local container = CreateFrame("AuraContainer", nil, holder, "CustomAuraContainerTemplate")
    container:SetFlowLayoutAxis(ns.FlowAxis.Horizontal)
    container:SetFlowLayoutMaximumLineSize(math.huge) -- one row; maxIcons caps it

    local display = { holder = holder, container = container }

    for _, group in ipairs(GROUPS) do
        container:AddAuraGroup(group.key, ns.FilterString(group.kind, "INCLUDE_NAME_PLATE_ONLY"), {
            maxFrameCount    = ns.GroupMaxFrames(group.kind, cfg.maxIcons),
            candidateFilters = ns.CandidateFilters(group.kind),
            sortMethod       = ns.SortMethod.ExpirationOnly,
            sortDirection    = ns.SortDirection.Normal,
            initializeFrame  = function(button) BuildIcon(group, button) end,
            layout = {
                elementSpacing = cfg.spacing,
                elementWidth   = cfg.size,
                elementHeight  = cfg.size,
            },
        })
    end

    ApplyLayout(display)
    displays[#displays + 1] = display
    return display
end

local function AcquireDisplay()
    local display = table.remove(freeList) or CreateDisplay()
    return display
end

local function ReleaseDisplay(display)
    display.container:SetEnabled(false)
    display.holder:Hide()
    display.holder:ClearAllPoints()
    display.unit = nil
    freeList[#freeList + 1] = display
end

--------------------------------------------------------------------
-- Attach a display to a nameplate
--  The Blizzard nameplate is only ever read here: we anchor to it and
--  never write a field, call a method or hook anything on it.
--------------------------------------------------------------------
local function Attach(display, unit, plate)
    local cfg = ns.db.nameplates
    local holder = display.holder
    local halfIcon = cfg.size / 2

    holder:ClearAllPoints()
    if cfg.below then
        holder:SetPoint("TOPLEFT", plate, "BOTTOM", cfg.xOffset - halfIcon, -cfg.yOffset)
    else
        holder:SetPoint("BOTTOMLEFT", plate, "TOP", cfg.xOffset - halfIcon, cfg.yOffset)
    end

    display.unit = unit
    holder:Show()
    display.container:SetUnit(unit)
    display.container:SetEnabled(cfg.enabled and true or false)
end

--------------------------------------------------------------------
-- Public interface
--------------------------------------------------------------------
function ns.Nameplates_OnAdded(unit)
    if not ns.hasAuraContainers or not unit then return end

    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    -- A token can come back without a matching removal (zoning, a plate
    -- recycled onto a different mob), so re-attach what is already there
    -- rather than leaking the display and blocking the new unit.
    local display = byUnit[unit]
    if not display then
        display = AcquireDisplay()
        byUnit[unit] = display
    end
    Attach(display, unit, plate)
end

function ns.Nameplates_OnRemoved(unit)
    local display = unit and byUnit[unit]
    if not display then return end
    byUnit[unit] = nil
    ReleaseDisplay(display)
end

-- Re-anchor and re-filter every visible display. Safe at any time: it
-- only touches our own holder and the container's inbound interface,
-- never an aura button.
function ns.Nameplates_RefreshAll()
    if not ns.hasAuraContainers then return end
    for _, display in ipairs(displays) do
        ApplyLayout(display)
    end
    for unit, display in pairs(byUnit) do
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            Attach(display, unit, plate)
        end
    end
end

-- Push size/font changes into the buttons themselves. The game owns
-- them, so this is only permitted while auras are not secret; when it is
-- refused the attempt is repeated after combat.
function ns.Nameplates_Restyle()
    local cfg = ns.db.nameplates

    ns.TryRestyle(function()
        for _, style in ipairs(styleList) do
            style.button:SetSize(cfg.size, cfg.size)
            style.cooldown:SetDrawSwipe(cfg.showSwipe and true or false)
            ns.SetFont(style.timer, cfg.timerFontSize)
            ns.SetFont(style.count, cfg.stackFontSize)
            if cfg.showStacks then
                style.button:SetApplicationCount(style.count)
            else
                style.button:ClearApplicationCount()
                style.count:SetText("")
            end
        end
    end)

    ns.Nameplates_RefreshAll()
end

-- Adding an aura group makes the container allocate a batch of buttons
-- up front, and our initializeFrame runs for each of them. Doing that for
-- the first time in the middle of a pull is a needless hitch, so a few
-- displays are built at login and then reused for the rest of the session.
local PREWARM = 5

function ns.Nameplates_Init()
    for _ = 1, PREWARM do
        freeList[#freeList + 1] = CreateDisplay()
    end

    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = plate.namePlateUnitToken
        if unit then
            ns.Nameplates_OnAdded(unit)
        end
    end
end

--------------------------------------------------------------------
-- /hnd debug
--------------------------------------------------------------------
function ns.Nameplates_Debug()
    local shown = 0
    for _ in pairs(byUnit) do shown = shown + 1 end
    print(ns.BRAND .. ": nameplate displays " .. shown .. " active, " ..
          #displays .. " built, " .. #styleList .. " icons.")
end
