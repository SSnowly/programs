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