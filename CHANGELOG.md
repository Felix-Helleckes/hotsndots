# HotsNDots – Changelog

## 1.4.1
- **Permanent DoTs are visible again.** "Hide auras without a timer" was one
  switch for both kinds, and it filtered debuffs as well - so an Affliction
  warlock running **Absolute Corruption**, which makes Corruption last until the
  target dies, saw no Corruption at all. The game rejects these C-side as
  `duration > maxDuration or duration == 0`, and the `duration == 0` half was
  never meant to apply to your DoTs.
  It is now **two** switches: *Hide buffs without a timer* (still on - your own
  raid buffs never expire and would sit in the capped slots forever) and *Hide
  debuffs without a timer* (**off**, so permanent DoTs show). An existing setting
  carries over to the buff switch; the debuff switch starts off either way.

## 1.4.0
- **Rebuilt on Blizzard's AuraContainer.** 12.1.0 finished closing the door on
  addon aura access: every `C_UnitAuras` call that reaches an aura by index,
  slot or instance ID now raises a Lua error while auras are secret (combat,
  encounters, M+, rated PvP), and `UNIT_AURA` carries a fully secret payload.
  1.2.x and 1.3.x worked around that — first by going quiet, then by asking for
  spells by name — and both left the display worse than it was.
  HotsNDots no longer looks at aura data at all. It creates an **AuraContainer**
  per nameplate and one for the bars, tells the game what it wants (a filter
  string plus candidate filters) and hands over plain regions to draw into. The
  game picks the auras and writes the icon, the countdown and the stacks itself.
  Everything works in combat again, including the seconds and the stack numbers,
  and there is nothing left for the client to refuse.
- **Fixed the Lua error flood on nameplates.**
  `UnitFrame.lua:777: attempt to compare local 'currValue' (a secret number
  value, while execution tainted by 'HotsNDots'` — several times per second per
  nameplate. Hiding Blizzard's nameplate auras meant calling `Hide()` on its
  aura frame and storing lookup fields on its `UnitFrame`, which tainted the
  nameplate; since 12.1 a tainted nameplate cannot even update its own mana bar.
  HotsNDots now treats the Blizzard nameplate as read-only: it anchors to it and
  touches nothing else.
- **The default nameplate auras are no longer hidden.** There is no taint-free
  way left to do it, and doing it anyway is what caused the errors above. Blizzard's
  own nameplate aura display can be turned down in the game's Nameplate options.
- **Removed "also count pet auras".** The game's `PLAYER` filter now always
  covers your pet's and your vehicle's auras, so there is no separate filter
  left to ask for — pet DoTs are simply included.
- The learned-spell list of the 1.3.x by-name fallback is dropped from your saved
  variables, along with `/hnd forget`. `/hnd debug` now reports the client build,
  whether AuraContainer is usable, and the filter strings actually in use.
- Icon size, bar size, fonts and the stack toggle reach buttons the game owns, so
  they can only be applied while auras are not secret. Changing them mid-fight is
  remembered and applied the moment you leave combat.
- `## Interface` bumped to **120100** (client 12.1.0). The .toc still claimed
  12.0.7, so the addon was flagged out of date.

## 1.3.1
- **No more "learn it first".** The combat fallback needs to know which spells
  to ask for; 1.3.0 could only learn that by watching you cast. The list is now
  seeded from your **spellbook** at login, on spec change and when your spells
  change, so a fresh character works from the first pull. Passives and other
  specs' tabs are skipped. Anything it still sees you apply is added on top.
- The by-name sweep is **throttled per unit** (0.2 s). It costs one API call per
  spell per filter, and `UNIT_AURA` fires constantly in combat, so results are
  briefly cached instead of re-queried on every event.
- `## Interface` corrected to **120100** — the client is 12.1.0, the .toc still
  claimed 12.0.7.

## 1.3.0
- **Your DoTs are visible in combat again.** 1.2.2 stopped the error flood but
  left the display blank exactly when it mattered. Enumeration stays refused
  while auras are secret, but the API rules document one exception: lookups by
  spell **name or ID** remain callable. HotsNDots now uses that door.
  - While auras are readable (out of combat, and the readable moment at the
    pull) it **learns the names** of the auras you apply, stored per class.
  - Once enumeration is refused, it looks those names up one by one with
    `C_UnitAuras.GetAuraDataBySpellName` and shows what comes back.
  - `/hnd debug` lists the learned spells; `/hnd forget` clears them.
- Every instance-ID based call (`GetAuraDuration`,
  `GetAuraApplicationDisplayCount`, `IsAuraFilteredOutByInstanceID`) now
  degrades instead of throwing, since those are refused while secret too.
  Debuff/buff colouring is remembered during the scan instead of being asked
  per icon, so it keeps working.

> **Limitations of the fallback, honestly:** only spells HotsNDots has already
> seen you cast can appear — a brand new character shows nothing until the
> first fight. Countdowns and stack numbers are unavailable while auras are
> secret, so you get the icon without the seconds. The "hide auras without a
> timer" and "hide crowd control" filters are skipped in that mode. Individual
> spells can still come back empty if the client keeps them secret by name too.

## 1.2.2
- **Stopped the Lua error flood in combat.** Since Midnight, *every* way of
  enumerating auras — by index, by slot, by instance ID, and Blizzard's own
  `AuraUtil.ForEachAura` — raises
  `Auras cannot be accessed when secret while tainted by 'HotsNDots'`
  while the auras are secret, which they are in combat, encounters, M+ and
  rated PvP. 1.2.1 swapped one blocked call for another; the whole approach is
  what Blizzard closed off.
  HotsNDots now detects the rejection, remembers it per unit so it stops
  retrying, hides its icons and bars instead of showing stale data, and says so
  once in chat. The state is dropped when you leave combat or zone, so the
  display comes back on its own.
