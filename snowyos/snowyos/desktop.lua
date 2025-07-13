-- SnowyOS Desktop Environment
-- Main desktop with taskbar, window management, and application system

local desktop = {}
local screenManager = require("screen_manager")

-- Desktop state
local state = {
    running = true,
    currentUser = nil,
    runningApps = {},
    windows = {},
    taskbarHeight = 3,
    showPowerMenu = false,
    powerMenuX = 1,
    powerMenuY = 1
}

-- Load session data
local function loadSession()
    if fs.exists("snowyos/session.dat") then
        local file = fs.open("snowyos/session.dat", "r")
        local data = file.readAll()
        file.close()
        
        local session = textutils.unserialize(data)
        if session then
            state.currentUser = session.username
        end
    end
end

-- Get current time formatted for display
local function getFormattedTime()
    local time = os.time()
    local hour = math.floor(time)
    local minute = math.floor((time - hour) * 60)
    
    -- Convert to 12-hour format
    local ampm = "AM"
    if hour >= 12 then
        ampm = "PM"
        if hour > 12 then
            hour = hour - 12
        end
    end
    if hour == 0 then
        hour = 12
    end
    
    return string.format("%d:%02d %s", hour, minute, ampm)
end

-- Draw desktop background
local function drawDesktop()
    screenManager.clearAll()
    
    -- Simple desktop background
    screenManager.forEach(function(display, isAdvanced, name)
        local w, h = display.getSize()
        
        -- Fill with dark blue background
        display.setBackgroundColor(colors.blue)
        for y = 1, h - state.taskbarHeight do
            display.setCursorPos(1, y)
            for x = 1, w do
                display.write(" ")
            end
        end
        
        -- Add some simple decoration if advanced monitor
        if isAdvanced then
            -- Draw small snowgolem in corner
            display.setBackgroundColor(colors.lightBlue)
            display.setCursorPos(w - 10, 2)
            display.write("  SnowyOS  ")
            display.setCursorPos(w - 10, 3)
            display.write("           ")
        end
    end)
end

