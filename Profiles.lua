--=====================================================================
--  HotsNDots - Profiles
--
--  Every setting that describes what the display LOOKS like lives in a
--  profile: filters, nameplate icons, bars and the bar anchor position.
--  Which profile a character uses is decided PER SPECIALIZATION, because
--  that is the thing that actually changes what you need on screen - a
--  Resto Druid watches HoTs, the same character as Balance watches two
--  DoTs on a nameplate. Switching spec therefore switches the layout,
--  without anyone having to remember to do it.
--
--  What is NOT in a profile: the minimap button. Its position and
--  visibility belong to the character's UI, not to a spec layout - a
--  button that jumps around the minimap on every spec change would be a
--  bug report, not a feature. It lives in db.global.
--
--  The stored shape is
--      HotsNDotsDB = {
--          dbVersion   = 4,
--          global      = { minimap = {...} },
--          profiles    = { ["Default"] = { filters/nameplates/bars }, ... },
--          profileKeys = { ["Name - Realm"] = { [specID] = "profile" } },
--      }
--  profileKeys is keyed by character and then by specialization ID (not
--  by the spec INDEX, which shifts whenever Blizzard reorders the tree).
--  ID 0 stands for "this character has no specialization yet".
--=====================================================================

local ADDON_NAME, ns = ...

local DEFAULT_PROFILE = "Default"
ns.DEFAULT_PROFILE = DEFAULT_PROFILE

--------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------
local function CharKey()
    local name  = UnitName("player") or "?"
    local realm = GetRealmName() or "?"
    return name .. " - " .. realm
end
ns.CharKey = CharKey

-- The spec ID, not the index. 0 = no spec (fresh character, or the API
-- answering before talent data is around) - that is a legitimate slot
-- and gets its own profile assignment like any other.
local function SpecID()
    if not GetSpecialization then return 0 end
    local index = GetSpecialization()
    if not index then return 0 end
    local id = GetSpecializationInfo(index)
    return id or 0
end
ns.SpecID = SpecID

function ns.SpecName(specID)
    if not specID or specID == 0 then return ns.L.noSpec end
    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(specID)
        if name then return name end
    end
    return format(ns.L.specNumbered, tostring(specID))
end

--------------------------------------------------------------------
-- Profile storage
--------------------------------------------------------------------
-- Only the display keys are profile data. Anything else that ever ends
-- up at the root of a profile table is left alone rather than deleted:
-- a future setting must not be silently thrown away by an old copy of
-- this list.
local PROFILE_KEYS = { "filters", "nameplates", "bars" }

local function NewProfile()
    local p = {}
    for _, key in ipairs(PROFILE_KEYS) do
        p[key] = ns.copyDefaults(ns.defaults[key], {})
    end
    return p
end

-- A deep copy, so two profiles never share a sub-table. Sharing would
-- make "copy from" silently link the two together, and that surfaces
-- much later as "editing one profile changes another".
local function DeepCopy(src)
    local out = {}
    for k, v in pairs(src) do
        if type(v) == "table" then out[k] = DeepCopy(v) else out[k] = v end
    end
    return out
end
ns.DeepCopy = DeepCopy

--------------------------------------------------------------------
-- Migrations that apply to ONE profile
--  These used to run once on the single flat settings table; with
--  profiles they have to run on each of them, because every profile
--  created from an old save carries the old values.
--------------------------------------------------------------------
local function UpgradeProfile(p, version)
    version = version or 0

    -- 1.1.0: "show stacks" changed meaning - it used to print the raw
    -- number on every aura (so a plain DoT read "1"). Opt everyone back in.
    if version < 1 then
        p.nameplates = p.nameplates or {}
        p.bars = p.bars or {}
        p.nameplates.showStacks = true
        p.bars.showStacks = true
    end

    -- 1.4.0: the display belongs to the game now; settings that only made
    -- sense for the old hand-rolled scanner are dropped.
    if version < 2 then
        p.watch      = nil -- learned spell names of the by-name fallback
        p.includePet = nil -- "PLAYER" always covers pet/vehicle now
        p.onlyMine   = nil -- was never anything but true
        if p.nameplates then p.nameplates.hideBlizzard = nil end
    end

    -- 1.4.1: one "hide auras without a timer" switch became two. The old
    -- one only ever hid raid buffs on purpose; applying it to debuffs as
    -- well swallowed permanent DoTs like Absolute Corruption.
    if version < 3 then
        p.filters = p.filters or {}
        if p.filters.hidePermanent ~= nil then
            p.filters.hidePermanentBuffs = p.filters.hidePermanent
            p.filters.hidePermanent = nil
        end
        p.filters.hidePermanentDebuffs = false
    end

    for _, key in ipairs(PROFILE_KEYS) do
        p[key] = ns.copyDefaults(ns.defaults[key], p[key] or {})
    end
    return p
