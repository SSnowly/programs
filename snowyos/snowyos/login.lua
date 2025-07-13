-- SnowyOS Login System
-- Handles user authentication and session management

local login = {}

-- Snowgolem pixel art (same as installer)
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

-- Screen management functions
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

local function loadScreenPreference()
    if fs.exists("snowyos/screen.cfg") then
        local file = fs.open("snowyos/screen.cfg", "r")
        local screen = file.readAll()
        file.close()
        return screen
    end
    return nil
end

local function shouldReplicateToTerminal()
    if fs.exists("snowyos/replicate.cfg") then
        local file = fs.open("snowyos/replicate.cfg", "r")
        local setting = file.readAll()
        file.close()
        return setting == "true"
    end
    return false
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

local function drawSimpleLoginScreen(display, title)
    local w, h = display.getSize()
    display.clear()
    
    local startY = 3
    
    -- Draw title
    display.setCursorPos(math.floor((w - #title) / 2) + 1, startY)
    display.write(title)
    
    -- Draw underline
    local underline = string.rep("=", #title)
    display.setCursorPos(math.floor((w - #underline) / 2) + 1, startY + 1)
    display.write(underline)
    
    return startY + 6
end

local function drawLoginScreen(display, isAdvanced, title)
    display.clear()
    display.setBackgroundColor(colors.black)
    display.setTextColor(colors.white)
    
    if isAdvanced then
        -- Draw small icon in top-left and return center position for content
        drawPixelSnowgolem(display, title, true)
        local w, h = display.getSize()
        return math.floor(h / 2) - 2
    else
        return drawSimpleLoginScreen(display, title)
    end
end

local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash + string.byte(str, i)) * 31
        hash = hash % 1000000
    end
    return tostring(hash)
end

local function loadUserData(username)
    local userFile = "snowyos/users/" .. username .. ".dat"
    if not fs.exists(userFile) then
        return nil
    end
    
    local file = fs.open(userFile, "r")
    local data = file.readAll()
    file.close()
    
    return textutils.unserialize(data)
end

local function authenticateUser(username, password)
    local userData = loadUserData(username)
    if not userData then
        return false
    end
    
    local hashedPassword = simpleHash(password)
    return userData.passwordHash == hashedPassword
end

local function getCredentials(display, startY)
    local w, h = display.getSize()
    local username, password
    
    -- Get username
    while true do
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        
        -- Center the username input
        local usernamePrompt = "Username: "
        display.setCursorPos(math.floor((w - 20) / 2), startY + 2)
        display.write(usernamePrompt)
        username = read()
        
        if username == "" then
            display.setCursorPos(math.floor((w - 25) / 2), startY + 4)
            display.setTextColor(colors.red)
            display.write("Username cannot be empty!")
            display.setTextColor(colors.white)
            sleep(2)
            
            -- Clear the screen for next attempt
            display.clear()
            drawLoginScreen(display, display ~= term, "SnowyOS Login")
        else
            break
        end
    end
    
    -- Get password
    while true do
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        
        display.setCursorPos(math.floor((w - 20) / 2), startY + 2)
        display.write("Username: " .. username)
        display.setCursorPos(math.floor((w - 20) / 2), startY + 4)
        display.write("Password: ")
        password = read("*")
        
        if password == "" then
            display.setCursorPos(math.floor((w - 25) / 2), startY + 6)
            display.setTextColor(colors.red)
            display.write("Password cannot be empty!")
            display.setTextColor(colors.white)
            sleep(2)
            
            -- Clear the screen for next attempt
            display.clear()
            drawLoginScreen(display, display ~= term, "SnowyOS Login")
        else
            break
        end
    end
    
    return username, password
end

local function showLoginError(display, startY)
    local w, h = display.getSize()
    
    display.setCursorPos(math.floor((w - 20) / 2), startY + 6)
    display.setTextColor(colors.red)
    display.setBackgroundColor(colors.black)
    display.write("Invalid credentials!")
    display.setTextColor(colors.white)
    
    sleep(2)
end

local function createSession(username)
    local sessionData = {
        username = username,
        loginTime = os.date(),
        sessionId = os.time()
    }
    
    local file = fs.open("snowyos/session.dat", "w")
    file.write(textutils.serialize(sessionData))
    file.close()
    
    return sessionData
end

local function showSuccessMessage(displays, username)
    for _, display in ipairs(displays) do
        display.clear()
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
        
        local w, h = display.getSize()
        local centerY = math.floor(h / 2)
        
        display.setCursorPos(math.floor((w - 20) / 2) + 1, centerY - 1)
        display.setTextColor(colors.lime)
        display.write("Welcome, " .. username .. "!")
        
        display.setTextColor(colors.white)
        display.setCursorPos(math.floor((w - 18) / 2) + 1, centerY + 1)
        display.write("Loading SnowyOS...")
    end
    sleep(2)
end

function login.start()
    -- Load screen configuration
    local preferredScreen = loadScreenPreference()
    local replicateToTerminal = shouldReplicateToTerminal()
    
    -- Setup displays
    local displays = {}
    local primaryDisplay = nil
    
    if preferredScreen and peripheral.isPresent(preferredScreen) then
        local monitor, isAdvanced = setupDisplay(preferredScreen)
        primaryDisplay = monitor
        table.insert(displays, monitor)
    else
        local terminal, isAdvanced = setupDisplay(nil)
        primaryDisplay = terminal
        table.insert(displays, terminal)
    end
    
    -- Add terminal replication if enabled
    if replicateToTerminal and preferredScreen then
        local terminal, _ = setupDisplay(nil)
        table.insert(displays, terminal)
    end
    
    while true do
        -- Draw login screen on all displays
        local startY = nil
        for _, display in ipairs(displays) do
            local isAdvanced = display ~= term
            startY = drawLoginScreen(display, isAdvanced, "SnowyOS Login")
        end
        
        -- Get credentials from primary display only
        local username, password = getCredentials(primaryDisplay, startY)
        
        if authenticateUser(username, password) then
            -- Successful login
            local session = createSession(username)
            showSuccessMessage(displays, username)
            
            -- Launch the main OS
            if fs.exists("snowyos/desktop.lua") then
                shell.run("snowyos/desktop.lua")
            else
                for _, display in ipairs(displays) do
                    local w, h = display.getSize()
                    local centerY = math.floor(h / 2)
                    display.setCursorPos(math.floor((w - 30) / 2) + 1, centerY + 3)
                    display.write("Desktop not found! Starting shell...")
                end
                sleep(1)
                shell.run("snowyos/shell.lua")
            end
            break
        else
            -- Failed login - show error on primary display
            showLoginError(primaryDisplay, startY)
        end
    end
end

-- Start login process
login.start() 