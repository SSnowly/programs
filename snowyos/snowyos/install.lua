-- SnowyOS Installer
-- Handles initial setup, screen selection, and user account creation

local install = {}

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

local function selectScreen()
    local screens = findScreens()
    
    if #screens == 0 then
        print("No external monitors found. Using computer terminal.")
        return nil
    end
    
    print("SnowyOS Installation")
    print("===================")
    print()
    print("Available screens:")
    print("0. Computer terminal")
    
    for i, screen in ipairs(screens) do
        print(i .. ". " .. screen)
    end
    
    print()
    write("Select screen (0-" .. #screens .. "): ")
    
    local choice = tonumber(read())
    
    if choice == 0 or choice == nil then
        return nil
    elseif choice >= 1 and choice <= #screens then
        return screens[choice]
    else
        print("Invalid choice. Using computer terminal.")
        return nil
    end
end

local function setupUserAccount()
    print()
    print("User Account Setup")
    print("==================")
    print()
    
    local username, password
    
    repeat
        write("Username: ")
        username = read()
        if username == "" then
            print("Username cannot be empty!")
        end
    until username ~= ""
    
    repeat
        write("Password: ")
        password = read("*")  -- Hide password input
        if password == "" then
            print("Password cannot be empty!")
        end
    until password ~= ""
    
    write("Confirm password: ")
    local confirmPassword = read("*")
    
    if password ~= confirmPassword then
        print("Passwords don't match! Please try again.")
        return setupUserAccount()  -- Recursive retry
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
    term.clear()
    term.setCursorPos(1, 1)
    
    print("Welcome to SnowyOS Installation!")
    print("================================")
    print()
    print("This will set up SnowyOS on your computer.")
    print("Press any key to continue...")
    
    os.pullEvent("key")
    
    -- Screen selection
    term.clear()
    term.setCursorPos(1, 1)
    local selectedScreen = selectScreen()
    
    -- User account setup
    term.clear()
    term.setCursorPos(1, 1)
    local username, password = setupUserAccount()
    
    -- Create system files
    term.clear()
    term.setCursorPos(1, 1)
    print("Setting up SnowyOS...")
    createSystemFiles()
    
    -- Save user data
    saveUserData(username, password)
    
    -- Save screen preference
    if selectedScreen then
        local screenConfig = fs.open("snowyos/screen.cfg", "w")
        screenConfig.write(selectedScreen)
        screenConfig.close()
    end
    
    print()
    print("Installation complete!")
    print("User '" .. username .. "' created successfully.")
    print()
    print("SnowyOS will now restart...")
    sleep(3)
    
    -- Restart the system
    os.reboot()
end

-- Start installation
install.start() 