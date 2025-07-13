-- SnowyOS Installer
-- Handles initial setup, screen selection, and user account creation

local install = {}
local screenManager = require("screen_manager")

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

-- Color map for icons
local iconColors = {
    [0] = colors.black,
    [1] = colors.white,
    [2] = colors.lime,
    [8] = colors.gray
}

-- Standard terminal-first UI positioning
local function drawInstallScreen(title)
    screenManager.clearAll()
    
    -- Draw snowgolem icon with title (small version) - positioned for terminal
    screenManager.drawPixelSnowgolem(title, false)
    
    -- Return consistent Y position for content (designed for terminal)
    return 8  -- Fixed position that works on terminal and scales to other screens
end

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
                display.setBackgroundColor(iconColors[colorCode] or colors.gray)
            end
            display.write(" ")
        end
    end
    
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
end

local function drawScreenGrid(screens, selectedIndex, hoveredIndex)
    screenManager.clearAll()
    
    -- Draw title centered at top on ALL screens - terminal-first design
    screenManager.writeCentered(3, "Select Display")
    
    -- Terminal-first layout: 3 icons per row, fixed positions
    local iconsPerRow = 3
    local totalIcons = #screens + 2  -- +2 for terminal and replicate options
    local rows = math.ceil(totalIcons / iconsPerRow)
    
    -- Fixed positions designed for terminal (51 chars wide)
    local startX = 5  -- Fixed start position
    local startY = 6  -- Fixed Y position
    local spacing = 15  -- Fixed spacing between icons
    
    local iconIndex = 1
    
    -- Draw terminal option on ALL screens
    local termX = startX + ((iconIndex - 1) % iconsPerRow) * spacing
    local termY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    -- Draw icon on all screens
    screenManager.forEach(function(display, isAdvanced, name)
        drawScreenIcon(display, termX, termY, terminalIcon, selectedIndex == 0, hoveredIndex == 0)
        display.setCursorPos(termX, termY + 7)
        display.write("Terminal")
    end)
    
    iconIndex = iconIndex + 1
    
    -- Draw screen options on ALL screens
    for i, screen in ipairs(screens) do
        local iconX = startX + ((iconIndex - 1) % iconsPerRow) * spacing
        local iconY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
        
        -- Draw on all screens
        screenManager.forEach(function(display, isAdvanced, name)
            drawScreenIcon(display, iconX, iconY, screenIcon, selectedIndex == i, hoveredIndex == i)
            
            -- Truncate long screen names
            local displayName = screen
            if #displayName > 8 then
                displayName = string.sub(displayName, 1, 6) .. ".."
            end
            
            display.setCursorPos(iconX, iconY + 7)
            display.write(displayName)
        end)
        
        iconIndex = iconIndex + 1
    end
    
    -- Draw replicate option on ALL screens
    local repX = startX + ((iconIndex - 1) % iconsPerRow) * spacing
    local repY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    screenManager.forEach(function(display, isAdvanced, name)
        drawScreenIcon(display, repX, repY, terminalIcon, selectedIndex == -1, hoveredIndex == -1)
        display.setCursorPos(repX, repY + 7)
        display.write("Replicate")
    end)
    
    return startY + rows * 8 + 2
end

