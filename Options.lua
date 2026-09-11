--=====================================================================
--  HotsNDots - Options
--  Settings screen (Interface options) + slash commands.
--
--  Two things about this file only make sense with profiles in mind:
--
--  * Every getter reads ns.db at CALL time, never a captured local.
--    ns.db is repointed when the profile changes, and a captured table
--    would leave the panel editing the profile you just left.
--  * Every control registers a refresher. Switching profile does not
--    rebuild the panel, so the widgets have to be told to re-read - an
--    options screen still showing the old profile's numbers is worse
--    than none, because it will happily write them back.
--=====================================================================

local ADDON_NAME, ns = ...
local L = ns.L

-- Controls that have to re-read their value after a profile switch.
local refreshers = {}
-- While refreshing, a widget's own handler must not write back into the
-- (new) profile - SetValue/SetChecked fire the scripts.
local refreshing = false

--------------------------------------------------------------------
-- small UI helpers
--------------------------------------------------------------------
local function CreateCheckbox(parent, label, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetChecked(getter())
    cb:SetScript("OnClick", function(self)
        if refreshing then return end
        setter(self:GetChecked() and true or false)
    end)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)

    refreshers[#refreshers + 1] = function() cb:SetChecked(getter()) end
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
        if refreshing then return end
        setter(val)
    end)

    refreshers[#refreshers + 1] = function()
        local v = getter()
        setCaption(v)
        s:SetValue(v)
    end
    return s
end

-- Panels that are built later register their own refreshers here; the
-- forward declarations keep every "something changed" path able to say
-- "redraw everything" without caring which pages exist yet.
local profileRefreshers = {}
local styleRefreshers   = {}

-- One change can move all three pages: picking a profile changes every
-- widget AND the style preview, and picking a style changes the preview
-- AND the bars. Everything therefore goes through one refresh.
function ns.Options_RefreshUI()
    for _, fn in ipairs(profileRefreshers) do pcall(fn) end
    for _, fn in ipairs(styleRefreshers)   do pcall(fn) end
    ns.Options_Refresh()
end

-- kept as its own name because the popups and slash commands read better
-- for it, and because it is what the profile code calls
function ns.Options_RefreshProfiles()
    ns.Options_RefreshUI()
end

-- Called after every profile switch, reset and copy.
function ns.Options_Refresh()
    if refreshing then return end
    refreshing = true
    for _, fn in ipairs(refreshers) do
        pcall(fn)
    end
    refreshing = false
end

--------------------------------------------------------------------
-- A dropdown that does not depend on a Blizzard menu template
--  The dropdown templates were replaced in 11.0 and the old
--  UIDropDownMenu ones are gone. This is a Button plus a list of
--  Buttons: it cannot break with the next menu rewrite, and picking a
--  profile needs nothing more.
--------------------------------------------------------------------
local menuFrame

local function EnsureMenu()
    if menuFrame then return menuFrame end

    menuFrame = CreateFrame("Frame", nil, UIParent)
    menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    menuFrame:EnableMouse(true)
    menuFrame:Hide()

    local border = menuFrame:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.35, 0.35, 0.35, 1)

    local bg = menuFrame:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

    menuFrame.buttons = {}
    return menuFrame
end

local function CloseMenu()
    if menuFrame then menuFrame:Hide() end
end
ns.Options_CloseMenu = CloseMenu

local ROW_H = 18

local function ShowMenu(anchor, items, onPick)
    local m = EnsureMenu()

    -- Clicking the same anchor again closes it: that is what a dropdown
    -- does, and it is what a player tries when they change their mind.
    if m:IsShown() and m.anchor == anchor then
        m:Hide()
        return
    end
    m.anchor = anchor

    for _, b in ipairs(m.buttons) do b:Hide() end

    local width = math.max(anchor:GetWidth(), 140)
    local y = -4
    for i, item in ipairs(items) do
        local b = m.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, m)
            b:SetHeight(ROW_H)
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            b.text:SetPoint("LEFT", 8, 0)
            b.text:SetPoint("RIGHT", -8, 0)
            b.text:SetJustifyH("LEFT")
            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.15)
            m.buttons[i] = b
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 4, y)
        b:SetWidth(width - 8)
        b.text:SetText(item)
        b:SetScript("OnClick", function()
            m:Hide()
            onPick(item)
        end)
        b:Show()
        y = y - ROW_H
    end

    m:SetSize(width, -y + 4)
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    m:Show()
end

