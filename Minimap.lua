--=====================================================================
--  HotsNDots - Minimap Button
--  Self-contained minimap button (no external libraries), built with
--  the standard LibDBIcon geometry so it sits on the ring exactly like
--  every other addon button.
--    Left click  = open settings
--    Right click = lock / unlock the bars
--    Drag        = move the button around the minimap
--=====================================================================

local ADDON_NAME, ns = ...

local button

--------------------------------------------------------------------
-- Place the button on the ring around the minimap.
-- Radius is derived from the actual minimap size at runtime, so it
-- lines up regardless of minimap scale/shape (round).
--------------------------------------------------------------------
local function UpdatePosition()
    if not button then return end
    local angle = math.rad(ns.db.minimap.angle or 220)
    local w = (Minimap:GetWidth()  / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * w, math.sin(angle) * h)
end

-- While dragging: derive the angle from the cursor position.
local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale  = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
    UpdatePosition()
end

--------------------------------------------------------------------
-- Visibility
--------------------------------------------------------------------
function ns.Minimap_UpdateShown()
    if ns.ldbIcon then
        if ns.db.minimap.hide then
            ns.ldbIcon:Hide(ns.name)
        else
            ns.ldbIcon:Show(ns.name)
        end
        return
    end
    if not button then return end
    if ns.db.minimap.hide then button:Hide() else button:Show() end
end

--------------------------------------------------------------------
-- LibDBIcon route
--  Minimap-button managers (Leatrix Plus' button bag, ElvUI, MoveAny,
--  ...) collect buttons through LibDBIcon's registry - a hand-rolled
--  button parented to the Minimap is invisible to all of them, which is
--  why HotsNDots never turned up in Leatrix' right-click bag.
--  We do not ship the libraries (the addon stays dependency-free); we
--  just use them when some other addon has already loaded them, and
--  fall back to our own button otherwise.
--------------------------------------------------------------------
local function TryLibDBIcon()
    if not LibStub then return false end

    local LDB     = LibStub:GetLibrary("LibDataBroker-1.1", true)
    local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not (LDB and LDBIcon) then return false end
    if LDBIcon:GetMinimapButton(ns.name) then return true end -- already there

    local obj = LDB:NewDataObject(ns.name, {
        type = "launcher",
        text = ns.name,
        icon = "Interface\\AddOns\\HotsNDots\\Icon.tga",
        OnClick = function(_, mouseButton)
            if mouseButton == "RightButton" then
                ns.db.bars.locked = not ns.db.bars.locked
                ns.Bars_UpdateLock()
                print(ns.BRAND .. ": bars " ..
                    (ns.db.bars.locked and "locked." or "unlocked \226\128\147 drag to move."))
            else
                ns.OpenConfig()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(ns.BRAND)
            tt:AddLine("Left click: settings", 1, 1, 1)
            tt:AddLine("Right click: lock/unlock bars", 1, 1, 1)
            tt:AddLine("Drag: move this button", 1, 1, 1)
        end,
    })
    if not obj then return false end

    -- LibDBIcon owns db.hide and db.minimapPos; our own db.angle stays
    -- untouched so the fallback button keeps its position too.
    -- showInCompartment is deliberately NOT set: the .toc already
    -- registers an Addon Compartment entry and we don't want two.
    LDBIcon:Register(ns.name, obj, ns.db.minimap)

    ns.ldbObject = obj
    ns.ldbIcon = LDBIcon
    return true
end

--------------------------------------------------------------------
-- Create
--------------------------------------------------------------------
function ns.Minimap_Init()
    if TryLibDBIcon() then
        ns.Minimap_UpdateShown()
        return
    end

    button = CreateFrame("Button", "HotsNDotsMinimapButton", Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(31, 31)
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Standard minimap-button art (identical layout to LibDBIcon buttons)
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    -- custom HotsNDots logo (self-contained TGA shipped with the addon)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(19, 19)
    icon:SetTexture("Interface\\AddOns\\HotsNDots\\Icon.tga")
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetPoint("CENTER", 0, 1)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.db.bars.locked = not ns.db.bars.locked
            ns.Bars_UpdateLock()
            print("|cff33ff99HotsNDots|r: bars " ..
                (ns.db.bars.locked and "locked." or "unlocked \226\128\147 drag to move."))
        else
            ns.OpenConfig()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff33ff99HotsNDots|r")
        GameTooltip:AddLine("Left click: settings", 1, 1, 1)
        GameTooltip:AddLine("Right click: lock/unlock bars", 1, 1, 1)
        GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
    ns.Minimap_UpdateShown()
end

--------------------------------------------------------------------
-- Native Addon Compartment integration (icon menu next to the minimap)
-- Called via the .toc directives.
--------------------------------------------------------------------
function HotsNDots_OnCompartmentClick()
    ns.OpenConfig()
end

function HotsNDots_OnCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff33ff99HotsNDots|r")
    GameTooltip:AddLine("Click: open settings", 1, 1, 1)
    GameTooltip:Show()
end

function HotsNDots_OnCompartmentLeave()
    GameTooltip:Hide()
end
