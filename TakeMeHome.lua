-- TakeMeHome - Quick access to Hearthstones and travel options
local addonName, addon = ...

-- Public external data table. Any addon or WeakAura can write values here and
-- TakeMeHome will display them in the info bar.
-- Example (from another addon or WeakAura):
--   TakeMeHomeExternalData["att"] = "63.8%"
TakeMeHomeExternalData = TakeMeHomeExternalData or {}

-- Item IDs for travel items (isToy = true for toys, false/nil for bag items)
local TRAVEL_ITEMS = {
    { itemID = 6948,   name = "Hearthstone", isToy = false, settingsKey = "hearthstone" },
    { itemID = 140192, name = "Dalaran Hearthstone", isToy = true, settingsKey = "dalaran_hearthstone" },
    { itemID = 110560, name = "Garrison Hearthstone", isToy = true, settingsKey = "garrison_hearthstone" },
    { itemID = 253629, name = "Personal Key to the Arcantina", isToy = true, settingsKey = "arcantina_key" },
}

-- Alternative toy hearthstones (used when regular hearthstone is not in bags)
-- Excludes Garrison (110560) and Dalaran (140192) hearthstones
local ALTERNATIVE_HEARTHSTONE_TOYS = {
    { itemID = 64488,  name = "The Innkeeper's Daughter" },
    { itemID = 93672,  name = "Dark Portal" },
    { itemID = 142298, name = "Astonishingly Scarlet Slippers" },
    { itemID = 162973, name = "Greatfather Winter's Hearthstone" },
    { itemID = 163045, name = "Headless Horseman's Hearthstone" },
    { itemID = 163206, name = "Weary Spirit Binding" },
    { itemID = 165669, name = "Lunar Elder's Hearthstone" },
    { itemID = 165670, name = "Peddlefeet's Lovely Hearthstone" },
    { itemID = 165802, name = "Noble Gardener's Hearthstone" },
    { itemID = 166746, name = "Fire Eater's Hearthstone" },
    { itemID = 166747, name = "Brewfest Reveler's Hearthstone" },
    { itemID = 168907, name = "Holographic Digitalization Hearthstone" },
    { itemID = 172179, name = "Eternal Traveler's Hearthstone" },
    { itemID = 182773, name = "Necrolord Hearthstone" },
    { itemID = 180290, name = "Night Fae Hearthstone" },
    { itemID = 184353, name = "Kyrian Hearthstone" },
    { itemID = 183716, name = "Venthyr Sinstone" },
    { itemID = 188952, name = "Dominated Hearthstone" },
    { itemID = 190237, name = "Broker Translocation Matrix" },
    { itemID = 193588, name = "Timewalker's Hearthstone" },
    { itemID = 200630, name = "Ohn'ir Windsage's Hearthstone" },
    { itemID = 206195, name = "Path of the Naaru" },
    { itemID = 208704, name = "Deepdweller's Earthen Hearthstone" },
    { itemID = 209035, name = "Hearthstone of the Flame" },
    { itemID = 212337, name = "Stone of the Hearth" },
}

-- Mailbox Toys (in priority order)
local MAILBOX_TOYS = {
    { itemID = 40768,  name = "MOLL-E" },
    { itemID = 156833, name = "Katy's Stampwhistle" },
}

-- Info bar module definitions (section: "left" | "center" | "right")
local INFO_BAR_MODULES = {
    { key = "zone",        name = "Zone",         section = "left",   order = 1  },
    { key = "coords",      name = "Coords",       section = "left",   order = 2  },
    { key = "ilvl",        name = "Item Level",   section = "left",   order = 3  },
    { key = "rep",         name = "Reputation",   section = "left",   order = 4  },
    { key = "gold",        name = "Gold",         section = "center", order = 5  },
    { key = "bags",        name = "Bags",         section = "center", order = 6  },
    { key = "durability",  name = "Durability",   section = "center", order = 7  },
    { key = "xp",          name = "XP",           section = "center", order = 8  },
    { key = "sessionGold", name = "Session Gold", section = "center", order = 9  },

    { key = "hsCooldown",  name = "HS Cooldown",  section = "left",   order = 10 },
    { key = "fps",         name = "FPS",          section = "right",  order = 11 },
    { key = "latency",     name = "Latency",      section = "right",  order = 12 },
    { key = "timeLocal",   name = "Local Time",   section = "right",  order = 13 },
    { key = "time",        name = "Server Time",  section = "right",  order = 14 },
    { key = "friends",     name = "Friends",      section = "right",  order = 15 },
}

-- All The Things dropdown entries with their slash command arguments
local ATT_EXPANSIONS = {
    { name = "Main",                    cmd = "main",       separator = false },
    { name = "Mini",                    cmd = "mini",       separator = true  }, -- separator drawn after this entry
    { name = "Classic",                 cmd = "awp classic" },
    { name = "The Burning Crusade",     cmd = "awp tbc"     },
    { name = "Wrath of the Lich King",  cmd = "awp wotlk"   },
    { name = "Cataclysm",               cmd = "awp cata"    },
    { name = "Mists of Pandaria",       cmd = "awp mop"     },
    { name = "Warlords of Draenor",     cmd = "awp wod"     },
    { name = "Legion",                  cmd = "awp legion"  },
    { name = "Battle for Azeroth",      cmd = "awp bfa"     },
    { name = "Shadowlands",             cmd = "awp sl"      },
    { name = "Dragonflight",            cmd = "awp df"      },
    { name = "The War Within",          cmd = "awp tww"     },
    { name = "Midnight",                cmd = "awp mid"     },
}

-- Warband Bank Spell
local WARBAND_BANK_SPELL = { name = "Warband Bank Distance Inhibitor" }

-- Mobile Banking Spell (Guild Perk)
local MOBILE_BANKING_SPELL = { name = "Mobile Banking" }

-- Druid-specific spells
local DRUID_SPELLS = {
    dreamwalk = { spellID = 193753, name = "Dreamwalk" },
    moonglade = { spellID = 18960, name = "Teleport: Moonglade" },
    travelForm = { spellID = 783, name = "Travel Form" },
}

-- Helper to check if player is a Druid
local function IsDruid()
    local _, playerClass = UnitClass("player")
    return playerClass == "DRUID"
end

-- Button definitions with keys for settings
local BUTTON_DEFINITIONS = {
    -- Row 1: Hearthstones
    { key = "hearthstone", name = "Hearthstone", row = 1 },
    { key = "dalaran_hearthstone", name = "Dalaran Hearthstone", row = 1 },
    { key = "garrison_hearthstone", name = "Garrison Hearthstone", row = 1 },
    { key = "arcantina_key", name = "Personal Key to the Arcantina", row = 1 },
    { key = "druid_teleport", name = "Dreamwalk", row = 1, classRestricted = "DRUID" },
    -- Row 2: Utilities
    { key = "mailbox", name = "Mailbox", row = 2 },
    { key = "warband_bank", name = "Warband Bank", row = 2 },
    { key = "mobile_banking", name = "Mobile Banking", row = 2 },
}

-- Default saved variables
local defaults = {
    position = { point = "CENTER", x = 0, y = 0 },
    professionPosition = { point = "CENTER", x = 100, y = 0 },
    mountsPosition = { point = "CENTER", x = -100, y = 0 },
    functionPosition = { point = "CENTER", x = 0, y = -100 },
    missionPosition = { point = "CENTER", x = 100, y = -100 },
    locked = false,
    scale = 0.75,
    minimapPos = 220, -- Angle around minimap
    buttonSettings = {
        hearthstone = { enabled = true, order = 1 },
        dalaran_hearthstone = { enabled = true, order = 2 },
        garrison_hearthstone = { enabled = true, order = 3 },
        arcantina_key = { enabled = true, order = 4 },
        druid_teleport = { enabled = true, order = 5 },
        mailbox = { enabled = true, order = 6 },
        warband_bank = { enabled = true, order = 7 },
        mobile_banking = { enabled = true, order = 8 },
    },
    professionSettings = {
        -- Will be populated dynamically based on learned professions
        -- Format: ["professionName"] = { enabled = true, order = 1 }
    },
    selectedMounts = {
        -- User-selected mounts (max 6)
        -- Format: { spellID = 264058 }
        { spellID = 264058 },  -- Mighty Caravan Brutosaur
        { spellID = 122708 },  -- Grand Expedition Yak
    },
    functionSettings = {
        logout = { enabled = true, order = 1 },
    },
    missionSettings = {
        wod = { enabled = true, order = 1 },
        legion = { enabled = true, order = 2 },
        bfa = { enabled = true, order = 3 },
        shadowlands = { enabled = true, order = 4 },
    },
    -- Window snapping and linking
    snapEnabled = true,
    linkedWindows = {}, -- Groups of linked window keys, e.g., { {"main", "professions"}, {"mounts", "function"} }
    -- Per-window visibility overrides set by bar toggle buttons (persisted across sessions)
    hiddenWindows = {},
    -- Info bar
    infoBarSettings = {
        enabled = true,
        position = "BOTTOM", -- "TOP" or "BOTTOM"
        yOffset = 0,
        attButton = true,  -- show ATT expansion dropdown button on bar
        modules = {
            zone =        { enabled = true,  order = 1  },
            coords =      { enabled = true,  order = 2  },
            ilvl =        { enabled = true,  order = 3  },
            rep =         { enabled = false, order = 4  },
            gold =        { enabled = true,  order = 5  },
            bags =        { enabled = true,  order = 6  },
            durability =  { enabled = true,  order = 7  },
            xp =          { enabled = false, order = 8  },
            sessionGold = { enabled = true,  order = 9  },

            hsCooldown =  { enabled = true,  order = 10 },
            fps =         { enabled = true,  order = 11 },
            latency =     { enabled = true,  order = 12 },
            timeLocal =   { enabled = true,  order = 13 },
            time =        { enabled = true,  order = 14 },
            friends =     { enabled = false, order = 15 },
        }
    },
}

