# TakeMeHome Changelog

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