-- getSelected/onPick work on names, so callers never touch the widget.
local function CreateDropdown(parent, width, getItems, getSelected, onPick)
    local dd = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dd:SetSize(width, 22)

    function dd:Refresh() self:SetText(getSelected() or "") end
    dd:Refresh()

    dd:SetScript("OnClick", function(self)
        ShowMenu(self, getItems(), function(item)
            onPick(item)
            ns.Options_RefreshUI()
        end)
    end)
    return dd
end

--------------------------------------------------------------------
-- Colour picker
--  ColorPickerFrame was reworked in 10.2.5: the fields became one info
--  table. Both shapes are handled because the cost is six lines and the
--  failure mode is a click that does nothing.
--------------------------------------------------------------------
local function OpenColorPicker(get, set)
    local r, g, b = get()

    local function apply()
        set(ColorPickerFrame:GetColorRGB())
    end
    -- The cancel payload is a table with r/g/b on modern clients and a
    -- plain array on older ones.
    local function restore(prev)
        if type(prev) ~= "table" then return end
        set(prev.r or prev[1] or r, prev.g or prev[2] or g, prev.b or prev[3] or b)
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = false,
            swatchFunc = apply,
            cancelFunc = restore,
        })
        return
    end

    ColorPickerFrame.func       = apply
    ColorPickerFrame.cancelFunc = restore
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r = r, g = g, b = b }
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Hide()   -- forces OnShow to run even if it was open
    ColorPickerFrame:Show()
end

local function CreateColorSwatch(parent, label, x, y, get, set)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(22, 22)
    b:SetPoint("TOPLEFT", x, y)

    local border = b:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)

    local fill = b:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)

    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("LEFT", b, "RIGHT", 6, 0)
    fs:SetText(label)

    function b:Refresh()
        fill:SetColorTexture(get())
    end
    b:Refresh()

    b:SetScript("OnClick", function()
        OpenColorPicker(get, function(r, g, bl)
            set(r, g, bl)
            b:Refresh()
            ns.Options_RefreshUI()
        end)
    end)
    return b
end

--------------------------------------------------------------------
-- Build the settings panel
--------------------------------------------------------------------
-- Container-level changes (filters, growth, caps, offsets). Always
-- allowed: no aura button is touched.
local function RefreshAll()
    if ns.Nameplates_RefreshAll then ns.Nameplates_RefreshAll() end
    if ns.Bars_Update then ns.Bars_Update() end
end

-- Changes that have to reach the aura buttons themselves (sizes, fonts,
-- stacks). The game only lets us touch them while auras are not secret,
-- so these are retried after combat when they are refused.
local function RestyleNameplates()
    if ns.Nameplates_Restyle then ns.Nameplates_Restyle() end
end

local function RestyleBars()
    if ns.Bars_Restyle then ns.Bars_Restyle() end
end

