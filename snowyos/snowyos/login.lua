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

local function drawSmallSnowgolem(title)
    -- Draw snowgolem on advanced screens only
    screenManager.forEachAdvanced(function(display, name)
        local pixelW = #snowgolem[1]
        local pixelH = #snowgolem
        
        -- Small icon in top-left corner
        local startX = 2
        local startY = 2
        
        -- Draw smaller pixel art (1 char per pixel)
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
    
    return 16  -- Return content start position
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

local function drawLoginScreen()
    screenManager.clearAll()
    
    local w, h = screenManager.getSize()
    
    -- Draw small snowgolem and title
    drawSmallSnowgolem("SnowyOS Login")
    
    -- Create modern login form in center
    local formWidth = 30
    local formHeight = 8
    local startX = math.floor((w - formWidth) / 2)
    local startY = math.floor(h / 2) - 2
    
    screenManager.forEach(function(display, isAdvanced, name)
        -- Draw login form background
        display.setBackgroundColor(colors.gray)
        for y = 0, formHeight - 1 do
            display.setCursorPos(startX, startY + y)
            for x = 1, formWidth do
                display.write(" ")
            end
        end
        
        -- Draw form border
        display.setBackgroundColor(colors.lightGray)
        -- Top border
        display.setCursorPos(startX, startY)
        for x = 1, formWidth do
            display.write(" ")
        end
        -- Bottom border
        display.setCursorPos(startX, startY + formHeight - 1)
        for x = 1, formWidth do
            display.write(" ")
        end
        -- Side borders
        for y = 1, formHeight - 2 do
            display.setCursorPos(startX, startY + y)
            display.write(" ")
            display.setCursorPos(startX + formWidth - 1, startY + y)
            display.write(" ")
        end
        
        -- Reset colors for text
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.white)
        
        -- Draw labels
        display.setCursorPos(startX + 2, startY + 2)
        display.write("Username:")
        display.setCursorPos(startX + 2, startY + 5)
        display.write("Password:")
        
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
    end)
    
    return startX, startY
end

local function getCredentials(startX, startY)
    local primaryDisplay = screenManager.getPrimaryDisplay()
    
    -- Create input fields on all screens
    screenManager.forEach(function(display, isAdvanced, name)
        display.setBackgroundColor(colors.white)
        display.setTextColor(colors.black)
        
        -- Username input field
        display.setCursorPos(startX + 12, startY + 2)
        for i = 1, 15 do
            display.write(" ")
        end
        
        -- Password input field
        display.setCursorPos(startX + 12, startY + 5)
        for i = 1, 15 do
            display.write(" ")
        end
        
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
    end)
    
    -- Get input from primary display only
    primaryDisplay.setCursorPos(startX + 12, startY + 2)
    primaryDisplay.setBackgroundColor(colors.white)
    primaryDisplay.setTextColor(colors.black)
    local username = read()
    
    primaryDisplay.setCursorPos(startX + 12, startY + 5)
    primaryDisplay.setBackgroundColor(colors.white)
    primaryDisplay.setTextColor(colors.black)
    local password = read("*")
    
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
    return username, password
end

local function showLoginError(startX, startY)
    screenManager.forEach(function(display, isAdvanced, name)
        display.setCursorPos(startX + 2, startY + 7)
        display.setTextColor(colors.red)
        display.setBackgroundColor(colors.gray)
        display.write("Invalid credentials!")
        display.setTextColor(colors.white)
        display.setBackgroundColor(colors.black)
    end)
    
    sleep(2)
    
    -- Clear error message
    screenManager.forEach(function(display, isAdvanced, name)
        display.setCursorPos(startX + 2, startY + 7)
        display.setBackgroundColor(colors.gray)
        display.write("                   ")
        display.setBackgroundColor(colors.black)
    end)
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

function login.start()
    -- Initialize screen manager
    screenManager.init()
    
    while true do
        local startX, startY = drawLoginScreen()
        local username, password = getCredentials(startX, startY)
        
        if authenticateUser(username, password) then
            -- Successful login
            local session = createSession(username)
            
            screenManager.clearAll()
            
            local w, h = screenManager.getSize()
            local centerY = math.floor(h / 2)
            
            screenManager.setCursorPos(math.floor((w - 20) / 2), centerY - 1)
            screenManager.setTextColor(colors.lime)
            screenManager.write("Welcome, " .. username .. "!")
            
            screenManager.setTextColor(colors.white)
            screenManager.setCursorPos(math.floor((w - 18) / 2), centerY + 1)
            screenManager.write("Loading SnowyOS...")
            sleep(2)
            
            -- Launch the main OS
            if fs.exists("snowyos/desktop.lua") then
                shell.run("snowyos/desktop.lua")
            else
                screenManager.setCursorPos(math.floor((w - 30) / 2), centerY + 3)
                screenManager.write("Desktop not found! Starting shell...")
                sleep(1)
                shell.run("snowyos/shell.lua")
            end
            break
        else
            -- Failed login
            showLoginError(startX, startY)
        end
    end
end

-- Start login process
login.start() 