local function getClickedScreen(x, y, screens, startY)
    local iconsPerRow = 3
    local startX = 5
    local spacing = 15
    
    local totalIcons = #screens + 2
    
    for iconIndex = 1, totalIcons do
        local iconX = startX + ((iconIndex - 1) % iconsPerRow) * spacing
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
    local screens = screenManager.findAvailableScreens()
    
    if #screens == 0 then
        drawInstallScreen("No External Displays")
        local nextY = 10  -- Fixed position for terminal
        screenManager.writeAtPos(1, nextY, "No external monitors found.")
        screenManager.writeAtPos(1, nextY + 1, "Using computer terminal.")
        screenManager.writeAtPos(1, nextY + 3, "Press any key to continue...")
        os.pullEvent("key")
        return nil, false
    end
    
    local selectedIndex = nil
    local hoveredIndex = nil
    
    while true do
        local gridEndY = drawScreenGrid(screens, selectedIndex, hoveredIndex)
        
        -- Show selection info on ALL screens - terminal-first positioning
        if selectedIndex ~= nil then
            local selectionText = "Selected: "
            
            if selectedIndex == 0 then
                selectionText = selectionText .. "Computer Terminal"
            elseif selectedIndex == -1 then
                selectionText = selectionText .. "Replicate to Terminal"
            else
                selectionText = selectionText .. screens[selectedIndex]
            end
            
            screenManager.writeAtPos(1, gridEndY + 1, selectionText)
            
            screenManager.writeAtPos(1, gridEndY + 3, "")
            screenManager.setBackgroundColor(colors.lime)
            screenManager.setTextColor(colors.black)
            screenManager.write(" CONFIRM SELECTION ")
            screenManager.setBackgroundColor(colors.black)
            screenManager.setTextColor(colors.white)
            
            screenManager.writeAtPos(1, gridEndY + 5, "Click screen to change, or press Enter to confirm")
        else
            screenManager.writeAtPos(1, gridEndY + 1, "Click on a display option above")
        end
        
        local event, button, x, y = os.pullEvent()
        
        if event == "mouse_click" then
            if selectedIndex ~= nil and y == gridEndY + 3 then
                -- Clicked confirm button
                if selectedIndex == 0 then
                    return nil, false
                elseif selectedIndex == -1 then
                    -- Replicate to terminal - use first available screen as primary
                    return screens[1], true
                else
                    return screens[selectedIndex], false
                end
            else
                -- Check if clicked on a screen icon
                local clickedScreen = getClickedScreen(x, y, screens, 6)
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
                    -- Replicate to terminal - use first available screen as primary
                    return screens[1], true
                else
                    return screens[selectedIndex], false
                end
            end
        end
    end
end