function ns.Options_Init()
    local panel = CreateFrame("Frame")
    panel.name = "HotsNDots"
    panel:SetScript("OnHide", CloseMenu)
    ns.optionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff33ff99HotsNDots|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(560); sub:SetJustifyH("LEFT")
    sub:SetText(L.tagline)

    -- Which profile these controls are editing. Everything below writes
    -- into the ACTIVE profile, and that is not obvious once profiles
    -- switch themselves on a spec change - so the panel says it.
    local where = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    where:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -8)
    where:SetJustifyH("LEFT")
    local function updateWhere()
        where:SetText(format(L.editingProfile, "|cff33ff99" .. tostring(ns.activeProfile) .. "|r")
            .. "   " .. L.profilesTabHint)
    end
    updateWhere()
    refreshers[#refreshers + 1] = updateWhere

    -- =========================== LEFT COLUMN: Nameplates ===========================
    local h1 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h1:SetPoint("TOPLEFT", 24, -80)
    h1:SetText(L.hdrNameplates)

    CreateCheckbox(panel, L.cbNameplates, 24, -104,
        function() return ns.db.nameplates.enabled end,
        function(v) ns.db.nameplates.enabled = v; ns.Nameplates_RefreshAll() end)

    CreateCheckbox(panel, L.cbBelow, 24, -130,
        function() return ns.db.nameplates.below end,
        function(v) ns.db.nameplates.below = v; ns.Nameplates_RefreshAll() end)

    CreateCheckbox(panel, L.cbStacks, 24, -156,
        function() return ns.db.nameplates.showStacks end,
        function(v) ns.db.nameplates.showStacks = v; RestyleNameplates() end)

    CreateCheckbox(panel, L.cbSwipe, 24, -182,
        function() return ns.db.nameplates.showSwipe end,
        function(v) ns.db.nameplates.showSwipe = v; RestyleNameplates() end)

    CreateSlider(panel, L.slIconSize, 40, -230, 16, 64, 1,
        function() return ns.db.nameplates.size end,
        function(v) ns.db.nameplates.size = v; RestyleNameplates() end)

    CreateSlider(panel, L.slSecondsFont, 40, -278, 8, 36, 1,
        function() return ns.db.nameplates.timerFontSize end,
        function(v) ns.db.nameplates.timerFontSize = v; RestyleNameplates() end)

    CreateSlider(panel, L.slDistance, 40, -326, 0, 60, 1,
        function() return ns.db.nameplates.yOffset end,
        function(v) ns.db.nameplates.yOffset = v; ns.Nameplates_RefreshAll() end)

    CreateSlider(panel, L.slMaxIcons, 40, -374, 1, 16, 1,
        function() return ns.db.nameplates.maxIcons end,
        function(v) ns.db.nameplates.maxIcons = v; ns.Nameplates_RefreshAll() end)

    -- =========================== RIGHT COLUMN: Bars + General ======================
    local h2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h2:SetPoint("TOPLEFT", 330, -80)
    h2:SetText(L.hdrBars)

    CreateCheckbox(panel, L.cbBars, 330, -104,
        function() return ns.db.bars.enabled end,
        function(v) ns.db.bars.enabled = v; ns.Bars_Update() end)

    CreateCheckbox(panel, L.cbLock, 330, -130,
        function() return ns.db.bars.locked end,
        function(v) ns.db.bars.locked = v; ns.Bars_UpdateLock() end)

    CreateCheckbox(panel, L.cbGrowUp, 330, -156,
        function() return ns.db.bars.growthUp end,
        function(v) ns.db.bars.growthUp = v; ns.Bars_Update() end)

    CreateCheckbox(panel, L.cbStacks, 330, -182,
        function() return ns.db.bars.showStacks end,
        function(v) ns.db.bars.showStacks = v; RestyleBars() end)

    CreateSlider(panel, L.slBarWidth, 346, -230, 100, 400, 5,
        function() return ns.db.bars.width end,
        function(v) ns.db.bars.width = v; RestyleBars() end)

    CreateSlider(panel, L.slBarHeight, 346, -278, 12, 40, 1,
        function() return ns.db.bars.height end,
        function(v) ns.db.bars.height = v; RestyleBars() end)

    CreateSlider(panel, L.slMaxBars, 346, -326, 1, 20, 1,
        function() return ns.db.bars.maxBars end,
        function(v) ns.db.bars.maxBars = v; ns.Bars_Update() end)

    -- =========================== RIGHT COLUMN: Filters =============================
    -- "Mine" is not the same as "worth watching": your own long raid buffs,
    -- utility snares and CC all land in the list otherwise, and the icon/bar
    -- count is capped - so junk auras push real DoTs out of the display.
    local h3 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h3:SetPoint("TOPLEFT", 330, -370)
    h3:SetText(L.hdrFilters)

    CreateCheckbox(panel, L.cbShowDebuffs, 330, -394,
        function() return ns.db.filters.showDebuffs end,
        function(v) ns.db.filters.showDebuffs = v; RefreshAll() end)

    CreateCheckbox(panel, L.cbShowBuffs, 330, -420,
        function() return ns.db.filters.showBuffs end,
        function(v) ns.db.filters.showBuffs = v; RefreshAll() end)

    -- Permanent auras, split by kind: your own raid buffs never expire
    -- and would sit in the capped slots forever, but a permanent DoT
    -- (Absolute Corruption) is exactly what you want to see.
    CreateCheckbox(panel, L.cbHidePermBuffs, 330, -446,
        function() return ns.db.filters.hidePermanentBuffs end,
        function(v) ns.db.filters.hidePermanentBuffs = v; RefreshAll() end)

    CreateCheckbox(panel, L.cbHidePermDebuffs, 330, -472,
        function() return ns.db.filters.hidePermanentDebuffs end,
        function(v) ns.db.filters.hidePermanentDebuffs = v; RefreshAll() end)

    CreateCheckbox(panel, L.cbHideCC, 330, -498,
        function() return ns.db.filters.hideCrowdControl end,
        function(v) ns.db.filters.hideCrowdControl = v; RefreshAll() end)

    -- =========================== LEFT COLUMN: General ==============================
    local h4 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h4:SetPoint("TOPLEFT", 24, -420)
    h4:SetText(L.hdrGeneral)

    -- There is no "also count pet auras" option any more: the game's
    -- PLAYER filter now always covers your pet's and your vehicle's
    -- auras, and there is no separate filter left to ask for.
    --
    -- The minimap button is deliberately NOT part of a profile: it is
    -- where your button sits, not what your spec's display looks like.
    CreateCheckbox(panel, L.cbMinimap, 24, -444,
        function() return not ns.global.minimap.hide end,
        function(v) ns.global.minimap.hide = not v; ns.Minimap_UpdateShown() end)

    -- Register category (modern Settings API)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "HotsNDots")
        Settings.RegisterAddOnCategory(category)
        ns.settingsCategory = category

        -- Profiles as a subcategory, the way every addon with profiles
        -- does it - so it is where people already look for it.
        if Settings.RegisterCanvasLayoutSubcategory then
            for _, sub in ipairs(ns.Options_SubPanels()) do
                Settings.RegisterCanvasLayoutSubcategory(category, sub, sub.name)
            end
        end
    elseif InterfaceOptions_AddCategory then -- fallback for older clients
        InterfaceOptions_AddCategory(panel)
        for _, sub in ipairs(ns.Options_SubPanels()) do
            sub.parent = panel.name
            InterfaceOptions_AddCategory(sub)
        end
    end
