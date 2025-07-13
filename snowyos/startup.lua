-- SnowyOS Startup
-- This file automatically launches SnowyOS when the computer boots

-- Clear the screen
term.clear()
term.setCursorPos(1, 1)

-- Check if SnowyOS is installed
if not fs.exists("snowyos/boot.lua") then
    print("SnowyOS not found. Starting installation...")
    sleep(1)
    
    -- Run the installer
    if fs.exists("snowyos/install.lua") then
        shell.run("snowyos/install.lua")
    else
        print("Installer not found. Please reinstall SnowyOS.")
        return
    end
else
    -- Launch SnowyOS
    shell.run("snowyos/boot.lua")
end 