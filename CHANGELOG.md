# DotsNHots – Changelog

## 1.0.0
- First public release.
- Tracks **only your own** auras: DoTs/debuffs on enemies, HoTs/buffs on friends.
- Large **nameplate icons** with an always-on **seconds countdown**, cooldown swipe,
  colored border (red = debuff, green = buff/HoT) and optional stacks.
- Option to **hide/replace the default Blizzard nameplate auras**, and to place the
  icons **above or below** the nameplate.
- Freely **movable bars** for the current target (icon, name, live timer, depleting bar).
- In-game **settings screen**, **minimap button** and native **Addon Compartment** entry.
- Slash commands: `/dotsnhots` (`/dnh`) with `lock`, `unlock`, `bars`, `nameplates`, `minimap`.
- Fully **Midnight 12.0 "Secret Values"** compliant:
  Duration objects, Blizzard's built-in Cooldown countdown numbers,
  `Cooldown:SetCooldownFromDurationObject` and `StatusBar:SetTimerDuration`.
- Language-independent (never reads spell names/IDs).
