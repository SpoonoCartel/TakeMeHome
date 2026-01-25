-- TakeMeHome - Quick access to Hearthstones and travel options
local addonName, addon = ...

-- Item IDs for travel items (isToy = true for toys, false/nil for bag items)
local TRAVEL_ITEMS = {
    { itemID = 6948,   name = "Hearthstone", isToy = false, settingsKey = "hearthstone" },
    { itemID = 140192, name = "Dalaran Hearthstone", isToy = true, settingsKey = "dalaran_hearthstone" },
    { itemID = 110560, name = "Garrison Hearthstone", isToy = true, settingsKey = "garrison_hearthstone" },
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

-- Warband Bank Spell
local WARBAND_BANK_SPELL = { name = "Warband Bank Distance Inhibitor" }

-- Mobile Banking Spell (Guild Perk)
local MOBILE_BANKING_SPELL = { name = "Mobile Banking" }

-- Button definitions with keys for settings
local BUTTON_DEFINITIONS = {
    -- Row 1: Hearthstones
    { key = "hearthstone", name = "Hearthstone", row = 1 },
    { key = "dalaran_hearthstone", name = "Dalaran Hearthstone", row = 1 },
    { key = "garrison_hearthstone", name = "Garrison Hearthstone", row = 1 },
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
    locked = false,
    scale = 0.75,
    minimapPos = 220, -- Angle around minimap
    buttonSettings = {
        hearthstone = { enabled = true, order = 1 },
        dalaran_hearthstone = { enabled = true, order = 2 },
        garrison_hearthstone = { enabled = true, order = 3 },
        mailbox = { enabled = true, order = 4 },
        warband_bank = { enabled = true, order = 5 },
        mobile_banking = { enabled = true, order = 6 },
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
    -- Window snapping and linking
    snapEnabled = true,
    linkedWindows = {}, -- Groups of linked window keys, e.g., { {"main", "professions"}, {"mounts", "function"} }
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
local UpdateMainDragBanner, UpdateProfDragBanner, UpdateMountsDragBanner, UpdateFuncDragBanner
local InitializeProfessions, InitializeMounts, InitializeFunction
local UpdateProfessionButtons, UpdateMountButtons, UpdateFunctionButtons

-- Track if user wants windows visible (used by minimap toggle)
local userWantsWindowsVisible = true

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
    }
    windowPositionKeys = {
        main = "position",
        professions = "professionPosition",
        mounts = "mountsPosition",
        ["function"] = "functionPosition",
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
        -- Only show if user wants windows visible
        if userWantsWindowsVisible then
            mainFrame:Show()
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

        -- Ensure snap/link settings exist
        if TakeMeHomeDB.snapEnabled == nil then
            TakeMeHomeDB.snapEnabled = defaults.snapEnabled
        end
        if not TakeMeHomeDB.linkedWindows then
            TakeMeHomeDB.linkedWindows = {}
        end

        -- Ensure all button keys exist
        for key, defaultSettings in pairs(defaults.buttonSettings) do
            if not TakeMeHomeDB.buttonSettings[key] then
                TakeMeHomeDB.buttonSettings[key] = CopyTable(defaultSettings)
            end
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

        -- Initial update
        C_Timer.After(1, UpdateAllButtons)

        -- Set up periodic updates (to swap mailbox toy when cooldowns end)
        C_Timer.NewTicker(1, function()
            if not InCombatLockdown() then
                UpdateAllButtons()
            end
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

-- Create the configuration panel with tabs
local function CreateConfigPanel()
    if configFrame then
        configFrame:Show()
        return
    end

    configFrame = CreateFrame("Frame", "TakeMeHomeConfig", UIParent, "BackdropTemplate")
    configFrame:SetSize(340, 400)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetClampedToScreen(true)
    configFrame:SetFrameStrata("DIALOG")

    -- Modern dark backdrop
    configFrame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    configFrame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    configFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

    configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    configFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Title bar background
    local titleBar = configFrame:CreateTexture(nil, "ARTWORK")
    titleBar:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(28)
    titleBar:SetColorTexture(0.15, 0.15, 0.18, 1)

    -- Title
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", configFrame, "TOP", 0, -8)
    title:SetText("|cff4da6ffTakeMeHome|r Settings")

    -- Close button
    local closeButton = CreateFrame("Button", nil, configFrame)
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -5, -5)
    closeButton:SetNormalFontObject("GameFontNormal")
    closeButton:SetText("x")

    local closeBg = closeButton:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.5, 0.2, 0.2, 0)

    closeButton:SetScript("OnEnter", function(self) closeBg:SetColorTexture(0.7, 0.2, 0.2, 0.8) end)
    closeButton:SetScript("OnLeave", function(self) closeBg:SetColorTexture(0.5, 0.2, 0.2, 0) end)
    closeButton:SetScript("OnClick", function(self) configFrame:Hide() end)

    -- Helper function to create modern button
    local function CreateModernButton(parent, width, text)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(width, 20)
        btn:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(text)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.5, 0.7, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.25, 1)
        end)

        return btn
    end

    -- Tab buttons container
    local tabContainer = CreateFrame("Frame", nil, configFrame)
    tabContainer:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -32)
    tabContainer:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -10, -32)
    tabContainer:SetHeight(28)

    -- Content frames for each tab
    local travelContent = CreateFrame("Frame", nil, configFrame)
    travelContent:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -65)
    travelContent:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 35)

    local professionsContent = CreateFrame("Frame", nil, configFrame)
    professionsContent:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -65)
    professionsContent:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 35)
    professionsContent:Hide()

    local mountsContent = CreateFrame("Frame", nil, configFrame)
    mountsContent:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -65)
    mountsContent:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 35)
    mountsContent:Hide()

    local functionContent = CreateFrame("Frame", nil, configFrame)
    functionContent:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -65)
    functionContent:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 35)
    functionContent:Hide()

    local contentFrames = { travelContent, professionsContent, mountsContent, functionContent }
    local tabButtons = {}

    -- Create tab button helper
    local function CreateTabButton(parent, text, index)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(75, 24)
        btn:SetBackdrop({
            bgFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(text)

        btn.index = index
        btn.isActive = false

        btn:SetScript("OnClick", function(self)
            -- Hide all content frames
            for _, frame in ipairs(contentFrames) do
                frame:Hide()
            end
            -- Show selected content
            contentFrames[self.index]:Show()
            -- Update tab appearances
            for _, tabBtn in ipairs(tabButtons) do
                if tabBtn.index == self.index then
                    tabBtn:SetBackdropColor(0.2, 0.5, 0.8, 1)
                    tabBtn.isActive = true
                else
                    tabBtn:SetBackdropColor(0.15, 0.15, 0.18, 1)
                    tabBtn.isActive = false
                end
            end
        end)

        btn:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropColor(0.25, 0.25, 0.3, 1)
            end
        end)

        btn:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropColor(0.15, 0.15, 0.18, 1)
            end
        end)

        return btn
    end

    -- Create tab buttons
    local travelTab = CreateTabButton(tabContainer, "Travel", 1)
    travelTab:SetPoint("LEFT", tabContainer, "LEFT", 0, 0)
    travelTab:SetBackdropColor(0.2, 0.5, 0.8, 1)
    travelTab.isActive = true
    table.insert(tabButtons, travelTab)

    local professionsTab = CreateTabButton(tabContainer, "Professions", 2)
    professionsTab:SetPoint("LEFT", travelTab, "RIGHT", 5, 0)
    table.insert(tabButtons, professionsTab)

    local mountsTab = CreateTabButton(tabContainer, "Mounts", 3)
    mountsTab:SetPoint("LEFT", professionsTab, "RIGHT", 5, 0)
    table.insert(tabButtons, mountsTab)

    local functionTab = CreateTabButton(tabContainer, "Function", 4)
    functionTab:SetPoint("LEFT", mountsTab, "RIGHT", 5, 0)
    table.insert(tabButtons, functionTab)

    -- =====================
    -- TRAVEL TAB CONTENT
    -- =====================
    local travelYOffset = 0
    for i, def in ipairs(BUTTON_DEFINITIONS) do
        local row = CreateFrame("Frame", nil, travelContent, "BackdropTemplate")
        row:SetSize(300, 30)
        row:SetPoint("TOPLEFT", travelContent, "TOPLEFT", 0, travelYOffset)

        row:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
        row:SetBackdropColor(0.12, 0.12, 0.15, (i % 2 == 0) and 0.5 or 0)

        local checkbox = CreateFrame("CheckButton", "TakeMeHomeTravelCheck"..def.key, row, "UICheckButtonTemplate")
        checkbox:SetPoint("LEFT", row, "LEFT", 5, 0)
        checkbox:SetChecked(TakeMeHomeDB.buttonSettings[def.key].enabled)
        checkbox.key = def.key

        checkbox:SetScript("OnClick", function(self)
            TakeMeHomeDB.buttonSettings[self.key].enabled = self:GetChecked()
            UpdateAllButtons()
        end)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        label:SetWidth(120)
        label:SetJustifyH("LEFT")
        label:SetText(def.name)

        local rowLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rowLabel:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        rowLabel:SetText("Row " .. def.row)
        rowLabel:SetTextColor(0.5, 0.5, 0.55)

        -- Up/Down buttons
        local downBtn = CreateModernButton(row, 24, "v")
        downBtn:SetPoint("RIGHT", rowLabel, "LEFT", -8, 0)
        downBtn.index = i

        local upBtn = CreateModernButton(row, 24, "^")
        upBtn:SetPoint("RIGHT", downBtn, "LEFT", -4, 0)
        upBtn.index = i

        upBtn:SetScript("OnClick", function(self)
            if self.index > 1 then
                local currentKey = BUTTON_DEFINITIONS[self.index].key
                local prevKey = BUTTON_DEFINITIONS[self.index - 1].key
                local currentOrder = TakeMeHomeDB.buttonSettings[currentKey].order
                local prevOrder = TakeMeHomeDB.buttonSettings[prevKey].order
                TakeMeHomeDB.buttonSettings[currentKey].order = prevOrder
                TakeMeHomeDB.buttonSettings[prevKey].order = currentOrder
                UpdateAllButtons()
            end
        end)

        downBtn:SetScript("OnClick", function(self)
            if self.index < #BUTTON_DEFINITIONS then
                local currentKey = BUTTON_DEFINITIONS[self.index].key
                local nextKey = BUTTON_DEFINITIONS[self.index + 1].key
                local currentOrder = TakeMeHomeDB.buttonSettings[currentKey].order
                local nextOrder = TakeMeHomeDB.buttonSettings[nextKey].order
                TakeMeHomeDB.buttonSettings[currentKey].order = nextOrder
                TakeMeHomeDB.buttonSettings[nextKey].order = currentOrder
                UpdateAllButtons()
            end
        end)

        travelYOffset = travelYOffset - 32
    end

    -- =====================
    -- PROFESSIONS TAB CONTENT
    -- =====================
    local function RefreshProfessionsTab()
        -- Clear existing children
        for _, child in ipairs({professionsContent:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local professions = GetLearnedProfessions()

        -- Initialize settings for any new professions
        for i, prof in ipairs(professions) do
            if not TakeMeHomeDB.professionSettings[prof.name] then
                TakeMeHomeDB.professionSettings[prof.name] = { enabled = true, order = i }
            end
        end

        -- Sort by current order
        table.sort(professions, function(a, b)
            return GetProfessionOrder(a.name) < GetProfessionOrder(b.name)
        end)

        if #professions == 0 then
            local noProf = professionsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noProf:SetPoint("CENTER")
            noProf:SetText("No crafting professions learned")
            noProf:SetTextColor(0.5, 0.5, 0.5)
            return
        end

        local yOffset = 0
        for i, prof in ipairs(professions) do
            local row = CreateFrame("Frame", nil, professionsContent, "BackdropTemplate")
            row:SetSize(300, 30)
            row:SetPoint("TOPLEFT", professionsContent, "TOPLEFT", 0, yOffset)

            row:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
            row:SetBackdropColor(0.12, 0.12, 0.15, (i % 2 == 0) and 0.5 or 0)

            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetPoint("LEFT", row, "LEFT", 5, 0)
            checkbox:SetChecked(IsProfessionEnabled(prof.name))
            checkbox.profName = prof.name

            checkbox:SetScript("OnClick", function(self)
                TakeMeHomeDB.professionSettings[self.profName].enabled = self:GetChecked()
                UpdateProfessionButtons()
            end)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            icon:SetTexture(prof.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            label:SetWidth(120)
            label:SetJustifyH("LEFT")
            label:SetText(prof.name)

            -- Up/Down buttons
            local downBtn = CreateModernButton(row, 24, "v")
            downBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            downBtn.profName = prof.name
            downBtn.index = i
            downBtn.professions = professions

            local upBtn = CreateModernButton(row, 24, "^")
            upBtn:SetPoint("RIGHT", downBtn, "LEFT", -4, 0)
            upBtn.profName = prof.name
            upBtn.index = i
            upBtn.professions = professions

            upBtn:SetScript("OnClick", function(self)
                if self.index > 1 then
                    local currentName = self.profName
                    local prevName = self.professions[self.index - 1].name
                    local currentOrder = TakeMeHomeDB.professionSettings[currentName].order
                    local prevOrder = TakeMeHomeDB.professionSettings[prevName].order
                    TakeMeHomeDB.professionSettings[currentName].order = prevOrder
                    TakeMeHomeDB.professionSettings[prevName].order = currentOrder
                    UpdateProfessionButtons()
                    RefreshProfessionsTab()
                end
            end)

            downBtn:SetScript("OnClick", function(self)
                if self.index < #self.professions then
                    local currentName = self.profName
                    local nextName = self.professions[self.index + 1].name
                    local currentOrder = TakeMeHomeDB.professionSettings[currentName].order
                    local nextOrder = TakeMeHomeDB.professionSettings[nextName].order
                    TakeMeHomeDB.professionSettings[currentName].order = nextOrder
                    TakeMeHomeDB.professionSettings[nextName].order = currentOrder
                    UpdateProfessionButtons()
                    RefreshProfessionsTab()
                end
            end)

            yOffset = yOffset - 32
        end
    end

    -- Refresh professions when tab is shown
    professionsTab:HookScript("OnClick", RefreshProfessionsTab)

    -- =====================
    -- MOUNTS TAB CONTENT
    -- =====================
    local mountSearchResults = {}
    local maxMounts = 6

    local function RefreshMountsTab()
        -- Clear existing children (frames)
        for _, child in ipairs({mountsContent:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        -- Clear existing regions (fontstrings, textures)
        for _, region in ipairs({mountsContent:GetRegions()}) do
            region:Hide()
            region:SetParent(nil)
        end

        local selectedMounts = TakeMeHomeDB.selectedMounts or {}
        local yOffset = 0

        -- Header: Selected Mounts (X/6)
        local header = mountsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", mountsContent, "TOPLEFT", 0, yOffset)
        header:SetText(string.format("Selected Mounts (%d/%d)", #selectedMounts, maxMounts))
        header:SetTextColor(0.4, 0.6, 1)
        yOffset = yOffset - 20

        -- Show selected mounts
        for i, mountEntry in ipairs(selectedMounts) do
            local name, icon, isCollected = GetMountInfoBySpellID(mountEntry.spellID)

            local row = CreateFrame("Frame", nil, mountsContent, "BackdropTemplate")
            row:SetSize(300, 26)
            row:SetPoint("TOPLEFT", mountsContent, "TOPLEFT", 0, yOffset)
            row:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
            row:SetBackdropColor(0.08, 0.08, 0.1, (i % 2 == 0) and 0.95 or 0.85)

            -- Icon
            local iconTex = row:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(20, 20)
            iconTex:SetPoint("LEFT", row, "LEFT", 5, 0)
            if icon then iconTex:SetTexture(icon) end
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not isCollected then iconTex:SetDesaturated(true) end

            -- Name
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", iconTex, "RIGHT", 5, 0)
            label:SetWidth(140)
            label:SetJustifyH("LEFT")
            label:SetText(name or "Unknown Mount")
            if not isCollected then label:SetTextColor(0.5, 0.5, 0.5) end

            -- Remove button
            local removeBtn = CreateModernButton(row, 20, "x")
            removeBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            removeBtn.index = i
            removeBtn:SetScript("OnClick", function(self)
                table.remove(TakeMeHomeDB.selectedMounts, self.index)
                UpdateMountButtons()
                RefreshMountsTab()
            end)

            -- Down button
            local downBtn = CreateModernButton(row, 20, "v")
            downBtn:SetPoint("RIGHT", removeBtn, "LEFT", -2, 0)
            downBtn.index = i
            downBtn:SetScript("OnClick", function(self)
                if self.index < #TakeMeHomeDB.selectedMounts then
                    local temp = TakeMeHomeDB.selectedMounts[self.index]
                    TakeMeHomeDB.selectedMounts[self.index] = TakeMeHomeDB.selectedMounts[self.index + 1]
                    TakeMeHomeDB.selectedMounts[self.index + 1] = temp
                    UpdateMountButtons()
                    RefreshMountsTab()
                end
            end)

            -- Up button
            local upBtn = CreateModernButton(row, 20, "^")
            upBtn:SetPoint("RIGHT", downBtn, "LEFT", -2, 0)
            upBtn.index = i
            upBtn:SetScript("OnClick", function(self)
                if self.index > 1 then
                    local temp = TakeMeHomeDB.selectedMounts[self.index]
                    TakeMeHomeDB.selectedMounts[self.index] = TakeMeHomeDB.selectedMounts[self.index - 1]
                    TakeMeHomeDB.selectedMounts[self.index - 1] = temp
                    UpdateMountButtons()
                    RefreshMountsTab()
                end
            end)

            yOffset = yOffset - 28
        end

        -- Only show Add Mount section if less than max mounts selected
        if #selectedMounts >= maxMounts then
            return  -- Don't show search section when at max capacity
        end

        -- Spacer
        yOffset = yOffset - 15

        -- Search section header
        local searchHeader = mountsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        searchHeader:SetPoint("TOPLEFT", mountsContent, "TOPLEFT", 0, yOffset)
        searchHeader:SetText("Add Mount")
        searchHeader:SetTextColor(0.4, 0.6, 1)
        yOffset = yOffset - 22

        -- Search box
        local searchBox = CreateFrame("EditBox", "TakeMeHomeMountSearch", mountsContent, "InputBoxTemplate")
        searchBox:SetSize(290, 22)
        searchBox:SetPoint("TOPLEFT", mountsContent, "TOPLEFT", 8, yOffset)
        searchBox:SetAutoFocus(false)
        searchBox:SetMaxLetters(50)
        yOffset = yOffset - 28

        -- Search results container
        local resultsContainer = CreateFrame("Frame", nil, mountsContent)
        resultsContainer:SetPoint("TOPLEFT", mountsContent, "TOPLEFT", 0, yOffset)
        resultsContainer:SetSize(300, 150)

        local function DisplaySearchResults(searchText)
            -- Clear previous results
            for _, child in ipairs({resultsContainer:GetChildren()}) do
                child:Hide()
                child:SetParent(nil)
            end

            if not searchText or searchText == "" then return end

            searchText = searchText:lower()
            local results = {}
            local mountIDs = C_MountJournal.GetMountIDs()

            for _, mountID in ipairs(mountIDs) do
                local name, spellID, icon, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
                if isCollected and name and name:lower():find(searchText, 1, true) then
                    -- Check if not already selected
                    local alreadySelected = false
                    for _, sel in ipairs(TakeMeHomeDB.selectedMounts) do
                        if sel.spellID == spellID then
                            alreadySelected = true
                            break
                        end
                    end
                    if not alreadySelected then
                        table.insert(results, { name = name, spellID = spellID, icon = icon, mountID = mountID })
                    end
                end
                if #results >= 5 then break end  -- Limit results
            end

            local resY = 0
            for i, result in ipairs(results) do
                local row = CreateFrame("Frame", nil, resultsContainer, "BackdropTemplate")
                row:SetSize(295, 24)
                row:SetPoint("TOPLEFT", resultsContainer, "TOPLEFT", 0, resY)
                row:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
                row:SetBackdropColor(0.15, 0.15, 0.18, 0.8)

                local iconTex = row:CreateTexture(nil, "ARTWORK")
                iconTex:SetSize(18, 18)
                iconTex:SetPoint("LEFT", row, "LEFT", 5, 0)
                iconTex:SetTexture(result.icon)
                iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("LEFT", iconTex, "RIGHT", 5, 0)
                label:SetWidth(180)
                label:SetJustifyH("LEFT")
                label:SetText(result.name)

                -- Add button
                local addBtn = CreateModernButton(row, 30, "+")
                addBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                addBtn.spellID = result.spellID
                addBtn:SetScript("OnClick", function(self)
                    if #TakeMeHomeDB.selectedMounts >= maxMounts then
                        print("|cff00ff00TakeMeHome|r: Maximum of " .. maxMounts .. " mounts reached.")
                        return
                    end
                    table.insert(TakeMeHomeDB.selectedMounts, { spellID = self.spellID })
                    UpdateMountButtons()
                    searchBox:SetText("")
                    RefreshMountsTab()
                end)

                resY = resY - 26
            end

            if #results == 0 and searchText ~= "" then
                local noResults = resultsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                noResults:SetPoint("TOPLEFT", resultsContainer, "TOPLEFT", 5, 0)
                noResults:SetText("No matching mounts found")
                noResults:SetTextColor(0.5, 0.5, 0.5)
            end
        end

        searchBox:SetScript("OnTextChanged", function(self)
            DisplaySearchResults(self:GetText())
        end)

        searchBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)

        searchBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
        end)
    end

    -- Refresh mounts when tab is shown
    mountsTab:HookScript("OnClick", RefreshMountsTab)

    -- =====================
    -- FUNCTION TAB CONTENT
    -- =====================
    local FUNCTION_DEFINITIONS = {
        { key = "logout", name = "Logout", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
    }

    local function IsFunctionEnabled(key)
        if not TakeMeHomeDB or not TakeMeHomeDB.functionSettings then return true end
        local settings = TakeMeHomeDB.functionSettings[key]
        if not settings then return true end
        return settings.enabled
    end

    local function RefreshFunctionTab()
        -- Clear existing children
        for _, child in ipairs({functionContent:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        -- Clear existing regions
        for _, region in ipairs({functionContent:GetRegions()}) do
            region:Hide()
            region:SetParent(nil)
        end

        local yOffset = 0
        for i, def in ipairs(FUNCTION_DEFINITIONS) do
            local row = CreateFrame("Frame", nil, functionContent, "BackdropTemplate")
            row:SetSize(300, 30)
            row:SetPoint("TOPLEFT", functionContent, "TOPLEFT", 0, yOffset)

            row:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8" })
            row:SetBackdropColor(0.12, 0.12, 0.15, (i % 2 == 0) and 0.5 or 0)

            local checkbox = CreateFrame("CheckButton", "TakeMeHomeFuncCheck"..def.key, row, "UICheckButtonTemplate")
            checkbox:SetPoint("LEFT", row, "LEFT", 5, 0)
            checkbox:SetChecked(IsFunctionEnabled(def.key))
            checkbox.key = def.key

            checkbox:SetScript("OnClick", function(self)
                if not TakeMeHomeDB.functionSettings[self.key] then
                    TakeMeHomeDB.functionSettings[self.key] = { enabled = true, order = 1 }
                end
                TakeMeHomeDB.functionSettings[self.key].enabled = self:GetChecked()
                UpdateFunctionButtons()
            end)

            -- Icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            icon:SetTexture(def.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            label:SetWidth(180)
            label:SetJustifyH("LEFT")
            label:SetText(def.name)

            yOffset = yOffset - 32
        end
    end

    -- Refresh function tab when shown
    functionTab:HookScript("OnClick", RefreshFunctionTab)

    -- Initial population of tabs (so they're not empty when first opened)
    RefreshProfessionsTab()
    RefreshMountsTab()
    RefreshFunctionTab()

    -- Instructions
    local instructions = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 12)
    instructions:SetText("|cff888888Check to enable  |  ^ v to reorder|r")

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
    -- Only show if user wants windows visible
    if userWantsWindowsVisible then
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
    -- Only show if user wants windows visible
    if userWantsWindowsVisible then
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
    { key = "logout", name = "Logout", icon = "Interface\\Icons\\Spell_Shadow_Teleport" },
}

-- Update function buttons
UpdateFunctionButtons = function()
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
    -- Only show if user wants windows visible
    if userWantsWindowsVisible then
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
            userWantsWindowsVisible = false
        else
            mainFrame:Show()
            professionFrame:Show()
            mountsFrame:Show()
            functionFrame:Show()
            userWantsWindowsVisible = true
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
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    elseif cmd == "show" then
        mainFrame:Show()
    elseif cmd == "hide" then
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