- `/hnd debug` reports whether the `AuraContainer` widget (Blizzard's sanctioned
  replacement, added in 12.1.0) exists on your client.

> **Known limitation:** icons and bars are blank while auras are secret. Fixing
> that properly means rebuilding the display on `AuraContainer`/`AuraGroup`,
> where the game owns the buttons and the addon never touches aura data.

## 1.2.1
- **Fixed a flood of Lua errors in combat:**
  `GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by
  'HotsNDots'`. Index-based aura enumeration is rejected for addon code as soon
  as the auras are secret, which they are for hostile units in combat — so the
  error fired once per aura, per nameplate, per update. Scanning now goes
  through `AuraUtil.ForEachAura` (as it did before 1.1.0) with a direct
  `C_UnitAuras.GetAuraSlots` / `GetAuraDataBySlot` fallback. That is the same
  path every library scanning arbitrary units uses.
- The slot fallback walks the returned slots as varargs. Packing
  `(continuationToken, slot1, ...)` into a table leaves a hole once the token is
  nil on the last batch, which silently truncated the aura list.

## 1.2.0
- **Aura filters.** "Cast by me" is not the same as "worth watching", and the
  icon/bar count is capped — so junk auras used to push real DoTs out of the
  display. New **Filters** section in the settings:
  - **Show debuffs** / **Show buffs** — track only your DoTs, only your HoTs,
    or both.
  - **Hide auras without a timer** (*on by default*) — drops your own
    Fortitude, Arcane Intellect, Mark of the Wild and other permanent buffs.
    They have no countdown, so this addon has nothing to show for them.
  - **Hide crowd control** — keeps your Fear/Polymorph out of the DoT list.

  All of it is decided C-side (`IsAuraFilteredOutByInstanceID`,
  `GetAuraDuration`), so no secret value is ever read.
- `/hnd debug` now also lists your auras on the current target and reports
  which fields the client keeps secret. A blacklist of individual spells is
  only possible where `spellId` comes back readable — this tells you whether
  that is the case before anyone builds one.

## 1.1.1
- **Fixed invisible spell names and stack numbers.** Every font string was set
  up with `STANDARD_TEXT_FONT`, which is *not* a Blizzard global — some addons
  (ElvUI) define it, so it worked on some setups and silently left the text
  with no font at all on others. The font path now comes from a real Blizzard
  font object, which is also correct on CJK/RU clients.
- **The default Blizzard nameplate auras are now actually gone** whenever
  nameplate icons are on. `HookScript("OnShow")` only fires on a hidden→shown
  transition, so a recycled nameplate kept its default icons; `Show()` itself is
  hooked now, the state is re-asserted on every refresh, and the aura container
  is looked up by several possible field names instead of one hard-coded guess.
- **Removed the "Hide default Blizzard auras" option** — showing both sets at
  once was never useful. "Show nameplate icons" now implies replacing them.
- **The minimap button is registered through LibDBIcon** when any loaded addon
  provides it, so button collectors (Leatrix Plus' button bag, ElvUI, MoveAny)
  can find it. Falls back to the built-in button when the library is absent, so
  HotsNDots still ships without dependencies.
- Added `/hnd debug`, which reports the resolved font, the minimap route and
  what it found as the default nameplate aura container.

## 1.1.0
- **Renamed to HotsNDots** everywhere (folder, `.toc`, settings screen, minimap
  button, addon compartment, chat output) so the in-game name matches the
  CurseForge project. New slash commands `/hotsndots` and `/hnd`; the old
  `/dotsnhots` and `/dnh` still work, and existing settings are carried over.
- **Fixed missing and wrong timers.** Remaining time now comes from
  `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)` — the Duration object the
  game builds itself — instead of a hand-built `C_DurationUtil` duration fed
  from the (secret) `expirationTime`, which silently failed on many auras. When
  an aura has no duration, or an icon/bar is reused for a different aura, the
  countdown, swipe and bar fill are now explicitly cleared, so a slot can no
  longer keep showing the previous aura's time.
- **Fixed stacks.** The stack number is decided C-side by
  `C_UnitAuras.GetAuraApplicationDisplayCount` and only appears at 2 or more
  applications — single-application DoTs like Unstable Affliction no longer get
  a bogus "1". Stacks are therefore **on by default** now, and the bars show
  them too.
- The countdown text is Blizzard's own cooldown countdown (drawn by a
  swipe-less `Cooldown` frame), the only text that can display a secret
  remaining time. It is styled and positioned like before: big seconds above
  the nameplate icon, right-aligned on the bars.
- Aura scanning no longer reads `isHarmful` / `isFromPlayerOrPlayerPet`
  directly — both can be secret and would throw when used in a condition.
  Ownership and debuff/buff colouring now go through
  `C_UnitAuras.IsAuraFilteredOutByInstanceID`.
- Removed the blanket `pcall` wrappers that were hiding all of the above.

## 1.0.0
- First public release (as DotsNHots).
- Tracks **only your own** auras: DoTs/debuffs on enemies, HoTs/buffs on friends.
- Large **nameplate icons** with a **seconds countdown**, cooldown swipe,
  colored border (red = debuff, green = buff/HoT) and optional stacks.
- Option to **hide/replace the default Blizzard nameplate auras**, and to place the
  icons **above or below** the nameplate.
- Freely **movable bars** for the current target (icon, name, live timer, depleting bar).
- In-game **settings screen**, **minimap button** and native **Addon Compartment** entry.
- Language-independent (never reads spell names/IDs).