end

--------------------------------------------------------------------
-- Setup / migration of the whole DB
--------------------------------------------------------------------
function ns.Profiles_Setup(db)
    local version = db.dbVersion or 0

    -- 1.5.0: flat settings become profiles. Everything that was on the
    -- root moves into "Default" and this character's current spec keeps
    -- following it, so the first login after the update looks exactly
    -- like the last one before it.
    if not db.profiles then
        local carried = {}
        for _, key in ipairs(PROFILE_KEYS) do
            carried[key] = db[key]
            db[key] = nil
        end
        -- pre-1.4 leftovers the per-profile migration still wants to see
        carried.watch,      db.watch      = db.watch, nil
        carried.includePet, db.includePet = db.includePet, nil
        carried.onlyMine,   db.onlyMine   = db.onlyMine, nil

        db.profiles = { [DEFAULT_PROFILE] = carried }
    end

    db.global = db.global or {}
    db.global.minimap = ns.copyDefaults(ns.defaults.minimap, db.global.minimap or db.minimap or {})
    db.minimap = nil

    for _, p in pairs(db.profiles) do
        UpgradeProfile(p, version)
    end
    if not db.profiles[DEFAULT_PROFILE] then
        db.profiles[DEFAULT_PROFILE] = NewProfile()
    end

    db.profileKeys = db.profileKeys or {}
    db.dbVersion = 4

    ns.rawDB  = db
    ns.global = db.global
    ns.Profiles_Activate(ns.Profiles_CurrentName(), true)
end

--------------------------------------------------------------------
-- Which profile is this character/spec on
--------------------------------------------------------------------
local function KeysForChar(create)
    local db = ns.rawDB
    local char = CharKey()
    local t = db.profileKeys[char]
    if not t and create then
        t = {}
        db.profileKeys[char] = t
    end
    return t
end

-- Name of the profile this character's CURRENT spec should use. An
-- unassigned spec resolves to Default rather than being written to the
-- save on sight: a character that never opens the options should not
-- accumulate entries.
function ns.Profiles_CurrentName()
    local t = KeysForChar(false)
    local name = t and t[SpecID()]
    if name and ns.rawDB.profiles[name] then return name end
    return DEFAULT_PROFILE
end

-- Which profile a given spec of this character uses. A name that no
-- longer exists (profile deleted on another character, then this one
-- logged in) reads as Default instead of leaving the caller with a
-- dangling string.
function ns.Profiles_AssignedTo(specID)
    local t = KeysForChar(false)
    local name = t and t[specID]
    if name and ns.rawDB.profiles[name] then return name end
    return DEFAULT_PROFILE
end

-- Point one spec at a profile. Assigning Default CLEARS the entry
-- instead of storing it: a spec that has never chosen anything should
-- keep following whatever Default is, and an explicit "Default" and no
-- entry at all mean exactly the same thing.
function ns.Profiles_AssignSpec(specID, name)
    local t = KeysForChar(true)
    if name == DEFAULT_PROFILE then
        t[specID] = nil
    else
        t[specID] = name
    end
    -- Assigning the spec you are actually in takes effect immediately;
    -- assigning another one is a note for later.
    if specID == SpecID() then
        ns.Profiles_Activate(name, true)
    end
end

function ns.Profiles_AssignCurrentSpec(name)
    ns.Profiles_AssignSpec(SpecID(), name)
end