-- Main frame
local mainFrame = CreateFrame("Frame", "TakeMeHomeFrame", UIParent, "BackdropTemplate")
mainFrame:SetSize(56, 71) -- Will be resized by RepositionButtons
mainFrame:SetPoint("CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetClampedToScreen(true)
mainFrame:Hide() -- Start hidden until buttons are ready

-- Modern dark backdrop with subtle border
mainFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
mainFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
mainFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

-- Scale (will be updated from saved variables on login)
mainFrame:SetScale(0.75)

-- Forward declarations for banner update functions and initialization
local UpdateMainDragBanner, UpdateProfDragBanner, UpdateMountsDragBanner, UpdateFuncDragBanner, UpdateMissionDragBanner
local InitializeProfessions, InitializeMounts, InitializeFunction, InitializeMissions
local UpdateProfessionButtons, UpdateMountButtons, UpdateFunctionButtons, UpdateMissionButtons
local UpdateInfoBar, UpdateInfoBarPosition, InitializeInfoBar

-- Track if user wants windows visible (used by minimap toggle)
local userWantsWindowsVisible = true

-- Per-window hide flags set by the info bar toggle buttons
local windowHiddenByBar = {}

-- Session gold baseline (set at PLAYER_LOGIN)
local sessionGoldStart = nil

-- Click actions and tooltips for info bar modules
-- Last coordinate string (updated each tick, used by right-click copy)
local lastCoordsString = ""

local INFO_MODULE_ACTIONS = {
    zone        = function() pcall(ToggleWorldMap) end,
    coords      = function() pcall(ToggleWorldMap) end,
    gold        = function() pcall(OpenAllBags) end,
    bags        = function() pcall(OpenAllBags) end,
    durability  = function() pcall(function() ToggleCharacter("PaperDollFrame") end) end,
    ilvl        = function() pcall(function() ToggleCharacter("PaperDollFrame") end) end,
    time        = function() pcall(ToggleCalendar) end,
    timeLocal   = function() pcall(ToggleCalendar) end,
    friends     = function() pcall(function() ToggleFriendsFrame(1) end) end,
    rep         = function() pcall(function() ToggleCharacter("ReputationFrame") end) end,
    sessionGold = function() pcall(OpenAllBags) end,
    hsCooldown  = function() if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end end,
}

-- Right-click actions for modules that support it
local INFO_MODULE_RIGHT_ACTIONS = {
    coords = function()
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then return end
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if not pos then return end
        local coordStr = string.format("%.1f, %.1f", pos.x * 100, pos.y * 100)
        if TomTom and TomTom.AddWaypoint then
            pcall(function()
                TomTom:AddWaypoint(mapID, pos.x, pos.y, {
                    title = "TakeMeHome: " .. coordStr,
                    persistent = false,
                    minimap = true,
                    world = true,
                })
            end)
            print("|cff00ff00TakeMeHome|r: TomTom waypoint set at |cff00ffff" .. coordStr .. "|r")
        else
            ChatFrame_OpenChat(coordStr)
        end
    end,
}

local INFO_MODULE_TIPS = {
    zone        = "Click to open Map",
    coords      = "Click to open Map  |cff888888Right-click: TomTom waypoint (or share in chat)|r",
    gold        = "Click to open Bags",
    bags        = "Click to open Bags",
    durability  = "Click to open Character",
    ilvl        = "Click to open Character",
    time        = "Click to open Calendar",
    timeLocal   = "Click to open Calendar",
    friends     = "Click to open Friends List",
    rep         = "Click to open Reputations",
    sessionGold = "Click to open Bags",
    hsCooldown  = "Click to toggle Travel window",
}

-- ============================================
-- WINDOW SNAPPING AND LINKING SYSTEM
-- ============================================

-- Window registry (populated after all frames are created)
local windowRegistry = {}
local windowPositionKeys = {} -- Maps window key to position saved variable key

-- Snap threshold in pixels
local SNAP_THRESHOLD = 20

-- Track drag start positions for linked window movement
local dragStartPositions = {}

-- Initialize window registry (called after all frames are created)
-- Uses global frame names since local variables aren't in scope when this function is defined
local function InitializeWindowRegistry()
    windowRegistry = {
        main = TakeMeHomeFrame,
        professions = TakeMeHomeProfessions,
        mounts = TakeMeHomeMountsFrame,
        ["function"] = TakeMeHomeFunctionFrame,
        missions = TakeMeHomeMissionFrame,
    }
    windowPositionKeys = {
        main = "position",
        professions = "professionPosition",
        mounts = "mountsPosition",
        ["function"] = "functionPosition",
        missions = "missionPosition",
    }
end

-- Get window bounds in screen coordinates
-- Note: GetRect() already returns screen coordinates after scaling
local function GetWindowBounds(frame)
    if not frame or not frame:IsShown() then return nil end
    local left, bottom, width, height = frame:GetRect()
    if not left then return nil end
    return {
        left = left,
        right = left + width,
        top = bottom + height,
        bottom = bottom,
        width = width,
        height = height,
        frame = frame
    }
end

-- Get window key from frame
local function GetWindowKey(frame)
    for key, f in pairs(windowRegistry) do
        if f == frame then return key end
    end
    return nil
end

-- Get all windows in the same link group as the given key
local function GetLinkedKeys(windowKey)
    if not TakeMeHomeDB or not TakeMeHomeDB.linkedWindows then return { windowKey } end
    for _, group in ipairs(TakeMeHomeDB.linkedWindows) do
        for _, key in ipairs(group) do
            if key == windowKey then
                return group
            end
        end
    end
    return { windowKey }
end

-- Check if two windows are in the same link group
local function AreWindowsLinked(key1, key2)
    local group = GetLinkedKeys(key1)
    for _, key in ipairs(group) do
        if key == key2 then return true end
    end
    return false
end

-- Link two windows together (merges their groups)
local function LinkWindows(key1, key2)
    if not TakeMeHomeDB then return end
    if not TakeMeHomeDB.linkedWindows then TakeMeHomeDB.linkedWindows = {} end

    -- Find existing groups
    local group1Idx, group2Idx = nil, nil
    for i, group in ipairs(TakeMeHomeDB.linkedWindows) do
        for _, key in ipairs(group) do
            if key == key1 then group1Idx = i end
            if key == key2 then group2Idx = i end
        end
    end

    if group1Idx and group2Idx then
        if group1Idx == group2Idx then return end -- Already in same group
        -- Merge groups
        for _, key in ipairs(TakeMeHomeDB.linkedWindows[group2Idx]) do
            table.insert(TakeMeHomeDB.linkedWindows[group1Idx], key)
        end
        table.remove(TakeMeHomeDB.linkedWindows, group2Idx)
    elseif group1Idx then
        -- Add key2 to group1
        table.insert(TakeMeHomeDB.linkedWindows[group1Idx], key2)
    elseif group2Idx then
        -- Add key1 to group2
        table.insert(TakeMeHomeDB.linkedWindows[group2Idx], key1)
    else
        -- Create new group
        table.insert(TakeMeHomeDB.linkedWindows, { key1, key2 })
    end
end

-- Unlink a window from its group
local function UnlinkWindow(windowKey)
    if not TakeMeHomeDB or not TakeMeHomeDB.linkedWindows then return end
    for i, group in ipairs(TakeMeHomeDB.linkedWindows) do
        for j, key in ipairs(group) do
            if key == windowKey then
                table.remove(group, j)
                -- Remove group if only one window left
                if #group <= 1 then
                    table.remove(TakeMeHomeDB.linkedWindows, i)
                end
                return
            end
        end
    end
end

-- Check if a window is part of any link group
local function IsWindowLinked(windowKey)
    if not TakeMeHomeDB or not TakeMeHomeDB.linkedWindows then return false end
    for _, group in ipairs(TakeMeHomeDB.linkedWindows) do
        for _, key in ipairs(group) do
            if key == windowKey then return true end
        end
    end
    return false
end

-- Find snap target for a dragged frame
-- Returns: targetKey, snapSide, snapX, snapY (or nil if no snap)
local function FindSnapTarget(draggedFrame)
    if not TakeMeHomeDB or not TakeMeHomeDB.snapEnabled then return nil end

    local draggedKey = GetWindowKey(draggedFrame)
    local draggedBounds = GetWindowBounds(draggedFrame)
    if not draggedBounds then return nil end

    local bestTarget = nil
    local bestDistance = SNAP_THRESHOLD + 1
    local bestSnapSide = nil
    local bestSnapX, bestSnapY = nil, nil

    for key, frame in pairs(windowRegistry) do
        if key ~= draggedKey and frame:IsShown() then
            local targetBounds = GetWindowBounds(frame)
            if targetBounds then
                -- Check right edge of dragged to left edge of target
                local distRightToLeft = math.abs(draggedBounds.right - targetBounds.left)
                local verticalOverlap = not (draggedBounds.bottom > targetBounds.top or draggedBounds.top < targetBounds.bottom)
                if distRightToLeft < bestDistance and verticalOverlap then
                    bestDistance = distRightToLeft
                    bestTarget = key
                    bestSnapSide = "right"
                    -- Overlap by 1 pixel so borders blend together
                    bestSnapX = targetBounds.left - draggedBounds.width + 1
                    -- Align tops
                    bestSnapY = targetBounds.top - draggedBounds.height
                end

                -- Check left edge of dragged to right edge of target
                local distLeftToRight = math.abs(draggedBounds.left - targetBounds.right)
                if distLeftToRight < bestDistance and verticalOverlap then
                    bestDistance = distLeftToRight
                    bestTarget = key
                    bestSnapSide = "left"
                    -- Overlap by 1 pixel so borders blend together
                    bestSnapX = targetBounds.right - 1
                    bestSnapY = targetBounds.top - draggedBounds.height
                end

                -- Check bottom edge of dragged to top edge of target
                local distBottomToTop = math.abs(draggedBounds.bottom - targetBounds.top)
                local horizontalOverlap = not (draggedBounds.right < targetBounds.left or draggedBounds.left > targetBounds.right)
                if distBottomToTop < bestDistance and horizontalOverlap then
                    bestDistance = distBottomToTop
                    bestTarget = key
                    bestSnapSide = "bottom"
                    bestSnapX = targetBounds.left
                    -- Overlap by 1 pixel so borders blend together
                    bestSnapY = targetBounds.top - 1
                end

                -- Check top edge of dragged to bottom edge of target
                local distTopToBottom = math.abs(draggedBounds.top - targetBounds.bottom)
                if distTopToBottom < bestDistance and horizontalOverlap then
                    bestDistance = distTopToBottom
                    bestTarget = key
                    bestSnapSide = "top"
                    bestSnapX = targetBounds.left
                    -- Overlap by 1 pixel so borders blend together
                    bestSnapY = targetBounds.bottom - draggedBounds.height + 1
                end
            end
        end
    end

    if bestDistance <= SNAP_THRESHOLD then
        return bestTarget, bestSnapSide, bestSnapX, bestSnapY
    end
    return nil
end

-- Snap a frame to a position and link it to the target
local function SnapAndLinkWindow(frame, targetKey, snapX, snapY)
    -- Don't reposition frames during combat (protected frames)
    if InCombatLockdown() then return end

    local windowKey = GetWindowKey(frame)

    -- snapX, snapY are in screen coordinates (from GetRect)
    -- SetPoint with BOTTOMLEFT uses the same coordinate system
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", snapX, snapY)

    -- Save position
    local posKey = windowPositionKeys[windowKey]
    if posKey and TakeMeHomeDB then
        local point, _, _, px, py = frame:GetPoint()
        TakeMeHomeDB[posKey] = { point = point, x = px, y = py }
    end

    -- Auto-link the windows
    if windowKey and targetKey then
        LinkWindows(windowKey, targetKey)
        print("|cff00ff00TakeMeHome|r: Windows linked! They will now move together.")
    end
end

-- Store start positions for linked window movement
local function StoreDragStartPositions(primaryFrame)
    wipe(dragStartPositions)
    local primaryKey = GetWindowKey(primaryFrame)
    if not primaryKey then return end

    local linkedKeys = GetLinkedKeys(primaryKey)
    for _, key in ipairs(linkedKeys) do
        local frame = windowRegistry[key]
        if frame and frame:IsShown() then
            -- Store screen position using GetRect for consistency
            local left, bottom = frame:GetRect()
            dragStartPositions[key] = { left = left, bottom = bottom }
        end
    end
end

-- Move all linked windows by the same delta (called during drag via OnUpdate)
local function MoveLinkedWindowsDuringDrag(primaryFrame)
    -- Don't reposition frames during combat (protected frames)
    if InCombatLockdown() then return end

    local primaryKey = GetWindowKey(primaryFrame)
    if not primaryKey then return end

    -- Get primary frame's current position
    local primaryLeft, primaryBottom = primaryFrame:GetRect()
    local primaryStart = dragStartPositions[primaryKey]
    if not primaryStart then return end

    -- Calculate how much the primary frame actually moved
    local deltaX = primaryLeft - primaryStart.left
    local deltaY = primaryBottom - primaryStart.bottom

    -- Move all linked windows (except primary which moved itself)
    local linkedKeys = GetLinkedKeys(primaryKey)
    for _, key in ipairs(linkedKeys) do
        if key ~= primaryKey then
            local frame = windowRegistry[key]
            local startPos = dragStartPositions[key]
            if frame and startPos then
                -- Calculate new position
                local newLeft = startPos.left + deltaX
                local newBottom = startPos.bottom + deltaY

                frame:ClearAllPoints()
                frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", newLeft, newBottom)
            end
        end
    end
end

-- Save positions of all linked windows (called at end of drag)
local function SaveLinkedWindowPositions(primaryFrame)
    local primaryKey = GetWindowKey(primaryFrame)
    if not primaryKey then return end

    local linkedKeys = GetLinkedKeys(primaryKey)
    for _, key in ipairs(linkedKeys) do
        local frame = windowRegistry[key]
        if frame then
            local posKey = windowPositionKeys[key]
            if posKey and TakeMeHomeDB then
                local point, _, _, x, y = frame:GetPoint()
                TakeMeHomeDB[posKey] = { point = point, x = x, y = y }
            end
        end
    end
end

-- Start dragging with linked window updates
local function StartLinkedDrag(primaryFrame)
    -- Don't allow dragging during combat (protected frames)
    if InCombatLockdown() then return end

    StoreDragStartPositions(primaryFrame)
    primaryFrame:StartMoving()

    -- Set up OnUpdate to move linked windows during drag
    primaryFrame:SetScript("OnUpdate", function(self)
        MoveLinkedWindowsDuringDrag(self)
    end)
end

-- Stop dragging and clean up
local function StopLinkedDrag(primaryFrame)
    primaryFrame:StopMovingOrSizing()
    primaryFrame:SetScript("OnUpdate", nil)
    SaveLinkedWindowPositions(primaryFrame)
end

-- Custom context menu frame (modern style)
local bannerMenu = CreateFrame("Frame", "TakeMeHomeBannerMenu", UIParent, "BackdropTemplate")
bannerMenu:SetSize(110, 88)  -- Larger to fit Unlink button
bannerMenu:SetFrameStrata("TOOLTIP")
bannerMenu:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
bannerMenu:SetBackdropColor(0.1, 0.1, 0.12, 0.95)
bannerMenu:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
bannerMenu:EnableMouse(true)
bannerMenu:Hide()
bannerMenu.sourceFrame = nil  -- Track which frame opened the menu

-- Lock/Unlock button
local lockButton = CreateFrame("Button", nil, bannerMenu)
lockButton:SetSize(100, 18)
lockButton:SetPoint("TOP", bannerMenu, "TOP", 0, -6)
lockButton:SetNormalFontObject("GameFontNormalSmall")
lockButton:SetHighlightFontObject("GameFontHighlightSmall")
lockButton:SetText("Lock Windows")

local lockHighlight = lockButton:CreateTexture(nil, "HIGHLIGHT")
lockHighlight:SetAllPoints()
lockHighlight:SetColorTexture(0.3, 0.6, 1, 0.3)

lockButton:SetScript("OnClick", function()
    TakeMeHomeDB.locked = not TakeMeHomeDB.locked
    UpdateMainDragBanner()
    UpdateProfDragBanner()
    UpdateMountsDragBanner()
    if UpdateFuncDragBanner then UpdateFuncDragBanner() end
    bannerMenu:Hide()
    if TakeMeHomeDB.locked then
        print("|cff00ff00TakeMeHome|r: Windows locked.")
    else
        print("|cff00ff00TakeMeHome|r: Windows unlocked.")
    end
end)

-- Settings button
local settingsButton = CreateFrame("Button", nil, bannerMenu)
settingsButton:SetSize(100, 18)
settingsButton:SetPoint("TOP", lockButton, "BOTTOM", 0, -2)
settingsButton:SetNormalFontObject("GameFontNormalSmall")
settingsButton:SetHighlightFontObject("GameFontHighlightSmall")
settingsButton:SetText("Settings")

local settingsHighlight = settingsButton:CreateTexture(nil, "HIGHLIGHT")
settingsHighlight:SetAllPoints()
settingsHighlight:SetColorTexture(0.3, 0.6, 1, 0.3)

settingsButton:SetScript("OnClick", function()
    bannerMenu:Hide()
    -- Delay slightly to ensure menu closes first
    C_Timer.After(0.1, function()
        SlashCmdList["TAKEMEHOME"]("config")
    end)
end)

-- Unlink Window button
local unlinkButton = CreateFrame("Button", nil, bannerMenu)
unlinkButton:SetSize(100, 18)
unlinkButton:SetPoint("TOP", settingsButton, "BOTTOM", 0, -2)
unlinkButton:SetNormalFontObject("GameFontNormalSmall")
unlinkButton:SetHighlightFontObject("GameFontHighlightSmall")
unlinkButton:SetText("Unlink Window")

local unlinkHighlight = unlinkButton:CreateTexture(nil, "HIGHLIGHT")
unlinkHighlight:SetAllPoints()
unlinkHighlight:SetColorTexture(1, 0.6, 0.3, 0.3)

unlinkButton:SetScript("OnClick", function()
    if bannerMenu.sourceFrame then
        local windowKey = GetWindowKey(bannerMenu.sourceFrame)
        if windowKey then
            UnlinkWindow(windowKey)
            print("|cff00ff00TakeMeHome|r: Window unlinked.")
        end
    end
    bannerMenu:Hide()
end)

-- Cancel button
local cancelButton = CreateFrame("Button", nil, bannerMenu)
cancelButton:SetSize(100, 18)
cancelButton:SetPoint("TOP", unlinkButton, "BOTTOM", 0, -2)
cancelButton:SetNormalFontObject("GameFontNormalSmall")
cancelButton:SetHighlightFontObject("GameFontHighlightSmall")
cancelButton:SetText("Cancel")

local cancelHighlight = cancelButton:CreateTexture(nil, "HIGHLIGHT")
cancelHighlight:SetAllPoints()
cancelHighlight:SetColorTexture(1, 0.3, 0.3, 0.3)

cancelButton:SetScript("OnClick", function()
    bannerMenu:Hide()
end)

-- Hide menu when clicking elsewhere
bannerMenu:SetScript("OnShow", function(self)
    -- Update lock button text
    lockButton:SetText(TakeMeHomeDB.locked and "Unlock Windows" or "Lock Windows")

    -- Show/hide unlink button based on whether window is linked
    if self.sourceFrame then
        local windowKey = GetWindowKey(self.sourceFrame)
        if windowKey and IsWindowLinked(windowKey) then
            unlinkButton:Show()
            cancelButton:SetPoint("TOP", unlinkButton, "BOTTOM", 0, -2)
            self:SetHeight(88)
        else
            unlinkButton:Hide()
            cancelButton:SetPoint("TOP", settingsButton, "BOTTOM", 0, -2)
            self:SetHeight(68)
        end
    else
        unlinkButton:Hide()
        cancelButton:SetPoint("TOP", settingsButton, "BOTTOM", 0, -2)
        self:SetHeight(68)
    end
end)

bannerMenu:SetScript("OnLeave", function(self)
    -- Small delay before hiding to allow clicking buttons
    C_Timer.After(0.1, function()
        if not bannerMenu:IsMouseOver() and not lockButton:IsMouseOver() and not settingsButton:IsMouseOver() and not unlinkButton:IsMouseOver() and not cancelButton:IsMouseOver() then
            bannerMenu:Hide()
        end
    end)
end)

local function ShowBannerContextMenu(anchor)
    -- Store source frame (anchor's parent is the window frame)
    bannerMenu.sourceFrame = anchor:GetParent()

    -- Position at cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    bannerMenu:ClearAllPoints()
    bannerMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    bannerMenu:Show()
end

-- Drag banner (visible when unlocked, hover-visible when locked)
local mainDragBanner = CreateFrame("Frame", nil, mainFrame)
mainDragBanner:SetHeight(8)
mainDragBanner:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 1, -1)
mainDragBanner:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -1)
mainDragBanner:EnableMouse(true)
mainDragBanner:RegisterForDrag("LeftButton")

local mainBannerTexture = mainDragBanner:CreateTexture(nil, "BACKGROUND")
mainBannerTexture:SetAllPoints()
mainBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)

mainDragBanner:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(mainFrame)
    end
end)

mainDragBanner:SetScript("OnDragStop", function(self)
    StopLinkedDrag(mainFrame)

    -- Save primary window position
    local point, _, _, x, y = mainFrame:GetPoint()
    TakeMeHomeDB.position = { point = point, x = x, y = y }

    -- Check for snap target (only if not already linked to avoid re-linking)
    local windowKey = GetWindowKey(mainFrame)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(mainFrame)
        if targetKey then
            SnapAndLinkWindow(mainFrame, targetKey, snapX, snapY)
        end
    end
end)

-- Right-click to show menu
mainDragBanner:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ShowBannerContextMenu(self)
    end
end)

-- Hover to show banner when locked
mainDragBanner:SetScript("OnEnter", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mainBannerTexture:SetColorTexture(0.3, 0.6, 0.9, 0.8)
    end
end)

mainDragBanner:SetScript("OnLeave", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mainBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0) -- Invisible when locked
    end
end)

-- Drag functionality for main frame
mainFrame:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(self)
    end
end)

mainFrame:SetScript("OnDragStop", function(self)
    StopLinkedDrag(self)

    -- Save primary window position
    local point, _, _, x, y = self:GetPoint()
    TakeMeHomeDB.position = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(self)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(self)
        if targetKey then
            SnapAndLinkWindow(self, targetKey, snapX, snapY)
        end
    end
end)

-- Container for buttons (offset for drag banner when unlocked)
local buttonContainer = CreateFrame("Frame", nil, mainFrame)
buttonContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -15)
buttonContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -5, 5)

-- Function to update drag banner visibility and container position
-- (defined here after buttonContainer is created)
UpdateMainDragBanner = function()
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mainBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0) -- Invisible but still interactive
        mainDragBanner:Show() -- Keep shown for hover detection
        -- Adjust container to have same padding as other sides when locked
        buttonContainer:ClearAllPoints()
        buttonContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -5)
        buttonContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -5, 5)
    else
        mainBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8) -- Visible when unlocked
        mainDragBanner:Show()
        -- Extra top padding for visible banner when unlocked
        buttonContainer:ClearAllPoints()
        buttonContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -15)
        buttonContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -5, 5)
    end
end

-- Create item buttons
local buttons = {}
local buttonSize = 36
local buttonSpacing = 6

local function CreateItemButton(index, itemData)
    local button = CreateFrame("Button", "TakeMeHomeButton"..index, buttonContainer, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Position will be set by RepositionButtons
    button:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)

    -- Set up as item or toy button
    if itemData.isToy then
        button:SetAttribute("type", "toy")
        button:SetAttribute("toy", itemData.itemID)
    else
        button:SetAttribute("type", "item")
        button:SetAttribute("item", itemData.name)
    end

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Check if using alternative hearthstone
        if self.currentAltHearthstone then
            GameTooltip:SetToyByItemID(self.currentAltHearthstone.itemID)
        elseif itemData.isToy then
            GameTooltip:SetToyByItemID(itemData.itemID)
        else
            GameTooltip:SetItemByID(itemData.itemID)
        end
        -- Add warning if toy is not usable yet
        if self.isUsable == false then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Requires content completion to use", 1, 0.2, 0.2)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button.currentAltHearthstone = nil  -- Track alternative hearthstone usage
    button.itemID = itemData.itemID
    button.itemName = itemData.name
    button.isToy = itemData.isToy
    button.settingsKey = itemData.settingsKey

    -- Start hidden
    button:Hide()

    return button
end

-- Mailbox button reference
local mailboxButton = nil

-- Warband Bank button reference
local warbandBankButton = nil

-- Mobile Banking button reference
local mobileBankingButton = nil

-- Druid teleport button reference
local druidTeleportButton = nil

-- Config frame reference
local configFrame = nil

-- Helper function to check if a button is enabled in settings
local function IsButtonEnabled(key)
    if not TakeMeHomeDB or not TakeMeHomeDB.buttonSettings then return true end
    local settings = TakeMeHomeDB.buttonSettings[key]
    return settings and settings.enabled
end

-- Helper function to get button order
local function GetButtonOrder(key)
    if not TakeMeHomeDB or not TakeMeHomeDB.buttonSettings then return 99 end
    local settings = TakeMeHomeDB.buttonSettings[key]
    return settings and settings.order or 99
end

-- Helper function to check if a profession is enabled in settings
local function IsProfessionEnabled(profName)
    if not TakeMeHomeDB or not TakeMeHomeDB.professionSettings then return true end
    local settings = TakeMeHomeDB.professionSettings[profName]
    if not settings then return true end -- Default to enabled if not set
    return settings.enabled
end

-- Helper function to get profession order
local function GetProfessionOrder(profName)
    if not TakeMeHomeDB or not TakeMeHomeDB.professionSettings then return 99 end
    local settings = TakeMeHomeDB.professionSettings[profName]
    return settings and settings.order or 99
end

-- Session-cached alternative hearthstone (persists until logout/reload)
local cachedAlternativeHearthstone = nil

