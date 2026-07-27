--=====================================================================
--  DotsNHots - Minimap Button
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
    if not button then return end
    if ns.db.minimap.hide then button:Hide() else button:Show() end
end

--------------------------------------------------------------------
-- Create
--------------------------------------------------------------------
function ns.Minimap_Init()
    button = CreateFrame("Button", "DotsNHotsMinimapButton", Minimap)
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

    -- custom DotsNHots logo (self-contained TGA shipped with the addon)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(19, 19)
    icon:SetTexture("Interface\\AddOns\\DotsNHots\\Icon.tga")
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetPoint("CENTER", 0, 1)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.db.bars.locked = not ns.db.bars.locked
            ns.Bars_UpdateLock()
            print("|cff33ff99DotsNHots|r: bars " ..
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
        GameTooltip:AddLine("|cff33ff99DotsNHots|r")
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
function DotsNHots_OnCompartmentClick()
    ns.OpenConfig()
end

function DotsNHots_OnCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff33ff99DotsNHots|r")
    GameTooltip:AddLine("Click: open settings", 1, 1, 1)
    GameTooltip:Show()
end

function DotsNHots_OnCompartmentLeave()
    GameTooltip:Hide()
end
