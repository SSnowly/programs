-- SnowyOS Screen Manager
-- Centralized display management for multi-screen support

local screenManager = {}

-- Configuration
local config = {
    primaryScreen = nil,
    replicateToTerminal = false,
    screens = {},
    initialized = false
}

-- Snowgolem pixel art (from boot.lua)
local snowgolem = {
    {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},  -- Top of head
    {0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},  -- Head top
    {0, 1, 1, 8, 1, 1, 1, 8, 1, 1, 0},  -- Eyes
    {0, 1, 1, 1, 4, 4, 4, 1, 1, 1, 0},  -- Nose (carrot)
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},  -- Mouth area
    {0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},  -- Head bottom
    {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},  -- Neck
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},  -- Body top
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},  -- Body middle
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},  -- Body bottom
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},  -- Body lower
    {0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},  -- Base
}

-- Color palette for snowgolem
local snowgolemColors = {
    [0] = colors.black,    -- Background/transparent
    [1] = colors.white,    -- Snow body
    [4] = colors.orange,   -- Carrot nose
    [8] = colors.gray,     -- Coal eyes/buttons
}

-- Load configuration from files
local function loadConfig()
    -- Load primary screen
    if fs.exists("snowyos/screen.cfg") then
        local file = fs.open("snowyos/screen.cfg", "r")
        config.primaryScreen = file.readAll()
        file.close()
        
        -- Verify screen still exists
        if not peripheral.isPresent(config.primaryScreen) then
            config.primaryScreen = nil
        end
    end
    
    -- Load replication setting
    if fs.exists("snowyos/replicate.cfg") then
        local file = fs.open("snowyos/replicate.cfg", "r")
        local setting = file.readAll()
        file.close()
        config.replicateToTerminal = (setting == "true")
    end
end

-- Find all available screens
local function findScreens()
    local screens = {}
    local peripherals = peripheral.getNames()
    
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "monitor" then
            table.insert(screens, name)
        end
    end
    
    return screens
end

-- Auto-discover and add additional screens beyond primary
local function addAdditionalScreens()
    if not config.primaryScreen then
        return
    end
    
    local allScreens = findScreens()
    for _, screenName in ipairs(allScreens) do
        if screenName ~= config.primaryScreen then
            local monitor = peripheral.wrap(screenName)
            if monitor then
                monitor.setTextScale(0.5)
                table.insert(config.screens, {
                    name = screenName,
                    display = monitor,
                    isAdvanced = true,
                    isPrimary = false
                })
            end
        end
    end
end

-- Initialize screen manager
function screenManager.init()
    if config.initialized then
        return
    end
    
    loadConfig()
    
    -- Build active screen list
    config.screens = {}
    
    -- Add primary screen if available
    if config.primaryScreen and peripheral.isPresent(config.primaryScreen) then
        local monitor = peripheral.wrap(config.primaryScreen)
        monitor.setTextScale(0.5)
        table.insert(config.screens, {
            name = config.primaryScreen,
            display = monitor,
            isAdvanced = true,
            isPrimary = true
        })
    end
    
    -- Add additional screens automatically
    addAdditionalScreens()
    
    -- Add terminal if replicating or no primary screen
    if config.replicateToTerminal or not config.primaryScreen then
        table.insert(config.screens, {
            name = "terminal",
            display = term,
            isAdvanced = false,
            isPrimary = not config.primaryScreen
        })
    end
    
    config.initialized = true
end

-- Get primary display (for input operations)
function screenManager.getPrimaryDisplay()
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        if screen.isPrimary then
            return screen.display, screen.isAdvanced
        end
    end
    
    -- Fallback to terminal
    return term, false
end

-- Clear all screens
function screenManager.clearAll()
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        screen.display.clear()
        screen.display.setBackgroundColor(colors.black)
        screen.display.setTextColor(colors.white)
    end
end

-- Set cursor position on all screens
function screenManager.setCursorPos(x, y)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        screen.display.setCursorPos(x, y)
    end
end

-- Write text to all screens
function screenManager.write(text)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        screen.display.write(text)
    end
end

-- Set background color on all screens
function screenManager.setBackgroundColor(color)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        screen.display.setBackgroundColor(color)
    end
end

-- Set text color on all screens
function screenManager.setTextColor(color)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        screen.display.setTextColor(color)
    end
end

-- Get size of primary display
function screenManager.getSize()
    local primary = screenManager.getPrimaryDisplay()
    return primary.getSize()
end

-- Execute a function on all screens
function screenManager.forEach(func)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        func(screen.display, screen.isAdvanced, screen.name)
    end
end

-- Execute a function only on advanced screens
function screenManager.forEachAdvanced(func)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        if screen.isAdvanced then
            func(screen.display, screen.name)
        end
    end
end