-- Get a random alternative hearthstone toy that the player owns
-- Caches the selection for the entire session
-- Returns toyData or nil if player doesn't own any
local function GetRandomAlternativeHearthstone()
    -- Return cached selection if still valid (player still owns it)
    if cachedAlternativeHearthstone and PlayerHasToy(cachedAlternativeHearthstone.itemID) then
        return cachedAlternativeHearthstone
    end

    -- Build list of owned toys
    local ownedToys = {}
    for _, toyData in ipairs(ALTERNATIVE_HEARTHSTONE_TOYS) do
        if PlayerHasToy(toyData.itemID) then
            table.insert(ownedToys, toyData)
        end
    end

    if #ownedToys == 0 then
        cachedAlternativeHearthstone = nil
        return nil
    end

    -- Pick a random one and cache it for the session
    local randomIndex = math.random(1, #ownedToys)
    cachedAlternativeHearthstone = ownedToys[randomIndex]
    return cachedAlternativeHearthstone
end

-- Find the best available mailbox toy (not on cooldown, or shortest cooldown)
-- Only considers toys the player owns AND can use (handles profession requirements)
local function GetBestMailboxToy()
    local bestToy = nil
    local bestCooldownRemaining = math.huge

    for _, toyData in ipairs(MAILBOX_TOYS) do
        local itemID = toyData.itemID
        -- Check both ownership AND usability (IsToyUsable checks profession requirements)
        if PlayerHasToy(itemID) and C_ToyBox.IsToyUsable(itemID) then
            -- Get cooldown info
            local start, duration = GetItemCooldown(itemID)
            local cooldownRemaining = 0

            if start and duration and start > 0 and duration > 0 then
                cooldownRemaining = (start + duration) - GetTime()
                if cooldownRemaining < 0 then cooldownRemaining = 0 end
            end

            -- If not on cooldown, use this one immediately
            if cooldownRemaining == 0 then
                return toyData, true
            end

            -- Track the one with shortest cooldown
            if cooldownRemaining < bestCooldownRemaining then
                bestCooldownRemaining = cooldownRemaining
                bestToy = toyData
            end
        end
    end

    return bestToy, false -- Returns best toy and whether it's ready
end

-- Create the mailbox toy button
local function CreateMailboxButton(parent, index)
    local button = CreateFrame("Button", "TakeMeHomeMailbox", parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Position will be set by RepositionButtons
    button:SetPoint("LEFT", parent, "LEFT", 0, 0)

    button:SetAttribute("type", "toy")

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if self.currentToyID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetToyByItemID(self.currentToyID)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button.isMailbox = true

    -- Start hidden
    button:Hide()

    return button
end

-- Update the mailbox button to show the best available toy
local function UpdateMailboxButton()
    if not mailboxButton then return end

    -- Can't modify secure buttons during combat
    if InCombatLockdown() then return end

    -- Check if enabled in settings
    if not IsButtonEnabled("mailbox") then
        mailboxButton:Hide()
        return
    end

    local toyData, isReady = GetBestMailboxToy()

    if not toyData then
        -- No mailbox toys owned
        mailboxButton:Hide()
        return
    end

    mailboxButton:Show()
    mailboxButton.currentToyID = toyData.itemID

    -- Update the secure attribute (only works out of combat)
    if not InCombatLockdown() then
        mailboxButton:SetAttribute("toy", toyData.itemID)
    end

    -- Update icon
    local _, name, icon = C_ToyBox.GetToyInfo(toyData.itemID)
    if icon then
        mailboxButton.icon:SetTexture(icon)
    end

    -- Update cooldown
    local start, duration = GetItemCooldown(toyData.itemID)
    if start and duration and duration > 0 then
        mailboxButton.cooldown:SetCooldown(start, duration)
        mailboxButton:SetAlpha(0.5)
    else
        mailboxButton.cooldown:Clear()
        mailboxButton:SetAlpha(1)
    end
end

-- Create the Warband Bank spell button
local function CreateWarbandBankButton(parent, index)
    local button = CreateFrame("Button", "TakeMeHomeWarbandBank", parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Position will be set by RepositionButtons
    button:SetPoint("LEFT", parent, "LEFT", 0, 0)

    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", WARBAND_BANK_SPELL.name)

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spellID or 0)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Start hidden
    button:Hide()

    return button
end

-- Update the Warband Bank button
local function UpdateWarbandBankButton()
    if not warbandBankButton then return end

    -- Can't modify secure buttons during combat
    if InCombatLockdown() then return end

    -- Check if enabled in settings
    if not IsButtonEnabled("warband_bank") then
        warbandBankButton:Hide()
        return
    end

    local spellName = WARBAND_BANK_SPELL.name
    local spellInfo = C_Spell.GetSpellInfo(spellName)

    -- Check if player knows the spell
    if not spellInfo then
        warbandBankButton:Hide()
        return
    end

    warbandBankButton:Show()
    warbandBankButton.spellID = spellInfo.spellID

    -- Update icon
    local icon = spellInfo.iconID
    if icon then
        warbandBankButton.icon:SetTexture(icon)
    end

    -- Update cooldown (use pcall to safely handle secret values)
    local cooldownInfo = C_Spell.GetSpellCooldown(spellInfo.spellID)
    local success, hasCooldown = pcall(function()
        return cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration and cooldownInfo.duration > 0
    end)
    if success and hasCooldown then
        pcall(function()
            warbandBankButton.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
        end)
        warbandBankButton:SetAlpha(0.5)
    else
        warbandBankButton.cooldown:Clear()
        warbandBankButton:SetAlpha(1)
    end
end

-- Create the Mobile Banking spell button
local function CreateMobileBankingButton(parent, index)
    local button = CreateFrame("Button", "TakeMeHomeMobileBanking", parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Position will be set by RepositionButtons
    button:SetPoint("LEFT", parent, "LEFT", 0, 0)

    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", MOBILE_BANKING_SPELL.name)

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spellID or 0)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Start hidden
    button:Hide()

    return button
end

-- Update the Mobile Banking button
local function UpdateMobileBankingButton()
    if not mobileBankingButton then return end

    -- Can't modify secure buttons during combat
    if InCombatLockdown() then return end

    -- Check if enabled in settings
    if not IsButtonEnabled("mobile_banking") then
        mobileBankingButton:Hide()
        return
    end

    -- Only show if player is in a guild
    if not IsInGuild() then
        mobileBankingButton:Hide()
        return
    end

    local spellName = MOBILE_BANKING_SPELL.name
    local spellInfo = C_Spell.GetSpellInfo(spellName)

    -- Check if player knows the spell
    if not spellInfo then
        mobileBankingButton:Hide()
        return
    end

    mobileBankingButton:Show()
    mobileBankingButton.spellID = spellInfo.spellID

    -- Update icon
    local icon = spellInfo.iconID
    if icon then
        mobileBankingButton.icon:SetTexture(icon)
    end

    -- Update cooldown (use pcall to safely handle secret values)
    local cooldownInfo = C_Spell.GetSpellCooldown(spellInfo.spellID)
    local success, hasCooldown = pcall(function()
        return cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration and cooldownInfo.duration > 0
    end)
    if success and hasCooldown then
        pcall(function()
            mobileBankingButton.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
        end)
        mobileBankingButton:SetAlpha(0.5)
    else
        mobileBankingButton.cooldown:Clear()
        mobileBankingButton:SetAlpha(1)
    end
end

-- Create Druid teleport button (Dreamwalk or Moonglade)
local function CreateDruidTeleportButton(parent, index)
    local button = CreateFrame("Button", "TakeMeHomeDruidTeleport", parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Position will be set by RepositionButtons
    button:SetPoint("LEFT", parent, "LEFT", 0, 0)

    button:SetAttribute("type", "spell")
    -- Spell will be set dynamically in UpdateDruidTeleportButton

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(true)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spellID or 0)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Start hidden
    button:Hide()

    return button
end

-- Update the Druid teleport button
local function UpdateDruidTeleportButton()
    if not druidTeleportButton then return end

    -- Can't modify secure buttons during combat
    if InCombatLockdown() then return end

    -- Only show for Druids
    if not IsDruid() then
        druidTeleportButton:Hide()
        return
    end

    -- Check if enabled in settings
    if not IsButtonEnabled("druid_teleport") then
        druidTeleportButton:Hide()
        return
    end

    -- Check for Dreamwalk first, then fall back to Moonglade
    local spellToUse = nil
    local dreamwalkInfo = C_Spell.GetSpellInfo(DRUID_SPELLS.dreamwalk.spellID)
    local moongladeInfo = C_Spell.GetSpellInfo(DRUID_SPELLS.moonglade.spellID)

    -- Prefer Dreamwalk if known
    if dreamwalkInfo and IsSpellKnown(DRUID_SPELLS.dreamwalk.spellID) then
        spellToUse = { spellID = DRUID_SPELLS.dreamwalk.spellID, name = DRUID_SPELLS.dreamwalk.name, info = dreamwalkInfo }
    elseif moongladeInfo and IsSpellKnown(DRUID_SPELLS.moonglade.spellID) then
        spellToUse = { spellID = DRUID_SPELLS.moonglade.spellID, name = DRUID_SPELLS.moonglade.name, info = moongladeInfo }
    end

    if not spellToUse then
        druidTeleportButton:Hide()
        return
    end

    druidTeleportButton:Show()
    druidTeleportButton.spellID = spellToUse.spellID
    druidTeleportButton:SetAttribute("spell", spellToUse.name)

    -- Update icon
    local icon = spellToUse.info.iconID
    if icon then
        druidTeleportButton.icon:SetTexture(icon)
    end

    -- Update cooldown
    local cooldownInfo = C_Spell.GetSpellCooldown(spellToUse.spellID)
    local success, hasCooldown = pcall(function()
        return cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration and cooldownInfo.duration > 0
    end)
    if success and hasCooldown then
        pcall(function()
            druidTeleportButton.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
        end)
        druidTeleportButton:SetAlpha(0.5)
    else
        druidTeleportButton.cooldown:Clear()
        druidTeleportButton:SetAlpha(1)
    end
end

-- Update button appearance and cooldown
local function UpdateButton(button)
    local itemID = button.itemID
    local hasItem = false
    local icon = nil
    local useAltHearthstone = false
    local altHearthstone = nil

    -- Can't modify secure buttons during combat
    if InCombatLockdown() then return button:IsShown() end

    -- Check if button is enabled in settings
    if not IsButtonEnabled(button.settingsKey) then
        button:Hide()
        return false
    end

    if button.isToy then
        -- Check if player has the toy
        hasItem = PlayerHasToy(itemID)
        if hasItem then
            local _, _, toyIcon = C_ToyBox.GetToyInfo(itemID)
            icon = toyIcon
        end
    else
        -- Check if player has the item in bags
        local count = C_Item.GetItemCount(itemID)
        hasItem = count > 0

        -- Special handling for main Hearthstone: fallback to random toy hearthstone
        if not hasItem and itemID == 6948 then
            altHearthstone = GetRandomAlternativeHearthstone()
            if altHearthstone then
                useAltHearthstone = true
                hasItem = true
                local _, _, toyIcon = C_ToyBox.GetToyInfo(altHearthstone.itemID)
                icon = toyIcon
                itemID = altHearthstone.itemID
            end
        else
            icon = C_Item.GetItemIconByID(itemID)
        end
    end

    -- Hide if player doesn't have the item/toy
    if not hasItem then
        button:Hide()
        return false
    end

    button:Show()
    if icon then
        button.icon:SetTexture(icon)
    end

    -- Check if toy is usable (for Garrison/Dalaran hearthstones that require content completion)
    local isUsable = true
    if button.isToy then
        -- First check the general toy usability
        isUsable = C_ToyBox.IsToyUsable(itemID)

        -- Specific quest completion checks for hearthstones
        -- Garrison Hearthstone (110560) requires quest 34586 (Establishing Your Garrison) for Alliance
        -- or quest 34378 for Horde
        if itemID == 110560 then
            local allianceQuestDone = C_QuestLog.IsQuestFlaggedCompleted(34586)
            local hordeQuestDone = C_QuestLog.IsQuestFlaggedCompleted(34378)
            if not allianceQuestDone and not hordeQuestDone then
                isUsable = false
            end
        end

        -- Dalaran Hearthstone (140192) requires quest 44184 (In the Blink of an Eye)
        if itemID == 140192 then
            local questDone = C_QuestLog.IsQuestFlaggedCompleted(44184)
            if not questDone then
                isUsable = false
            end
        end
    end

    -- Grey out unusable toys but still show them
    if isUsable then
        button:SetAlpha(1)
        button.icon:SetDesaturated(false)
    else
        button:SetAlpha(0.6)
        button.icon:SetDesaturated(true)  -- Makes icon grey/desaturated
    end
    button:Enable()
    button.isUsable = isUsable  -- Store for tooltip

    -- Update secure attributes for alternative hearthstone (only out of combat)
    if useAltHearthstone and altHearthstone and not InCombatLockdown() then
        button:SetAttribute("type", "toy")
        button:SetAttribute("toy", altHearthstone.itemID)
        button:SetAttribute("item", nil)
        button.currentAltHearthstone = altHearthstone
    elseif button.itemID == 6948 and not useAltHearthstone and not InCombatLockdown() then
        -- Reset to regular hearthstone if it's back in bags
        button:SetAttribute("type", "item")
        button:SetAttribute("item", "Hearthstone")
        button:SetAttribute("toy", nil)
        button.currentAltHearthstone = nil
    end

    -- Update cooldown
    local start, duration = GetItemCooldown(itemID)
    if start and duration and duration > 0 then
        button.cooldown:SetCooldown(start, duration)
    else
        button.cooldown:Clear()
    end

    return true
end

-- Reposition all visible buttons and update frame size (2 rows layout)
local function RepositionButtons()
    -- Don't reposition secure buttons during combat
    if InCombatLockdown() then return end

    local row1Count = 0  -- Hearthstones (top row)
    local row2Count = 0  -- Utilities (bottom row)

    -- Row 1: Travel item buttons (hearthstones)
    for _, button in ipairs(buttons) do
        if button:IsShown() then
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", row1Count * (buttonSize + buttonSpacing), 0)
            row1Count = row1Count + 1
        end
    end

    -- Druid teleport button (Row 1, after hearthstones)
    if druidTeleportButton and druidTeleportButton:IsShown() then
        druidTeleportButton:ClearAllPoints()
        druidTeleportButton:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", row1Count * (buttonSize + buttonSpacing), 0)
        row1Count = row1Count + 1
    end

    -- Row 2: Utility buttons (mailbox, warband bank)
    local row2Y = -(buttonSize + buttonSpacing)

    -- Reposition mailbox button
    if mailboxButton and mailboxButton:IsShown() then
        mailboxButton:ClearAllPoints()
        mailboxButton:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", row2Count * (buttonSize + buttonSpacing), row2Y)
        row2Count = row2Count + 1
    end

    -- Reposition warband bank button
    if warbandBankButton and warbandBankButton:IsShown() then
        warbandBankButton:ClearAllPoints()
        warbandBankButton:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", row2Count * (buttonSize + buttonSpacing), row2Y)
        row2Count = row2Count + 1
    end

    -- Reposition mobile banking button
    if mobileBankingButton and mobileBankingButton:IsShown() then
        mobileBankingButton:ClearAllPoints()
        mobileBankingButton:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", row2Count * (buttonSize + buttonSpacing), row2Y)
        row2Count = row2Count + 1
    end

    -- Update frame size based on visible buttons
    local maxColumns = math.max(row1Count, row2Count)
    local numRows = 0
    if row1Count > 0 then numRows = numRows + 1 end
    if row2Count > 0 then numRows = numRows + 1 end

    if maxColumns > 0 and numRows > 0 then
        local width = (maxColumns * buttonSize) + ((maxColumns - 1) * buttonSpacing) + 10
        -- Add extra height for banner only when unlocked
        local bannerPadding = (TakeMeHomeDB and TakeMeHomeDB.locked) and 10 or 20
        local height = (numRows * buttonSize) + ((numRows - 1) * buttonSpacing) + bannerPadding
        mainFrame:SetSize(width, height)
        if userWantsWindowsVisible and not windowHiddenByBar["main"] then
            mainFrame:Show()
        elseif windowHiddenByBar["main"] then
            mainFrame:Hide()
        end
        UpdateMainDragBanner()
    else
        mainFrame:Hide()
    end
end

-- Update all buttons
local function UpdateAllButtons()
    for _, button in ipairs(buttons) do
        UpdateButton(button)
    end
    UpdateMailboxButton()
    UpdateWarbandBankButton()
    UpdateMobileBankingButton()
    UpdateDruidTeleportButton()
    RepositionButtons()
end

-- Check if player has any usable mailbox toys
local function HasAnyMailboxToy()
    for _, toyData in ipairs(MAILBOX_TOYS) do
        if PlayerHasToy(toyData.itemID) and C_ToyBox.IsToyUsable(toyData.itemID) then
            return true
        end
    end
    return false
end

-- Check if player knows the Warband Bank spell
local function HasWarbandBankSpell()
    local spellInfo = C_Spell.GetSpellInfo(WARBAND_BANK_SPELL.name)
    return spellInfo ~= nil
end

-- Calculate frame size based on number of items (initial setup)
local function UpdateFrameSize()
    -- This is now handled by RepositionButtons
    RepositionButtons()
end

-- Initialize buttons
local function InitializeButtons()
    for i, itemData in ipairs(TRAVEL_ITEMS) do
        local button = CreateItemButton(i, itemData)
        table.insert(buttons, button)
    end

    -- Track position for optional buttons
    local nextIndex = #TRAVEL_ITEMS

    -- Create mailbox button (positioned after travel items)
    mailboxButton = CreateMailboxButton(buttonContainer, nextIndex)
    nextIndex = nextIndex + 1

    -- Create Warband Bank button (positioned after mailbox)
    warbandBankButton = CreateWarbandBankButton(buttonContainer, nextIndex)
    nextIndex = nextIndex + 1

    -- Create Mobile Banking button (positioned after warband bank)
    mobileBankingButton = CreateMobileBankingButton(buttonContainer, nextIndex)
    nextIndex = nextIndex + 1

    -- Create Druid Teleport button (only visible for Druids)
    druidTeleportButton = CreateDruidTeleportButton(buttonContainer, nextIndex)

    UpdateFrameSize()
end

-- Event handling
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("BAG_UPDATE")
mainFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("TOYS_UPDATED")
mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Out of combat, can update secure buttons

mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Initialize saved variables
        if not TakeMeHomeDB then
            TakeMeHomeDB = CopyTable(defaults)
        end

        -- Ensure buttonSettings exists (for upgrades from older versions)
        if not TakeMeHomeDB.buttonSettings then
            TakeMeHomeDB.buttonSettings = CopyTable(defaults.buttonSettings)
        end

        -- Ensure professionPosition exists
        if not TakeMeHomeDB.professionPosition then
            TakeMeHomeDB.professionPosition = CopyTable(defaults.professionPosition)
        end

        -- Ensure mountsPosition exists
        if not TakeMeHomeDB.mountsPosition then
            TakeMeHomeDB.mountsPosition = CopyTable(defaults.mountsPosition)
        end

        -- Ensure professionSettings exists
        if not TakeMeHomeDB.professionSettings then
            TakeMeHomeDB.professionSettings = {}
        end

        -- Ensure selectedMounts exists
        if not TakeMeHomeDB.selectedMounts then
            TakeMeHomeDB.selectedMounts = CopyTable(defaults.selectedMounts)
        end

        -- Ensure functionPosition exists
        if not TakeMeHomeDB.functionPosition then
            TakeMeHomeDB.functionPosition = CopyTable(defaults.functionPosition)
        end

        -- Ensure functionSettings exists
        if not TakeMeHomeDB.functionSettings then
            TakeMeHomeDB.functionSettings = CopyTable(defaults.functionSettings)
        end

        -- Ensure missionPosition exists
        if not TakeMeHomeDB.missionPosition then
            TakeMeHomeDB.missionPosition = CopyTable(defaults.missionPosition)
        end

        -- Ensure missionSettings exists
        if not TakeMeHomeDB.missionSettings then
            TakeMeHomeDB.missionSettings = CopyTable(defaults.missionSettings)
        end

        -- Ensure snap/link settings exist
        if TakeMeHomeDB.snapEnabled == nil then
            TakeMeHomeDB.snapEnabled = defaults.snapEnabled
        end
        if not TakeMeHomeDB.linkedWindows then
            TakeMeHomeDB.linkedWindows = {}
        end

        -- Ensure infoBarSettings exists
        if not TakeMeHomeDB.infoBarSettings then
            TakeMeHomeDB.infoBarSettings = CopyTable(defaults.infoBarSettings)
        end
        if TakeMeHomeDB.infoBarSettings.enabled == nil then
            TakeMeHomeDB.infoBarSettings.enabled = true
        end
        if not TakeMeHomeDB.infoBarSettings.modules then
            TakeMeHomeDB.infoBarSettings.modules = CopyTable(defaults.infoBarSettings.modules)
        end
        for key, defaultModule in pairs(defaults.infoBarSettings.modules) do
            if not TakeMeHomeDB.infoBarSettings.modules[key] then
                TakeMeHomeDB.infoBarSettings.modules[key] = CopyTable(defaultModule)
            end
        end
        -- Remove legacy att text module if it exists
        TakeMeHomeDB.infoBarSettings.modules["att"] = nil
        if TakeMeHomeDB.infoBarSettings.attButton == nil then
            TakeMeHomeDB.infoBarSettings.attButton = defaults.infoBarSettings.attButton
        end

        -- Ensure all button keys exist
        for key, defaultSettings in pairs(defaults.buttonSettings) do
            if not TakeMeHomeDB.buttonSettings[key] then
                TakeMeHomeDB.buttonSettings[key] = CopyTable(defaultSettings)
            end
        end

        -- Restore per-window bar visibility overrides
        if not TakeMeHomeDB.hiddenWindows then
            TakeMeHomeDB.hiddenWindows = {}
        end
        wipe(windowHiddenByBar)
        for key, hidden in pairs(TakeMeHomeDB.hiddenWindows) do
            if hidden then windowHiddenByBar[key] = true end
        end

        -- Initialize window registry for snapping/linking
        InitializeWindowRegistry()

        -- Restore position
        local pos = TakeMeHomeDB.position
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)

        -- Create buttons
        InitializeButtons()

        -- Initialize professions window
        InitializeProfessions()

        -- Initialize mounts window
        InitializeMounts()

        -- Initialize function window
        InitializeFunction()

        -- Initialize mission table window
        InitializeMissions()

        -- Initialize info bar
        InitializeInfoBar()

        -- Initial update
        C_Timer.After(1, UpdateAllButtons)

        -- Set up periodic updates (to swap mailbox toy when cooldowns end)
        C_Timer.NewTicker(1, function()
            if not InCombatLockdown() then
                UpdateAllButtons()
            end
            UpdateInfoBar()
        end)

        print("|cff00ff00TakeMeHome|r loaded! Type |cff00ffff/tmh|r for commands.")
    elseif event == "BAG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, UpdateAllButtons)
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "TOYS_UPDATED" then
        UpdateAllButtons()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Update secure button attributes when leaving combat
        UpdateMailboxButton()
        UpdateWarbandBankButton()
        UpdateMobileBankingButton()
        UpdateDruidTeleportButton()
    end
end)

