# HotsNDots

**Track *only your own* DoTs and HoTs — big and clear.**

HotsNDots shows exclusively the auras **you** applied: your **DoTs/debuffs on enemies** and your **HoTs/buffs on friends**. Everything else is hidden, so you instantly see what *you* need to refresh — no more squinting at the tiny default nameplate auras.

It shows them **two ways at once**:

- 🎯 **On the nameplate** — large icons with a **seconds countdown**, cooldown swipe and stacks, sized well above the default WoW display.
- 📊 **As movable bars** — a clean, freely draggable bar list for your current target, with icon, spell name, a live timer and a depleting bar.

Works for **every class and spec**, for both **DoTs on enemies** and **HoTs/buffs on friends** (healers included), and in **every game language** — it never reads spell names, so localization is automatic.

---

## ✨ Features

- **Only your auras.** Filters to what you cast (optionally your pet too). No clutter from other players.
- **DoTs *and* HoTs.** Debuffs on enemies and buffs/HoTs on friends are both tracked automatically based on the unit.
- **Big nameplate icons** with an always-on **seconds countdown**, cooldown swipe and colored border (red = debuff, green = buff/HoT).
- **Real stacks only.** The stack number appears at 2+ applications and stays off single-application DoTs.
- **Replaces the default Blizzard nameplate auras** — turning nameplate icons on always hides Blizzard's own, so you never see both. Can sit **above or below** the nameplate.
- **Freely movable bars** for the current target — drag them anywhere, lock them in place.
- **Fully configurable** in-game settings screen: icon size, seconds font size, height above the nameplate, max icons, bar size, bar count, grow direction, and more.
- **Minimap button** (registered via LibDBIcon when available, so button collectors like Leatrix Plus' button bag pick it up) and a native **Addon Compartment** entry.
- **Slash commands** for quick toggling.
- **Lightweight & self-contained.** Ships no libraries and has no dependencies; it only *uses* LibDBIcon if some other addon already loaded it. No background timers — the countdown is driven by the game itself.
- **Midnight 12.0 ready.** Built around the new **Secret Values** system (`C_UnitAuras.GetAuraDuration`, `SetCooldownFromDurationObject`, `SetTimerDuration`, `GetAuraApplicationDisplayCount`).

---

## 📥 Installation

**Via CurseForge App:** search for *HotsNDots* and click Install.

**Manual:**
1. Download and unzip.
2. Copy the `HotsNDots` folder into:
   `World of Warcraft\_retail_\Interface\AddOns\`
   so that `...\AddOns\HotsNDots\HotsNDots.toc` exists.
3. Restart WoW. Enable *HotsNDots* on the character-select AddOns screen.

---

## 🎮 Usage

| Command | Action |
|---|---|
| `/hotsndots` or `/hnd` | Open the settings screen |
| `/hnd unlock` | Unlock the bars (then drag them) |
| `/hnd lock` | Lock the bars in place |
| `/hnd bars` | Toggle bars on/off |
| `/hnd nameplates` | Toggle nameplate icons on/off |
| `/hnd minimap` | Toggle the minimap button |
| `/hnd debug` | Print diagnostics (font, minimap route, nameplate aura container) |

The old `/dotsnhots` and `/dnh` aliases still work.

**Minimap button:** left click = settings, right click = lock/unlock bars, drag = reposition.

**Moving the bars:** `/hnd unlock`, drag the green anchor anywhere, then `/hnd lock`.

---

## 🎨 What the colors mean

- **Red** border / bar = a **debuff (DoT)** on an enemy.
- **Green** border / bar = a **buff / HoT** on a friend.

---

## ❓ FAQ

**Does it work for healers (HoTs on friendly units)?**
Yes. Enable friendly nameplates (`/console nameplateShowFriends 1`) to see HoT icons on friendly nameplates; the bars always track your current target regardless.

**Why does my 1-stack DoT not show a number?**
Because it shouldn't. The stack text only appears from 2 applications upwards, so a stacking DoT at 5 reads "5" while Unstable Affliction, Corruption and friends stay clean.

**Does it work in non-English clients?**
Yes. HotsNDots never reads spell names or IDs — it only passes the game's own (secret) data through to the display widgets — so it is language-independent.

**Is it heavy on performance?**
No. There is no polling loop; the seconds text, cooldown swipe and bar fill are updated by the game engine itself.

---

## 🛠️ For developers / About Secret Values

Midnight 12.0 made aura fields (`duration`, `expirationTime`, `icon`, `name`, `applications`, `sourceUnit`, `isHarmful`, ...) *secret*: they cannot be compared, calculated with, used in an `if` condition, or string-formatted in addon code. HotsNDots is built to be fully compliant:

- Player-cast filtering asks the C side via `C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HARMFUL|PLAYER")` — never a `sourceUnit` comparison, and never the (possibly secret) `isFromPlayerOrPlayerPet` flag on its own.
- Debuff vs. buff colouring goes through the same call with the `HARMFUL` filter, because `aura.isHarmful` can be secret and would throw inside an `if`.
- Remaining time comes from `C_UnitAuras.GetAuraDuration(unit, auraInstanceID)`. Building a Duration object yourself from `aura.expirationTime` does **not** work — the secret never makes it in, and you end up with missing or frozen timers.
- The seconds text is the `Cooldown` frame's own built-in countdown (a swipe-less Cooldown frame is used purely as a number), the only text widget that can render a secret remaining time.
- The cooldown swipe uses `Cooldown:SetCooldownFromDurationObject()`; the bar fill uses `StatusBar:SetTimerDuration()`.
- Stacks use `C_UnitAuras.GetAuraApplicationDisplayCount(unit, id, 2, 999)`, which decides C-side whether there is anything worth printing.
- Icons and names are passed straight into `SetTexture` / `SetText`.

---

## 📜 License

MIT — see [LICENSE](LICENSE). Contributions welcome.
