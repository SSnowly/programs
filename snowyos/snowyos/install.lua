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

local function drawInstallScreen(title)
    screenManager.clearAll()
    
    -- Draw snowgolem icon with title (small version)
    screenManager.drawPixelSnowgolem(title, false)
    
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    return math.floor(h / 2) - 2
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
    local primaryDisplay = screenManager.getPrimaryDisplay()
    primaryDisplay.clear()
    primaryDisplay.setBackgroundColor(colors.black)
    primaryDisplay.setTextColor(colors.white)
    
    local w, h = primaryDisplay.getSize()
    
    -- Draw title centered at top
    local title = "Select Display"
    primaryDisplay.setCursorPos(math.floor((w - #title) / 2) + 1, 3)
    primaryDisplay.write(title)
    
    -- Calculate grid layout
    local iconsPerRow = math.floor(w / 12)  -- 8 width + 4 spacing
    local totalIcons = #screens + 2  -- +2 for terminal and replicate options
    local rows = math.ceil(totalIcons / iconsPerRow)
    
    local startX = math.floor((w - (iconsPerRow * 12 - 4)) / 2)
    local startY = 6  -- Fixed position from top
    
    local iconIndex = 1
    
    -- Draw terminal option
    local termX = startX + ((iconIndex - 1) % iconsPerRow) * 12
    local termY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    drawScreenIcon(primaryDisplay, termX, termY, terminalIcon, selectedIndex == 0, hoveredIndex == 0)
    
    primaryDisplay.setCursorPos(termX, termY + 7)
    primaryDisplay.write("Terminal")
    
    iconIndex = iconIndex + 1
    
    -- Draw screen options
    for i, screen in ipairs(screens) do
        local iconX = startX + ((iconIndex - 1) % iconsPerRow) * 12
        local iconY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
        
        drawScreenIcon(primaryDisplay, iconX, iconY, screenIcon, selectedIndex == i, hoveredIndex == i)
        
        -- Truncate long screen names
        local displayName = screen
        if #displayName > 8 then
            displayName = string.sub(displayName, 1, 6) .. ".."
        end
        
        primaryDisplay.setCursorPos(iconX, iconY + 7)
        primaryDisplay.write(displayName)
        
        iconIndex = iconIndex + 1
    end
    
    -- Draw replicate option
    local repX = startX + ((iconIndex - 1) % iconsPerRow) * 12
    local repY = startY + math.floor((iconIndex - 1) / iconsPerRow) * 8
    
    drawScreenIcon(primaryDisplay, repX, repY, terminalIcon, selectedIndex == -1, hoveredIndex == -1)
    
    primaryDisplay.setCursorPos(repX, repY + 7)
    primaryDisplay.write("Replicate")
    
    return startY + rows * 8 + 2
end

local function getClickedScreen(x, y, screens, startY)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
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
    local screens = screenManager.findAvailableScreens()
    
    if #screens == 0 then
        drawInstallScreen("No External Displays")
        local primaryDisplay = screenManager.getPrimaryDisplay()
        local w, h = primaryDisplay.getSize()
        local nextY = 18
        primaryDisplay.setCursorPos(1, nextY)
        primaryDisplay.write("No external monitors found.")
        primaryDisplay.setCursorPos(1, nextY + 1)
        primaryDisplay.write("Using computer terminal.")
        primaryDisplay.setCursorPos(1, nextY + 3)
        primaryDisplay.write("Press any key to continue...")
        os.pullEvent("key")
        return nil, false
    end
    
    local selectedIndex = nil
    local hoveredIndex = nil
    
    while true do
        local gridEndY = drawScreenGrid(screens, selectedIndex, hoveredIndex)
        local primaryDisplay = screenManager.getPrimaryDisplay()
        
        -- Show selection info
        if selectedIndex ~= nil then
            primaryDisplay.setCursorPos(1, gridEndY + 1)
            primaryDisplay.write("Selected: ")
            
            if selectedIndex == 0 then
                primaryDisplay.write("Computer Terminal")
            elseif selectedIndex == -1 then
                primaryDisplay.write("Replicate to Terminal")
            else
                primaryDisplay.write(screens[selectedIndex])
            end
            
            primaryDisplay.setCursorPos(1, gridEndY + 3)
            primaryDisplay.setBackgroundColor(colors.lime)
            primaryDisplay.setTextColor(colors.black)
            primaryDisplay.write(" CONFIRM SELECTION ")
            primaryDisplay.setBackgroundColor(colors.black)
            primaryDisplay.setTextColor(colors.white)
            
            primaryDisplay.setCursorPos(1, gridEndY + 5)
            primaryDisplay.write("Click screen to change, or press Enter to confirm")
        else
            primaryDisplay.setCursorPos(1, gridEndY + 1)
            primaryDisplay.write("Click on a display option above")
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
                    return nil, true
                else
                    return screens[selectedIndex], false
                end
            end
        end
    end
end

local function setupUserAccount()
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local username, password
    
    while true do
        local nextY = drawInstallScreen("User Account Setup")
        local w, h = primaryDisplay.getSize()
        
        -- Center the username input
        local usernamePrompt = "Username: "
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 2)
        primaryDisplay.write(usernamePrompt)
        username = read()
        
        if username == "" then
            primaryDisplay.setCursorPos(math.floor((w - 25) / 2), nextY + 4)
            primaryDisplay.setTextColor(colors.red)
            primaryDisplay.write("Username cannot be empty!")
            primaryDisplay.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        local nextY = drawInstallScreen("User Account Setup")
        local w, h = primaryDisplay.getSize()
        
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 2)
        primaryDisplay.write("Username: " .. username)
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 4)
        primaryDisplay.write("Password: ")
        password = read("*")
        
        if password == "" then
            primaryDisplay.setCursorPos(math.floor((w - 25) / 2), nextY + 6)
            primaryDisplay.setTextColor(colors.red)
            primaryDisplay.write("Password cannot be empty!")
            primaryDisplay.setTextColor(colors.white)
            sleep(2)
        else
            break
        end
    end
    
    while true do
        local nextY = drawInstallScreen("User Account Setup")
        local w, h = primaryDisplay.getSize()
        
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 2)
        primaryDisplay.write("Username: " .. username)
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 4)
        primaryDisplay.write("Password: " .. string.rep("*", #password))
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 6)
        primaryDisplay.write("Confirm password: ")
        local confirmPassword = read("*")
        
        if password ~= confirmPassword then
            primaryDisplay.setCursorPos(math.floor((w - 30) / 2), nextY + 8)
            primaryDisplay.setTextColor(colors.red)
            primaryDisplay.write("Passwords don't match! Try again...")
            primaryDisplay.setTextColor(colors.white)
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

local function drawProgressBar(progress, message)
    screenManager.clearAll()
    
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
    -- Draw title on all screens
    local title = "Setting up SnowyOS..."
    screenManager.setCursorPos(math.floor((w - #title) / 2) + 1, math.floor(h / 2) - 3)
    screenManager.write(title)
    
    -- Draw progress bar on primary display only
    local barWidth = math.min(40, w - 10)
    local barStart = math.floor((w - barWidth) / 2) + 1
    local barY = math.floor(h / 2)
    
    -- Progress bar background
    primaryDisplay.setCursorPos(barStart, barY)
    primaryDisplay.setBackgroundColor(colors.gray)
    for i = 1, barWidth do
        primaryDisplay.write(" ")
    end
    
    -- Progress bar fill
    local fillWidth = math.floor(barWidth * (progress / 100))
    primaryDisplay.setCursorPos(barStart, barY)
    primaryDisplay.setBackgroundColor(colors.lime)
    for i = 1, fillWidth do
        primaryDisplay.write(" ")
    end
    
    -- Reset colors and draw percentage/message on all screens
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
    -- Progress percentage
    local percentText = progress .. "%"
    screenManager.setCursorPos(math.floor((w - #percentText) / 2) + 1, barY + 2)
    screenManager.write(percentText)
    
    -- Status message
    screenManager.setCursorPos(math.floor((w - #message) / 2) + 1, barY + 4)
    screenManager.write(message)
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
            local primaryDisplay = screenManager.getPrimaryDisplay()
            local w, h = primaryDisplay.getSize()
            
            primaryDisplay.setCursorPos(math.floor((w - 40) / 2), nextY + 2)
            primaryDisplay.write("SnowyOS is already installed with users.")
            primaryDisplay.setCursorPos(math.floor((w - 20) / 2), nextY + 4)
            primaryDisplay.write("1. Add new user")
            primaryDisplay.setCursorPos(math.floor((w - 35) / 2), nextY + 5)
            primaryDisplay.write("2. Reset system (deletes all users)")
            primaryDisplay.setCursorPos(math.floor((w - 10) / 2), nextY + 6)
            primaryDisplay.write("3. Cancel")
            primaryDisplay.setCursorPos(math.floor((w - 15) / 2), nextY + 8)
            primaryDisplay.write("Choice (1-3): ")
            
            local choice = read()
            if choice == "1" then
                local username, password = setupUserAccount()
                saveUserData(username, password)
                
                local successY = drawInstallScreen("User Added Successfully")
                local w, h = primaryDisplay.getSize()
                primaryDisplay.setCursorPos(math.floor((w - 35) / 2), successY + 2)
                primaryDisplay.write("User '" .. username .. "' added successfully!")
                primaryDisplay.setCursorPos(math.floor((w - 15) / 2), successY + 4)
                primaryDisplay.write("Restarting...")
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
                local w, h = primaryDisplay.getSize()
                primaryDisplay.setCursorPos(math.floor((w - 45) / 2), resetY + 2)
                primaryDisplay.write("System reset. Continuing with fresh installation...")
                sleep(2)
                break
            else
                local cancelY = drawInstallScreen("Installation Cancelled")
                local w, h = primaryDisplay.getSize()
                primaryDisplay.setCursorPos(math.floor((w - 25) / 2), cancelY + 2)
                primaryDisplay.write("Installation cancelled.")
                sleep(2)
                return
            end
        end
    end
    
    -- Welcome screen
    local nextY = drawInstallScreen("Welcome to SnowyOS!")
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    
    primaryDisplay.setCursorPos(math.floor((w - 40) / 2), nextY + 2)
    primaryDisplay.write("This will set up SnowyOS on your computer.")
    primaryDisplay.setCursorPos(math.floor((w - 30) / 2), nextY + 4)
    primaryDisplay.write("Press any key to continue...")
    
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
    
    local w, h = primaryDisplay.getSize()
    local centerY = math.floor(h / 2)
    
    screenManager.setCursorPos(math.floor((w - 22) / 2) + 1, centerY - 1)
    screenManager.setTextColor(colors.lime)
    screenManager.write("Installation Complete!")
    
    screenManager.setTextColor(colors.white)
    screenManager.setCursorPos(math.floor((w - 30) / 2) + 1, centerY + 1)
    screenManager.write("User '" .. username .. "' created successfully")
    
    screenManager.setCursorPos(math.floor((w - 25) / 2) + 1, centerY + 3)
    screenManager.write("SnowyOS will now restart...")
    sleep(3)
    
    -- Restart the system
    os.reboot()
end

-- Start installation
install.start() 