-- ============================================
-- HELPER FUNCTIONS FOR CONFIG PANEL
-- (defined here so they're available in CreateConfigPanel)
-- ============================================

-- Gathering professions that don't have a crafting window
local GATHERING_PROFESSIONS = {
    ["Mining"] = true,
    ["Herbalism"] = true,
    ["Skinning"] = true,
}

-- Get all learned professions (excludes gathering professions without crafting windows)
local function GetLearnedProfessions()
    local professions = {}
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    local profIndices = { prof1, prof2, archaeology, fishing, cooking }

    for _, profIndex in ipairs(profIndices) do
        if profIndex then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLineID = GetProfessionInfo(profIndex)
            if name and icon and not GATHERING_PROFESSIONS[name] then
                table.insert(professions, {
                    name = name,
                    icon = icon,
                    skillLineID = skillLineID,
                    skillLevel = skillLevel,
                    maxSkillLevel = maxSkillLevel
                })
            end
        end
    end
    return professions
end

-- Get mount info by spell ID
local function GetMountInfoBySpellID(spellID)
    local mountIDs = C_MountJournal.GetMountIDs()
    for _, mountID in ipairs(mountIDs) do
        local name, mountSpellID, icon, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if mountSpellID == spellID then
            return name, icon, isCollected, isUsable, mountID
        end
    end
    return nil
end

-- ============================================
-- CONFIGURATION PANEL (v1.9 — sidebar nav)
-- ============================================

local function MakeBackdropFrame(parent, w, h)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
    f:SetBackdropColor(0.07, 0.07, 0.10, 0.97)
    f:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
    return f
end

local function MakeLabel(parent, text, font, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text)
    if r then fs:SetTextColor(r, g, b) end
    return fs
end

local function MakeCheckRow(parent, yOff, label, isChecked, onToggle, altText)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(480, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)
    row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
    row:SetBackdropColor(0.10, 0.10, 0.13, 0.4)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetPoint("LEFT", row, "LEFT", 4, 0)
    cb:SetChecked(isChecked)
    cb:SetScript("OnClick", function(self) onToggle(self:GetChecked()) end)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    lbl:SetText(label)
    if altText then
        local sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sub:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        sub:SetText(altText)
        sub:SetTextColor(0.5, 0.5, 0.55)
    end
    return row, cb
end

local function MakeUpDownRow(parent, yOff, label, index, totalCount, onUp, onDown, altText, stripeIndex)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(480, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)
    row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
    row:SetBackdropColor(0.10, 0.10, 0.13, stripeIndex and stripeIndex%2==0 and 0.5 or 0)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
    lbl:SetText(label)
    if altText then
        local sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sub:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        sub:SetText(altText)
        sub:SetTextColor(0.5, 0.5, 0.55)
    end
    return row
end

local function CreateConfigPanel()
    if configFrame then configFrame:Show() return end

    local PANEL_W, PANEL_H = 720, 540
    local NAV_W = 160
    local CONTENT_W = PANEL_W - NAV_W - 3

    configFrame = CreateFrame("Frame", "TakeMeHomeConfig", UIParent, "BackdropTemplate")
    configFrame:SetSize(PANEL_W, PANEL_H)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetClampedToScreen(true)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1, insets={left=1,right=1,top=1,bottom=1} })
    configFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.98)
    configFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    configFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    -- Title bar
    local titleBar = configFrame:CreateTexture(nil, "ARTWORK")
    titleBar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(32)
    titleBar:SetColorTexture(0.10, 0.10, 0.14, 1)

    local cogTex = configFrame:CreateTexture(nil, "OVERLAY")
    cogTex:SetSize(20, 20)
    cogTex:SetPoint("LEFT", configFrame, "LEFT", 10, PANEL_H/2 - 16)
    cogTex:SetTexture("Interface\\Icons\\Trade_Engineering")
    cogTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local titleFS = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetPoint("TOP", configFrame, "TOP", 0, -9)
    titleFS:SetText("|cff4da6ffTakeMeHome|r  Settings")

    local closeBtn = CreateFrame("Button", nil, configFrame)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -6, -6)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.5, 0.15, 0.15, 0)
    closeBtn:SetNormalFontObject("GameFontNormal")
    closeBtn:SetText("×")
    closeBtn:SetScript("OnEnter", function() closeBg:SetColorTexture(0.7, 0.15, 0.15, 0.9) end)
    closeBtn:SetScript("OnLeave", function() closeBg:SetColorTexture(0.5, 0.15, 0.15, 0) end)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    -- Left navigation panel
    local navPanel = CreateFrame("Frame", nil, configFrame, "BackdropTemplate")
    navPanel:SetSize(NAV_W, PANEL_H - 34)
    navPanel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 1, -33)
    navPanel:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
    navPanel:SetBackdropColor(0.05, 0.05, 0.08, 1)

    -- Divider between nav and content
    local divider = configFrame:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", navPanel, "BOTTOMRIGHT", 0, 0)
    divider:SetColorTexture(0.25, 0.25, 0.30, 1)

    -- Content area (scrollable)
    local contentScroll = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    contentScroll:SetPoint("TOPLEFT", navPanel, "TOPRIGHT", 4, -4)
    contentScroll:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -22, 4)

    local contentParent = CreateFrame("Frame", nil, contentScroll)
    contentParent:SetSize(CONTENT_W - 30, 2000)
    contentScroll:SetScrollChild(contentParent)

    -- Section content frames (only one shown at a time)
    local sections = {}
    local navButtons = {}
    local navSectionCount = 0
    local activeSection = nil

    local function ShowSection(key)
        activeSection = key
        for k, frame in pairs(sections) do
            if k == key then frame:Show() else frame:Hide() end
        end
        for k, btn in pairs(navButtons) do
            if k == key then btn:SetBackdropColor(0.15, 0.40, 0.70, 1)
            else              btn:SetBackdropColor(0.10, 0.10, 0.14, 0) end
        end
        contentScroll:SetVerticalScroll(0)
    end

    local function AddSection(key, label, icon)
        local sec = CreateFrame("Frame", nil, contentParent)
        sec:SetSize(CONTENT_W - 30, 1800)
        sec:SetPoint("TOPLEFT")
        sec:Hide()
        sections[key] = sec

        -- Nav button
        local yPos = -(28 * navSectionCount)
        navSectionCount = navSectionCount + 1
        local navBtn = CreateFrame("Button", nil, navPanel, "BackdropTemplate")
        navBtn:SetSize(NAV_W, 28)
        navBtn:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 0, yPos)
        navBtn:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
        navBtn:SetBackdropColor(0.10, 0.10, 0.14, 0)
        local navHL = navBtn:CreateTexture(nil, "HIGHLIGHT")
        navHL:SetAllPoints()
        navHL:SetColorTexture(0.3, 0.5, 0.8, 0.2)
        if icon then
            local ic = navBtn:CreateTexture(nil, "ARTWORK")
            ic:SetSize(16, 16)
            ic:SetPoint("LEFT", navBtn, "LEFT", 8, 0)
            ic:SetTexture(icon)
            ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        local navLbl = navBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        navLbl:SetPoint("LEFT", navBtn, "LEFT", icon and 30 or 10, 0)
        navLbl:SetText(label)
        navBtn:SetScript("OnClick", function() ShowSection(key) end)
        navButtons[key] = navBtn
        return sec
    end

    -- ====================================================
    -- GENERAL section
    -- ====================================================
    local genSec = AddSection("general", "General", "Interface\\Icons\\inv_misc_gear_01")
    do
        local y = -8
        local hdr = genSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", genSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffGeneral|r")
        y = y - 30

        -- Scale slider
        local scaleLabel = genSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        scaleLabel:SetPoint("TOPLEFT", genSec, "TOPLEFT", 4, y)
        scaleLabel:SetText("Window Scale")
        y = y - 22

        local slider = CreateFrame("Slider", "TakeMeHomeConfigScaleSlider", genSec, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", genSec, "TOPLEFT", 4, y)
        slider:SetWidth(280)
        slider:SetMinMaxValues(0.4, 1.5)
        slider:SetValueStep(0.05)
        slider:SetValue(TakeMeHomeDB and TakeMeHomeDB.scale or 0.75)
        _G[slider:GetName().."Low"]:SetText("0.4×")
        _G[slider:GetName().."High"]:SetText("1.5×")
        _G[slider:GetName().."Text"]:SetText(string.format("%.2f×", slider:GetValue()))
        slider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val * 20 + 0.5) / 20
            _G[self:GetName().."Text"]:SetText(string.format("%.2f×", val))
            UpdateScale(val)
        end)
        y = y - 48

        -- Lock toggle
        MakeCheckRow(genSec, y, "Lock all window positions",
            TakeMeHomeDB and TakeMeHomeDB.locked or false,
            function(v)
                TakeMeHomeDB.locked = v
                UpdateMainDragBanner(); UpdateProfDragBanner()
                UpdateMountsDragBanner(); UpdateFuncDragBanner()
            end)
        y = y - 32

        -- Snap toggle
        MakeCheckRow(genSec, y, "Enable window snapping",
            TakeMeHomeDB and TakeMeHomeDB.snapEnabled ~= false or true,
            function(v) TakeMeHomeDB.snapEnabled = v end)
        y = y - 48

        -- Reset button
        local resetBtn = CreateFrame("Button", nil, genSec, "BackdropTemplate")
        resetBtn:SetSize(160, 26)
        resetBtn:SetPoint("TOPLEFT", genSec, "TOPLEFT", 4, y)
        resetBtn:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1 })
        resetBtn:SetBackdropColor(0.20, 0.20, 0.25, 1)
        resetBtn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
        local resetLbl = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        resetLbl:SetPoint("CENTER")
        resetLbl:SetText("Reset All Positions")
        resetBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.5, 0.7, 1) end)
        resetBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 1) end)
        resetBtn:SetScript("OnClick", function()
            SlashCmdList["TAKEMEHOME"]("reset")
        end)
    end

    -- ====================================================
    -- INFO BAR section
    -- ====================================================
    local barSec = AddSection("bar", "Info Bar", "Interface\\Icons\\inv_misc_spyglass_02")
    do
        local y = -8
        local hdr = barSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", barSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffInfo Bar|r")
        y = y - 30

        -- Enable bar
        MakeCheckRow(barSec, y, "Enable Info Bar",
            TakeMeHomeDB and TakeMeHomeDB.infoBarSettings and TakeMeHomeDB.infoBarSettings.enabled or true,
            function(v) if TakeMeHomeDB.infoBarSettings then TakeMeHomeDB.infoBarSettings.enabled = v; UpdateInfoBar() end end)
        y = y - 32

        -- Position buttons
        local posLabel = barSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        posLabel:SetPoint("TOPLEFT", barSec, "TOPLEFT", 4, y)
        posLabel:SetText("Bar Position:")
        y = y - 26

        local function MakePosBtn(parent, yy, label, posVal)
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(80, 24)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4 + (posVal == "TOP" and 88 or 0), yy)
            btn:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1 })
            local isActive = TakeMeHomeDB and TakeMeHomeDB.infoBarSettings and TakeMeHomeDB.infoBarSettings.position == posVal
            btn:SetBackdropColor(isActive and 0.2 or 0.12, isActive and 0.5 or 0.12, isActive and 0.8 or 0.15, 1)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            btn:SetScript("OnClick", function()
                if TakeMeHomeDB.infoBarSettings then
                    TakeMeHomeDB.infoBarSettings.position = posVal
                    UpdateInfoBarPosition()
                    -- Refresh section
                    ShowSection("bar")
                end
            end)
            return btn
        end
        MakePosBtn(barSec, y, "Bottom", "BOTTOM")
        MakePosBtn(barSec, y, "Top",    "TOP")
        y = y - 34

        -- ATT button toggle (if ATT loaded)
        if C_AddOns.IsAddOnLoaded("AllTheThings") then
            local attRow, attCB = MakeCheckRow(barSec, y,
                "|cffcc99ffAll The Things|r expansion menu",
                TakeMeHomeDB and TakeMeHomeDB.infoBarSettings and TakeMeHomeDB.infoBarSettings.attButton ~= false or true,
                function(v)
                    TakeMeHomeDB.infoBarSettings.attButton = v
                    print("|cff00ff00TakeMeHome|r: Reload UI to apply ATT button change.")
                end)
            y = y - 36
        end

        -- Modules header
        local modHdr = barSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modHdr:SetPoint("TOPLEFT", barSec, "TOPLEFT", 4, y)
        modHdr:SetText("|cff888888Text Modules|r")
        y = y - 22

        local secColors = { left="|cff88aaff", center="|cff88ffaa", right="|cffffaa88" }
        for i, mod in ipairs(INFO_BAR_MODULES) do
            local addonLoaded = not mod.addonName or C_AddOns.IsAddOnLoaded(mod.addonName)
            local settings = TakeMeHomeDB and TakeMeHomeDB.infoBarSettings and TakeMeHomeDB.infoBarSettings.modules[mod.key]
            local row = CreateFrame("Frame", nil, barSec, "BackdropTemplate")
            row:SetSize(480, 26)
            row:SetPoint("TOPLEFT", barSec, "TOPLEFT", 0, y)
            row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
            row:SetBackdropColor(0.10, 0.10, 0.13, i%2==0 and 0.5 or 0)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetPoint("LEFT", row, "LEFT", 4, 0)
            cb:SetChecked(settings and settings.enabled or false)
            cb.modKey = mod.key
            if addonLoaded then
                cb:SetScript("OnClick", function(self)
                    if TakeMeHomeDB.infoBarSettings.modules[self.modKey] then
                        TakeMeHomeDB.infoBarSettings.modules[self.modKey].enabled = self:GetChecked()
                        UpdateInfoBar()
                    end
                end)
            else
                cb:SetEnabled(false); cb:SetAlpha(0.4)
            end

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetText(mod.name)
            if not addonLoaded then lbl:SetTextColor(0.5,0.5,0.5) end

            local secLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            secLbl:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            local hasClick = INFO_MODULE_ACTIONS[mod.key] ~= nil
            local secText = (secColors[mod.section] or "|cff888888") .. mod.section .. "|r"
            if hasClick then secText = secText .. " |cff44ff88⊕|r" end
            secLbl:SetText(secText)

            y = y - 27
        end
    end

    -- ====================================================
    -- TRAVEL section
    -- ====================================================
    local travelSec = AddSection("travel", "Travel",  "Interface\\Icons\\inv_misc_rune_01")
    do
        local y = -8
        local hdr = travelSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", travelSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffTravel Buttons|r")
        y = y - 30

        for i, def in ipairs(BUTTON_DEFINITIONS) do
            local row = CreateFrame("Frame", nil, travelSec, "BackdropTemplate")
            row:SetSize(480, 28)
            row:SetPoint("TOPLEFT", travelSec, "TOPLEFT", 0, y)
            row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
            row:SetBackdropColor(0.10, 0.10, 0.13, i%2==0 and 0.5 or 0)
            local cb = CreateFrame("CheckButton", "TakeMeHomeTravelCheck2"..def.key, row, "UICheckButtonTemplate")
            cb:SetPoint("LEFT", row, "LEFT", 4, 0)
            if TakeMeHomeDB and TakeMeHomeDB.buttonSettings and TakeMeHomeDB.buttonSettings[def.key] then
                cb:SetChecked(TakeMeHomeDB.buttonSettings[def.key].enabled)
            end
            cb.key = def.key
            cb:SetScript("OnClick", function(self)
                TakeMeHomeDB.buttonSettings[self.key].enabled = self:GetChecked()
                UpdateAllButtons()
            end)
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetText(def.name)
            local rowLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowLbl:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            rowLbl:SetText("|cff888888Row " .. def.row .. "|r")
            y = y - 30
        end
    end

    -- ====================================================
    -- PROFESSIONS section
    -- ====================================================
    local profSec = AddSection("professions", "Professions", "Interface\\Icons\\trade_alchemy")
    do
        local y = -8
        local hdr = profSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", profSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffProfessions|r")
        y = y - 30

        local function RefreshProfSection()
            for _, c in ipairs({profSec:GetChildren()}) do c:Hide(); c:SetParent(nil) end
            local profs = GetLearnedProfessions()
            if #profs == 0 then
                local msg = profSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                msg:SetPoint("TOPLEFT", profSec, "TOPLEFT", 4, -8)
                msg:SetText("No crafting professions learned")
                msg:SetTextColor(0.5, 0.5, 0.5)
                return
            end
            table.sort(profs, function(a,b) return GetProfessionOrder(a.name) < GetProfessionOrder(b.name) end)
            local ly = -8
            for i, prof in ipairs(profs) do
                if not TakeMeHomeDB.professionSettings[prof.name] then
                    TakeMeHomeDB.professionSettings[prof.name] = { enabled=true, order=i }
                end
                local row = CreateFrame("Frame", nil, profSec, "BackdropTemplate")
                row:SetSize(480, 28)
                row:SetPoint("TOPLEFT", profSec, "TOPLEFT", 0, ly)
                row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
                row:SetBackdropColor(0.10, 0.10, 0.13, i%2==0 and 0.5 or 0)
                local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                cb:SetPoint("LEFT", row, "LEFT", 4, 0)
                cb:SetChecked(IsProfessionEnabled(prof.name))
                cb.profName = prof.name
                cb:SetScript("OnClick", function(self)
                    TakeMeHomeDB.professionSettings[self.profName].enabled = self:GetChecked()
                    UpdateProfessionButtons()
                end)
                local ic = row:CreateTexture(nil, "ARTWORK")
                ic:SetSize(18, 18); ic:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                ic:SetTexture(prof.icon); ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetPoint("LEFT", ic, "RIGHT", 4, 0)
                lbl:SetText(prof.name)
                ly = ly - 30
            end
        end
        RefreshProfSection()
    end

    -- ====================================================
    -- MOUNTS section
    -- ====================================================
    local mountsSec = AddSection("mounts", "Mounts", "Interface\\Icons\\ability_mount_mountainram")
    do
        local y = -8
        local hdr = mountsSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffMounts|r  |cff888888(max 6)|r")
        y = y - 30

        local function RefreshMountsSection()
            for _, c in ipairs({mountsSec:GetChildren()}) do c:Hide(); c:SetParent(nil) end
            local sel = TakeMeHomeDB.selectedMounts or {}
            local ly = -8
            local hdr2 = mountsSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            hdr2:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 4, ly)
            hdr2:SetText(string.format("|cff4da6ffSelected (%d/6)|r", #sel))
            ly = ly - 22

            for i, me in ipairs(sel) do
                local name, icon, collected = GetMountInfoBySpellID(me.spellID)
                local row = CreateFrame("Frame", nil, mountsSec, "BackdropTemplate")
                row:SetSize(480, 26)
                row:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 0, ly)
                row:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
                row:SetBackdropColor(0.10, 0.10, 0.13, i%2==0 and 0.95 or 0.85)
                local ic = row:CreateTexture(nil, "ARTWORK")
                ic:SetSize(18,18); ic:SetPoint("LEFT", row, "LEFT", 5, 0)
                if icon then ic:SetTexture(icon); ic:SetTexCoord(0.08,0.92,0.08,0.92) end
                if not collected then ic:SetDesaturated(true) end
                local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                lbl:SetPoint("LEFT", ic, "RIGHT", 4, 0); lbl:SetWidth(200)
                lbl:SetText(name or "Unknown")
                if not collected then lbl:SetTextColor(0.5,0.5,0.5) end
                local remBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                remBtn:SetSize(20,18); remBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                remBtn:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1 })
                remBtn:SetBackdropColor(0.4, 0.1, 0.1, 1)
                local rl = remBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); rl:SetPoint("CENTER"); rl:SetText("×")
                remBtn.idx = i
                remBtn:SetScript("OnClick", function(self)
                    table.remove(TakeMeHomeDB.selectedMounts, self.idx)
                    UpdateMountButtons(); RefreshMountsSection()
                end)
                ly = ly - 28
            end

            if #sel < 6 then
                ly = ly - 10
                local addHdr = mountsSec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addHdr:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 4, ly)
                addHdr:SetText("|cff4da6ffAdd Mount|r")
                ly = ly - 22
                local sb = CreateFrame("EditBox", "TakeMeHomeMountSearch2", mountsSec, "InputBoxTemplate")
                sb:SetSize(300, 22); sb:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 8, ly)
                sb:SetAutoFocus(false); sb:SetMaxLetters(50)
                ly = ly - 28
                local rc = CreateFrame("Frame", nil, mountsSec)
                rc:SetSize(480, 120); rc:SetPoint("TOPLEFT", mountsSec, "TOPLEFT", 0, ly)
                local function DoSearch(txt)
                    for _, c in ipairs({rc:GetChildren()}) do c:Hide(); c:SetParent(nil) end
                    if not txt or txt=="" then return end
                    txt = txt:lower()
                    local results, n = {}, 0
                    for _, mid in ipairs(C_MountJournal.GetMountIDs()) do
                        local mn, ms, mi, _, _, _, _, _, _, _, mc = C_MountJournal.GetMountInfoByID(mid)
                        if mc and mn and mn:lower():find(txt, 1, true) then
                            local already = false
                            for _, sm in ipairs(TakeMeHomeDB.selectedMounts) do if sm.spellID==ms then already=true; break end end
                            if not already then table.insert(results,{name=mn,spellID=ms,icon=mi}); n=n+1; if n>=5 then break end end
                        end
                    end
                    local ry=0
                    for _, res in ipairs(results) do
                        local rr = CreateFrame("Frame", nil, rc, "BackdropTemplate")
                        rr:SetSize(470, 22); rr:SetPoint("TOPLEFT", rc, "TOPLEFT", 0, ry)
                        rr:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8" })
                        rr:SetBackdropColor(0.12,0.12,0.15,0.8)
                        local ri = rr:CreateTexture(nil,"ARTWORK"); ri:SetSize(16,16)
                        ri:SetPoint("LEFT",rr,"LEFT",4,0); ri:SetTexture(res.icon); ri:SetTexCoord(0.08,0.92,0.08,0.92)
                        local rl2 = rr:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
                        rl2:SetPoint("LEFT",ri,"RIGHT",4,0); rl2:SetWidth(200); rl2:SetText(res.name)
                        local ab = CreateFrame("Button", nil, rr, "BackdropTemplate")
                        ab:SetSize(26,18); ab:SetPoint("RIGHT",rr,"RIGHT",-4,0)
                        ab:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1 })
                        ab:SetBackdropColor(0.1,0.3,0.1,1)
                        local al2 = ab:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); al2:SetPoint("CENTER"); al2:SetText("+")
                        ab.sID = res.spellID
                        ab:SetScript("OnClick", function(self)
                            if #TakeMeHomeDB.selectedMounts >= 6 then return end
                            table.insert(TakeMeHomeDB.selectedMounts, {spellID=self.sID})
                            UpdateMountButtons(); sb:SetText(""); RefreshMountsSection()
                        end)
                        ry = ry - 24
                    end
                end
                sb:SetScript("OnTextChanged", function(self) DoSearch(self:GetText()) end)
                sb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
            end
        end
        RefreshMountsSection()
    end

    -- ====================================================
    -- FUNCTION section
    -- ====================================================
    local funcSec = AddSection("function", "Function", "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    do
        local y = -8
        local hdr = funcSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", funcSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffFunction Buttons|r")
        y = y - 30

        local FUNC_DEFS_CFG = {
            { key="logout",     name="Logout" },
            { key="afk",        name="AFK Toggle" },
            { key="sit",        name="Sit / Stand" },
            { key="screenshot", name="Screenshot" },
            { key="lootspec",   name="Loot Spec Cycle" },
            { key="readycheck", name="Ready Check" },
            { key="openbags",   name="Open All Bags" },
        }
        for i, def in ipairs(FUNC_DEFS_CFG) do
            local enabled = true
            if TakeMeHomeDB and TakeMeHomeDB.functionSettings and TakeMeHomeDB.functionSettings[def.key] then
                enabled = TakeMeHomeDB.functionSettings[def.key].enabled
            end
            local row, cb = MakeCheckRow(funcSec, y, def.name, enabled, function(v)
                if not TakeMeHomeDB.functionSettings then TakeMeHomeDB.functionSettings={} end
                if not TakeMeHomeDB.functionSettings[def.key] then
                    TakeMeHomeDB.functionSettings[def.key] = { enabled=true, order=i }
                end
                TakeMeHomeDB.functionSettings[def.key].enabled = v
                UpdateFunctionButtons()
            end)
            y = y - 30
        end
    end

    -- ====================================================
    -- MISSIONS section
    -- ====================================================
    local missSec = AddSection("missions", "Missions", "Interface\\Icons\\inv_garrison_resource")
    do
        local y = -8
        local hdr = missSec:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetPoint("TOPLEFT", missSec, "TOPLEFT", 4, y)
        hdr:SetText("|cff4da6ffMission Tables|r")
        y = y - 30

        for i, def in ipairs(MISSION_TABLE_DEFINITIONS) do
            local enabled = TakeMeHomeDB and TakeMeHomeDB.missionSettings and TakeMeHomeDB.missionSettings[def.key]
            enabled = enabled and enabled.enabled ~= false
            local row, cb = MakeCheckRow(missSec, y, def.name, enabled, function(v)
                if TakeMeHomeDB.missionSettings and TakeMeHomeDB.missionSettings[def.key] then
                    TakeMeHomeDB.missionSettings[def.key].enabled = v
                    UpdateMissionButtons()
                end
            end)
            y = y - 30
        end
    end

    -- Show General by default
    ShowSection("general")
    configFrame:Show()
