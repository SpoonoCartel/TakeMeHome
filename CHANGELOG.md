# TakeMeHome Changelog

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
