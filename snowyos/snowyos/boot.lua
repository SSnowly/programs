-- SnowyOS Boot System
-- Main boot loader with visual interface

local boot = {}
local screenManager = require("screen_manager")

function boot.start()
    -- Initialize screen manager
    screenManager.init()
    
    -- Only show boot screen if we have advanced monitors
    local hasAdvancedScreens = false
    screenManager.forEach(function(display, isAdvanced, name)
        if isAdvanced then
            hasAdvancedScreens = true
        end
    end)
    
    if hasAdvancedScreens then
        -- Draw boot screen on all displays
        screenManager.drawBootScreen()
        
        -- Wait for user input
        screenManager.waitForInput()
        
        -- Clear all displays
        screenManager.clearAll()
        screenManager.setCursorPos(1, 1)
    else
        -- No advanced monitor, go straight to login
        screenManager.clearAll()
        screenManager.setCursorPos(1, 1)
    end
    
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