end


-- ============================================
-- PROFESSIONS WINDOW
-- ============================================

-- Note: GATHERING_PROFESSIONS is defined earlier in the file

local professionFrame = CreateFrame("Frame", "TakeMeHomeProfessions", UIParent, "BackdropTemplate")
professionFrame:SetSize(88, 46) -- Will be resized based on professions
professionFrame:SetPoint("CENTER", 100, 0)
professionFrame:SetMovable(true)
professionFrame:EnableMouse(true)
professionFrame:RegisterForDrag("LeftButton")
professionFrame:SetClampedToScreen(true)
professionFrame:Hide()

-- Modern dark backdrop with subtle border
professionFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
professionFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
professionFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

-- Scale to 75% (same as main frame)
professionFrame:SetScale(0.75)

-- Drag banner for profession frame (visible when unlocked, hover-visible when locked)
local profDragBanner = CreateFrame("Frame", nil, professionFrame)
profDragBanner:SetHeight(8)
profDragBanner:SetPoint("TOPLEFT", professionFrame, "TOPLEFT", 1, -1)
profDragBanner:SetPoint("TOPRIGHT", professionFrame, "TOPRIGHT", -1, -1)
profDragBanner:EnableMouse(true)
profDragBanner:RegisterForDrag("LeftButton")

local profBannerTexture = profDragBanner:CreateTexture(nil, "BACKGROUND")
profBannerTexture:SetAllPoints()
profBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)

profDragBanner:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(professionFrame)
    end
end)

profDragBanner:SetScript("OnDragStop", function(self)
    StopLinkedDrag(professionFrame)

    -- Save primary window position
    local point, _, _, x, y = professionFrame:GetPoint()
    TakeMeHomeDB.professionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(professionFrame)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(professionFrame)
        if targetKey then
            SnapAndLinkWindow(professionFrame, targetKey, snapX, snapY)
        end
    end
end)

-- Right-click to show menu
profDragBanner:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ShowBannerContextMenu(self)
    end
end)

-- Hover to show banner when locked
profDragBanner:SetScript("OnEnter", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        profBannerTexture:SetColorTexture(0.3, 0.6, 0.9, 0.8)
    end
end)

profDragBanner:SetScript("OnLeave", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        profBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0) -- Invisible when locked
    end
end)

-- Drag functionality
professionFrame:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(self)
    end
end)

professionFrame:SetScript("OnDragStop", function(self)
    StopLinkedDrag(self)

    -- Save primary window position
    local point, _, _, x, y = self:GetPoint()
    TakeMeHomeDB.professionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(self)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(self)
        if targetKey then
            SnapAndLinkWindow(self, targetKey, snapX, snapY)
        end
    end
end)

-- Container for profession buttons (offset for drag banner)
local profButtonContainer = CreateFrame("Frame", nil, professionFrame)
profButtonContainer:SetPoint("TOPLEFT", professionFrame, "TOPLEFT", 5, -15)
profButtonContainer:SetPoint("BOTTOMRIGHT", professionFrame, "BOTTOMRIGHT", -5, 5)

-- Function to update profession drag banner visibility and container position
-- (defined here after profButtonContainer is created)
UpdateProfDragBanner = function()
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        profBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0) -- Invisible but still interactive
        profDragBanner:Show() -- Keep shown for hover detection
        -- Adjust container to have same padding as other sides when locked
        profButtonContainer:ClearAllPoints()
        profButtonContainer:SetPoint("TOPLEFT", professionFrame, "TOPLEFT", 5, -5)
        profButtonContainer:SetPoint("BOTTOMRIGHT", professionFrame, "BOTTOMRIGHT", -5, 5)
    else
        profBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8) -- Visible when unlocked
        profDragBanner:Show()
        -- Extra top padding for visible banner when unlocked
        profButtonContainer:ClearAllPoints()
        profButtonContainer:SetPoint("TOPLEFT", professionFrame, "TOPLEFT", 5, -15)
        profButtonContainer:SetPoint("BOTTOMRIGHT", professionFrame, "BOTTOMRIGHT", -5, 5)
    end
end

local professionButtons = {}
local profButtonSize = 36
local profButtonSpacing = 6
local profColumns = 2
local profButtonCounter = 0  -- Unique counter for button names

-- Create a profession button
local function CreateProfessionButton(skillLineID, profName, profIcon)
    profButtonCounter = profButtonCounter + 1
    -- Use regular button since professions can't be used in combat anyway
    local button = CreateFrame("Button", "TakeMeHomeProfBtn"..profButtonCounter, profButtonContainer)
    button:SetSize(profButtonSize, profButtonSize)
    button:RegisterForClicks("LeftButtonUp")

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetTexture(profIcon)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Store profession data
    button.skillLineID = skillLineID
    button.profName = profName

    -- OnClick to toggle profession window using the API
    button:SetScript("OnClick", function(self)
        if InCombatLockdown() then
            print("|cff00ff00TakeMeHome|r: Cannot open professions during combat.")
            return
        end
        -- Check if this profession is already open
        if C_TradeSkillUI.IsTradeSkillReady() then
            local profInfo = C_TradeSkillUI.GetBaseProfessionInfo()
            if profInfo and profInfo.professionID == self.skillLineID then
                -- Same profession is open, close it
                C_TradeSkillUI.CloseTradeSkill()
                return
            end
        end
        -- Open the profession
        C_TradeSkillUI.OpenTradeSkill(self.skillLineID)
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(profName, 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Note: GetLearnedProfessions is defined earlier in the file

-- Update profession buttons
UpdateProfessionButtons = function()
    -- Clear existing buttons
    for _, button in ipairs(professionButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(professionButtons)

    local professions = GetLearnedProfessions()

    if #professions == 0 then
        professionFrame:Hide()
        return
    end

    -- Initialize profession settings for any new professions
    for i, prof in ipairs(professions) do
        if not TakeMeHomeDB.professionSettings[prof.name] then
            TakeMeHomeDB.professionSettings[prof.name] = { enabled = true, order = i }
        end
    end

    -- Filter and sort professions by enabled status and order
    local sortedProfessions = {}
    for _, prof in ipairs(professions) do
        if IsProfessionEnabled(prof.name) then
            table.insert(sortedProfessions, {
                prof = prof,
                order = GetProfessionOrder(prof.name)
            })
        end
    end

    table.sort(sortedProfessions, function(a, b) return a.order < b.order end)

    if #sortedProfessions == 0 then
        professionFrame:Hide()
        return
    end

    -- Create buttons for each enabled profession
    for i, profInfo in ipairs(sortedProfessions) do
        local prof = profInfo.prof
        local button = CreateProfessionButton(prof.skillLineID, prof.name, prof.icon)
        table.insert(professionButtons, button)

        -- Position in 2-column grid
        local col = (i - 1) % profColumns
        local row = math.floor((i - 1) / profColumns)

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", profButtonContainer, "TOPLEFT",
            col * (profButtonSize + profButtonSpacing),
            -row * (profButtonSize + profButtonSpacing))
        button:Show()
    end

    -- Resize frame based on number of professions
    local numRows = math.ceil(#sortedProfessions / profColumns)
    local numCols = math.min(#sortedProfessions, profColumns)

    local width = (numCols * profButtonSize) + ((numCols - 1) * profButtonSpacing) + 10
    -- Add extra height for banner only when unlocked
    local bannerPadding = (TakeMeHomeDB and TakeMeHomeDB.locked) and 10 or 20
    local height = (numRows * profButtonSize) + ((numRows - 1) * profButtonSpacing) + bannerPadding

    professionFrame:SetSize(width, height)
    if userWantsWindowsVisible and not windowHiddenByBar["professions"] then
        professionFrame:Show()
    end
    UpdateProfDragBanner()
end

-- Initialize professions on login
InitializeProfessions = function()
    -- Restore position
    if TakeMeHomeDB.professionPosition then
        local pos = TakeMeHomeDB.professionPosition
        professionFrame:ClearAllPoints()
        professionFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    -- Delay to ensure profession data is loaded
    C_Timer.After(2, UpdateProfessionButtons)
end

-- ============================================
-- MOUNTS WINDOW
-- ============================================

-- Note: UTILITY_MOUNTS is defined at the top of the file

local mountsFrame = CreateFrame("Frame", "TakeMeHomeMountsFrame", UIParent, "BackdropTemplate")
mountsFrame:SetSize(88, 46)
mountsFrame:SetPoint("CENTER", -100, 0)
mountsFrame:SetMovable(true)
mountsFrame:EnableMouse(true)
mountsFrame:RegisterForDrag("LeftButton")
mountsFrame:SetClampedToScreen(true)
mountsFrame:Hide()

-- Modern dark backdrop with subtle border
mountsFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
mountsFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
mountsFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

-- Scale to 75% (same as other frames)
mountsFrame:SetScale(0.75)

-- Drag banner for mounts frame
local mountsDragBanner = CreateFrame("Frame", nil, mountsFrame)
mountsDragBanner:SetHeight(8)
mountsDragBanner:SetPoint("TOPLEFT", mountsFrame, "TOPLEFT", 1, -1)
mountsDragBanner:SetPoint("TOPRIGHT", mountsFrame, "TOPRIGHT", -1, -1)
mountsDragBanner:EnableMouse(true)
mountsDragBanner:RegisterForDrag("LeftButton")

local mountsBannerTexture = mountsDragBanner:CreateTexture(nil, "BACKGROUND")
mountsBannerTexture:SetAllPoints()
mountsBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)

mountsDragBanner:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(mountsFrame)
    end
end)

mountsDragBanner:SetScript("OnDragStop", function(self)
    StopLinkedDrag(mountsFrame)

    -- Save primary window position
    local point, _, _, x, y = mountsFrame:GetPoint()
    TakeMeHomeDB.mountsPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(mountsFrame)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(mountsFrame)
        if targetKey then
            SnapAndLinkWindow(mountsFrame, targetKey, snapX, snapY)
        end
    end
end)

-- Right-click to show menu
mountsDragBanner:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ShowBannerContextMenu(self)
    end
end)

-- Hover to show banner when locked
mountsDragBanner:SetScript("OnEnter", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mountsBannerTexture:SetColorTexture(0.3, 0.6, 0.9, 0.8)
    end
end)

mountsDragBanner:SetScript("OnLeave", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mountsBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
    end
end)

-- Drag functionality
mountsFrame:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(self)
    end
end)