function ns.Profiles_List()
    local out = {}
    for name in pairs(ns.rawDB.profiles) do out[#out + 1] = name end
    table.sort(out, function(a, b)
        -- Default first, then alphabetical: it is the one profile that is
        -- always there, so it should not wander around the list.
        if a == DEFAULT_PROFILE then return true end
        if b == DEFAULT_PROFILE then return false end
        return a:lower() < b:lower()
    end)
    return out
end

--------------------------------------------------------------------
-- Activating a profile
--  ns.db is what every other file reads, so switching profile is
--  literally repointing it and then pushing the new values through the
--  same paths an options change uses.
--------------------------------------------------------------------
local function PushProfileToDisplay()
    if not ns.hasAuraContainers then return end
    -- The bar anchor position lives in the profile, so it has to be moved
    -- as well - that is the "different arrangement per spec" half of the
    -- feature and no restyle covers it.
    if ns.Bars_ApplyPosition then ns.Bars_ApplyPosition() end
    if ns.Bars_Restyle       then ns.Bars_Restyle()       end
    if ns.Bars_UpdateLock    then ns.Bars_UpdateLock()    end
    if ns.Nameplates_Restyle then ns.Nameplates_Restyle() end
end
ns.Profiles_PushToDisplay = PushProfileToDisplay

function ns.Profiles_Activate(name, quiet)
    local db = ns.rawDB
    local profile = db.profiles[name]
    if not profile then
        name = DEFAULT_PROFILE
        profile = db.profiles[name]
    end

    local changed = ns.db ~= profile
    ns.db = profile
    ns.activeProfile = name

    if changed then
        PushProfileToDisplay()
        if ns.Options_Refresh then ns.Options_Refresh() end
        if not quiet then
            print(ns.BRAND .. ": " .. format(ns.L.msgProfileNow, "|cffffffff" .. name .. "|r"))
        end
    else
        if ns.Options_Refresh then ns.Options_Refresh() end
    end
    return name
end

-- Re-resolve the assignment for whatever spec the player is in now.
function ns.Profiles_ApplyForSpec(quiet)
    return ns.Profiles_Activate(ns.Profiles_CurrentName(), quiet)
end

--------------------------------------------------------------------
-- Management
--  These return nil plus a reason instead of printing: the caller
--  (options panel, slash command) knows how it wants to complain.
--------------------------------------------------------------------
function ns.Profiles_Create(name, copyFrom)
    name = strtrim(name or "")
    if name == "" then return nil, ns.L.errNeedsName end
    if ns.rawDB.profiles[name] then return nil, ns.L.errExists end

    local source = copyFrom and ns.rawDB.profiles[copyFrom]
    ns.rawDB.profiles[name] = source and UpgradeProfile(DeepCopy(source), 4) or NewProfile()
    return name
end

function ns.Profiles_Delete(name)
    if name == DEFAULT_PROFILE then return nil, ns.L.errDefaultKeep end
    if not ns.rawDB.profiles[name] then return nil, ns.L.errNoSuch end

    ns.rawDB.profiles[name] = nil

    -- Every character/spec that pointed at it falls back to Default,
    -- across the whole account: a dangling name would show up on another
    -- character as "my settings are gone".
    for _, specs in pairs(ns.rawDB.profileKeys) do
        for spec, assigned in pairs(specs) do
            if assigned == name then specs[spec] = nil end
        end
    end

    ns.Profiles_ApplyForSpec(true)
    return true
end

-- Overwrite a profile table IN PLACE. ns.db and the assignments keep
-- pointing at the same table, so nothing has to be repointed - which is
-- what makes "reset" and "copy from" safe while the profile is active.
local function Overwrite(target, contents)
    for k in pairs(target) do target[k] = nil end
    for k, v in pairs(contents) do target[k] = v end
    return UpgradeProfile(target, 4)
end

function ns.Profiles_Reset(name)
    name = name or ns.activeProfile
    local target = ns.rawDB.profiles[name]
    if not target then return nil, ns.L.errNoSuch end

    Overwrite(target, NewProfile())
    if name == ns.activeProfile then
        PushProfileToDisplay()
        if ns.Options_Refresh then ns.Options_Refresh() end
    end
    return true
end

function ns.Profiles_Copy(fromName)
    local source = ns.rawDB.profiles[fromName]
    if not source then return nil, ns.L.errNoSuch end
    if fromName == ns.activeProfile then return nil, ns.L.errSameProfile end

    Overwrite(ns.rawDB.profiles[ns.activeProfile], DeepCopy(source))
    PushProfileToDisplay()
    if ns.Options_Refresh then ns.Options_Refresh() end
    return true
end
