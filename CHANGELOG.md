# TakeMeHome Changelog

## [2.6.0] - 2026-08-08
### Added
- **Settings panel redesign** — the whole config window has moved to a modern dark UI with a gold-yellow accent, pill-style toggle switches instead of checkboxes, uppercase section labels grouping related fields, and a subtle glow strip under each section header; the sidebar's active tab now shows a left accent bar and dimmed inactive icons instead of a flat colour fill
- **Time Played graph window** — a new pop-out window (toggle via its own bar icon or by clicking the Played Time bar module) showing a bar chart of your played time, with **By Class** and **By Character** tabs; each bar uses the real class colour, sorted highest first, with an account-total footer
- **Configurable button grid** for the Professions, Mounts, and Missions windows — a new "Buttons per row" slider in each window's settings section lets you choose the column count (row count still follows automatically); changes apply live, no reload needed

## [2.5.0] - 2026-08-07
### Added
- **To Do List window** — a new draggable window (toggle via the info bar or the window-toggle icons) for tracking tasks, with separate **Account** and **Character** tabs; organize tasks into collapsible, renameable groups; add, edit, check off, and delete tasks freely; a **Todo Count** bar module shows pending/done counts for both account and character scope, with a full breakdown in its tooltip and a click to open the window
- **Time Played module** — tracks how long you've played each character, refreshed from the server at login and every 10 minutes; bar shows a live-updating total (e.g. `Played 12d 4h`); tooltip breaks down this character's total and time-at-current-level, then lists every character's played time (class-coloured, richest-first), a **Total by class** rollup, and an account grand total
- **Minimap Button Collector** (opt-in, off by default in Settings → Info Bar) — sweeps other addons' minimap icon buttons off the minimap and into a single icon on the bottom bar; hover it to browse a flyout grid of everything collected, click any icon to trigger that addon's real button exactly as if you'd clicked it on the minimap
- **Interface 12.1 (120100)** added to the multi-interface TOC line, alongside the existing 12.0.x entries, so the addon keeps loading across the 12.0 → 12.1 transition

### Fixed
- Info bar modules with only a left-click action (no right-click) never actually responded to clicks — `RegisterForClicks` was never called for that case, so `OnClick` was set but never fired
- Clicking a module's L/C/R section-cycle button in Settings → Info Bar threw a Lua error (`bad argument #1 to 'ipairs'`) because two of the button lists it referenced were declared later in the file than the code that closed over them, putting them out of lexical scope

## [2.4.2] - 2026-06-12
### Added
- **Warband Bank gold** included in the Warband Gold module — the shared account-wide gold pool in the Warband Bank is now tracked via `C_Bank.FetchDepositedMoney(Enum.BankType.Account)` and the `ACCOUNT_MONEY` event; the bar total and tooltip grand total both include it; the tooltip shows it as a separate `Warband Bank` line (in blue) between the per-character list and the overall total

## [2.4.1] - 2026-06-12
### Added
- **Daily Gold module** — tracks how much gold your character has made or lost since midnight; bar shows `Day +5g 23s` (green) or `Day -200g` (red); resets automatically when the calendar date changes on next login; tooltip shows full g/s/c breakdown and what you started the day with
- **Warband Gold module** — shows combined total gold across every character on your account that has ever logged in with the addon; bar shows formatted total; tooltip lists each character by name in their class colour, sorted richest first, with a total line at the bottom; characters on a different realm display the realm name; gold is stored account-wide and updated live whenever your gold changes

### Fixed
- **Session Gold** was always blank — `sessionGoldStart` was declared but never assigned; it is now correctly set to your current gold at login

## [2.4.0] - 2026-06-04
### Added
- **Rich tooltips** on all info bar modules — hover any module for a detailed breakdown:
  - Gold: full g/s/c values
  - Bags: per-bag free slot count
  - Durability: per-slot percentages (head, chest, legs, etc.)
  - Session Gold: net +/- with session starting gold
  - Friends: online friends list (up to 10 names)
  - Reputation: current value and progress to next standing
  - HS Cooldown: each hearthstone with exact time remaining
  - Spec: all specs listed with current one marked
  - Item Level: equipped vs overall split
  - Keystone: full dungeon name and key level

## [2.3.0] - 2026-06-04
### Added
- **Quick-cast bar buttons** — two icon buttons on the bottom bar after the ATT button:
  - Hearthstone: uses best available hearthstone (shortest cooldown); shows cooldown swipe; tooltip shows name and remaining time
  - Mount: summons a random favourite mount from the journal (`C_MountJournal.SummonByID(0)`)

## [2.2.0] - 2026-06-04
### Added
- **Currency module** — shows watched currency with count/cap, colour-coded red when capped; click opens Currency tab
- **Keystone module** — shows owned Mythic+ key level and dungeon name, colour-coded by level; click opens Challenges