mountsFrame:SetScript("OnDragStop", function(self)
    StopLinkedDrag(self)

    -- Save primary window position
    local point, _, _, x, y = self:GetPoint()
    TakeMeHomeDB.mountsPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(self)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(self)
        if targetKey then
            SnapAndLinkWindow(self, targetKey, snapX, snapY)
        end
    end
end)

-- Container for mount buttons
local mountsButtonContainer = CreateFrame("Frame", nil, mountsFrame)
mountsButtonContainer:SetPoint("TOPLEFT", mountsFrame, "TOPLEFT", 5, -15)
mountsButtonContainer:SetPoint("BOTTOMRIGHT", mountsFrame, "BOTTOMRIGHT", -5, 5)

-- Function to update mounts drag banner
UpdateMountsDragBanner = function()
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        mountsBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
        mountsDragBanner:Show()
        mountsButtonContainer:ClearAllPoints()
        mountsButtonContainer:SetPoint("TOPLEFT", mountsFrame, "TOPLEFT", 5, -5)
        mountsButtonContainer:SetPoint("BOTTOMRIGHT", mountsFrame, "BOTTOMRIGHT", -5, 5)
    else
        mountsBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)
        mountsDragBanner:Show()
        mountsButtonContainer:ClearAllPoints()
        mountsButtonContainer:SetPoint("TOPLEFT", mountsFrame, "TOPLEFT", 5, -15)
        mountsButtonContainer:SetPoint("BOTTOMRIGHT", mountsFrame, "BOTTOMRIGHT", -5, 5)
    end
end

local mountButtons = {}
local mountButtonSize = 36
local mountButtonSpacing = 6
local mountButtonCounter = 0

-- Note: GetMountInfoBySpellID is defined earlier in the file

-- Create a mount button
local function CreateMountButton(mountData, mountName)
    mountButtonCounter = mountButtonCounter + 1
    local button = CreateFrame("Button", "TakeMeHomeMountBtn"..mountButtonCounter, mountsButtonContainer, "SecureActionButtonTemplate")
    button:SetSize(mountButtonSize, mountButtonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Use mount name for secure action (spell IDs don't work reliably for mounts)
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", mountName or mountData.name)

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Store mount data
    button.spellID = mountData.spellID
    button.mountName = mountData.name

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spellID)
        if not self.isCollected then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("You do not have this mount", 1, 0.2, 0.2)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Update mount buttons
UpdateMountButtons = function()
    -- Don't update secure buttons during combat
    if InCombatLockdown() then return end

    -- Clear existing buttons
    for _, button in ipairs(mountButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(mountButtons)

    -- Get selected mounts from saved variables
    local selectedMounts = TakeMeHomeDB and TakeMeHomeDB.selectedMounts or {}

    local visibleCount = 0
    local maxMounts = 6
    local mountColumns = 3  -- 3 mounts per row

    for i, mountEntry in ipairs(selectedMounts) do
        if visibleCount >= maxMounts then break end

        local name, icon, isCollected, isUsable, mountID = GetMountInfoBySpellID(mountEntry.spellID)

        -- Only show if player owns the mount
        if isCollected then
            local mountData = { spellID = mountEntry.spellID, name = name or "Unknown Mount" }
            local button = CreateMountButton(mountData, name)
            table.insert(mountButtons, button)

            button.isCollected = isCollected
            button.mountID = mountID
            button.spellID = mountEntry.spellID

            -- Set icon
            if icon then
                button.icon:SetTexture(icon)
            else
                button.icon:SetTexture(GetSpellTexture(mountEntry.spellID))
            end

            -- Position in 3-column grid
            local col = visibleCount % mountColumns
            local row = math.floor(visibleCount / mountColumns)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", mountsButtonContainer, "TOPLEFT",
                col * (mountButtonSize + mountButtonSpacing),
                -row * (mountButtonSize + mountButtonSpacing))
            button:Show()

            visibleCount = visibleCount + 1
        end
    end

    -- Add Travel Form button for Druids
    if IsDruid() and visibleCount < maxMounts then
        local travelFormSpell = DRUID_SPELLS.travelForm
        local spellInfo = C_Spell.GetSpellInfo(travelFormSpell.spellID)

        if spellInfo and IsSpellKnown(travelFormSpell.spellID) then
            local mountData = { spellID = travelFormSpell.spellID, name = travelFormSpell.name }
            local button = CreateMountButton(mountData, travelFormSpell.name)
            table.insert(mountButtons, button)

            button.isCollected = true
            button.spellID = travelFormSpell.spellID
            button.isTravelForm = true

            -- Set icon
            button.icon:SetTexture(spellInfo.iconID)

            -- Position in 3-column grid
            local col = visibleCount % mountColumns
            local row = math.floor(visibleCount / mountColumns)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", mountsButtonContainer, "TOPLEFT",
                col * (mountButtonSize + mountButtonSpacing),
                -row * (mountButtonSize + mountButtonSpacing))
            button:Show()

            visibleCount = visibleCount + 1
        end
    end

    -- Resize frame based on visible mounts
    if visibleCount == 0 then
        mountsFrame:Hide()
        return
    end

    local numRows = math.ceil(visibleCount / mountColumns)
    local numCols = math.min(visibleCount, mountColumns)
    local width = (numCols * mountButtonSize) + ((numCols - 1) * mountButtonSpacing) + 10
    local bannerPadding = (TakeMeHomeDB and TakeMeHomeDB.locked) and 10 or 20
    local height = (numRows * mountButtonSize) + ((numRows - 1) * mountButtonSpacing) + bannerPadding

    mountsFrame:SetSize(width, height)
    if userWantsWindowsVisible and not windowHiddenByBar["mounts"] then
        mountsFrame:Show()
    end
    UpdateMountsDragBanner()
end

-- Initialize mounts on login
InitializeMounts = function()
    -- Restore position
    if TakeMeHomeDB.mountsPosition then
        local pos = TakeMeHomeDB.mountsPosition
        mountsFrame:ClearAllPoints()
        mountsFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    -- Delay to ensure mount data is loaded
    C_Timer.After(2, UpdateMountButtons)
end

-- ============================================
-- FUNCTION WINDOW
-- ============================================

local functionFrame = CreateFrame("Frame", "TakeMeHomeFunctionFrame", UIParent, "BackdropTemplate")
functionFrame:SetSize(46, 46)
functionFrame:SetPoint("CENTER", 0, -100)
functionFrame:SetMovable(true)
functionFrame:EnableMouse(true)
functionFrame:RegisterForDrag("LeftButton")
functionFrame:SetClampedToScreen(true)
functionFrame:Hide()

-- Modern dark backdrop with subtle border
functionFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
functionFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
functionFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

-- Scale to 75% (same as other frames)
functionFrame:SetScale(0.75)

-- Drag banner for function frame
local funcDragBanner = CreateFrame("Frame", nil, functionFrame)
funcDragBanner:SetHeight(8)
funcDragBanner:SetPoint("TOPLEFT", functionFrame, "TOPLEFT", 1, -1)
funcDragBanner:SetPoint("TOPRIGHT", functionFrame, "TOPRIGHT", -1, -1)
funcDragBanner:EnableMouse(true)
funcDragBanner:RegisterForDrag("LeftButton")

local funcBannerTexture = funcDragBanner:CreateTexture(nil, "BACKGROUND")
funcBannerTexture:SetAllPoints()
funcBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)

funcDragBanner:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(functionFrame)
    end
end)

funcDragBanner:SetScript("OnDragStop", function(self)
    StopLinkedDrag(functionFrame)

    -- Save primary window position
    local point, _, _, x, y = functionFrame:GetPoint()
    TakeMeHomeDB.functionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(functionFrame)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(functionFrame)
        if targetKey then
            SnapAndLinkWindow(functionFrame, targetKey, snapX, snapY)
        end
    end
end)

-- Right-click to show menu
funcDragBanner:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ShowBannerContextMenu(self)
    end
end)

-- Hover to show banner when locked
funcDragBanner:SetScript("OnEnter", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        funcBannerTexture:SetColorTexture(0.3, 0.6, 0.9, 0.8)
    end
end)

funcDragBanner:SetScript("OnLeave", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        funcBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
    end
end)

-- Drag functionality
functionFrame:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(self)
    end
end)

functionFrame:SetScript("OnDragStop", function(self)
    StopLinkedDrag(self)

    -- Save primary window position
    local point, _, _, x, y = self:GetPoint()
    TakeMeHomeDB.functionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(self)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(self)
        if targetKey then
            SnapAndLinkWindow(self, targetKey, snapX, snapY)
        end
    end
end)

-- Container for function buttons
local funcButtonContainer = CreateFrame("Frame", nil, functionFrame)
funcButtonContainer:SetPoint("TOPLEFT", functionFrame, "TOPLEFT", 5, -15)
funcButtonContainer:SetPoint("BOTTOMRIGHT", functionFrame, "BOTTOMRIGHT", -5, 5)

-- Function to update function drag banner
UpdateFuncDragBanner = function()
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        funcBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
        funcDragBanner:Show()
        funcButtonContainer:ClearAllPoints()
        funcButtonContainer:SetPoint("TOPLEFT", functionFrame, "TOPLEFT", 5, -5)
        funcButtonContainer:SetPoint("BOTTOMRIGHT", functionFrame, "BOTTOMRIGHT", -5, 5)
    else
        funcBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)
        funcDragBanner:Show()
        funcButtonContainer:ClearAllPoints()
        funcButtonContainer:SetPoint("TOPLEFT", functionFrame, "TOPLEFT", 5, -15)
        funcButtonContainer:SetPoint("BOTTOMRIGHT", functionFrame, "BOTTOMRIGHT", -5, 5)
    end
end

local functionButtons = {}
local funcButtonSize = 36
local funcButtonSpacing = 6
local funcButtonCounter = 0

-- Helper function to check if a function button is enabled
local function IsFuncButtonEnabled(key)
    if not TakeMeHomeDB or not TakeMeHomeDB.functionSettings then return true end
    local settings = TakeMeHomeDB.functionSettings[key]
    if not settings then return true end
    return settings.enabled
end

-- Create a function button
local function CreateFunctionButton(funcData)
    funcButtonCounter = funcButtonCounter + 1
    -- Use SecureActionButtonTemplate with macro type for protected actions
    local button = CreateFrame("Button", "TakeMeHomeFuncBtn"..funcButtonCounter, funcButtonContainer, "SecureActionButtonTemplate")
    button:SetSize(funcButtonSize, funcButtonSize)
    button:RegisterForClicks("AnyUp", "AnyDown")

    -- Set up as macro button for logout
    if funcData.key == "logout" then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", "/logout")
    end

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetTexture(funcData.icon)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Store function data
    button.funcKey = funcData.key
    button.funcName = funcData.name

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.funcName, 1, 1, 1)
        if self.funcKey == "logout" then
            GameTooltip:AddLine("Log out of the game", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Function button definitions
local FUNC_BUTTON_DEFINITIONS = {
    { key = "logout", name = "Logout", icon = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up" },
}

-- Update function buttons
UpdateFunctionButtons = function()
    -- Don't update secure buttons during combat
    if InCombatLockdown() then return end

    -- Clear existing buttons
    for _, button in ipairs(functionButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(functionButtons)

    local visibleCount = 0
    local funcColumns = 1  -- Single column for now

    for i, funcDef in ipairs(FUNC_BUTTON_DEFINITIONS) do
        if IsFuncButtonEnabled(funcDef.key) then
            local button = CreateFunctionButton(funcDef)
            table.insert(functionButtons, button)

            -- Position
            local col = visibleCount % funcColumns
            local row = math.floor(visibleCount / funcColumns)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", funcButtonContainer, "TOPLEFT",
                col * (funcButtonSize + funcButtonSpacing),
                -row * (funcButtonSize + funcButtonSpacing))
            button:Show()

            visibleCount = visibleCount + 1
        end
    end

    -- Resize frame based on visible buttons
    if visibleCount == 0 then
        functionFrame:Hide()
        return
    end

    local numRows = math.ceil(visibleCount / funcColumns)
    local numCols = math.min(visibleCount, funcColumns)
    local width = (numCols * funcButtonSize) + ((numCols - 1) * funcButtonSpacing) + 10
    local bannerPadding = (TakeMeHomeDB and TakeMeHomeDB.locked) and 10 or 20
    local height = (numRows * funcButtonSize) + ((numRows - 1) * funcButtonSpacing) + bannerPadding

    functionFrame:SetSize(width, height)
    if userWantsWindowsVisible and not windowHiddenByBar["function"] then
        functionFrame:Show()
    end
    UpdateFuncDragBanner()
end

-- Initialize function window on login
InitializeFunction = function()
    -- Restore position
    if TakeMeHomeDB.functionPosition then
        local pos = TakeMeHomeDB.functionPosition
        functionFrame:ClearAllPoints()
        functionFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    -- Delay to ensure data is loaded
    C_Timer.After(2, UpdateFunctionButtons)
end

-- ============================================
-- MISSION TABLE WINDOW
-- ============================================

local missionFrame = CreateFrame("Frame", "TakeMeHomeMissionFrame", UIParent, "BackdropTemplate")
missionFrame:SetSize(160, 46)
missionFrame:SetPoint("CENTER", 100, -100)
missionFrame:SetMovable(true)
missionFrame:EnableMouse(true)
missionFrame:RegisterForDrag("LeftButton")
missionFrame:SetClampedToScreen(true)
missionFrame:Hide()

-- Modern dark backdrop with subtle border
missionFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
missionFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
missionFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

-- Scale to 75% (same as other frames)
missionFrame:SetScale(0.75)

-- Drag banner for mission frame
local missionDragBanner = CreateFrame("Frame", nil, missionFrame)
missionDragBanner:SetHeight(8)
missionDragBanner:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 1, -1)
missionDragBanner:SetPoint("TOPRIGHT", missionFrame, "TOPRIGHT", -1, -1)
missionDragBanner:EnableMouse(true)
missionDragBanner:RegisterForDrag("LeftButton")

local missionBannerTexture = missionDragBanner:CreateTexture(nil, "BACKGROUND")
missionBannerTexture:SetAllPoints()
missionBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)

missionDragBanner:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(missionFrame)
    end
end)

missionDragBanner:SetScript("OnDragStop", function(self)
    StopLinkedDrag(missionFrame)

    -- Save primary window position
    local point, _, _, x, y = missionFrame:GetPoint()
    TakeMeHomeDB.missionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(missionFrame)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(missionFrame)
        if targetKey then
            SnapAndLinkWindow(missionFrame, targetKey, snapX, snapY)
        end
    end
end)

-- Right-click to show menu
missionDragBanner:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ShowBannerContextMenu(self)
    end
end)

-- Hover to show banner when locked
missionDragBanner:SetScript("OnEnter", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        missionBannerTexture:SetColorTexture(0.3, 0.6, 0.9, 0.8)
    end
end)

missionDragBanner:SetScript("OnLeave", function(self)
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        missionBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
    end
end)

-- Drag functionality
missionFrame:SetScript("OnDragStart", function(self)
    if not TakeMeHomeDB.locked then
        StartLinkedDrag(self)
    end
end)

missionFrame:SetScript("OnDragStop", function(self)
    StopLinkedDrag(self)

    -- Save primary window position
    local point, _, _, x, y = self:GetPoint()
    TakeMeHomeDB.missionPosition = { point = point, x = x, y = y }

    -- Check for snap target
    local windowKey = GetWindowKey(self)
    if windowKey and not IsWindowLinked(windowKey) then
        local targetKey, snapSide, snapX, snapY = FindSnapTarget(self)
        if targetKey then
            SnapAndLinkWindow(self, targetKey, snapX, snapY)
        end
    end
end)

-- Container for mission buttons
local missionButtonContainer = CreateFrame("Frame", nil, missionFrame)
missionButtonContainer:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 5, -15)
missionButtonContainer:SetPoint("BOTTOMRIGHT", missionFrame, "BOTTOMRIGHT", -5, 5)

-- Function to update mission drag banner
UpdateMissionDragBanner = function()
    if TakeMeHomeDB and TakeMeHomeDB.locked then
        missionBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.0)
        missionDragBanner:Show()
        missionButtonContainer:ClearAllPoints()
        missionButtonContainer:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 5, -5)
        missionButtonContainer:SetPoint("BOTTOMRIGHT", missionFrame, "BOTTOMRIGHT", -5, 5)
    else
        missionBannerTexture:SetColorTexture(0.2, 0.5, 0.8, 0.8)
        missionDragBanner:Show()
        missionButtonContainer:ClearAllPoints()
        missionButtonContainer:SetPoint("TOPLEFT", missionFrame, "TOPLEFT", 5, -15)
        missionButtonContainer:SetPoint("BOTTOMRIGHT", missionFrame, "BOTTOMRIGHT", -5, 5)
    end
end

local missionButtons = {}
local missionButtonSize = 36
local missionButtonSpacing = 6
local missionButtonCounter = 0

-- Helper function to check if a mission button is enabled
local function IsMissionButtonEnabled(key)
    if not TakeMeHomeDB or not TakeMeHomeDB.missionSettings then return true end
    local settings = TakeMeHomeDB.missionSettings[key]
    if not settings then return true end
    return settings.enabled
end

-- Mission table definitions with expansion-specific icons
local MISSION_TABLE_DEFINITIONS = {
    {
        key = "wod",
        name = "Warlords of Draenor",
        icon = "Interface\\Icons\\inv_garrison_resource",
        garrisonType = 2,
    },
    {
        key = "legion",
        name = "Legion",
        icon = "Interface\\Icons\\inv_orderhall_orderresources",
        garrisonType = 3,
    },
    {
        key = "bfa",
        name = "Battle for Azeroth",
        icon = "Interface\\Icons\\inv_heartofazeroth",
        garrisonType = 9,
    },
    {
        key = "shadowlands",
        name = "Shadowlands",
        icon = "Interface\\Icons\\spell_animarevendreth_buff",
        garrisonType = 111,
    },
}

-- Track which garrison type is currently shown
local currentGarrisonType = nil

