--=====================================================================
--  DotsNHots - Options
--  Settings screen (Interface options) + slash commands.
--=====================================================================

local ADDON_NAME, ns = ...

--------------------------------------------------------------------
-- small UI helpers
--------------------------------------------------------------------
local function CreateCheckbox(parent, label, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetChecked(getter())
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)
    return cb
end

local function CreateSlider(parent, label, x, y, minV, maxV, step, getter, setter)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:SetWidth(190)
    if s.Low  then s.Low:SetText(tostring(minV))  end
    if s.High then s.High:SetText(tostring(maxV)) end

    local caption = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    caption:SetPoint("BOTTOM", s, "TOP", 0, 2)
    local function setCaption(v) caption:SetText(label .. ": " .. v) end

    setCaption(getter())
    s:SetValue(getter())
    s:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        setCaption(val)
        setter(val)
    end)
    return s
end

--------------------------------------------------------------------
-- Build the settings panel
--------------------------------------------------------------------
function ns.Options_Init()
    local db = ns.db
    local panel = CreateFrame("Frame")
    panel.name = "DotsNHots"
    ns.optionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99DotsNHots|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(560); sub:SetJustifyH("LEFT")
    sub:SetText("Shows only your own DoTs (on enemies) and HoTs/buffs (on friends) on nameplates and as movable bars.")

    -- =========================== LEFT COLUMN: Nameplates ===========================
    local h1 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h1:SetPoint("TOPLEFT", 24, -80)
    h1:SetText("Nameplate icons")

    CreateCheckbox(panel, "Show nameplate icons", 24, -104,
        function() return db.nameplates.enabled end,
        function(v) db.nameplates.enabled = v; ns.Nameplates_RefreshAll(); ns.Nameplates_ApplyBlizzardAll() end)

    CreateCheckbox(panel, "Hide default Blizzard auras", 24, -130,
        function() return db.nameplates.hideBlizzard end,
        function(v) db.nameplates.hideBlizzard = v; ns.Nameplates_ApplyBlizzardAll() end)

    CreateCheckbox(panel, "Show below the nameplate", 24, -156,
        function() return db.nameplates.below end,
        function(v) db.nameplates.below = v; ns.Nameplates_RefreshAll() end)

    CreateCheckbox(panel, "Show stacks (always shows the number)", 24, -182,
        function() return db.nameplates.showStacks end,
        function(v) db.nameplates.showStacks = v; ns.Nameplates_RefreshAll() end)

    CreateCheckbox(panel, "Show cooldown swipe", 24, -208,
        function() return db.nameplates.showSwipe end,
        function(v) db.nameplates.showSwipe = v; ns.Nameplates_RefreshAll() end)

    CreateSlider(panel, "Icon size", 40, -256, 16, 64, 1,
        function() return db.nameplates.size end,
        function(v) db.nameplates.size = v; ns.Nameplates_RefreshAll() end)

    CreateSlider(panel, "Distance from nameplate", 40, -304, 0, 60, 1,
        function() return db.nameplates.yOffset end,
        function(v) db.nameplates.yOffset = v; ns.Nameplates_RefreshAll() end)

    CreateSlider(panel, "Max icons", 40, -352, 1, 16, 1,
        function() return db.nameplates.maxIcons end,
        function(v) db.nameplates.maxIcons = v; ns.Nameplates_RefreshAll() end)

    -- =========================== RIGHT COLUMN: Bars + General ======================
    local h2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h2:SetPoint("TOPLEFT", 330, -80)
    h2:SetText("Bars (movable)")

    CreateCheckbox(panel, "Show bars", 330, -104,
        function() return db.bars.enabled end,
        function(v) db.bars.enabled = v; ns.Bars_Update() end)

    CreateCheckbox(panel, "Lock bars (not movable)", 330, -130,
        function() return db.bars.locked end,
        function(v) db.bars.locked = v; ns.Bars_UpdateLock() end)

    CreateCheckbox(panel, "Grow upwards", 330, -156,
        function() return db.bars.growthUp end,
        function(v) db.bars.growthUp = v; ns.Bars_Update() end)

    CreateSlider(panel, "Bar width", 346, -204, 100, 400, 5,
        function() return db.bars.width end,
        function(v) db.bars.width = v; ns.Bars_Update() end)

    CreateSlider(panel, "Bar height", 346, -252, 12, 40, 1,
        function() return db.bars.height end,
        function(v) db.bars.height = v; ns.Bars_Update() end)

    CreateSlider(panel, "Max bars", 346, -300, 1, 20, 1,
        function() return db.bars.maxBars end,
        function(v) db.bars.maxBars = v; ns.Bars_Update() end)

    local h3 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h3:SetPoint("TOPLEFT", 330, -344)
    h3:SetText("General")

    CreateCheckbox(panel, "Also count pet auras", 330, -368,
        function() return db.includePet end,
        function(v) db.includePet = v; ns.Nameplates_RefreshAll(); ns.Bars_Update() end)

    CreateCheckbox(panel, "Show minimap button", 330, -394,
        function() return not db.minimap.hide end,
        function(v) db.minimap.hide = not v; ns.Minimap_UpdateShown() end)

    -- Register category (modern Settings API)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "DotsNHots")
        Settings.RegisterAddOnCategory(category)
        ns.settingsCategory = category
    elseif InterfaceOptions_AddCategory then -- fallback for older clients
        InterfaceOptions_AddCategory(panel)
    end
end

function ns.OpenConfig()
    -- Settings.OpenToCategory needs the category's NUMERIC id (category:GetID()),
    -- not a string - passing a string throws the OpenSettingsPanel range error.
    if ns.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(ns.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and ns.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
    else
        print("|cff33ff99DotsNHots|r: open settings via ESC > Options > AddOns > DotsNHots.")
    end
end

--------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------
SLASH_DOTSNHOTS1 = "/dotsnhots"
SLASH_DOTSNHOTS2 = "/dnh"
SlashCmdList["DOTSNHOTS"] = function(msg)
    msg = strtrim(strlower(msg or ""))

    if msg == "lock" then
        ns.db.bars.locked = true
        ns.Bars_UpdateLock()
        print("|cff33ff99DotsNHots|r: bars locked.")
    elseif msg == "unlock" then
        ns.db.bars.locked = false
        ns.Bars_UpdateLock()
        print("|cff33ff99DotsNHots|r: bars unlocked \226\128\147 drag to move.")
    elseif msg == "nameplates" then
        ns.db.nameplates.enabled = not ns.db.nameplates.enabled
        ns.Nameplates_RefreshAll()
        print("|cff33ff99DotsNHots|r: nameplate icons " .. (ns.db.nameplates.enabled and "ON" or "OFF"))
    elseif msg == "bars" then
        ns.db.bars.enabled = not ns.db.bars.enabled
        ns.Bars_Update()
        print("|cff33ff99DotsNHots|r: bars " .. (ns.db.bars.enabled and "ON" or "OFF"))
    elseif msg == "minimap" then
        ns.db.minimap.hide = not ns.db.minimap.hide
        ns.Minimap_UpdateShown()
        print("|cff33ff99DotsNHots|r: minimap button " .. (ns.db.minimap.hide and "OFF" or "ON"))
    else
        ns.OpenConfig()
    end
end
