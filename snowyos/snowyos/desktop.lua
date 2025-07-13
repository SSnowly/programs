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
        display.write(" \7 ")  -- Power symbol
        
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
        local menuY = h - state.taskbarHeight - 3
        
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
        
        -- Menu border
        display.setBackgroundColor(colors.gray)
        display.setCursorPos(menuX - 1, menuY - 1)
        display.write("           ")
        display.setCursorPos(menuX - 1, menuY + 3)
        display.write("           ")
        
        for y = menuY, menuY + 2 do
            display.setCursorPos(menuX - 1, y)
            display.write(" ")
            display.setCursorPos(menuX + 9, y)
            display.write(" ")
        end
    end)
end

-- Handle power menu clicks
local function handlePowerMenuClick(x, y)
    local w, h = screenManager.getSize()
    local menuX = 2
    local menuY = h - state.taskbarHeight - 3
    
    if x >= menuX and x <= menuX + 8 then
        if y == menuY then
            -- Reboot
            screenManager.clearAll()
            screenManager.writeCentered(math.floor(h/2), "Rebooting...")
            sleep(1)
            os.reboot()
        elseif y == menuY + 1 then
            -- Shutdown
            screenManager.clearAll()
            screenManager.writeCentered(math.floor(h/2), "Shutting down...")
            sleep(1)
            os.shutdown()
        elseif y == menuY + 2 then
            -- Cancel
            state.showPowerMenu = false
        end
    else
        -- Click outside menu - close it
        state.showPowerMenu = false
    end
end

-- Handle taskbar clicks
local function handleTaskbarClick(x, y)
    local w, h = screenManager.getSize()
    local taskbarY = h - state.taskbarHeight + 1
    
    if y >= taskbarY then
        -- Power button click
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
    while state.running do
        -- Draw desktop components
        drawDesktop()
        drawTaskbar()
        drawPowerMenu()
        
        -- Handle events
        local event, button, x, y = os.pullEvent()
        
        if event == "mouse_click" then
            if state.showPowerMenu then
                handlePowerMenuClick(x, y)
            else
                handleTaskbarClick(x, y)
            end
        elseif event == "key" then
            -- Handle keyboard shortcuts
            if button == keys.f4 and state.showPowerMenu then
                -- Alt+F4 equivalent - close power menu
                state.showPowerMenu = false
            end
        elseif event == "timer" then
            -- Update time display periodically
            -- Timer will be set up separately
        end
        
        sleep(0.1)  -- Small delay to prevent excessive CPU usage
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