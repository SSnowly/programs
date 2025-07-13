-- SnowyOS Startup
-- This file automatically launches SnowyOS when the computer boots

-- Clear the screen
term.clear()
term.setCursorPos(1, 1)

-- Check if SnowyOS is installed and configured
local function isSystemConfigured()
    -- Check if core files exist
    if not fs.exists("snowyos/boot.lua") then
        return false, "Core files missing"
    end
    
    -- Check if any users exist (system has been set up)
    if not fs.exists("snowyos/users") then
        return false, "No users directory"
    end
    
    -- Check if there are any user files
    local userFiles = fs.list("snowyos/users")
    if #userFiles == 0 then
        return false, "No users configured"
    end
    
    -- Check if system config exists
    if not fs.exists("snowyos/config.dat") then
        return false, "System not configured"
    end
    
    return true, "System ready"
end

local configured, reason = isSystemConfigured()

if not configured then
    print("SnowyOS setup required: " .. reason)
    print("Starting installation...")
    sleep(1)
    
    -- Run the installer
    if fs.exists("snowyos/install.lua") then
        shell.run("snowyos/install.lua")
    else
        print("Installer not found. Please reinstall SnowyOS.")
        print("Run: wget run https://raw.githubusercontent.com/SSnowly/programs/refs/heads/main/snowyos/installer.lua")
        return
    end
else
    -- Launch SnowyOS
    shell.run("snowyos/boot.lua")
end 