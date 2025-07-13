-- SnowyOS Login System
-- Handles user authentication and session management

local login = {}

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
    term.clear()
    term.setCursorPos(1, 1)
    
    local w, h = term.getSize()
    
    -- Center the login box
    local loginBox = {
        "┌─────────────────────────┐",
        "│       SnowyOS Login     │",
        "├─────────────────────────┤",
        "│                         │",
        "│ Username:               │",
        "│                         │",
        "│ Password:               │",
        "│                         │",
        "└─────────────────────────┘"
    }
    
    local startY = math.floor((h - #loginBox) / 2)
    local startX = math.floor((w - #loginBox[1]) / 2)
    
    for i, line in ipairs(loginBox) do
        term.setCursorPos(startX, startY + i - 1)
        term.write(line)
    end
    
    return startX, startY
end

local function getCredentials(startX, startY)
    -- Get username
    term.setCursorPos(startX + 11, startY + 4)
    local username = read()
    
    -- Get password
    term.setCursorPos(startX + 11, startY + 6)
    local password = read("*")
    
    return username, password
end

local function showLoginError(startX, startY)
    term.setCursorPos(startX + 2, startY + 7)
    term.setTextColor(colors.red)
    term.write("Invalid credentials!")
    term.setTextColor(colors.white)
    sleep(2)
    
    -- Clear error message
    term.setCursorPos(startX + 2, startY + 7)
    term.write("                     ")
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
    while true do
        local startX, startY = drawLoginScreen()
        local username, password = getCredentials(startX, startY)
        
        if authenticateUser(username, password) then
            -- Successful login
            local session = createSession(username)
            
            term.clear()
            term.setCursorPos(1, 1)
            print("Welcome, " .. username .. "!")
            print("Loading SnowyOS...")
            sleep(1)
            
            -- Launch the main OS
            if fs.exists("snowyos/desktop.lua") then
                shell.run("snowyos/desktop.lua")
            else
                print("Desktop not found! Starting basic shell...")
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