-- Create a mission button (using regular button since ShowGarrisonLandingPage is not protected)
local function CreateMissionButton(missionData)
    missionButtonCounter = missionButtonCounter + 1
    local button = CreateFrame("Button", "TakeMeHomeMissionBtn"..missionButtonCounter, missionButtonContainer)
    button:SetSize(missionButtonSize, missionButtonSize)
    button:RegisterForClicks("LeftButtonUp")

    -- Store garrison type for click handler
    button.garrisonType = missionData.garrisonType

    -- Click handler with toggle logic
    button:SetScript("OnClick", function(self)
        if GarrisonLandingPage and GarrisonLandingPage:IsShown() and currentGarrisonType == self.garrisonType then
            -- Same expansion is showing, hide it
            HideUIPanel(GarrisonLandingPage)
            currentGarrisonType = nil
        else
            -- Show the requested expansion
            ShowGarrisonLandingPage(self.garrisonType)
            currentGarrisonType = self.garrisonType
        end
    end)

    -- Icon texture
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetTexture(missionData.icon)

    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.3)

    -- Store mission data
    button.missionKey = missionData.key
    button.missionName = missionData.name

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.missionName, 1, 1, 1)
        GameTooltip:AddLine("Open Mission Table", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- Update mission buttons
UpdateMissionButtons = function()
    -- Don't update secure buttons during combat
    if InCombatLockdown() then return end

    -- Clear existing buttons
    for _, button in ipairs(missionButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(missionButtons)

    local visibleCount = 0
    local missionColumns = 4  -- 4 buttons in a row

    for i, missionDef in ipairs(MISSION_TABLE_DEFINITIONS) do
        if IsMissionButtonEnabled(missionDef.key) then
            local button = CreateMissionButton(missionDef)
            table.insert(missionButtons, button)

            -- Position
            local col = visibleCount % missionColumns
            local row = math.floor(visibleCount / missionColumns)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", missionButtonContainer, "TOPLEFT",
                col * (missionButtonSize + missionButtonSpacing),
                -row * (missionButtonSize + missionButtonSpacing))
            button:Show()

            visibleCount = visibleCount + 1
        end
    end

    -- Resize frame based on visible buttons
    if visibleCount == 0 then
        missionFrame:Hide()
        return
    end

    local numRows = math.ceil(visibleCount / missionColumns)
    local numCols = math.min(visibleCount, missionColumns)
    local width = (numCols * missionButtonSize) + ((numCols - 1) * missionButtonSpacing) + 10
    local bannerPadding = (TakeMeHomeDB and TakeMeHomeDB.locked) and 10 or 20
    local height = (numRows * missionButtonSize) + ((numRows - 1) * missionButtonSpacing) + bannerPadding

    missionFrame:SetSize(width, height)
    if userWantsWindowsVisible and not windowHiddenByBar["missions"] then
        missionFrame:Show()
    end
    UpdateMissionDragBanner()
end

-- Initialize mission window on login
InitializeMissions = function()
    -- Restore position
    if TakeMeHomeDB.missionPosition then
        local pos = TakeMeHomeDB.missionPosition
        missionFrame:ClearAllPoints()
        missionFrame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    -- Delay to ensure data is loaded
    C_Timer.After(2, UpdateMissionButtons)
end

-- ============================================
-- INFO BAR
-- ============================================

local infoBarToggleButtons = {}

local infoBar = CreateFrame("Frame", "TakeMeHomeInfoBar", UIParent, "BackdropTemplate")
infoBar:SetHeight(22)
infoBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
infoBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
infoBar:SetFrameStrata("MEDIUM")
infoBar:SetFrameLevel(1)
infoBar:Hide()

infoBar:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 1, bottom = 0 }
})
infoBar:SetBackdropColor(0.05, 0.05, 0.08, 0.88)
infoBar:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)

-- Individual module button registry (populated in InitializeInfoBar)
local infoBarModuleBtns  = {}
local infoBarLeftOffset  = 8   -- updated in InitializeInfoBar after toggle+ATT buttons
local infoBarCogButton   = nil

local INFO_SEP = " |cff2a2a40||r "

-- Creates one clickable Button for an info bar module
local function CreateInfoModuleBtn(key, section)
    local btn = CreateFrame("Button", nil, infoBar)
    btn:SetHeight(20)
    btn:SetWidth(10)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetAllPoints()
    lbl:SetJustifyH("CENTER")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetWordWrap(false)
    btn.lbl = lbl

    btn.modKey  = key
    btn.section = section

    local hasLeft  = INFO_MODULE_ACTIONS[key] ~= nil
    local hasRight = INFO_MODULE_RIGHT_ACTIONS and INFO_MODULE_RIGHT_ACTIONS[key] ~= nil
    if hasLeft or hasRight then
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        if hasLeft and hasRight then
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function(self, mouseBtn)
                if mouseBtn == "RightButton" then
                    INFO_MODULE_RIGHT_ACTIONS[self.modKey]()
                else
                    INFO_MODULE_ACTIONS[self.modKey]()
                end
            end)
        elseif hasLeft then
            btn:SetScript("OnClick", function(self) INFO_MODULE_ACTIONS[self.modKey]() end)
        else
            btn:RegisterForClicks("RightButtonUp")
            btn:SetScript("OnClick", function(self) INFO_MODULE_RIGHT_ACTIONS[self.modKey]() end)
        end
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            local rawText = self.lbl:GetText() or ""
            GameTooltip:SetText(rawText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""), 1, 1, 1)
            local tip = INFO_MODULE_TIPS[self.modKey]
            if tip then GameTooltip:AddLine(tip, 0.6, 0.6, 0.6) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return btn
end

-- Reflows all module button positions after text updates
local function ReflowInfoBar()
    if not infoBar:IsShown() then return end
    local barW = infoBar:GetWidth()
    if not barW or barW < 10 then return end

    local pad = 6
    local left, center, right = {}, {}, {}

    for _, btn in ipairs(infoBarModuleBtns) do
        if btn:IsShown() then
            local tw = btn.lbl:GetStringWidth()
            if tw and tw > 0 then btn:SetWidth(tw + 2) end
            if     btn.section == "left"   then table.insert(left,   btn)
            elseif btn.section == "center" then table.insert(center, btn)
            else                                table.insert(right,  btn) end
        end
    end

    -- Left
    local lx = infoBarLeftOffset
    for _, btn in ipairs(left) do
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", infoBar, "LEFT", lx, 0)
        lx = lx + btn:GetWidth() + pad
    end

    -- Right (leaves room for cog: 22px + 6px gap)
    local rx = 28
    for i = #right, 1, -1 do
        local btn = right[i]
        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", infoBar, "RIGHT", -rx, 0)
        rx = rx + btn:GetWidth() + pad
    end

    -- Center
    if #center > 0 then
        local tw = 0
        for i, btn in ipairs(center) do
            tw = tw + btn:GetWidth() + (i < #center and pad or 0)
        end
        local cx = math.floor((barW - tw) / 2)
        for _, btn in ipairs(center) do
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", infoBar, "LEFT", cx, 0)
            cx = cx + btn:GetWidth() + pad
        end
    end
end

local function FormatGold(money)
    if money <= 0 then return "|cff8888880c|r" end
    local g = math.floor(money / 10000)
    local s = math.floor((money % 10000) / 100)
    local c = money % 100
    if g >= 1000000 then
        return string.format("|cffd4af37%.2fM|r|cff888888g|r", g / 1000000)
    elseif g > 0 then
        local gStr = g >= 1000 and string.format("%d,%03d", math.floor(g / 1000), g % 1000) or tostring(g)
        return "|cffd4af37" .. gStr .. "|r|cff888888g |r|cffc0c0c0" .. s .. "|r|cff888888s|r"
    elseif s > 0 then
        return "|cffc0c0c0" .. s .. "|r|cff888888s |r|cffcd7f32" .. c .. "|r|cff888888c|r"
    else
        return "|cffcd7f32" .. c .. "|r|cff888888c|r"
    end
end

local function GetInfoModuleText(key)
    if key == "zone" then
        local zone = GetRealZoneText() or ""
        local subzone = GetSubZoneText() or ""
        if subzone ~= "" and subzone ~= zone then
            return "|cffadd8e6" .. subzone .. "|r |cff666677(" .. zone .. ")|r"
        end
        return "|cffadd8e6" .. zone .. "|r"

    elseif key == "coords" then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                lastCoordsString = string.format("%.1f, %.1f", pos.x * 100, pos.y * 100)
                return string.format("|cff888888(|r|cffffffff%s|r|cff888888)|r", lastCoordsString)
            end
        end
        return ""

    elseif key == "gold" then
        return FormatGold(GetMoney())

    elseif key == "bags" then
        local free, total = 0, 0
        for i = 0, 4 do
            local slots = C_Container.GetContainerNumSlots(i)
            total = total + slots
            for j = 1, slots do
                if not C_Container.GetContainerItemInfo(i, j) then
                    free = free + 1
                end
            end
        end
        local color = free <= 4 and "|cffff4444" or free <= 10 and "|cffffff44" or "|cff44ff44"
        return "|cff888888Bags |r" .. color .. free .. "|r|cff888888/" .. total .. "|r"

    elseif key == "durability" then
        local lowest = 100
        for slot = 1, 18 do
            local cur, max = GetInventoryItemDurability(slot)
            if cur and max and max > 0 then
                local pct = math.floor(cur / max * 100)
                if pct < lowest then lowest = pct end
            end
        end
        if lowest == 100 then return "" end
        local color = lowest <= 20 and "|cffff4444" or lowest <= 50 and "|cffffff44" or "|cff44ff44"
        return "|cff888888Dur |r" .. color .. lowest .. "%|r"

    elseif key == "fps" then
        local fps = math.floor(GetFramerate())
        local color = fps < 20 and "|cffff4444" or fps < 40 and "|cffffff44" or "|cff44ff44"
        return "|cff888888FPS |r" .. color .. fps .. "|r"

    elseif key == "latency" then
        local _, _, lagHome, lagWorld = GetNetStats()
        local lag = math.max(lagHome or 0, lagWorld or 0)
        local color = lag > 300 and "|cffff4444" or lag > 150 and "|cffffff44" or "|cff44ff44"
        return "|cff888888MS |r" .. color .. lag .. "|r"

    elseif key == "time" then
        local h, m = GetGameTime()
        return string.format("|cff888888Srv |r|cffadd8e6%02d:%02d|r", h, m)

    elseif key == "xp" then
        if UnitLevel("player") >= GetMaxPlayerLevel() then return "" end
        local xp = UnitXP("player")
        local maxXP = UnitXPMax("player")
        if maxXP == 0 then return "" end
        local pct = math.floor(xp / maxXP * 100)
        return "|cff888888XP |r|cff8888ff" .. pct .. "%|r"

    elseif key == "ilvl" then
        local equipped, _ = GetAverageItemLevel()
        if not equipped or equipped == 0 then return "" end
        return "|cff888888iLvl |r|cffffffff" .. math.floor(equipped) .. "|r"

    elseif key == "rep" then
        local ok, result = pcall(function()
            if C_Reputation and C_Reputation.GetWatchedFactionData then
                local d = C_Reputation.GetWatchedFactionData()
                if d and d.name then
                    local cur = (d.currentValue or 0) - (d.currentReactionThreshold or 0)
                    local max = (d.nextReactionThreshold or 1) - (d.currentReactionThreshold or 0)
                    if max > 0 then
                        local pct = math.floor(cur / max * 100)
                        return "|cff888888" .. d.name:sub(1, 18) .. " |r|cffadd8e6" .. pct .. "%|r"
                    end
                end
            end
            local name, _, min, max, value = GetWatchedFactionInfo()
            if name and max and max > min then
                local pct = math.floor((value - min) / (max - min) * 100)
                return "|cff888888" .. name:sub(1, 18) .. " |r|cffadd8e6" .. pct .. "%|r"
            end
            return nil
        end)
        if ok and result then return result end
        return ""

    elseif key == "sessionGold" then
        if not sessionGoldStart then return "" end
        local delta = GetMoney() - sessionGoldStart
        if delta == 0 then return "" end
        local color = delta > 0 and "|cff44ff44" or "|cffff4444"
        local sign  = delta > 0 and "+" or "-"
        local abs   = math.abs(delta)
        local g     = math.floor(abs / 10000)
        local s     = math.floor((abs % 10000) / 100)
        local str
        if g > 0 then
            str = g >= 1000 and string.format("%d,%03dg", math.floor(g/1000), g%1000) .. " " .. s .. "s"
                           or   g .. "g " .. s .. "s"
        elseif s > 0 then
            str = s .. "s"
        else
            str = (abs % 100) .. "c"
        end
        return "|cff888888Sesh |r" .. color .. sign .. str .. "|r"

    elseif key == "timeLocal" then
        return string.format("|cff888888Local |r|cffadd8e6%s|r", date("%H:%M"))

    elseif key == "friends" then
        local ok, result = pcall(function()
            local onF = C_FriendList.GetNumOnlineFriends()
            local totF = C_FriendList.GetNumFriends()
            local text = string.format("|cff888888Friends |r|cff44ff44%d|r|cff888888/%d|r", onF, totF)
            if IsInGuild() then
                local _, _, onG = GetNumGuildMembers()
                text = text .. INFO_SEP .. string.format("|cff888888Guild |r|cff44ff44%d|r|cff888888 online|r", onG or 0)
            end
            return text
        end)
        if ok and result then return result end
        return ""

    elseif key == "hsCooldown" then
        local shortest = nil
        for _, item in ipairs(TRAVEL_ITEMS) do
            local ok, start, duration = pcall(GetItemCooldown, item.itemID)
            if ok and start and duration and duration > 0 then
                local rem = start + duration - GetTime()
                if rem > 0 and (not shortest or rem < shortest) then
                    shortest = rem
                end
            end
        end
        if shortest then
            local m = math.floor(shortest / 60)
            local s = math.floor(shortest % 60)
            if m > 0 then
                return string.format("|cff888888HS |r|cffff8844%dm %02ds|r", m, s)
            else
                return string.format("|cff888888HS |r|cffff8844%ds|r", s)
            end
        end
        return "|cff888888HS |r|cff44ff44Ready|r"

    elseif key == "att" then
        return "" -- ATT is now a dedicated bar button; see InitializeInfoBar
    end
    return ""
end


UpdateInfoBar = function()
    if not TakeMeHomeDB or not TakeMeHomeDB.infoBarSettings then return end
    if not TakeMeHomeDB.infoBarSettings.enabled then
        infoBar:Hide()
        return
    end

    -- Update each module button; track whether any text changed
    local needReflow = false
    for _, btn in ipairs(infoBarModuleBtns) do
        local s = TakeMeHomeDB.infoBarSettings.modules[btn.modKey]
        if s and s.enabled then
            local text = GetInfoModuleText(btn.modKey)
            if text and text ~= "" then
                if text ~= btn._lastText then
                    btn.lbl:SetText(text)
                    btn._lastText = text
                    needReflow = true
                end
                if not btn:IsShown() then btn:Show(); needReflow = true end
            else
                if btn:IsShown() then btn:Hide(); needReflow = true end
                btn._lastText = nil
            end
        else
            if btn:IsShown() then btn:Hide(); needReflow = true end
            btn._lastText = nil
        end
    end

    -- Dim window toggle buttons whose windows are hidden
    for _, btn in ipairs(infoBarToggleButtons) do
        if btn.dimOverlay then
            if btn.targetFrame and btn.targetFrame:IsShown() then
                btn.dimOverlay:Hide()
            else
                btn.dimOverlay:Show()
            end
        end
    end

    if userWantsWindowsVisible then
        infoBar:Show()
    end

    if needReflow then
        ReflowInfoBar()
    end
end

UpdateInfoBarPosition = function()
    if not TakeMeHomeDB or not TakeMeHomeDB.infoBarSettings then return end
    local pos = TakeMeHomeDB.infoBarSettings.position or "BOTTOM"
    local yOff = TakeMeHomeDB.infoBarSettings.yOffset or 0
    infoBar:ClearAllPoints()
    if pos == "TOP" then
        infoBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -yOff)
        infoBar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -yOff)
    else
        infoBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, yOff)
        infoBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, yOff)
    end
end

