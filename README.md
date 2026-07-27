# DotsNHots

**Track *only your own* DoTs and HoTs — big and clear.**

DotsNHots shows exclusively the auras **you** applied: your **DoTs/debuffs on enemies** and your **HoTs/buffs on friends**. Everything else is hidden, so you instantly see what *you* need to refresh — no more squinting at the tiny default nameplate auras.

It shows them **two ways at once**:

- 🎯 **On the nameplate** — large icons with a **seconds countdown**, cooldown swipe and (optional) stacks, sized well above the default WoW display.
- 📊 **As movable bars** — a clean, freely draggable bar list for your current target, with icon, spell name, a live timer and a depleting bar.

Works for **every class and spec**, for both **DoTs on enemies** and **HoTs/buffs on friends** (healers included), and in **every game language** — it never reads spell names, so localization is automatic.

---

## ✨ Features

- **Only your auras.** Filters to what you cast (optionally your pet too). No clutter from other players.
- **DoTs *and* HoTs.** Debuffs on enemies and buffs/HoTs on friends are both tracked automatically based on the unit.
- **Big nameplate icons** with an always-on **seconds countdown**, cooldown swipe and colored border (red = debuff, green = buff/HoT).
- **Replaces the default Blizzard nameplate auras** (hides them so yours are the only ones shown), and can sit **above or below** the nameplate.
- **Freely movable bars** for the current target — drag them anywhere, lock them in place.
- **Fully configurable** in-game settings screen: icon size, seconds font size, height above the nameplate, max icons, bar size, bar count, grow direction, and more.
- **Minimap button** and native **Addon Compartment** entry to open the settings.
- **Slash commands** for quick toggling.
- **Lightweight & self-contained.** No external libraries, no background timers — the countdown is driven by the game itself.
- **Midnight 12.0 ready.** Built from the ground up around the new **Secret Values** system (Duration objects, `DurationTextBinding`, `SetCooldownFromDurationObject`, `SetTimerDuration`).

---

## 📥 Installation

**Via CurseForge App:** search for *DotsNHots* and click Install.

**Manual:**
1. Download and unzip.
2. Copy the `DotsNHots` folder into:
   `World of Warcraft\_retail_\Interface\AddOns\`
   so that `...\AddOns\DotsNHots\DotsNHots.toc` exists.
3. Restart WoW. Enable *DotsNHots* on the character-select AddOns screen.

---

## 🎮 Usage

| Command | Action |
|---|---|
| `/dotsnhots` or `/dnh` | Open the settings screen |
| `/dnh unlock` | Unlock the bars (then drag them) |
| `/dnh lock` | Lock the bars in place |
| `/dnh bars` | Toggle bars on/off |
| `/dnh nameplates` | Toggle nameplate icons on/off |
| `/dnh minimap` | Toggle the minimap button |

**Minimap button:** left click = settings, right click = lock/unlock bars, drag = reposition.

**Moving the bars:** `/dnh unlock`, drag the green anchor anywhere, then `/dnh lock`.

---

## 🎨 What the colors mean

- **Red** border / bar = a **debuff (DoT)** on an enemy.
- **Green** border / bar = a **buff / HoT** on a friend.

---

## ❓ FAQ

**Does it work for healers (HoTs on friendly units)?**
Yes. Enable friendly nameplates (`/console nameplateShowFriends 1`) to see HoT icons on friendly nameplates; the bars always track your current target regardless.

**Why is the stack number off by default?**
Since Midnight (12.0), aura data is *secret* — addons may no longer compare values like "stacks > 1", so single-stack auras can't be hidden. Stacks are therefore **off by default**; enable them in the settings if you track stacking DoTs/HoTs (the number will then show on every aura, including `1`).

**Does it work in non-English clients?**
Yes. DotsNHots never reads spell names or IDs — it only passes the game's own (secret) data through to the display widgets — so it is language-independent.

**Is it heavy on performance?**
No. There is no polling loop; the seconds text, cooldown swipe and bar fill are updated by the game engine itself.

---

## 🛠️ For developers / About Secret Values

Midnight 12.0 made aura fields (`duration`, `expirationTime`, `icon`, `name`, `applications`, `sourceUnit`, ...) *secret*: they cannot be compared, calculated with, or string-formatted in addon code. DotsNHots is built to be fully compliant:

- Player-cast filtering uses the C-side `HARMFUL|PLAYER` / `HELPFUL|PLAYER` filters and the readable `isFromPlayerOrPlayerPet` boolean — never a `sourceUnit` comparison.
- Remaining time uses `C_DurationUtil.CreateDuration()` + `DurationObject:SetTimeFromEnd(...)`.
- The seconds use Blizzard's built-in Cooldown countdown numbers (`SetHideCountdownNumbers(false)` on a cooldown driven by `SetCooldownFromDurationObject`), so they render exactly like the default UI, correctly localized, with no secret-value handling on our side.
- The cooldown swipe uses `Cooldown:SetCooldownFromDurationObject()`.
- The bar fill uses `StatusBar:SetTimerDuration()`.
- Icons, names and stacks are passed straight into `SetTexture` / `SetText`.

---

## 📜 License

MIT — see [LICENSE](LICENSE). Contributions welcome.