### Fixed
- Config panel crashing on open when Missions section built — `MISSION_TABLE_DEFINITIONS` was declared after `CreateConfigPanel`, treated as nil global; fixed with forward declaration

## [2.1.0] - 2026-06-04
### Added
- **Notification dots** on bottom bar (left of cog): yellow = unread mail, green = LFG queue active, blue = pending calendar invite; each clickable to open the relevant UI

## [2.0.0] - 2026-06-04
### Added
- **Dual bar** — independent top and bottom bars, each with their own enable toggle
- Each module has a Bot/Top toggle in settings to assign it to either bar (reload to apply)
- Top bar has its own cog button to open settings
- **Spec module** — shows current specialization on bar; left-click opens Talents; right-click opens spec-switch dropdown with icons
- Window toggles and ATT button remain on the bottom bar

## [1.9.0] - 2026-06-04
### Added
- **HS Cooldown** info bar module — shows hearthstone cooldown countdown or "Ready" (green); click to toggle Travel window
- **Coordinates right-click** — right-clicking the Coords module drops a TomTom waypoint at your position (falls back to pre-filling chat if TomTom is not loaded)
- Right-click support infrastructure for all info bar modules (`INFO_MODULE_RIGHT_ACTIONS`)

### Fixed
- Config panel sidebar showing only "General" (nav counter used `#table` on a hash table, always returned 0)
- Unnamed slider (`GetName()` returned nil) crashing config panel on open
- Old tab-based config panel code (816 lines) was floating as module-level code with a stray `end`, preventing the addon from loading at all
- `ReflowInfoBar` called every second causing UI stutter — now only runs when text changes
- Removed Memory module (caused periodic GC lag spikes)
- ATT bar button anchor referenced undefined `infoBarLeft` variable — fixed to use `lastBtn`

## [1.8.0] - 2026-06-03
### Added
- **Info Bar**: Persistent full-width bar (docked top or bottom of screen) showing live game data
  - **Zone / Subzone**: Current location name with zone context
  - **Coordinates**: Player X, Y position in the current zone
  - **Gold**: Formatted gold display with g/s/c colour-coding (supports millions)
  - **Bags**: Free/total bag slot count, colour-coded when low
  - **Durability**: Lowest equipped item durability %, colour-coded (green/yellow/red)
  - **FPS**: Live frames-per-second, colour-coded by performance
  - **Latency**: Home/World latency in milliseconds, colour-coded
  - **Server Time**: Current server clock
  - **XP**: Experience progress percentage (hidden by default, useful for levelling alts)
- Info bar integrates with minimap toggle (left-click to show/hide all windows including bar)
- **Bar tab** in Settings panel: enable/disable bar, switch between Top/Bottom position, toggle individual modules

## [1.7.0] - 2025-03-01
### Added
- Personal Key to the Arcantina (item ID 253629) to the top row of the Hearthstone window

## [1.6.0] - 2025-02-05
### Added
- **Mission Table Window**: Quick access to expansion mission tables
  - Warlords of Draenor (Garrison)
  - Legion (Order Hall)
  - Battle for Azeroth (War Campaign)
  - Shadowlands (Covenant)
- Toggle functionality - click again to close mission table
- Expansion-specific icons (Garrison Resources, Order Resources, Heart of Azeroth, Anima)

### Removed
- Combat and pet battle auto-hide feature (by user request)

## [1.5.0] - 2025-01-30
### Added
- **Druid Support**: Travel Form button in Mounts window (Druid only)
- **Druid Support**: Dreamwalk/Teleport: Moonglade button in Hearthstone window (Druid only, prefers Dreamwalk if known)
- Windows automatically hide during combat
- Windows automatically hide during pet battles
- Combat lockdown protection to prevent "ADDON_ACTION_BLOCKED" errors

### Changed
- Logout button now uses the exit vehicle icon
- Windows restore automatically when leaving combat or pet battles

## [1.4.0] - 2025-01-25
### Added
- Window snapping system - windows snap together when dragged within 20 pixels of each other
- Window linking - snapped windows automatically link and move together as a group
- Support for snapping on all edges (left, right, top, bottom)
- "Unlink Window" option in right-click context menu to separate linked windows
- Real-time linked window movement during drag (windows move together smoothly)

### Changed
- Improved window positioning with 1-pixel overlap for seamless border blending

## [1.3.0] - 2025-01-24
### Added
- Function window with quick access buttons
- Logout button for fast character logout
- Drag banner for function window with lock/unlock support

## [1.2.0] - 2025-01-23
### Added
- Mounts window with mount selection feature
- Mount search functionality to filter available mounts
- Favorite mount summon button
- Drag banner for mounts window

## [1.1.2] - 2025-01-22
### Changed
- Updated author information

## [1.0.0] - 2025-01-21
### Added
- Initial release
- Main hearthstone window with quick access to travel items
- Professions window for profession-related teleports
- Movable and lockable windows
- Position saving across sessions
- Scale adjustment in settings
- Modern dark UI theme with subtle borders