end

-- Which extra pages exist depends on which files the client actually
-- loaded: after an update installed mid-session, Profiles.lua and
-- Media.lua can still be missing for one session, and a page built on
-- them would throw inside Options_Init - taking the minimap button and
-- everything after it with it.
function ns.Options_SubPanels()
    local out = {}
    if ns.TexturePath and ns.BarPresets then
        out[#out + 1] = ns.Options_BuildStylePanel()
    end
    if ns.Profiles_List then
        out[#out + 1] = ns.Options_BuildProfilePanel()
    end
    return out
end

--------------------------------------------------------------------
-- Profiles panel
--------------------------------------------------------------------
-- StaticPopup is the plainest thing that works for a name prompt and
-- needs no frame of ours to stay alive between clicks.
StaticPopupDialogs["HOTSNDOTS_NEW_PROFILE"] = {
    text = L.popupNewName,
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    OnShow = function(self)
        local edit = self.editBox or (self.GetEditBox and self:GetEditBox())
        if edit then edit:SetText("") end
    end,
    OnAccept = function(self, data)
        local edit = self.editBox or (self.GetEditBox and self:GetEditBox())
        local name = edit and edit:GetText() or ""
        local created, why = ns.Profiles_Create(name, data and data.copyFrom)
        if not created then
            print(ns.BRAND .. ": " .. why)
            return
        end
        -- A profile you just made is a profile you want to be on.
        ns.Profiles_AssignCurrentSpec(created)
        ns.Options_RefreshProfiles()
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["HOTSNDOTS_DELETE_PROFILE"] = {
    text = L.popupDelete,
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(self, data)
        local ok, why = ns.Profiles_Delete(data)
        if not ok then print(ns.BRAND .. ": " .. why) end
        ns.Options_RefreshProfiles()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["HOTSNDOTS_RESET_PROFILE"] = {
    text = L.popupReset,
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(self, data)
        local ok, why = ns.Profiles_Reset(data)
        if not ok then print(ns.BRAND .. ": " .. why) end
        ns.Options_RefreshProfiles()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function AddButton(parent, label, x, y, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

function ns.Options_BuildProfilePanel()
    local panel = CreateFrame("Frame")
    panel.name = L.pageProfiles
    panel:SetScript("OnHide", CloseMenu)
    ns.profilePanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ns.BRAND .. " - " .. L.pageProfiles)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(560); sub:SetJustifyH("LEFT")
    sub:SetText(L.profilesIntro)

    local who = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    who:SetPoint("TOPLEFT", 24, -100)
    who:SetJustifyH("LEFT")

    -- ---------------- assignments, one row per specialization ----------------
    local h1 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h1:SetPoint("TOPLEFT", 24, -136)
    h1:SetText(L.hdrPerSpec)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 24, -158)
    hint:SetText(L.perSpecHint)

    local rows = {}
    local y = -180

    local function AddRow(specID, label)
        local text = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", 32, y - 4)
        text:SetWidth(160)
        text:SetJustifyH("LEFT")
        text:SetText(label)

        local dd = CreateDropdown(panel, 200,
            ns.Profiles_List,
            function() return ns.Profiles_AssignedTo(specID) end,
            function(name) ns.Profiles_AssignSpec(specID, name) end)
        dd:SetPoint("TOPLEFT", 200, y)

        rows[#rows + 1] = { specID = specID, dd = dd }
        y = y - 30
    end

    local numSpecs = (GetNumSpecializations and GetNumSpecializations()) or 0
    if numSpecs > 0 then
        for i = 1, numSpecs do
            local id, name = GetSpecializationInfo(i)
            if id then AddRow(id, name or format(L.specNumbered, i)) end
        end
    else
        -- A low-level character has no specialization yet. That is a real
        -- slot (ID 0) and gets a row like any other, rather than an empty
        -- panel that reads as broken.
        AddRow(0, ns.SpecName(0))
    end

    -- ---------------- management ----------------
    local h2 = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h2:SetPoint("TOPLEFT", 24, y - 16)
    h2:SetText(L.hdrManage)
    y = y - 44

    local active = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    active:SetPoint("TOPLEFT", 32, y)
    active:SetJustifyH("LEFT")
    y = y - 28

    AddButton(panel, L.btnNewProfile, 32, y, 150, function()
        StaticPopup_Show("HOTSNDOTS_NEW_PROFILE")
    end)

    AddButton(panel, L.btnNewFromThis, 192, y, 170, function()
        StaticPopup_Show("HOTSNDOTS_NEW_PROFILE", nil, nil, { copyFrom = ns.activeProfile })
    end)
    y = y - 30

    -- "Copy from" overwrites the profile you are ON. That is how every
    -- other addon does it, and it is the only variant that does not need
    -- a second question about the target.
    AddButton(panel, L.btnCopyFrom, 32, y, 150, function(self)
        local items = {}
        for _, name in ipairs(ns.Profiles_List()) do
            if name ~= ns.activeProfile then items[#items + 1] = name end
        end
        if #items == 0 then
            print(ns.BRAND .. ": " .. L.msgNoOtherToCopy)
            return
        end
        ShowMenu(self, items, function(name)
            local ok, why = ns.Profiles_Copy(name)
            if not ok then print(ns.BRAND .. ": " .. why) end
            ns.Options_RefreshProfiles()
        end)
    end)

    AddButton(panel, L.btnResetProfile, 192, y, 170, function()
        StaticPopup_Show("HOTSNDOTS_RESET_PROFILE", ns.activeProfile, nil, ns.activeProfile)
    end)
    y = y - 30

    AddButton(panel, L.btnDelete, 32, y, 150, function(self)
        local items = {}
        for _, name in ipairs(ns.Profiles_List()) do
            if name ~= ns.DEFAULT_PROFILE then items[#items + 1] = name end
        end
        if #items == 0 then
            print(ns.BRAND .. ": " .. L.msgNothingToDel)
            return
        end
        ShowMenu(self, items, function(name)
            StaticPopup_Show("HOTSNDOTS_DELETE_PROFILE", name, nil, name)
        end)
    end)

    -- ---------------- refresh ----------------
    local function refresh()
        who:SetText(format(L.charLine,
            "|cffffffff" .. ns.CharKey() .. "|r",
            "|cffffffff" .. ns.SpecName(ns.SpecID()) .. "|r"))
        active:SetText(format(L.activeProfile, "|cff33ff99" .. tostring(ns.activeProfile) .. "|r"))
        for _, row in ipairs(rows) do
            row.dd:Refresh()
        end
    end
    profileRefreshers[#profileRefreshers + 1] = refresh
    panel:SetScript("OnShow", refresh)
    refresh()

    return panel
end

--------------------------------------------------------------------
-- Bar style panel
--  Style, texture, font and the two colours. It has its own page for
--  one reason: the main page is full, and a canvas panel does not
--  scroll - controls added below the fold are simply not reachable.
--------------------------------------------------------------------
function ns.Options_BuildStylePanel()
    local panel = CreateFrame("Frame")
    panel.name = L.pageBarStyle
    panel:SetScript("OnHide", CloseMenu)
    ns.stylePanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ns.BRAND .. " - " .. L.pageBarStyle)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(560); sub:SetJustifyH("LEFT")
    sub:SetText(L.barStyleIntro)

    local where = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    where:SetPoint("TOPLEFT", 24, -100)
    where:SetJustifyH("LEFT")

    -- ---------------- preview ----------------
    -- Built from the same two functions the real bars use, so it cannot
    -- drift away from them - a preview that lies is worse than none.
    local previewBG = panel:CreateTexture(nil, "BACKGROUND")
    previewBG:SetPoint("TOPLEFT", 24, -128)
    previewBG:SetSize(440, 92)
    previewBG:SetColorTexture(0, 0, 0, 0.35)

    local previewLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    previewLabel:SetPoint("BOTTOMLEFT", previewBG, "TOPLEFT", 2, 3)
    previewLabel:SetText(L.lblPreview)

    local rows = {}
    for i, spec in ipairs({
        { key = "dots", icon = [[Interface\Icons\INV_Misc_QuestionMark]], name = L.previewDot, time = "12", count = "3" },
        { key = "hots", icon = [[Interface\Icons\INV_Misc_QuestionMark]], name = L.previewHot, time = "8",  count = "" },
    }) do
        local holder = CreateFrame("Frame", nil, panel)
        holder:SetPoint("TOPLEFT", previewBG, "TOPLEFT", 12, -12 - (i - 1) * 34)
        local row = ns.Bars_CreateRow(holder, { key = spec.key, r = 0.7, g = 0.15, b = 0.15 })
        row.preview = spec
        rows[#rows + 1] = row
    end

    local function refreshPreview()
        for _, row in ipairs(rows) do
            ns.Bars_ApplyRowStyle(row)
            -- The game fills these in on a real bar; here we do, because
            -- the point is the LOOK, and an empty row shows none of it.
            row.icon:SetTexture(row.preview.icon)
            row.bar:SetMinMaxValues(0, 1)
            row.bar:SetValue(row.preview.key == "dots" and 0.62 or 0.34)
            row.name:SetText(row.preview.name)
            row.time:SetText(row.preview.time)
            row.count:SetText(row.preview.count)
        end
    end

    -- ---------------- controls ----------------
    local y = -240

    local function AddDropdown(label, x, getItems, getSelected, onPick)
        local caption = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        caption:SetPoint("TOPLEFT", x, y)
        caption:SetText(label)
        local dd = CreateDropdown(panel, 200, getItems, getSelected, onPick)
        dd:SetPoint("TOPLEFT", x, y - 18)
        return dd
    end

    local styleDD = AddDropdown(L.lblStyle, 32,
        function()
            local out = {}
            for _, preset in ipairs(ns.BarPresets) do out[#out + 1] = preset.label end
            return out
        end,
        function() return ns.BarPresetFor(ns.db.bars.style).label end,
        function(label)
            for _, preset in ipairs(ns.BarPresets) do
                if preset.label == label then ns.db.bars.style = preset.key end
            end
            ns.Bars_Restyle()
        end)

    local textureDD = AddDropdown(L.lblBarTexture, 272,
        ns.TextureList,
        function() return ns.db.bars.texture end,
        function(name) ns.db.bars.texture = name; ns.Bars_Restyle() end)
    y = y - 56

    local fontDD = AddDropdown(L.lblFont, 32,
        ns.FontList,
        function() return ns.db.bars.font end,
        function(name) ns.db.bars.font = name; ns.Bars_Restyle() end)
    y = y - 56

    local function colorGetter(key)
        return function()
            local c = ns.db.bars[key]
            if type(c) ~= "table" then return 1, 1, 1 end
            return c.r or 1, c.g or 1, c.b or 1
        end
    end
    local function colorSetter(key)
        return function(r, g, b)
            ns.db.bars[key] = { r = r, g = g, b = b }
            ns.Bars_Restyle()
        end
    end

    local dotSwatch = CreateColorSwatch(panel, L.lblColorDots, 32, y,
        colorGetter("colorDot"), colorSetter("colorDot"))
    local hotSwatch = CreateColorSwatch(panel, L.lblColorHots, 272, y,
        colorGetter("colorHot"), colorSetter("colorHot"))

    -- ---------------- refresh ----------------
    local function refresh()
        where:SetText(format(L.editingProfile, "|cff33ff99" .. tostring(ns.activeProfile) .. "|r"))
        styleDD:Refresh()
        textureDD:Refresh()
        fontDD:Refresh()
        dotSwatch:Refresh()
        hotSwatch:Refresh()
        refreshPreview()
    end
    styleRefreshers[#styleRefreshers + 1] = refresh
    panel:SetScript("OnShow", refresh)
    refresh()

    return panel
end

-- resolved through L at call time, not captured: the route is a sentence

-- Every way into the settings - minimap button, addon compartment, /hnd -
-- comes through here, so this is the only place that has to get it right.
--
-- Settings.OpenToCategory ends in OpenSettingsPanel(), and that one is
-- PROTECTED. The game refuses it while the UI panel system is locked down
-- (combat), and refuses it outright once any other addon has tainted the
-- settings path - which on a loaded UI is a matter of when, not if.
--
-- Neither case is catchable. A blocked action is not a Lua error, so pcall
-- sees nothing at all: the click silently does nothing and the player gets
-- "ADDON BLOCKED: OpenSettingsPanel()" in their error log with HotsNDots'
-- name on it. So don't try in combat, and afterwards check whether the
-- panel actually came up - a button that cannot open the settings should
-- at least say where they are.
function ns.OpenConfig()
    if InCombatLockdown() then
        print(ns.BRAND .. ": " .. L.msgCombat)
        return
    end

    local attempted = false
    if ns.settingsCategory and Settings and Settings.OpenToCategory then
        -- Needs the category's NUMERIC id (category:GetID()), not a string -
        -- passing a string throws the OpenSettingsPanel range error.
        Settings.OpenToCategory(ns.settingsCategory:GetID())
        attempted = true
    elseif InterfaceOptionsFrame_OpenToCategory and ns.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
        attempted = true
    end

    if not attempted then
        print(ns.BRAND .. ": " .. L.msgManualRoute)
        return
    end

    -- A frame later the panel is either up, or the call was blocked.
    C_Timer.After(0, function()
        local panel = _G.SettingsPanel or _G.InterfaceOptionsFrame
        if panel and not panel:IsShown() then
            print(ns.BRAND .. ": " .. L.msgBlocked .. L.msgManualRoute)
        end
    end)
end

--------------------------------------------------------------------
-- The profile commands, kept together so the slash handler can refuse
-- all three at once when Profiles.lua has not been loaded yet.
--------------------------------------------------------------------
function ns.Slash_Profile(cmd, rest)
    if cmd == "profile" then
        if rest == "" then
            print(ns.BRAND .. ": " .. format(L.msgSpecUses, ns.SpecName(ns.SpecID()),
                "|cff33ff99" .. tostring(ns.activeProfile) .. "|r"))
            print(ns.BRAND .. ": /hnd profile <name>  |  /hnd profiles  |  /hnd newprofile <name>")
        elseif not ns.rawDB.profiles[rest] then
            print(ns.BRAND .. ": " .. format(L.msgNoSuchProfile, rest))
        else
            ns.Profiles_AssignCurrentSpec(rest)
            ns.Options_RefreshProfiles()
            print(ns.BRAND .. ": " .. format(L.msgSpecNowUses, ns.SpecName(ns.SpecID()),
                "|cffffffff" .. rest .. "|r"))
        end
    elseif cmd == "profiles" then
        print(ns.BRAND .. ": " .. format(L.msgProfileList,
            "|cff33ff99" .. tostring(ns.activeProfile) .. "|r"))
        for _, name in ipairs(ns.Profiles_List()) do
            print("   " .. (name == ns.activeProfile and "|cff33ff99" .. name .. "|r" or name))
        end
    elseif cmd == "newprofile" then
        local created, why = ns.Profiles_Create(rest)
        if not created then
            print(ns.BRAND .. ": " .. why)
        else
            ns.Profiles_AssignCurrentSpec(created)
            ns.Options_RefreshProfiles()
            print(ns.BRAND .. ": " .. format(L.msgCreated,
                "|cffffffff" .. created .. "|r", ns.SpecName(ns.SpecID())))
        end
    end
end

--------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------
SLASH_HOTSNDOTS1 = "/hotsndots"
SLASH_HOTSNDOTS2 = "/hnd"
-- kept so the old DotsNHots muscle memory still works
SLASH_HOTSNDOTS3 = "/dotsnhots"
SLASH_HOTSNDOTS4 = "/dnh"
SlashCmdList["HOTSNDOTS"] = function(msg)
    -- Only the COMMAND word is lowercased: a profile name is stored as
    -- typed, so "PvP" and "pvp" are two different profiles and the
    -- argument has to survive intact.
    local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
    cmd  = strlower(cmd or "")
    rest = strtrim(rest or "")

    if cmd == "lock" then
        ns.db.bars.locked = true
        ns.Bars_UpdateLock()
        ns.Options_Refresh()
        print(ns.BRAND .. ": " .. L.msgBarsLocked)
    elseif cmd == "unlock" then
        ns.db.bars.locked = false
        ns.Bars_UpdateLock()
        ns.Options_Refresh()
        print(ns.BRAND .. ": " .. L.msgBarsUnlocked)
    elseif cmd == "nameplates" then
        ns.db.nameplates.enabled = not ns.db.nameplates.enabled
        ns.Nameplates_RefreshAll()
        ns.Options_Refresh()
        print(ns.BRAND .. ": " .. format(L.msgNameplates,
            ns.db.nameplates.enabled and L.on or L.off))
    elseif cmd == "bars" then
        ns.db.bars.enabled = not ns.db.bars.enabled
        ns.Bars_Update()
        ns.Options_Refresh()
        print(ns.BRAND .. ": " .. format(L.msgBars, ns.db.bars.enabled and L.on or L.off))

    elseif cmd == "profile" or cmd == "profiles" or cmd == "newprofile" then
        if not ns.rawDB then
            print(ns.BRAND .. ": " .. L.msgProfilesLate)
            return
        end
        ns.Slash_Profile(cmd, rest)

    elseif cmd == "debug" then
        local version, build, _, iface = GetBuildInfo()
        print(ns.BRAND .. ": client " .. tostring(version) .. " (build " .. tostring(build) ..
            "), interface " .. tostring(iface))
        print(ns.BRAND .. ": AuraContainer = " ..
            (ns.hasAuraContainers and "usable (CustomAuraContainerTemplate)"
                                  or "MISSING - needs client 12.1.0"))
        print(ns.BRAND .. ": font = " .. tostring(ns.FONT_PATH))
        print(ns.BRAND .. ": minimap button = " ..
            (ns.ldbIcon and "LibDBIcon (collectable by Leatrix/ElvUI/...)"
                        or "built-in (no LibDBIcon around)"))
        -- Profiles.lua may not be loaded yet after a mid-session update,
        -- and /hnd debug is exactly what someone runs when things look
        -- wrong - so it must not be the next thing that throws.
        if ns.SpecName then
            print(ns.BRAND .. ": profile = " .. tostring(ns.activeProfile) .. " ("
                .. ns.SpecName(ns.SpecID()) .. " on " .. ns.CharKey() .. ")")
        else
            print(ns.BRAND .. ": profiles NOT loaded - restart WoW to finish the update.")
        end
        print(ns.BRAND .. ": nameplate filter = " .. ns.FilterString("HARMFUL", "INCLUDE_NAME_PLATE_ONLY"))
        print(ns.BRAND .. ": bar filter = " .. ns.FilterString("HELPFUL"))
        if ns.Nameplates_Debug then ns.Nameplates_Debug() end
        if ns.Bars_Debug then ns.Bars_Debug() end

        -- The one thing worth having: what actually broke at login, kept
        -- across reloads so it can still be read (and copied out of the
        -- saved variables) long after the message scrolled away.
        local e = ns.lastError or (HotsNDotsDB and HotsNDotsDB.lastError)
        if e then
            print(ns.BRAND .. ": |cffff4444last failure: " .. tostring(e.where)
                .. "|r (" .. tostring(e.at) .. ")")
            for line in tostring(e.message):gmatch("[^\n]+") do
                print("   " .. line)
            end
        else
            print(ns.BRAND .. ": no start-up failures recorded.")
        end
    elseif cmd == "minimap" then
        ns.global.minimap.hide = not ns.global.minimap.hide
        ns.Minimap_UpdateShown()
        ns.Options_Refresh()
        print(ns.BRAND .. ": " .. format(L.msgMinimapButton,
            ns.global.minimap.hide and L.off or L.on))
    else
        ns.OpenConfig()
    end
end
