-- SnowyOS Login System
-- Handles user authentication and session management

local login = {}
local screenManager = require("screen_manager")

-- Standard terminal-first UI positioning
local function drawLoginScreen(title)
    screenManager.clearAll()
    
    -- Draw snowgolem icon with title (small version) - positioned for terminal
    screenManager.drawPixelSnowgolem(title, false)
    
    -- Return consistent Y position for content (designed for terminal)
    return 8  -- Fixed position that works on terminal and scales to other screens
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

-- Terminal-first credential input design
local function getCredentials(startY)
    local username, password
    
    -- Get username
    while true do
        screenManager.setBackgroundColor(colors.black)
        screenManager.setTextColor(colors.white)
        
        -- Center the username input on ALL screens - terminal-first design
        screenManager.writeCentered(startY + 2, "Username: ")
        username = read()
        
        if username == "" then
            screenManager.writeCentered(startY + 4, "Username cannot be empty!")
            screenManager.setTextColor(colors.red)
            screenManager.setTextColor(colors.white)
            sleep(2)
            
            -- Clear the screen for next attempt
            drawLoginScreen("SnowyOS Login")
        else
            break
        end
    end
    
    -- Get password
    while true do
        screenManager.setBackgroundColor(colors.black)
        screenManager.setTextColor(colors.white)
        
        screenManager.writeCentered(startY + 2, "Username: " .. username)
        screenManager.writeCentered(startY + 4, "Password: ")
        password = read("*")
        
        if password == "" then
            screenManager.writeCentered(startY + 6, "Password cannot be empty!")
            screenManager.setTextColor(colors.red)
            screenManager.setTextColor(colors.white)
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
    screenManager.writeCentered(startY + 6, "Invalid credentials!")
    screenManager.setTextColor(colors.red)
    screenManager.setBackgroundColor(colors.black)
    screenManager.setTextColor(colors.white)
    
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
    
    local centerY = 9  -- Fixed terminal-first positioning
    
    -- Show welcome message on all screens
    screenManager.writeCentered(centerY, "Welcome, " .. username .. "!")
    screenManager.setTextColor(colors.lime)
    
    screenManager.setTextColor(colors.white)
    screenManager.writeCentered(centerY + 2, "Loading SnowyOS...")
    
    sleep(2)
end

function login.start()
    -- Initialize screen manager
    screenManager.init()
    
    while true do
        -- Draw login screen on all displays
        local startY = drawLoginScreen("SnowyOS Login")
        
        -- Get credentials using terminal-first design
        local username, password = getCredentials(startY)
        
        if authenticateUser(username, password) then
            -- Successful login
            local session = createSession(username)
            showSuccessMessage(username)
            
            -- Launch the main OS
            if fs.exists("snowyos/desktop.lua") then
                shell.run("snowyos/desktop.lua")
            else
                screenManager.writeCentered(12, "Desktop not found! Starting shell...")
                sleep(1)
                shell.run("snowyos/shell.lua")
            end
            break
        else
            -- Failed login - show error on all screens
            showLoginError(startY)
        end
    end
end

-- Start login process
login.start() 