local function setupUserAccount()
    local username, password
    
    while true do
        -- Clear and draw the screen
        local nextY = drawInstallScreen("User Account Setup")
        
        -- Center the username input on ALL screens - terminal-first design
        screenManager.writeCentered(nextY + 2, "Username: ")
        username = read()
        
        if username == "" then
            screenManager.writeCentered(nextY + 4, "Username cannot be empty!")
            screenManager.setTextColor(colors.red)
            screenManager.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        -- Clear and draw the screen
        local nextY = drawInstallScreen("User Account Setup")
        
        screenManager.writeCentered(nextY + 2, "Username: " .. username)
        screenManager.writeCentered(nextY + 4, "Password: ")
        password = read("*")
        
        if password == "" then
            screenManager.writeCentered(nextY + 6, "Password cannot be empty!")
            screenManager.setTextColor(colors.red)
            screenManager.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        -- Clear and draw the screen
        local nextY = drawInstallScreen("User Account Setup")
        
        screenManager.writeCentered(nextY + 2, "Username: " .. username)
        screenManager.writeCentered(nextY + 4, "Password: " .. string.rep("*", #password))
        screenManager.writeCentered(nextY + 6, "Confirm password: ")
        local confirmPassword = read("*")
        
        if password ~= confirmPassword then
            screenManager.writeCentered(nextY + 8, "Passwords don't match! Try again...")
            screenManager.setTextColor(colors.red)
            screenManager.setTextColor(colors.white)
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

-- Fixed progress bar that shows on ALL screens
local function drawProgressBar(progress, message)
    screenManager.clearAll()
    
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
    -- Draw title on all screens - terminal-first positioning
    local title = "Setting up SnowyOS..."
    screenManager.writeCentered(8, title)
    
    -- Draw progress bar on ALL screens - terminal-first design
    local barWidth = 30  -- Fixed width that fits terminal
    local barY = 10  -- Fixed Y position
    
    screenManager.forEach(function(display, isAdvanced, name)
        local w, h = display.getSize()
        local barStart = math.floor((w - barWidth) / 2) + 1
        
        -- Progress bar background
        display.setCursorPos(barStart, barY)
        display.setBackgroundColor(colors.gray)
        for i = 1, barWidth do
            display.write(" ")
        end
        
        -- Progress bar fill
        local fillWidth = math.floor(barWidth * (progress / 100))
        display.setCursorPos(barStart, barY)
        display.setBackgroundColor(colors.lime)
        for i = 1, fillWidth do
            display.write(" ")
        end
        
        -- Reset colors
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
    end)
    
    -- Progress percentage on all screens
    local percentText = progress .. "%"
    screenManager.writeCentered(barY + 2, percentText)
    
    -- Status message on all screens
    screenManager.writeCentered(barY + 4, message)
end

local function createSystemFiles()
    -- Create necessary directories
    local dirs = {
        "snowyos/system",
        "snowyos/programs", 
        "snowyos/data",
        "snowyos/logs"
    }
    
    local totalSteps = #dirs + 3  -- +3 for additional setup steps
    local currentStep = 0
    
    for _, dir in ipairs(dirs) do
        currentStep = currentStep + 1
        local progress = math.floor((currentStep / totalSteps) * 100)
        drawProgressBar(progress, "Creating " .. dir .. "...")
        
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
        sleep(0.3)  -- Small delay to show progress
    end
end

function install.start()
    -- Initialize screen manager
    screenManager.init()
    
    -- Check if this is a fresh install or reconfiguration
    local isReconfigure = fs.exists("snowyos/users") and #fs.list("snowyos/users") > 0
    
    if isReconfigure then
        while true do
            local nextY = drawInstallScreen("SnowyOS Reconfiguration")
            
            screenManager.writeCentered(nextY + 2, "SnowyOS is already installed with users.")
            screenManager.writeCentered(nextY + 4, "1. Add new user")
            screenManager.writeCentered(nextY + 5, "2. Reset system (deletes all users)")
            screenManager.writeCentered(nextY + 6, "3. Cancel")
            screenManager.writeCentered(nextY + 8, "Choice (1-3): ")
            
            local choice = read()
            if choice == "1" then
                local username, password = setupUserAccount()
                saveUserData(username, password)
                
                local successY = drawInstallScreen("User Added Successfully")
                screenManager.writeCentered(successY + 2, "User '" .. username .. "' added successfully!")
                screenManager.writeCentered(successY + 4, "Restarting...")
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
                
                local resetY = drawInstallScreen("System Reset")
                screenManager.writeCentered(resetY + 2, "System reset. Continuing with fresh installation...")
                sleep(2)
                break
            else
                local cancelY = drawInstallScreen("Installation Cancelled")
                screenManager.writeCentered(cancelY + 2, "Installation cancelled.")
                sleep(2)
                return
            end
        end
    end
    
    -- Welcome screen
    local nextY = drawInstallScreen("Welcome to SnowyOS!")
    
    screenManager.writeCentered(nextY + 2, "This will set up SnowyOS on your computer.")
    screenManager.writeCentered(nextY + 4, "Press any key to continue...")
    
    os.pullEvent("key")
    
    -- Screen selection
    local selectedScreen, replicateToTerminal = selectScreen()
    
    -- User account setup
    local username, password = setupUserAccount()
    
    -- Start progress bar installation
    local totalSteps = 7
    local currentStep = 0
    
    -- Step 1-4: Create system files
    createSystemFiles()
    currentStep = 4
    
    -- Step 5: Save user data
    currentStep = currentStep + 1
    local progress = math.floor((currentStep / totalSteps) * 100)
    drawProgressBar(progress, "Saving user account...")
    saveUserData(username, password)
    sleep(0.5)
    
    -- Step 6: Save screen preference
    currentStep = currentStep + 1
    progress = math.floor((currentStep / totalSteps) * 100)
    if selectedScreen then
        drawProgressBar(progress, "Configuring display settings...")
        local screenConfig = fs.open("snowyos/screen.cfg", "w")
        screenConfig.write(selectedScreen)
        screenConfig.close()
    else
        drawProgressBar(progress, "Configuring display settings...")
    end
    sleep(0.5)
    
    -- Save replicate setting
    if replicateToTerminal then
        drawProgressBar(progress, "Enabling terminal replication...")
        local replicateConfig = fs.open("snowyos/replicate.cfg", "w")
        replicateConfig.write("true")
        replicateConfig.close()
        sleep(0.3)
    end
    
    -- Step 7: Finalize
    currentStep = currentStep + 1
    progress = 100
    drawProgressBar(progress, "Finalizing installation...")
    
    -- Mark installation as complete
    local installFile = fs.open("snowyos/installed.cfg", "w")
    installFile.write("true")
    installFile.close()
    sleep(1)
    
    -- Show completion screen
    screenManager.clearAll()
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
    local centerY = 9  -- Fixed terminal-first positioning
    
    screenManager.writeCentered(centerY, "Installation Complete!")
    screenManager.setTextColor(colors.lime)
    screenManager.setTextColor(colors.white)
    screenManager.writeCentered(centerY + 2, "User '" .. username .. "' created successfully")
    screenManager.writeCentered(centerY + 4, "SnowyOS will now restart...")
    sleep(3)
    
    -- Restart the system
    os.reboot()
end

-- Start installation
install.start() 