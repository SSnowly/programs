-- SnowyOS Installer
-- Handles initial setup, screen selection, and user account creation

local install = {}

-- Snowgolem pixel art (same as boot screen)
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
local colors_map = {
    [0] = colors.black,    -- Background/transparent
    [1] = colors.white,    -- Snow body
    [4] = colors.orange,   -- Carrot nose
    [8] = colors.gray,     -- Coal eyes/buttons
}

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
        monitor.setTextScale(0.5)
        return monitor, true
    else
        term.clear()
        return term, true
    end
end

local function drawPixelSnowgolem(display, message, isSmall)
    local w, h = display.getSize()
    local pixelW = #snowgolem[1]
    local pixelH = #snowgolem
    
    if isSmall then
        -- Small icon in top-left corner
        local startX = 2
        local startY = 2
        
        -- Draw smaller pixel art (1 char per pixel instead of 2)
        for y, row in ipairs(snowgolem) do
            for x, colorCode in ipairs(row) do
                if colorCode ~= 0 then
                    local pixelX = startX + (x - 1)
                    local pixelY = startY + (y - 1)
                    
                    display.setCursorPos(pixelX, pixelY)
                    display.setBackgroundColor(colors_map[colorCode])
                    display.write(" ")
                end
            end
        end
        
        -- Reset colors and draw title next to icon
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        display.setCursorPos(startX + pixelW + 2, startY + 2)
        display.write(message)
        
        -- Clear any remaining background artifacts
        display.setBackgroundColor(colors.black)
        
        return startY + pixelH + 2
    else
        -- Large centered snowgolem (original behavior for boot screen)
        local startX = math.floor((w - pixelW * 2) / 2)
        local startY = math.floor((h - pixelH - 6) / 2)
        
        -- Draw the pixel art
        for y, row in ipairs(snowgolem) do
            for x, colorCode in ipairs(row) do
                if colorCode ~= 0 then
                    local pixelX = startX + (x - 1) * 2 + 1
                    local pixelY = startY + y
                    
                    display.setCursorPos(pixelX, pixelY)
                    display.setBackgroundColor(colors_map[colorCode])
                    display.write("  ")
                end
            end
        end
        
        -- Reset colors and draw message
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        local msgX = math.floor((w - #message) / 2) + 1
        display.setCursorPos(msgX, startY + pixelH + 2)
        display.write(message)
        
        return startY + pixelH + 4
    end
end

local function drawSimpleInstallScreen(display, title)
    local w, h = display.getSize()
    display.clear()
    
    local startY = math.floor(h / 2) - 3
    
    -- Draw title
    display.setCursorPos(math.floor((w - #title) / 2) + 1, startY)
    display.write(title)
    
    -- Draw underline
    local underline = string.rep("=", #title)
    display.setCursorPos(math.floor((w - #underline) / 2) + 1, startY + 1)
    display.write(underline)
    
    return startY + 4
end

local function drawInstallScreen(display, isAdvanced, title)
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    if isAdvanced then
        -- Draw small icon in top-left and return center position for content
        drawPixelSnowgolem(display, title, true)
        local w, h = display.getSize()
        return math.floor(h / 2) - 5  -- Center position for main content
    else
        return drawSimpleInstallScreen(display, title)
    end
end

-- Screen icon art (8x6 pixels each)
local screenIcon = {
    {8, 8, 8, 8, 8, 8, 8, 8},
    {8, 0, 0, 0, 0, 0, 0, 8},
    {8, 0, 0, 0, 0, 0, 0, 8},
    {8, 0, 0, 0, 0, 0, 0, 8},
    {8, 0, 0, 0, 0, 0, 0, 8},
    {8, 8, 8, 8, 8, 8, 8, 8}
}

local terminalIcon = {
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 1, 1, 1, 1, 1, 1, 0},
    {0, 1, 2, 1, 1, 1, 1, 0},
    {0, 1, 1, 1, 1, 1, 1, 0},
    {0, 1, 1, 1, 2, 1, 1, 0},
    {0, 0, 0, 0, 0, 0, 0, 0}
}

local function drawScreenIcon(display, x, y, icon, selected, hovered)
    local bgColor = colors.black
    if selected then
        bgColor = colors.lime
    elseif hovered then
        bgColor = colors.lightGray
    end
    
    -- Clear the entire icon area first
    for row = 1, #icon do
        for col = 1, #icon[row] do
            local pixelX = x + (col - 1)
            local pixelY = y + (row - 1)
            
            display.setCursorPos(pixelX, pixelY)
            display.setBackgroundColor(colors.black)
            display.write(" ")
        end
    end
    
    -- Then draw the icon
    for row = 1, #icon do
        for col = 1, #icon[row] do
            local pixelX = x + (col - 1)
            local pixelY = y + (row - 1)
            
            display.setCursorPos(pixelX, pixelY)
            
            local colorCode = icon[row][col]
            if colorCode == 0 then
                display.setBackgroundColor(bgColor)
            else
                display.setBackgroundColor(colors_map[colorCode] or colors.gray)
            end
            display.write(" ")
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
end

local function drawScreenGrid(display, isAdvanced, screens, selectedIndex, hoveredIndex)
    local nextY = drawInstallScreen(display, isAdvanced, "Select Display")
    local w, h = display.getSize()
    
    -- Calculate grid layout
    local iconsPerRow = math.floor(w / 12)  -- 8 width + 4 spacing
    local totalIcons = #screens + 2  -- +2 for terminal and replicate options
    local rows = math.ceil(totalIcons / iconsPerRow)
    
    local startX = math.floor((w - (iconsPerRow * 12 - 4)) / 2)
    local startY = nextY + 2  -- Add more spacing from title
    
    local iconIndex = 1
    
    -- Draw terminal option
    local termX = startX + ((iconIndex - 1) % iconsPerRow) * 12
    local termY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    drawScreenIcon(display, termX, termY, terminalIcon, selectedIndex == 0, hoveredIndex == 0)
    
    display.setCursorPos(termX, termY + 7)
    display.write("Terminal")
    
    iconIndex = iconIndex + 1
    
    -- Draw screen options
    for i, screen in ipairs(screens) do
        local iconX = startX + ((iconIndex - 1) % iconsPerRow) * 12
        local iconY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
        
        drawScreenIcon(display, iconX, iconY, screenIcon, selectedIndex == i, hoveredIndex == i)
        
        -- Truncate long screen names
        local displayName = screen
        if #displayName > 8 then
            displayName = string.sub(displayName, 1, 6) .. ".."
        end
        
        display.setCursorPos(iconX, iconY + 7)
        display.write(displayName)
        
        iconIndex = iconIndex + 1
    end
    
    -- Draw replicate option
    local repX = startX + ((iconIndex - 1) % iconsPerRow) * 12
    local repY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    drawScreenIcon(display, repX, repY, terminalIcon, selectedIndex == -1, hoveredIndex == -1)
    
    display.setCursorPos(repX, repY + 7)
    display.write("Replicate")
    
    return startY + rows * 8 + 2
end

local function getClickedScreen(x, y, screens, startY, display)
    local w, h = display.getSize()
    local iconsPerRow = math.floor(w / 12)
    local startX = math.floor((w - (iconsPerRow * 12 - 4)) / 2)
    
    local totalIcons = #screens + 2
    
    for iconIndex = 1, totalIcons do
        local iconX = startX + ((iconIndex - 1) % iconsPerRow) * 12
        local iconY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
        
        -- Check if click is within the icon area (including label area)
        if x >= iconX and x < iconX + 8 and y >= iconY and y < iconY + 8 then
            if iconIndex == 1 then
                return 0  -- Terminal
            elseif iconIndex <= #screens + 1 then
                return iconIndex - 1  -- Screen index
            else
                return -1  -- Replicate
            end
        end
    end
    
    return nil
end

local function selectScreen()
    local screens = findScreens()
    local display, isAdvanced = setupDisplay(nil)
    
    if #screens == 0 then
        drawInstallScreen(display, isAdvanced, "No External Displays")
        local nextY = (isAdvanced and 18 or 16)
        display.setCursorPos(1, nextY)
        display.write("No external monitors found.")
        display.setCursorPos(1, nextY + 1)
        display.write("Using computer terminal.")
        display.setCursorPos(1, nextY + 3)
        display.write("Press any key to continue...")
        os.pullEvent("key")
        return nil, false
    end
    
    local selectedIndex = nil
    local hoveredIndex = nil
    
    while true do
        local gridEndY = drawScreenGrid(display, isAdvanced, screens, selectedIndex, hoveredIndex)
        
        -- Show selection info
        if selectedIndex ~= nil then
            display.setCursorPos(1, gridEndY + 1)
            display.write("Selected: ")
            
            if selectedIndex == 0 then
                display.write("Computer Terminal")
            elseif selectedIndex == -1 then
                display.write("Replicate to Terminal")
            else
                display.write(screens[selectedIndex])
            end
            
            display.setCursorPos(1, gridEndY + 3)
            display.setBackgroundColor(colors.lime)
            display.setTextColor(colors.black)
            display.write(" CONFIRM SELECTION ")
            display.setBackgroundColor(colors.black)
            display.setTextColor(colors.white)
            
            display.setCursorPos(1, gridEndY + 5)
            display.write("Click screen to change, or press Enter to confirm")
        else
            display.setCursorPos(1, gridEndY + 1)
            display.write("Click on a display option above")
        end
        
        local event, button, x, y = os.pullEvent()
        
        if event == "mouse_click" then
            if selectedIndex ~= nil and y == gridEndY + 3 then
                -- Clicked confirm button
                if selectedIndex == 0 then
                    return nil, false
                elseif selectedIndex == -1 then
                    return nil, true  -- Replicate to terminal
                else
                    return screens[selectedIndex], false
                end
            else
                -- Check if clicked on a screen icon
                local w, h = display.getSize()
                local gridStartY = (isAdvanced and math.floor(h / 2) - 3 or 16) + 2
                local clickedScreen = getClickedScreen(x, y, screens, gridStartY, display)
                if clickedScreen ~= nil then
                    selectedIndex = clickedScreen
                    hoveredIndex = clickedScreen
                end
            end
        elseif event == "key" and selectedIndex ~= nil then
            local key = button
            if key == keys.enter then
                if selectedIndex == 0 then
                    return nil, false
                elseif selectedIndex == -1 then
                    return nil, true
                else
                    return screens[selectedIndex], false
                end
            end
        end
    end
end

local function setupUserAccount(selectedScreen)
    local display, isAdvanced = setupDisplay(selectedScreen)
    local username, password
    
    while true do
        local nextY = drawInstallScreen(display, isAdvanced, "User Account Setup")
        local w, h = display.getSize()
        
        -- Center the username input
        local usernamePrompt = "Username: "
        display.setCursorPos(math.floor((w - 20) / 2), nextY)
        display.write(usernamePrompt)
        username = read()
        
        if username == "" then
            display.setCursorPos(math.floor((w - 25) / 2), nextY + 2)
            display.setTextColor(colors.red)
            display.write("Username cannot be empty!")
            display.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        local nextY = drawInstallScreen(display, isAdvanced, "User Account Setup")
        local w, h = display.getSize()
        
        display.setCursorPos(math.floor((w - 20) / 2), nextY)
        display.write("Username: " .. username)
        display.setCursorPos(math.floor((w - 20) / 2), nextY + 2)
        display.write("Password: ")
        password = read("*")
        
        if password == "" then
            display.setCursorPos(math.floor((w - 25) / 2), nextY + 4)
            display.setTextColor(colors.red)
            display.write("Password cannot be empty!")
            display.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        local nextY = drawInstallScreen(display, isAdvanced, "User Account Setup")
        local w, h = display.getSize()
        
        display.setCursorPos(math.floor((w - 20) / 2), nextY)
        display.write("Username: " .. username)
        display.setCursorPos(math.floor((w - 20) / 2), nextY + 1)
        display.write("Password: " .. string.rep("*", #password))
        display.setCursorPos(math.floor((w - 20) / 2), nextY + 3)
        display.write("Confirm password: ")
        local confirmPassword = read("*")
        
        if password ~= confirmPassword then
            display.setCursorPos(math.floor((w - 30) / 2), nextY + 5)
            display.setTextColor(colors.red)
            display.write("Passwords don't match! Try again...")
            display.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    return username, password
end

local function saveUserData(username, password)
    -- Create users directory
    if not fs.exists("snowyos/users") then
        fs.makeDir("snowyos/users")
    end
    
    -- Simple hash function (not secure, but sufficient for CC)
    local function simpleHash(str)
        local hash = 0
        for i = 1, #str do
            hash = (hash + string.byte(str, i)) * 31
            hash = hash % 1000000  -- Keep it manageable
        end
        return tostring(hash)
    end
    
    local userData = {
        username = username,
        passwordHash = simpleHash(password),
        isAdmin = true,  -- First user is admin
        createdAt = os.date()
    }
    
    -- Save user data
    local file = fs.open("snowyos/users/" .. username .. ".dat", "w")
    file.write(textutils.serialize(userData))
    file.close()
    
    -- Save system config
    local config = {
        defaultUser = username,
        installedAt = os.date(),
        version = "1.0.0"
    }
    
    local configFile = fs.open("snowyos/config.dat", "w")
    configFile.write(textutils.serialize(config))
    configFile.close()
end

local function createSystemFiles()
    -- Create necessary directories
    local dirs = {
        "snowyos/system",
        "snowyos/programs",
        "snowyos/data",
        "snowyos/logs"
    }
    
    for _, dir in ipairs(dirs) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
    
    print("System directories created.")
end

function install.start()
    local display, isAdvanced = setupDisplay(nil)
    
    -- Check if this is a fresh install or reconfiguration
    local isReconfigure = fs.exists("snowyos/users") and #fs.list("snowyos/users") > 0
    
    if isReconfigure then
        while true do
            local nextY = drawInstallScreen(display, isAdvanced, "SnowyOS Reconfiguration")
            
            display.setCursorPos(1, nextY)
            display.write("SnowyOS is already installed with users.")
            display.setCursorPos(1, nextY + 2)
            display.write("1. Add new user")
            display.setCursorPos(1, nextY + 3)
            display.write("2. Reset system (deletes all users)")
            display.setCursorPos(1, nextY + 4)
            display.write("3. Cancel")
            display.setCursorPos(1, nextY + 6)
            display.write("Choice (1-3): ")
            
            local choice = read()
            if choice == "1" then
                local username, password = setupUserAccount(nil)
                saveUserData(username, password)
                
                drawInstallScreen(display, isAdvanced, "User Added Successfully")
                display.setCursorPos(1, nextY)
                display.write("User '" .. username .. "' added successfully!")
                display.setCursorPos(1, nextY + 2)
                display.write("Restarting...")
                sleep(3)
                os.reboot()
                return
            elseif choice == "2" then
                if fs.exists("snowyos/users") then
                    fs.delete("snowyos/users")
                end
                if fs.exists("snowyos/config.dat") then
                    fs.delete("snowyos/config.dat")
                end
                
                drawInstallScreen(display, isAdvanced, "System Reset")
                display.setCursorPos(1, nextY)
                display.write("System reset. Continuing with fresh installation...")
                sleep(2)
                break
            else
                drawInstallScreen(display, isAdvanced, "Installation Cancelled")
                display.setCursorPos(1, nextY)
                display.write("Installation cancelled.")
                sleep(2)
                return
            end
        end
    end
    
    -- Welcome screen
    drawInstallScreen(display, isAdvanced, "Welcome to SnowyOS!")
    local nextY = (isAdvanced and 18 or 16)
    display.setCursorPos(1, nextY)
    display.write("This will set up SnowyOS on your computer.")
    display.setCursorPos(1, nextY + 2)
    display.write("Press any key to continue...")
    
    os.pullEvent("key")
    
    -- Screen selection
    local selectedScreen, replicateToTerminal = selectScreen()
    
    -- User account setup
    local username, password = setupUserAccount(selectedScreen)
    
    -- Create system files and finalize
    local finalDisplay, finalAdvanced = setupDisplay(selectedScreen)
    drawInstallScreen(finalDisplay, finalAdvanced, "Setting up SnowyOS...")
    
    local finalY = (finalAdvanced and 18 or 16)
    finalDisplay.setCursorPos(1, finalY)
    finalDisplay.write("Creating system files...")
    createSystemFiles()
    
    finalDisplay.setCursorPos(1, finalY + 1)
    finalDisplay.write("Saving user data...")
    saveUserData(username, password)
    
    -- Save screen preference
    if selectedScreen then
        finalDisplay.setCursorPos(1, finalY + 2)
        finalDisplay.write("Saving display preferences...")
        local screenConfig = fs.open("snowyos/screen.cfg", "w")
        screenConfig.write(selectedScreen)
        screenConfig.close()
    end
    
    -- Save replicate setting
    if replicateToTerminal then
        finalDisplay.setCursorPos(1, finalY + 3)
        finalDisplay.write("Enabling terminal replication...")
        local replicateConfig = fs.open("snowyos/replicate.cfg", "w")
        replicateConfig.write("true")
        replicateConfig.close()
    end
    
    -- Mark installation as complete
    finalDisplay.setCursorPos(1, finalY + 3)
    finalDisplay.write("Marking installation complete...")
    local installFile = fs.open("snowyos/installed.cfg", "w")
    installFile.write("true")
    installFile.close()
    
    finalDisplay.setCursorPos(1, finalY + 5)
    finalDisplay.setTextColor(colors.lime)
    finalDisplay.write("Installation complete!")
    finalDisplay.setTextColor(colors.white)
    finalDisplay.setCursorPos(1, finalY + 6)
    finalDisplay.write("User '" .. username .. "' created successfully.")
    finalDisplay.setCursorPos(1, finalY + 8)
    finalDisplay.write("SnowyOS will now restart...")
    sleep(3)
    
    -- Restart the system
    os.reboot()
end

-- Start installation
install.start() 