InitializeInfoBar = function()
    UpdateInfoBarPosition()

    -- Window toggle buttons on the left of the bar
    local TOGGLE_DEFS = {
        { key = "main",        name = "Travel",      icon = "Interface\\Icons\\inv_misc_rune_01",              frame = mainFrame,       showFunc = UpdateAllButtons },
        { key = "mounts",      name = "Mounts",      icon = "Interface\\Icons\\ability_mount_mountainram",     frame = mountsFrame,     showFunc = UpdateMountButtons },
        { key = "professions", name = "Professions", icon = "Interface\\Icons\\trade_alchemy",                 frame = professionFrame, showFunc = UpdateProfessionButtons },
        { key = "function",    name = "Function",    icon = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up", frame = functionFrame,   showFunc = UpdateFunctionButtons },
        { key = "missions",    name = "Missions",    icon = "Interface\\Icons\\inv_garrison_resource",         frame = missionFrame,    showFunc = UpdateMissionButtons },
    }

    local btnSize = 16
    local btnGap  = 3
    local lastBtn = nil

    wipe(infoBarToggleButtons)
    for _, def in ipairs(TOGGLE_DEFS) do
        local btn = CreateFrame("Button", nil, infoBar)
        btn:SetSize(btnSize, btnSize)
        if lastBtn then
            btn:SetPoint("LEFT", lastBtn, "RIGHT", btnGap, 0)
        else
            btn:SetPoint("LEFT", infoBar, "LEFT", 5, 0)
        end

        local iconTex = btn:CreateTexture(nil, "ARTWORK")
        iconTex:SetAllPoints()
        iconTex:SetTexture(def.icon)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Dimmed overlay when window is hidden
        local dimOverlay = btn:CreateTexture(nil, "OVERLAY")
        dimOverlay:SetAllPoints()
        dimOverlay:SetColorTexture(0, 0, 0, 0.55)
        btn.dimOverlay = dimOverlay

        -- Highlight on hover
        local hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
        hoverTex:SetAllPoints()
        hoverTex:SetColorTexture(1, 1, 1, 0.3)

        btn.targetFrame = def.frame
        btn.showFunc    = def.showFunc
        btn.windowName  = def.name
        btn.windowKey   = def.key

        btn:SetScript("OnClick", function(self)
            if InCombatLockdown() then return end
            if self.targetFrame:IsShown() then
                windowHiddenByBar[self.windowKey] = true
                if TakeMeHomeDB then TakeMeHomeDB.hiddenWindows[self.windowKey] = true end
                self.targetFrame:Hide()
            else
                windowHiddenByBar[self.windowKey] = nil
                if TakeMeHomeDB then TakeMeHomeDB.hiddenWindows[self.windowKey] = nil end
                if self.showFunc then self.showFunc() end
            end
        end)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.windowName, 1, 1, 1)
            GameTooltip:AddLine(self.targetFrame:IsShown() and "Click to hide" or "Click to show", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(infoBarToggleButtons, btn)
        lastBtn = btn
    end

    -- ---- ATT expansion dropdown button ----
    -- Resolve ATT's slash handler once at init — scan SlashCmdList to find whichever
    -- key has "/att" registered as one of its SLASH_<KEY>N aliases.
    local attSlashHandler = nil
    for handlerKey, handlerFunc in pairs(SlashCmdList) do
        local i = 1
        while true do
            local alias = _G["SLASH_" .. handlerKey .. i]
            if not alias then break end
            if alias:lower() == "/att" then
                attSlashHandler = handlerFunc
                break
            end
            i = i + 1
        end
        if attSlashHandler then break end
    end

    local attAnchor = lastBtn  -- track anchor for left-text offset
    local attIsPresent = attSlashHandler ~= nil
                      or C_AddOns.IsAddOnLoaded("AllTheThings")
                      or (AllTheThings ~= nil)
    if attIsPresent
    and TakeMeHomeDB.infoBarSettings
    and TakeMeHomeDB.infoBarSettings.attButton ~= false then

        -- Build expansion dropdown frame
        local rowH = 20
        local sepH = 6   -- height of separator lines
        local ddWidth = 170
        -- Count separators to size the frame correctly
        local separatorCount = 0
        for _, e in ipairs(ATT_EXPANSIONS) do if e.separator then separatorCount = separatorCount + 1 end end
        local attDD = CreateFrame("Frame", "TakeMeHomeATTDropdown", UIParent, "BackdropTemplate")
        attDD:SetSize(ddWidth, #ATT_EXPANSIONS * rowH + separatorCount * sepH + 8)
        attDD:SetFrameStrata("TOOLTIP")
        attDD:SetBackdrop({
            bgFile   = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        attDD:SetBackdropColor(0.07, 0.07, 0.10, 0.97)
        attDD:SetBackdropBorderColor(0.4, 0.3, 0.6, 1)
        attDD:EnableMouse(true)
        attDD:Hide()

        local currentY = 4
        for i, exp in ipairs(ATT_EXPANSIONS) do
            local row = CreateFrame("Button", nil, attDD)
            row:SetSize(ddWidth - 8, rowH - 2)
            row:SetPoint("TOPLEFT", attDD, "TOPLEFT", 4, -currentY)
            currentY = currentY + rowH

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(0.15, 0.10, 0.25, 0)
            row.bg = rowBg

            local rowHL = row:CreateTexture(nil, "HIGHLIGHT")
            rowHL:SetAllPoints()
            rowHL:SetColorTexture(0.4, 0.2, 0.7, 0.4)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", row, "LEFT", 4, 0)
            label:SetText(exp.name)
            label:SetJustifyH("LEFT")

            row.expID   = exp.id
            row.expName = exp.name
            row.expCmd  = exp.cmd

            row:SetScript("OnClick", function(self)
                attDD:Hide()
                print("|cff00ff00TakeMeHome|r: ATT click — cmd=|cff00ffff" .. tostring(self.expCmd) .. "|r  handler=" .. tostring(attSlashHandler))
                if attSlashHandler then
                    pcall(attSlashHandler, self.expCmd)
                end
            end)

            row:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.15, 0.10, 0.25, 0.6)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.expName, 1, 1, 1)
                GameTooltip:AddLine("Open All The Things", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0.15, 0.10, 0.25, 0)
                GameTooltip:Hide()
                C_Timer.After(0.15, function()
                    if not attDD:IsMouseOver() then attDD:Hide() end
                end)
            end)

            -- Draw a thin separator line after this entry if flagged
            if exp.separator then
                local sep = attDD:CreateTexture(nil, "ARTWORK")
                sep:SetHeight(1)
                sep:SetPoint("TOPLEFT",  attDD, "TOPLEFT",  6,  -currentY - 1)
                sep:SetPoint("TOPRIGHT", attDD, "TOPRIGHT", -6, -currentY - 1)
                sep:SetColorTexture(0.4, 0.3, 0.6, 0.6)
                currentY = currentY + sepH
            end
        end

        attDD:SetScript("OnLeave", function(self)
            C_Timer.After(0.15, function()
                if not self:IsMouseOver() then self:Hide() end
            end)
        end)

        -- ATT bar button — anchored after the last window-toggle button
        local attBarBtn = CreateFrame("Button", nil, infoBar)
        attBarBtn:SetSize(30, btnSize)
        attBarBtn:SetPoint("LEFT", lastBtn, "RIGHT", 8, 0)

        local attBtnTex = attBarBtn:CreateTexture(nil, "BACKGROUND")
        attBtnTex:SetAllPoints()
        attBtnTex:SetColorTexture(0.3, 0.1, 0.5, 0)
        attBarBtn.bg = attBtnTex

        local attBtnHL = attBarBtn:CreateTexture(nil, "HIGHLIGHT")
        attBtnHL:SetAllPoints()
        attBtnHL:SetColorTexture(0.4, 0.2, 0.7, 0.35)

        local attBtnLabel = attBarBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        attBtnLabel:SetPoint("CENTER", attBarBtn, "CENTER", 0, 0)
        attBtnLabel:SetText("|cffcc99ffATT|r")

        local function PositionAndShowDD()
            attDD:ClearAllPoints()
            local pos = TakeMeHomeDB.infoBarSettings and TakeMeHomeDB.infoBarSettings.position or "BOTTOM"
            if pos == "TOP" then
                attDD:SetPoint("TOPLEFT", attBarBtn, "BOTTOMLEFT", 0, -2)
            else
                attDD:SetPoint("BOTTOMLEFT", attBarBtn, "TOPLEFT", 0, 2)
            end
            attDD:Show()
        end

        attBarBtn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.3, 0.1, 0.5, 0.5)
            PositionAndShowDD()
        end)
        attBarBtn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.3, 0.1, 0.5, 0)
            C_Timer.After(0.15, function()
                if not attDD:IsMouseOver() then attDD:Hide() end
            end)
        end)

        attAnchor = attBarBtn
    end

    -- Settings cog button (far right)
    infoBarCogButton = CreateFrame("Button", nil, infoBar)
    infoBarCogButton:SetSize(20, 20)
    infoBarCogButton:SetPoint("RIGHT", infoBar, "RIGHT", -4, 0)

    local cogIcon = infoBarCogButton:CreateTexture(nil, "ARTWORK")
    cogIcon:SetAllPoints()
    cogIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
    cogIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cogHL = infoBarCogButton:CreateTexture(nil, "HIGHLIGHT")
    cogHL:SetAllPoints()
    cogHL:SetColorTexture(1, 1, 1, 0.25)

    infoBarCogButton:SetScript("OnClick", function()
        CreateConfigPanel()
    end)
    infoBarCogButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("TakeMeHome Settings", 1, 1, 1)
        GameTooltip:AddLine("Click to open settings", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    infoBarCogButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Create individual module buttons for each INFO_BAR_MODULE
    wipe(infoBarModuleBtns)
    -- Sort by order
    local sortedMods = {}
    for _, mod in ipairs(INFO_BAR_MODULES) do table.insert(sortedMods, mod) end
    table.sort(sortedMods, function(a, b) return a.order < b.order end)
    for _, mod in ipairs(sortedMods) do
        local btn = CreateInfoModuleBtn(mod.key, mod.section)
        table.insert(infoBarModuleBtns, btn)
    end

    -- Left text starts after toggle buttons (+ ATT button gap if present)
    infoBarLeftOffset = #TOGGLE_DEFS * (btnSize + btnGap) - btnGap + 12
    if attAnchor and attAnchor ~= lastBtn then
        infoBarLeftOffset = infoBarLeftOffset + btnGap * 3 + 30 + 4
    end

    UpdateInfoBar()
end

-- ============================================
-- MINIMAP BUTTON
-- ============================================

local minimapButton = CreateFrame("Button", "TakeMeHomeMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:EnableMouse(true)
minimapButton:SetMovable(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- Button textures
local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(18, 18)
minimapIcon:SetPoint("CENTER", 0, 0)
minimapIcon:SetTexture("Interface\\Icons\\inv_misc_rune_01") -- Hearthstone icon

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(52, 52)
minimapBorder:SetPoint("CENTER", 10, -10)  -- Offset to compensate for texture design
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local minimapHighlight = minimapButton:CreateTexture(nil, "HIGHLIGHT")
minimapHighlight:SetSize(24, 24)
minimapHighlight:SetPoint("CENTER")
minimapHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapHighlight:SetBlendMode("ADD")

-- Position minimap button around the minimap
local function UpdateMinimapButtonPosition()
    local angle = TakeMeHomeDB and TakeMeHomeDB.minimapPos or 220
    local radius = 80
    local x = cos(angle) * radius
    local y = sin(angle) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Dragging the minimap button
minimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        if angle < 0 then angle = angle + 360 end
        TakeMeHomeDB.minimapPos = angle
        UpdateMinimapButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetScript("OnUpdate", nil)
end)

-- Click handling
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Toggle all windows based on tracked state
        if userWantsWindowsVisible then
            mainFrame:Hide()
            professionFrame:Hide()
            mountsFrame:Hide()
            functionFrame:Hide()
            missionFrame:Hide()
            infoBar:Hide()
            userWantsWindowsVisible = false
        else
            userWantsWindowsVisible = true
            if not windowHiddenByBar["main"]        then mainFrame:Show()       end
            if not windowHiddenByBar["professions"] then professionFrame:Show() end
            if not windowHiddenByBar["mounts"]      then mountsFrame:Show()     end
            if not windowHiddenByBar["function"]    then functionFrame:Show()   end
            if not windowHiddenByBar["missions"]    then missionFrame:Show()    end
            UpdateInfoBar()
        end
    elseif button == "RightButton" then
        -- Open settings
        SlashCmdList["TAKEMEHOME"]("config")
    end
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff4da6ffTakeMeHome|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffffffLeft-click:|r Toggle window", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cffffffffRight-click:|r Settings", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cffffffffDrag:|r Move button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- ============================================
-- SCALE FUNCTIONS
-- ============================================

local function UpdateScale(newScale)
    TakeMeHomeDB.scale = newScale
    mainFrame:SetScale(newScale)
    professionFrame:SetScale(newScale)
    mountsFrame:SetScale(newScale)
    functionFrame:SetScale(newScale)
end

-- Slash commands
SLASH_TAKEMEHOME1 = "/takemehome"
SLASH_TAKEMEHOME2 = "/tmh"

SlashCmdList["TAKEMEHOME"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "lock" then
        TakeMeHomeDB.locked = true
        UpdateMainDragBanner()
        UpdateProfDragBanner()
        UpdateMountsDragBanner()
        UpdateFuncDragBanner()
        print("|cff00ff00TakeMeHome|r: Windows locked.")
    elseif cmd == "unlock" then
        TakeMeHomeDB.locked = false
        UpdateMainDragBanner()
        UpdateProfDragBanner()
        UpdateMountsDragBanner()
        UpdateFuncDragBanner()
        print("|cff00ff00TakeMeHome|r: Windows unlocked. Drag to move.")
    elseif cmd == "reset" then
        TakeMeHomeDB.position = { point = "CENTER", x = 0, y = 0 }
        TakeMeHomeDB.professionPosition = { point = "CENTER", x = 100, y = 0 }
        TakeMeHomeDB.mountsPosition = { point = "CENTER", x = -100, y = 0 }
        TakeMeHomeDB.functionPosition = { point = "CENTER", x = 0, y = -100 }
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER")
        professionFrame:ClearAllPoints()
        professionFrame:SetPoint("CENTER", 100, 0)
        mountsFrame:ClearAllPoints()
        mountsFrame:SetPoint("CENTER", -100, 0)
        functionFrame:ClearAllPoints()
        functionFrame:SetPoint("CENTER", 0, -100)
        print("|cff00ff00TakeMeHome|r: All positions reset to center.")
    elseif cmd == "toggle" or cmd == "" then
        if mainFrame:IsShown() then
            windowHiddenByBar["main"] = true
            mainFrame:Hide()
        else
            windowHiddenByBar["main"] = nil
            UpdateAllButtons()
        end
    elseif cmd == "show" then
        windowHiddenByBar["main"] = nil
        UpdateAllButtons()
    elseif cmd == "hide" then
        windowHiddenByBar["main"] = true
        mainFrame:Hide()
    elseif cmd == "prof" or cmd == "professions" then
        if professionFrame:IsShown() then
            professionFrame:Hide()
        else
            UpdateProfessionButtons()
        end
    elseif cmd == "prof show" then
        UpdateProfessionButtons()
    elseif cmd == "prof hide" then
        professionFrame:Hide()
    elseif cmd == "prof reset" then
        TakeMeHomeDB.professionPosition = { point = "CENTER", x = 100, y = 0 }
        professionFrame:ClearAllPoints()
        professionFrame:SetPoint("CENTER", 100, 0)
        print("|cff00ff00TakeMeHome|r: Professions position reset.")
    elseif cmd == "func" or cmd == "function" then
        if functionFrame:IsShown() then
            functionFrame:Hide()
        else
            UpdateFunctionButtons()
        end
    elseif cmd == "func show" or cmd == "function show" then
        UpdateFunctionButtons()
    elseif cmd == "func hide" or cmd == "function hide" then
        functionFrame:Hide()
    elseif cmd == "func reset" or cmd == "function reset" then
        TakeMeHomeDB.functionPosition = { point = "CENTER", x = 0, y = -100 }
        functionFrame:ClearAllPoints()
        functionFrame:SetPoint("CENTER", 0, -100)
        print("|cff00ff00TakeMeHome|r: Function position reset.")
    elseif cmd == "attdebug" then
        if not C_AddOns.IsAddOnLoaded("AllTheThings") then
            print("|cff00ff00TakeMeHome|r: AllTheThings is not loaded.")
        else
            print("|cff00ff00TakeMeHome|r: |cff00ffffATT debug v2|r")
            -- Scan ALL globals starting with "AllTheThings"
            print("  |cff00ffffAll ATT globals in _G:|r")
            for gk, gv in pairs(_G) do
                if type(gk) == "string" and gk:find("^AllTheThings") then
                    print("  |cffffcc00" .. gk .. "|r (" .. type(gv) .. ")")
                    if type(gv) == "table" then
                        for k, v in pairs(gv) do
                            if type(v) ~= "function" then
                                print("    ." .. tostring(k) .. " (" .. type(v) .. ") = " .. tostring(v):sub(1, 60))
                                if type(v) == "table" then
                                    local c = 0
                                    for k2, v2 in pairs(v) do
                                        c = c + 1
                                        if c <= 4 then
                                            print("      ." .. tostring(k2) .. " (" .. type(v2) .. ") = " .. tostring(v2):sub(1, 50))
                                        end
                                    end
                                    if c > 4 then print("      ...+" .. (c-4) .. " more") end
                                end
                            end
                        end
                    end
                end
            end
            -- LDB check
            local LibDataBroker = LibStub and LibStub("LibDataBroker-1.1", true)
            if LibDataBroker then
                local n = 0
                for name, obj in LibDataBroker:DataObjectIterator() do n = n + 1 end
                print("  LDB registered objects: " .. n)
                for name, obj in LibDataBroker:DataObjectIterator() do
                    if name:lower():find("things") or name:lower():find("^att") then
                        print("  LDB match: |cff00ffff" .. name .. "|r text=" .. tostring(obj.text))
                    end
                end
            else
                print("  LibDataBroker: not available")
            end
        end
    elseif cmd == "attdebug2" then
        if not AllTheThings then
            print("|cff00ff00TakeMeHome|r: AllTheThings global is nil.")
        else
            print("|cff00ff00TakeMeHome|r: |cff00ffffATT deep probe v2|r")
            -- LDB full field dump — run this AFTER being in game a few minutes
            local LibDataBroker = LibStub and LibStub("LibDataBroker-1.1", true)
            if LibDataBroker then
                -- Find ATT's LDB object by scanning all registered objects
                local attObj, attName = nil, nil
                for name, obj in LibDataBroker:DataObjectIterator() do
                    if name:lower():find("things") or name:lower():find("^att$") then
                        attObj, attName = obj, name
                    end
                end
                if attObj then
                    print("  |cff00ffffLDB '" .. attName .. "' ALL fields:|r")
                    for k, v in pairs(attObj) do
                        print("    ." .. tostring(k) .. " (" .. type(v) .. ") = " .. tostring(v):sub(1, 80))
                    end
                else
                    print("  |cffff4444No ATT LDB object found yet — wait for ATT to finish loading|r")
                end
            else
                print("  LibDataBroker not available")
            end
            -- UniqueCounter — print actual numeric values
            print("  |cff00ffffUniqueCounter numeric probe:|r")
            local uc = AllTheThings.UniqueCounter
            local propNames = {
                "Obtained","obtained","Collected","collected","Count","count",
                "Total","total","Max","max","Progress","progress",
                "progress_total","obtained_total","TotalCollected","TotalObtained",
            }
            for _, k in ipairs(propNames) do
                local ok, v = pcall(function() return uc[k] end)
                if ok and v ~= nil then
                    print("    .UniqueCounter." .. k .. " = " .. tostring(v))
                end
            end
            -- AccountUniqueSources count via # and pairs
            local uc2 = AllTheThings.AccountUniqueSources
            local pairsCount, hashCount = 0, 0
            pcall(function() hashCount = #uc2 end)
            for _ in pairs(uc2) do pairsCount = pairsCount + 1 end
            print("  AccountUniqueSources  # = " .. hashCount .. "  pairs = " .. pairsCount)
            -- Try AllTheThings root group fields (progress/total live on the root category)
            print("  |cff00ffffAllTheThings root group fields:|r")
            local rootProps = {
                "progress","total","filtered","filtersCount",
                "Progress","Total","Filtered","count","Count",
                "TotalProgress","TotalObtained","TotalCollected",
            }
            for _, k in ipairs(rootProps) do
                local ok, v = pcall(function() return AllTheThings[k] end)
                if ok and v ~= nil then
                    print("    .AllTheThings." .. k .. " (" .. type(v) .. ") = " .. tostring(v):sub(1,80))
                end
            end
        end
    elseif cmd == "config" or cmd == "settings" or cmd == "options" then
        CreateConfigPanel()
    else
        print("|cff00ff00TakeMeHome|r Commands:")
        print("  |cff00ffff/tmh|r - Toggle hearthstone window")
        print("  |cff00ffff/tmh show|r - Show hearthstone window")
        print("  |cff00ffff/tmh hide|r - Hide hearthstone window")
        print("  |cff00ffff/tmh prof|r - Toggle professions window")
        print("  |cff00ffff/tmh prof show|r - Show professions window")
        print("  |cff00ffff/tmh prof hide|r - Hide professions window")
        print("  |cff00ffff/tmh prof reset|r - Reset professions position")
        print("  |cff00ffff/tmh func|r - Toggle function window")
        print("  |cff00ffff/tmh func show|r - Show function window")
        print("  |cff00ffff/tmh func hide|r - Hide function window")
        print("  |cff00ffff/tmh func reset|r - Reset function position")
        print("  |cff00ffff/tmh lock|r - Lock all window positions")
        print("  |cff00ffff/tmh unlock|r - Unlock all windows (allow dragging)")
        print("  |cff00ffff/tmh reset|r - Reset all windows to center")
        print("  |cff00ffff/tmh config|r - Open settings panel")
    end
end
