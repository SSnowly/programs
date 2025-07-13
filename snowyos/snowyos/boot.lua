-- SnowyOS Boot System
-- Main boot loader with visual interface

local boot = {}

-- Snowgolem pixel art (for advanced monitors)
local snowgolem = {
    -- Each row is an array of color codes (using CC color constants)
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
local colors_map = {
    [0] = colors.black,    -- Background/transparent
    [1] = colors.white,    -- Snow body
    [4] = colors.orange,   -- Carrot nose
    [8] = colors.gray,     -- Coal eyes/buttons
}

-- Screen management
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

local function setupDisplay(screen)
    if screen then
        local monitor = peripheral.wrap(screen)
        monitor.clear()
        monitor.setTextScale(0.5)  -- Smaller scale for pixel art
        return monitor, true  -- Return monitor and advanced flag
    else
        term.clear()
        return term, false  -- Return terminal and not advanced
    end
end

local function drawPixelSnowgolem(display)
    local w, h = display.getSize()
    local pixelW = #snowgolem[1]
    local pixelH = #snowgolem
    
    -- Calculate starting position to center the snowgolem
    local startX = math.floor((w - pixelW * 2) / 2)  -- *2 because each pixel is 2 chars wide
    local startY = math.floor((h - pixelH - 4) / 2)
    
    -- Draw the pixel art
    for y, row in ipairs(snowgolem) do
        for x, colorCode in ipairs(row) do
            if colorCode ~= 0 then  -- Don't draw transparent pixels
                local pixelX = startX + (x - 1) * 2 + 1
                local pixelY = startY + y
                
                display.setCursorPos(pixelX, pixelY)
                display.setBackgroundColor(colors_map[colorCode])
                display.write("  ")  -- Two spaces to make square pixels
            end
        end
    end
    
    -- Reset colors and draw message
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    local message = "Press Any Button to start"
    local msgX = math.floor((w - #message) / 2) + 1
    display.setCursorPos(msgX, startY + pixelH + 2)
    display.write(message)
end

local function drawAsciiSnowgolem(display)
    -- Fallback ASCII art for regular terminals
    local ascii_snowgolem = {
        "     ___     ",
        "    (o o)    ",
        "   /  -  \\   ",
        "  /  ___  \\  ",
        " |  |   |  | ",
        " |  |___|  | ",
        "  \\       /  ",
        "   \\_____/   ",
        "     | |     ",
        "     |_|     "
    }
    
    local w, h = display.getSize()
    local startY = math.floor((h - #ascii_snowgolem - 3) / 2)
    
    for i, line in ipairs(ascii_snowgolem) do
        local x = math.floor((w - #line) / 2) + 1
        display.setCursorPos(x, startY + i)
        display.write(line)
    end
    
    -- Draw "Press Any Button to start" message
    local message = "Press Any Button to start"
    local msgX = math.floor((w - #message) / 2) + 1
    display.setCursorPos(msgX, startY + #ascii_snowgolem + 2)
    display.write(message)
end

local function waitForInput()
    while true do
        local event = os.pullEvent()
        if event == "key" or event == "char" or event == "mouse_click" then
            break
        end
    end
end

local function drawBootScreens(screens, replicateToTerminal)
    local displays = {}
    
    -- Add main screen
    for _, screen in ipairs(screens) do
        local monitor = peripheral.wrap(screen)
        if monitor then
            monitor.clear()
            monitor.setTextScale(0.5)
            table.insert(displays, {display = monitor, advanced = true})
        end
    end
    
    -- Add terminal if replicating
    if replicateToTerminal then
        term.clear()
        table.insert(displays, {display = term, advanced = false})
    end
    
    -- Draw on all displays
    for _, displayInfo in ipairs(displays) do
        displayInfo.display.clear()
        if displayInfo.advanced then
            drawPixelSnowgolem(displayInfo.display)
        else
            drawAsciiSnowgolem(displayInfo.display)
        end
    end
    
    return displays
end

function boot.start()
    -- Check for saved screen preference
    local currentScreen = nil
    local replicateToTerminal = false
    
    if fs.exists("snowyos/screen.cfg") then
        local file = fs.open("snowyos/screen.cfg", "r")
        currentScreen = file.readAll()
        file.close()
        
        -- Verify the screen still exists
        if not peripheral.isPresent(currentScreen) then
            currentScreen = nil
        end
    end
    
    -- Check for replication setting
    if fs.exists("snowyos/replicate.cfg") then
        local file = fs.open("snowyos/replicate.cfg", "r")
        local setting = file.readAll()
        file.close()
        replicateToTerminal = (setting == "true")
    end
    
    -- If no saved preference or screen not available, find available screens
    if not currentScreen then
        local screens = findScreens()
        if #screens > 0 then
            currentScreen = screens[1]
        end
    end
    
    local screensToUse = {}
    if currentScreen then
        table.insert(screensToUse, currentScreen)
    end
    
    -- Draw boot screens
    local displays = drawBootScreens(screensToUse, replicateToTerminal or not currentScreen)
    
    -- Wait for user input (check all displays)
    waitForInput()
    
    -- Clear all displays
    for _, displayInfo in ipairs(displays) do
        displayInfo.display.clear()
        displayInfo.display.setCursorPos(1, 1)
    end
    
    -- Load the login system
    if fs.exists("snowyos/login.lua") then
        shell.run("snowyos/login.lua")
    else
        print("Login system not found!")
        sleep(2)
    end
end

-- Start the boot process
boot.start() 