-- Execute a function only on the primary screen
function screenManager.onPrimary(func)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        if screen.isPrimary then
            func(screen.display, screen.isAdvanced, screen.name)
            break
        end
    end
end

-- Blit operation to all screens (for advanced displays)
function screenManager.blitAll(lines, textColors, backgroundColors)
    screenManager.init()
    
    for _, screen in ipairs(config.screens) do
        if screen.isAdvanced and screen.display.blit then
            for i, line in ipairs(lines) do
                screen.display.setCursorPos(1, i)
                screen.display.blit(line, textColors[i], backgroundColors[i])
            end
        end
    end
end

-- Draw pixel art on advanced screens, fallback on others
function screenManager.drawPixelArt(pixelData, colorMap, x, y, scale)
    screenManager.init()
    scale = scale or 1
    
    screenManager.forEach(function(display, isAdvanced, name)
        if isAdvanced then
            -- Draw pixel art
            for row, pixelRow in ipairs(pixelData) do
                for col, colorCode in ipairs(pixelRow) do
                    if colorCode ~= 0 then
                        local pixelX = x + (col - 1) * scale
                        local pixelY = y + (row - 1)
                        
                        display.setCursorPos(pixelX, pixelY)
                        display.setBackgroundColor(colorMap[colorCode] or colors.white)
                        
                        for i = 1, scale do
                            display.write(" ")
                        end
                    end
                end
            end
        end
    end)
end

-- Draw snowgolem pixel art (from boot.lua system)
function screenManager.drawPixelSnowgolem(message, centered)
    screenManager.init()
    centered = centered or false
    
    screenManager.forEach(function(display, isAdvanced, name)
        if isAdvanced or name.includes("terminal") then
            local w, h = display.getSize()
            local pixelW = #snowgolem[1]
            local pixelH = #snowgolem
            
            local startX, startY
            if centered then
                -- Large centered snowgolem (boot screen style)
                startX = math.floor((w - pixelW * 2) / 2)
                startY = math.floor((h - pixelH - 4) / 2)
            else
                -- Small icon in top-left
                startX = 2
                startY = 2
            end
            
            -- Draw the pixel art
            for y, row in ipairs(snowgolem) do
                for x, colorCode in ipairs(row) do
                    if colorCode ~= 0 then
                        local pixelX = startX + (x - 1) * (centered and 2 or 1) + 1
                        local pixelY = startY + y
                        
                        display.setCursorPos(pixelX, pixelY)
                        display.setBackgroundColor(snowgolemColors[colorCode])
                        display.write(centered and "  " or " ")
                    end
                end
            end
            
            -- Reset colors and draw message
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.white)
            
            if message then
                if centered then
                    local msgX = math.floor((w - #message) / 2) + 1
                    display.setCursorPos(msgX, startY + pixelH + 2)
                    display.write(message)
                else
                    display.setCursorPos(startX + pixelW + 2, startY + 2)
                    display.write(message)
                end
            end
        else
            -- Simple text for non-advanced displays
            if message then
                local w, h = display.getSize()
                if centered then
                    local startY = math.floor(h / 2) - 2
                    display.setCursorPos(math.floor((w - #"SnowyOS") / 2) + 1, startY)
                    display.write("SnowyOS")
                    display.setCursorPos(math.floor((w - #message) / 2) + 1, startY + 2)
                    display.write(message)
                else
                    display.setCursorPos(1, 1)
                    display.write("SnowyOS")
                    display.setCursorPos(1, 3)
                    display.write(message)
                end
            end
        end
    end)
end

-- Draw boot screen (from boot.lua system)
function screenManager.drawBootScreen()
    screenManager.init()
    screenManager.clearAll()
    screenManager.drawPixelSnowgolem("Press Any Button to start", true)
end

-- Wait for input on primary display
function screenManager.waitForInput()
    while true do
        local event = os.pullEvent()
        if event == "key" or event == "char" or event == "mouse_click" then
            break
        end
    end
end

-- Setup display with proper scaling (from boot.lua system)
function screenManager.setupDisplay(screenName)
    if screenName and peripheral.isPresent(screenName) then
        local monitor = peripheral.wrap(screenName)
        monitor.clear()
        monitor.setTextScale(0.5)
        return monitor, true
    else
        term.clear()
        return term, false
    end
end

-- Find available screens (exposed version of internal function)
function screenManager.findAvailableScreens()
    return findScreens()
end

-- Get list of active screens
function screenManager.getActiveScreens()
    screenManager.init()
    return config.screens
end

-- Check if multi-screen is enabled
function screenManager.isMultiScreen()
    screenManager.init()
    return #config.screens > 1
end

-- Reinitialize (useful after config changes)
function screenManager.reinit()
    config.initialized = false
    screenManager.init()
end

return screenManager 