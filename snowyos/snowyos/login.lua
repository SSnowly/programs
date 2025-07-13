-- SnowyOS Login System
-- Handles user authentication and session management

local login = {}
local screenManager = require("screen_manager")

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

local function drawPixelSnowgolem(title)
    local primaryDisplay, isAdvanced = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    local pixelW = #snowgolem[1]
    local pixelH = #snowgolem
    
    -- Small icon in top-left corner
    local startX = 2
    local startY = 2
    
    -- Draw smaller pixel art on all screens
    screenManager.forEach(function(display, isAdvanced, name)
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
        display.write(title)
    end)
    
    return startY + pixelH + 2
end

local function drawSimpleLoginScreen(title)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    
    local startY = 3
    
    -- Draw title on all screens
    screenManager.setCursorPos(math.floor((w - #title) / 2) + 1, startY)
    screenManager.write(title)
    
    -- Draw underline on all screens
    local underline = string.rep("=", #title)
    screenManager.setCursorPos(math.floor((w - #underline) / 2) + 1, startY + 1)
    screenManager.write(underline)
    
    return startY + 6
end

local function drawLoginScreen(title)
    screenManager.clearAll()
    
    -- Always use visual design like installer
    drawPixelSnowgolem(title)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    return math.floor(h / 2) - 2
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

local function getCredentials(startY)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    local username, password
    
    -- Get username
    while true do
        primaryDisplay.setBackgroundColor(colors.black)
        primaryDisplay.setTextColor(colors.white)
        
        -- Center the username input
        local usernamePrompt = "Username: "
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), startY + 2)
        primaryDisplay.write(usernamePrompt)
        username = read()
        
        if username == "" then
            primaryDisplay.setCursorPos(math.floor((w - 25) / 2), startY + 4)
            primaryDisplay.setTextColor(colors.red)
            primaryDisplay.write("Username cannot be empty!")
            primaryDisplay.setTextColor(colors.white)
            sleep(2)
            
            -- Clear the screen for next attempt
            screenManager.clearAll()
            drawLoginScreen("SnowyOS Login")
        else
            break
        end
    end
    
    -- Get password
    while true do
        primaryDisplay.setBackgroundColor(colors.black)
        primaryDisplay.setTextColor(colors.white)
        
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), startY + 2)
        primaryDisplay.write("Username: " .. username)
        primaryDisplay.setCursorPos(math.floor((w - 20) / 2), startY + 4)
        primaryDisplay.write("Password: ")
        password = read("*")
        
        if password == "" then
            primaryDisplay.setCursorPos(math.floor((w - 25) / 2), startY + 6)
            primaryDisplay.setTextColor(colors.red)
            primaryDisplay.write("Password cannot be empty!")
            primaryDisplay.setTextColor(colors.white)
            sleep(2)
            
            -- Clear the screen for next attempt
            screenManager.clearAll()
            drawLoginScreen("SnowyOS Login")
        else
            break
        end
    end
    
    return username, password
end

local function showLoginError(startY)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    
    primaryDisplay.setCursorPos(math.floor((w - 20) / 2), startY + 6)
    primaryDisplay.setTextColor(colors.red)
    primaryDisplay.setBackgroundColor(colors.black)
    primaryDisplay.write("Invalid credentials!")
    primaryDisplay.setTextColor(colors.white)
    
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

local function showSuccessMessage(username)
    screenManager.clearAll()
    
    local primaryDisplay = screenManager.getPrimaryDisplay()
    local w, h = primaryDisplay.getSize()
    local centerY = math.floor(h / 2)
    
    -- Show welcome message on all screens
    screenManager.setCursorPos(math.floor((w - 20) / 2) + 1, centerY - 1)
    screenManager.setTextColor(colors.lime)
    screenManager.write("Welcome, " .. username .. "!")
    
    screenManager.setTextColor(colors.white)
    screenManager.setCursorPos(math.floor((w - 18) / 2) + 1, centerY + 1)
    screenManager.write("Loading SnowyOS...")
    
    sleep(2)
end

function login.start()
    -- Initialize screen manager
    screenManager.init()
    
    while true do
        -- Draw login screen on all displays
        local startY = drawLoginScreen("SnowyOS Login")
        
        -- Get credentials from primary display only
        local username, password = getCredentials(startY)
        
        if authenticateUser(username, password) then
            -- Successful login
            local session = createSession(username)
            showSuccessMessage(username)
            
            -- Launch the main OS
            if fs.exists("snowyos/desktop.lua") then
                shell.run("snowyos/desktop.lua")
            else
                screenManager.forEach(function(display, isAdvanced, name)
                    local w, h = display.getSize()
                    local centerY = math.floor(h / 2)
                    display.setCursorPos(math.floor((w - 30) / 2) + 1, centerY + 3)
                    display.write("Desktop not found! Starting shell...")
                end)
                sleep(1)
                shell.run("snowyos/shell.lua")
            end
            break
        else
            -- Failed login - show error on primary display
            showLoginError(startY)
        end
    end
end

-- Start login process
login.start() 