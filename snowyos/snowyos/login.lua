-- SnowyOS Login System
-- Handles user authentication and session management

local login = {}
local screenManager = require("screen_manager")

local function drawLoginScreen(title)
    screenManager.clearAll()
    
    -- Draw snowgolem icon with title (small version)
    screenManager.drawPixelSnowgolem(title, false)
    
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