-- Draw taskbar
local function drawTaskbar()
    screenManager.forEach(function(display, isAdvanced, name)
        local w, h = display.getSize()
        local taskbarY = h - state.taskbarHeight + 1
        
        -- Taskbar background
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.white)
        
        for y = taskbarY, h do
            display.setCursorPos(1, y)
            for x = 1, w do
                display.write(" ")
            end
        end
        
        -- Power button (bottom left)
        display.setCursorPos(2, taskbarY + 1)
        display.setBackgroundColor(colors.red)
        display.setTextColor(colors.white)
        display.write(" ⚫ ")  -- Power symbol
        
        -- Running apps section (middle)
        local appStartX = 8
        local appIndex = 0
        for appName, _ in pairs(state.runningApps) do
            display.setCursorPos(appStartX + (appIndex * 10), taskbarY + 1)
            display.setBackgroundColor(colors.lightGray)
            display.setTextColor(colors.black)
            
            local displayName = appName
            if #displayName > 8 then
                displayName = string.sub(displayName, 1, 6) .. ".."
            end
            display.write(" " .. displayName .. " ")
            appIndex = appIndex + 1
        end
        
        -- Time display (right side)
        local timeStr = getFormattedTime()
        display.setCursorPos(w - #timeStr - 1, taskbarY + 1)
        display.setBackgroundColor(colors.gray)
        display.setTextColor(colors.white)
        display.write(" " .. timeStr)
        
        -- User name (right side, above time)
        if state.currentUser then
            display.setCursorPos(w - #state.currentUser - 1, taskbarY)
            display.setBackgroundColor(colors.gray)
            display.setTextColor(colors.lightGray)
            display.write(" " .. state.currentUser)
        end
    end)
end

-- Draw power menu dropdown
local function drawPowerMenu()
    if not state.showPowerMenu then
        return
    end
    
    screenManager.forEach(function(display, isAdvanced, name)
        local w, h = display.getSize()
        local menuX = 2
        local menuY = h - state.taskbarHeight - 4  -- Move up one more line for better spacing
        
        -- Ensure menu doesn't go off screen
        if menuY < 1 then
            menuY = 1
        end
        
        -- Menu border background first
        display.setBackgroundColor(colors.gray)
        for borderY = menuY - 1, menuY + 3 do
            if borderY >= 1 and borderY <= h then
                display.setCursorPos(menuX - 1, borderY)
                display.write("           ")
            end
        end
        
        -- Menu background
        display.setBackgroundColor(colors.lightGray)
        display.setTextColor(colors.black)
        
        -- Menu items
        display.setCursorPos(menuX, menuY)
        display.write(" Reboot   ")
        display.setCursorPos(menuX, menuY + 1)
        display.write(" Shutdown ")
        display.setCursorPos(menuX, menuY + 2)
        display.write(" Cancel   ")
    end)
end

-- Handle power menu clicks
local function handlePowerMenuClick(x, y)
    local w, h = screenManager.getSize()
    local menuX = 2
    local menuY = h - state.taskbarHeight - 4
    if menuY < 1 then
        menuY = 1
    end
    
    if y == menuY then
        -- Reboot
        state.showPowerMenu = false
        screenManager.clearAll()
        screenManager.writeCentered(math.floor(h/2), "Rebooting...")
        sleep(1)
        os.reboot()
    elseif y == menuY + 1 then
        -- Shutdown
        state.showPowerMenu = false
        screenManager.clearAll()
        screenManager.writeCentered(math.floor(h/2), "Shutting down...")
        sleep(1)
        os.shutdown()
    elseif y == menuY + 2 then
        -- Cancel
        state.showPowerMenu = false
    end
end

-- Handle taskbar clicks
local function handleTaskbarClick(x, y)
    local w, h = screenManager.getSize()
    local taskbarY = h - state.taskbarHeight + 1
    
    if y >= taskbarY then
        -- Power button click (spans x=2 to x=4, at taskbarY+1)
        if x >= 2 and x <= 4 and y == taskbarY + 1 then
            state.showPowerMenu = not state.showPowerMenu
            return
        end
        
        -- Running app clicks
        local appStartX = 8
        local appIndex = 0
        for appName, _ in pairs(state.runningApps) do
            local appX = appStartX + (appIndex * 10)
            if x >= appX and x <= appX + 8 and y == taskbarY + 1 then
                -- Focus/switch to app (placeholder for now)
                -- TODO: Implement window switching
                break
            end
            appIndex = appIndex + 1
        end
    end
end

-- Main desktop loop
local function desktopLoop()
    -- Initial draw
    drawDesktop()
    drawTaskbar()
    drawPowerMenu()
    
    while state.running do
        -- Handle events
        local event, button, x, y = os.pullEvent()
        local needsRedraw = false
        
        if event == "mouse_click" then
            if state.showPowerMenu then
                -- Handle power menu clicks first
                local w, h = screenManager.getSize()
                local menuX = 2
                local menuY = h - state.taskbarHeight - 4
                if menuY < 1 then
                    menuY = 1
                end
                
                if x >= menuX and x <= menuX + 8 and y >= menuY and y <= menuY + 2 then
                    -- Click inside power menu
                    handlePowerMenuClick(x, y)
                    needsRedraw = true
                else
                    -- Click outside power menu - check if it's the power button
                    local taskbarY = h - state.taskbarHeight + 1
                    if x >= 2 and x <= 4 and y == taskbarY + 1 then
                        -- Clicked power button while menu is open - toggle it
                        state.showPowerMenu = false
                        needsRedraw = true
                    else
                        -- Click elsewhere - close menu
                        state.showPowerMenu = false
                        needsRedraw = true
                    end
                end
            else
                -- Handle regular taskbar clicks
                handleTaskbarClick(x, y)
                needsRedraw = true
            end
        elseif event == "key" then
            -- Handle keyboard shortcuts
            if button == keys.escape and state.showPowerMenu then
                state.showPowerMenu = false
                needsRedraw = true
            end
        elseif event == "timer" then
            -- Update time display periodically
            needsRedraw = true
        end
        
        -- Only redraw if something changed
        if needsRedraw then
            drawDesktop()
            drawTaskbar()
            drawPowerMenu()
        end
    end
end

-- Initialize desktop
function desktop.start()
    screenManager.init()
    loadSession()
    
    -- Add some default "running apps" for demonstration
    state.runningApps["Desktop"] = true
    state.runningApps["Terminal"] = true
    
    -- Start desktop loop
    desktopLoop()
end

-- Start desktop
desktop.start() 