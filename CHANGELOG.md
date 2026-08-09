# HotsNDots – Changelog

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
