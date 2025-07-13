-- SnowyOS Boot System
-- Main boot loader with visual interface

local boot = {}
local screenManager = require("screen_manager")

function boot.start()
    -- Initialize screen manager
    screenManager.init()
    
    -- Always show boot screen on all available displays
    screenManager.drawBootScreen()
    
    -- Wait for user input
    screenManager.waitForInput()
    
    -- Clear all displays
    screenManager.clearAll()
    screenManager.setCursorPos(1, 1)
    
    -- Load the login system
    if fs.exists("snowyos/login.lua") then
        shell.run("snowyos/login.lua")
    else
        print("Login system not found!")
        sleep(2)
    end
end

-- Start the boot process
boot.start() 