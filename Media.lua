--=====================================================================
--  HotsNDots - Media
--  Bar textures and fonts, by NAME.
--
--  Two rules hold this together:
--
--  * What gets stored is a name, never a path. A path in the save file
--    is a promise about someone else's addon folder - it goes stale the
--    moment a media pack is updated or removed, and a StatusBar with a
--    dead texture path draws NOTHING. An unknown name, by contrast, can
--    simply fall back.
--  * LibSharedMedia is used if it is there and not required. It is what
--    every media pack registers into, so a player who already has one
--    sees their whole collection here. Without it there is still a small
--    built-in list of textures the GAME ships, so the setting is never
--    empty and nothing has to be shipped with this addon.
--=====================================================================

local ADDON_NAME, ns = ...

--------------------------------------------------------------------
-- Built-ins: paths that exist in the client itself
--  Kept deliberately short. A wrong path here is invisible - the bar
--  just stops being drawn - so this list only contains textures that
--  are demonstrably there, and everything else comes from a media
--  library that vouches for its own paths.
--------------------------------------------------------------------
--  The NAMES are LibSharedMedia's own, deliberately. A pick is stored by
--  name, so identical names mean a texture chosen on a client without the
--  library still resolves on one with it, and the other way round - the
--  setting survives installing or removing a media pack. The paths are the
--  ones the library itself vouches for, which is also why this list is
--  exactly as long as it is: those four are everything LSM ships on its
--  own. Everything beyond them comes from media packs, never from LSM.
local TEXTURES = {
    ["Blizzard"]                      = [[Interface\TargetingFrame\UI-StatusBar]],
    ["Blizzard Character Skills Bar"] = [[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]],
    ["Blizzard Raid Bar"]             = [[Interface\RaidFrame\Raid-Bar-Hp-Fill]],
    ["Solid"]                         = [[Interface\Buttons\WHITE8X8]],
}

--  Fonts that ship with the client. NOT offered on a CJK client: those
--  faces cannot render Korean or Chinese, and a font that draws boxes
--  does not fail - ns.SetFont only catches a font that cannot be SET, so
--  nothing would fall back and the player would just have unreadable
--  timers. "Default" is derived from a real Blizzard font object and is
--  therefore correct in every locale, which is why it is always there.
local FONTS = { ["Default"] = true }
do
    local locale = GetLocale and GetLocale() or "enUS"
    if locale ~= "koKR" and locale ~= "zhCN" and locale ~= "zhTW" then
        FONTS["Arial Narrow"] = [[Fonts\ARIALN.TTF]]
        FONTS["Skurri"]       = [[Fonts\SKURRI_CYR.TTF]]
        FONTS["Morpheus"]     = [[Fonts\MORPHEUS_CYR.TTF]]
        FONTS["2002"]         = [[Fonts\2002.TTF]]
    end
end

local DEFAULT_TEXTURE = "Blizzard"
local DEFAULT_FONT    = "Default"

--------------------------------------------------------------------
-- LibSharedMedia, if some addon (or we ourselves) loaded it
--  Looked up lazily and cached: LibStub libraries are registered while
--  addons load, so asking at file scope would answer for the load order
--  rather than for the session.
--------------------------------------------------------------------
local lsm
local function SharedMedia()
    if lsm == nil then
        local found
        if LibStub then
            -- the second argument makes LibStub return nil instead of
            -- throwing when the library is not there
            local ok, lib = pcall(LibStub, "LibSharedMedia-3.0", true)
            found = ok and lib or nil
        end
        lsm = found or false
    end
    return lsm or nil
end
ns.SharedMedia = SharedMedia

local function ListOf(mediaType, builtins, defaultName)
    local out, seen = {}, {}
    for name in pairs(builtins) do
        out[#out + 1] = name
        seen[name] = true
    end

    local lib = SharedMedia()
    if lib then
        for _, name in ipairs(lib:List(mediaType) or {}) do
            if not seen[name] then
                out[#out + 1] = name
                seen[name] = true
            end
        end
    end

    table.sort(out, function(a, b)
        -- the default first, so the list always starts where the addon does
        if a == defaultName then return true end
        if b == defaultName then return false end
        return a:lower() < b:lower()
    end)
    return out
end

--------------------------------------------------------------------
-- Textures
--------------------------------------------------------------------
function ns.TextureList()
    return ListOf("statusbar", TEXTURES, DEFAULT_TEXTURE)
end

function ns.TexturePath(name)
    -- Ours first: those three are guaranteed, and a media pack that
    -- happens to reuse one of the names points at the same art anyway.
    if name and TEXTURES[name] then return TEXTURES[name] end

    local lib = SharedMedia()
    if lib and name then
        -- Fetch(..., true) answers nil for an unknown name instead of
        -- quietly handing back the library's own default - which is the
        -- difference between "your pick is gone, here is ours" and
        -- "your pick is gone, and you will never find out".
        local path = lib:Fetch("statusbar", name, true)
        if path then return path end
    end
    return TEXTURES[DEFAULT_TEXTURE]
end

--------------------------------------------------------------------
-- Fonts
--  "Default" is the font the whole addon already derives from a real
--  Blizzard font object, which is also the only one that is correct on
--  a CJK or RU client.
--------------------------------------------------------------------
function ns.FontList()
    return ListOf("font", FONTS, DEFAULT_FONT)
end

function ns.FontPath(name)
    if not name or name == DEFAULT_FONT then return ns.FONT_PATH end

    local builtin = FONTS[name]
    if type(builtin) == "string" then return builtin end

    local lib = SharedMedia()
    if lib then
        local path = lib:Fetch("font", name, true)
        if path then return path end
    end
    return ns.FONT_PATH
end
