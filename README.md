# TakeMeHome

A World of Warcraft addon by **SpoonoTV** that started as a quick hearthstone launcher and grew into a full **Titan Panel rival** — floating action windows, a dual persistent info bar, smart travel shortcuts, and rich live tooltips.

---

## Features

### Floating Windows
Movable, lockable windows with drag-to-snap and group-linking:

| Window | Contents |
|---|---|
| **Travel** | Hearthstones, Dalaran HS, Garrison HS, Arcantina Key, Mailbox, Warband Bank, Mobile Banking, Druid Dreamwalk/Moonglade |
| **Professions** | One-click profession UI openers for all learned professions |
| **Mounts** | Up to 6 user-selected mounts + Druid Travel Form |
| **Function** | Logout button |
| **Missions** | WoD / Legion / BfA / Shadowlands mission table launchers |
| **To Do List** | Account and Character task lists, organized into collapsible groups — add, edit, check off, and delete tasks freely |

**Window features:**
- Drag within 20px of another window to auto-snap and link — linked windows move together
- Right-click any drag banner → context menu (lock, settings, unlink)
- Minimap button (draggable around the ring) — left-click toggles all windows

---

### Dual Info Bar
A persistent full-width bar docked to the **bottom** and/or **top** of the screen. Both bars are independently enabled in Settings → Info Bar. Every module can be assigned to either bar.

**Left section (character/location):**
- Zone / Subzone
- Coordinates — left-click opens map, right-click drops a **TomTom waypoint** (falls back to pre-filling chat)
- Item Level (equipped)
- Reputation (watched faction, % to next standing)
- HS Cooldown — live countdown per hearthstone, green "Ready" when available
- Specialization — right-click opens a **spec-switch dropdown** with icons

**Centre section (resources):**
- Gold — formatted with g/s/c colour coding
- Bags — free/total slots, colour-coded when low
- Durability — lowest equipped item %, colour-coded
- XP — progress % (hidden at max level)
- Session Gold — net +/- since login
- Daily Gold — net +/- since midnight, resets automatically each day
- Warband Gold — combined gold across every character on your account, including Warband Bank
- Currency — watched currency with cap colour-coding
- Keystone — owned Mythic+ key level and dungeon name
- Todo Count — pending/done task counts for account and character scope
- Played Time — live-updating total time played on this character

**Right section (system):**
- FPS — colour-coded by performance
- Latency — home/world ms, colour-coded
- Local Time
- Server Time
- Friends / Guild online count

**Bottom bar extras (left of modules):**
- Window toggle icons — dim when the window is hidden, click to show/hide
- ATT button — All The Things expansion dropdown (if ATT is loaded)
- Quick-cast HS — smart hearthstone button; picks the item with the shortest cooldown; shows a cooldown swipe
- Quick-cast Mount — summons a random favourite mount from your journal
- Minimap Button Collector *(opt-in, Settings → Info Bar)* — sweeps other addons' minimap icon buttons off the minimap; hover the icon to browse a flyout grid and click any icon to trigger that addon's real button

**Bottom bar extras (right of modules):**
- Notification dots — yellow = unread mail, green = LFG queue active, blue = pending calendar invite; each clickable
- Cog — opens settings

---

### Rich Tooltips
Hovering any bar module shows a detailed breakdown:

| Module | Tooltip shows |
|---|---|
| Gold | Full g / s / c values |
| Bags | Per-bag free slot count |
| Durability | Per-slot % (head, chest, legs, etc.) |
| Session Gold | Net +/- and session starting gold |
| Friends | Online friends list (up to 10 names) |
| Reputation | Current value and progress to next standing |
| HS Cooldown | Each hearthstone with exact time remaining |
| Spec | All specs listed, current one marked |
| Item Level | Equipped vs overall split |
| Keystone | Full dungeon name and key level |
| Daily Gold | Full breakdown and what you started the day with |
| Warband Gold | Every character's gold (class-coloured, richest first) plus Warband Bank and grand total |
| Todo Count | Pending/done breakdown for account and character |
| Played Time | This character's total and time-at-level, every character's played time by class, and an account grand total |

---

### Settings Panel
Opens via `/tmh config`, the minimap right-click menu, or the cog on either bar.

Seven sidebar sections:
- **General** — window scale slider, lock positions, snap toggle, reset all
- **Info Bar** — enable/disable each bar, per-module enable + Bot/Top bar assignment, ATT toggle, Minimap Button Collector toggle
- **Travel** — enable/reorder hearthstone and utility buttons
- **Professions** — enable/reorder profession buttons
- **Mounts** — add/remove mounts from the window
- **Function** — enable/reorder function buttons
- **Missions** — enable/reorder mission table buttons

---

### External Data API
Other addons and WeakAuras can write values to the `TakeMeHomeExternalData` table and have them displayed on the bar:
```lua
TakeMeHomeExternalData["myKey"] = "63.8%"
```

---

## Slash Commands

| Command | Action |
|---|---|
| `/tmh` | Toggle Travel window |
| `/tmh show` / `hide` | Show / hide Travel window |
| `/tmh prof` | Toggle Professions window |
| `/tmh func` | Toggle Function window |
| `/tmh todo` | Toggle To Do List window |
| `/tmh lock` / `unlock` | Lock / unlock all window positions |
| `/tmh reset` | Reset all windows to centre |
| `/tmh config` | Open settings panel |

---

## Requirements
- World of Warcraft (retail)
- **Optional:** [TomTom](https://www.curseforge.com/wow/addons/tomtom) — enables waypoint dropping from the Coords module
- **Optional:** [All The Things](https://www.curseforge.com/wow/addons/all-the-things) — enables the ATT expansion dropdown on the bar

---

## Installation
1. Download and extract to `World of Warcraft/_retail_/Interface/AddOns/TakeMeHome/`
2. Reload UI or restart the game client
3. The addon loads automatically — look for the hearthstone icon on your minimap

---

## Version History
See [CHANGELOG.md](CHANGELOG.md) for the full version history.

Current version: **2.5.0**
