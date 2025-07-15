local CONFIG_FILE = "blaster_config.txt"
local monitor = nil
local screenConfig = {
    width = 0,
    height = 0,
    textScale = 1.0,
    isColor = true
}

local function findMonitor()
    local networkPeripherals = peripheral.getNames()
    for _, name in pairs(networkPeripherals) do
        local type = peripheral.getType(name)
        if type and string.find(type, "monitor") then
            return peripheral.wrap(name)
        end
    end

    return nil
end

local function initMonitor()
    monitor = findMonitor()
    if monitor then
        monitor.clear()
        
        monitor.setTextScale(1.0)
        local baseWidth, baseHeight = monitor.getSize()
        print("Base monitor size at 1.0 scale: " .. baseWidth .. "x" .. baseHeight)
        
        screenConfig.isColor = monitor.isColor()
        
        if baseWidth < 10 or baseHeight < 5 then
            screenConfig.textScale = 2.0
            monitor.setTextScale(2.0)
            print("Tiny monitor detected, using 2.0 scale")
        elseif baseWidth < 30 or baseHeight < 15 then
            screenConfig.textScale = 1.0
            monitor.setTextScale(1.0)
            print("Small monitor detected, using 1.0 scale")
        else
            screenConfig.textScale = 0.5
            monitor.setTextScale(0.5)
            print("Large monitor detected, using 0.5 scale")
        end
        
        local finalWidth, finalHeight = monitor.getSize()
        screenConfig.width = finalWidth
        screenConfig.height = finalHeight
        
        print("Final monitor size: " .. finalWidth .. "x" .. finalHeight)
        print("Screen config saved: " .. screenConfig.width .. "x" .. screenConfig.height .. " scale:" .. screenConfig.textScale .. " color:" .. tostring(screenConfig.isColor))
        
        monitor.setCursorPos(1, 1)
        return true
    end
    return false
end

local function drawProgressBar(x, y, width, progress, maxProgress, label, color)
    if not monitor then return end
    
    local maxBarWidth = screenConfig.width - x - 15
    local actualWidth = math.min(width, maxBarWidth)
    
    local percentage = math.min(progress / maxProgress, 1)
    local filledWidth = math.floor(actualWidth * percentage)
    local percentageText = math.floor(percentage * 100) .. "%"
    
    monitor.setCursorPos(x, y)
    monitor.setTextColor(colors.yellow)
    monitor.write(label)
    
    local barText = string.rep(" ", actualWidth)
    local barBg = string.rep("7", actualWidth)
    local barFg = string.rep("0", actualWidth)
    
    if filledWidth > 0 then
        local colorChar = "0"
        if screenConfig.isColor then
            if color == colors.lime then colorChar = "5"
            elseif color == colors.orange then colorChar = "1"
            elseif color == colors.red then colorChar = "e"
            elseif color == colors.green then colorChar = "d"
            elseif color == colors.blue then colorChar = "b"
            end
        end
        
        barBg = string.rep(colorChar, filledWidth) .. string.rep("7", actualWidth - filledWidth)
    end
    
    monitor.setCursorPos(x, y + 1)
    monitor.blit(barText, barFg, barBg)
    
    monitor.setCursorPos(x + actualWidth + 2, y + 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    monitor.write(percentageText .. " (" .. progress .. "/" .. maxProgress .. ")")
end



local function updateMonitorDisplay(batchId, phase, progress, maxProgress, inputCount, outputCount, batchSize)
    if not monitor then return end
    
    monitor.clear()
    
    if screenConfig.width < 10 or screenConfig.height < 5 then
        monitor.setCursorPos(1, 1)
        monitor.setTextColor(colors.white)
        monitor.setBackgroundColor(colors.blue)
        monitor.write(string.rep(" ", screenConfig.width))
        monitor.setCursorPos(1, 1)
        if screenConfig.width >= 3 then
            monitor.write("B" .. batchId)
        else
            monitor.write(tostring(batchId))
        end
        
        if screenConfig.height >= 2 then
            monitor.setCursorPos(1, screenConfig.height)
            monitor.setTextColor(colors.white)
            monitor.setBackgroundColor(colors.gray)
            monitor.write(string.rep(" ", screenConfig.width))
            monitor.setCursorPos(1, screenConfig.height)
            local outputPercentage = math.floor((outputCount / 2304) * 100)
            if screenConfig.width >= 3 then
                monitor.write(outputPercentage .. "%")
            else
                monitor.write(tostring(outputPercentage))
            end
        end
        return
    end
    
    local headerText = "CREATE BLASTING SYSTEM"
    if string.len(headerText) > screenConfig.width then
        headerText = "BLASTING SYSTEM"
    end
    if string.len(headerText) > screenConfig.width then
        headerText = "BLASTER"
    end
    
    local headerBarBg = string.rep("4", screenConfig.width)
    local headerBarFg = string.rep("f", screenConfig.width)
    local headerBarText = string.rep(" ", screenConfig.width)
    
    local headerStart = math.floor((screenConfig.width - string.len(headerText)) / 2) + 1
    for i = 1, string.len(headerText) do
        headerBarText = string.sub(headerBarText, 1, headerStart + i - 2) .. string.sub(headerText, i, i) .. string.sub(headerBarText, headerStart + i, -1)
    end
    
    monitor.setCursorPos(1, 1)
    monitor.blit(headerBarText, headerBarFg, headerBarBg)
    
    monitor.setCursorPos(1, 3)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
    local statusText = "Batch #" .. batchId .. " | Phase: " .. phase
    if string.len(statusText) > screenConfig.width then
        statusText = "B" .. batchId .. " | " .. phase
    end
    monitor.write(statusText)
    
    local barColor = colors.blue
    if phase == "Processing" then
        barColor = colors.orange
    elseif phase == "Waiting for Items" then
        barColor = colors.red
    elseif phase == "Complete" then
        barColor = colors.green
    elseif phase == "Starting" then
        barColor = colors.lime
    end
    
    local progressBarWidth = math.min(20, screenConfig.width - 20)
    drawProgressBar(1, 5, progressBarWidth, progress, maxProgress, "Progress:", barColor)
    
    monitor.setCursorPos(1, 8)
    monitor.setTextColor(colors.cyan)
    monitor.setBackgroundColor(colors.black)
    monitor.write("Batch Size: " .. (batchSize or maxProgress) .. " items")
    
    local itemsProcessed = 0
    if phase == "Complete" then
        itemsProcessed = batchSize or maxProgress
    elseif phase == "Waiting for Items" then
        itemsProcessed = math.max(0, progress - (batchSize or maxProgress))
    end
    
    monitor.setCursorPos(1, 10)
    monitor.setTextColor(colors.yellow)
    monitor.write("Items Processed: " .. itemsProcessed .. "/" .. (batchSize or maxProgress))
    
    local bottomBarBg = string.rep("8", screenConfig.width)
    local bottomBarFg = string.rep("0", screenConfig.width)
    local bottomBarText = string.rep(" ", screenConfig.width)
    
    local outputPercentage = math.floor((outputCount / 2304) * 100)
    local outputText = outputPercentage .. "%"
    local timeText = os.date("%H:%M")
    
    for i = 1, string.len(outputText) do
        bottomBarText = string.sub(bottomBarText, 1, i - 1) .. string.sub(outputText, i, i) .. string.sub(bottomBarText, i + 1, -1)
    end
    
    local timeStart = screenConfig.width - string.len(timeText) + 1
    for i = 1, string.len(timeText) do
        bottomBarText = string.sub(bottomBarText, 1, timeStart + i - 2) .. string.sub(timeText, i, i) .. string.sub(bottomBarText, timeStart + i, -1)
    end
    
    monitor.setCursorPos(1, screenConfig.height)
    monitor.blit(bottomBarText, bottomBarFg, bottomBarBg)
end

local function showWaitingScreen(outputCount)
    if not monitor then return end
    
    monitor.clear()
    
    if screenConfig.width < 10 or screenConfig.height < 5 then
        monitor.setCursorPos(1, 1)
        monitor.setTextColor(colors.white)
        monitor.setBackgroundColor(colors.blue)
        monitor.write(string.rep(" ", screenConfig.width))
        monitor.setCursorPos(1, 1)
        if screenConfig.width >= 3 then
            monitor.write("RDY")
        else
            monitor.write("R")
        end
        
        if screenConfig.height >= 2 then
            monitor.setCursorPos(1, screenConfig.height)
            monitor.setTextColor(colors.white)
            monitor.setBackgroundColor(colors.gray)
            monitor.write(string.rep(" ", screenConfig.width))
            monitor.setCursorPos(1, screenConfig.height)
            local outputPercentage = math.floor(((outputCount or 0) / 2304) * 100)
            if screenConfig.width >= 3 then
                monitor.write(outputPercentage .. "%")
            else
                monitor.write(tostring(outputPercentage))
            end
        end
        return
    end
    
    local headerText = "CREATE BLASTING SYSTEM"
    if string.len(headerText) > screenConfig.width then
        headerText = "BLASTING SYSTEM"
    end
    if string.len(headerText) > screenConfig.width then
        headerText = "BLASTER"
    end
    
    local headerBarBg = string.rep("4", screenConfig.width)
    local headerBarFg = string.rep("f", screenConfig.width)
    local headerBarText = string.rep(" ", screenConfig.width)
    
    local headerStart = math.floor((screenConfig.width - string.len(headerText)) / 2) + 1
    for i = 1, string.len(headerText) do
        headerBarText = string.sub(headerBarText, 1, headerStart + i - 2) .. string.sub(headerText, i, i) .. string.sub(headerBarText, headerStart + i, -1)
    end
    
    monitor.setCursorPos(1, 1)
    monitor.blit(headerBarText, headerBarFg, headerBarBg)
    
    local startY = math.max(3, math.floor(screenConfig.height / 4))
    
    monitor.setCursorPos(2, startY)
    monitor.setTextColor(colors.lime)
    monitor.setBackgroundColor(colors.black)
    monitor.write("Ready for Operation")
    
    monitor.setCursorPos(2, startY + 2)
    monitor.setTextColor(colors.yellow)
    monitor.write("Waiting for Items...")
    
    if screenConfig.height > startY + 4 then
        monitor.setCursorPos(2, startY + 4)
        monitor.setTextColor(colors.orange)
        monitor.write("Status:")
        
        local barWidth = math.min(20, screenConfig.width - 12)
        local time = os.clock()
        local cycle = time % 4
        local position = 0
        
        if cycle < 2 then
            position = math.floor((cycle / 2) * barWidth)
        else
            position = math.floor(((4 - cycle) / 2) * barWidth)
        end
        
        local statusBarText = string.rep(" ", barWidth)
        local statusBarBg = string.rep("8", barWidth)
        local statusBarFg = string.rep("0", barWidth)
        
        if position >= 0 and position < barWidth then
            if screenConfig.isColor then
                statusBarBg = string.sub(statusBarBg, 1, position) .. "d" .. string.sub(statusBarBg, position + 2, -1)
            else
                statusBarBg = string.sub(statusBarBg, 1, position) .. "0" .. string.sub(statusBarBg, position + 2, -1)
            end
        end
        
        monitor.setCursorPos(2, startY + 5)
        monitor.blit(statusBarText, statusBarFg, statusBarBg)
    end
    
    if screenConfig.height > startY + 7 then
        monitor.setCursorPos(2, startY + 7)
        monitor.setTextColor(colors.cyan)
        monitor.write("Network: Active")
        
        monitor.setCursorPos(2, startY + 8)
        monitor.setTextColor(colors.lightBlue)
        monitor.write("System: Online")
    end
    
    local bottomBarBg = string.rep("8", screenConfig.width)
    local bottomBarFg = string.rep("0", screenConfig.width)
    local bottomBarText = string.rep(" ", screenConfig.width)
    
    local outputPercentage = math.floor(((outputCount or 0) / 2304) * 100)
    local outputText = outputPercentage .. "%"
    local timeText = os.date("%H:%M")
    
    for i = 1, string.len(outputText) do
        bottomBarText = string.sub(bottomBarText, 1, i - 1) .. string.sub(outputText, i, i) .. string.sub(bottomBarText, i + 1, -1)
    end
    
    local timeStart = screenConfig.width - string.len(timeText) + 1
    for i = 1, string.len(timeText) do
        bottomBarText = string.sub(bottomBarText, 1, timeStart + i - 2) .. string.sub(timeText, i, i) .. string.sub(bottomBarText, timeStart + i, -1)
    end
    
    monitor.setCursorPos(1, screenConfig.height)
    monitor.blit(bottomBarText, bottomBarFg, bottomBarBg)
end

local function getBlastTime(quantity)
    if quantity >= 1 and quantity <= 16 then
        return 7.5
    elseif quantity >= 17 and quantity <= 32 then
        return 15
    elseif quantity >= 33 and quantity <= 48 then
        return 22.5
    elseif quantity >= 49 and quantity <= 64 then
        return 30
    else
        error("Invalid quantity: " .. quantity .. ". Must be between 1-64")
    end
end

local function sendRedstonePulse(side, ticks)
    redstone.setOutput(side, true)
    sleep(ticks / 20)
    redstone.setOutput(side, false)
end

local function saveConfig(config)
    local file = fs.open(CONFIG_FILE, "w")
    if file then
        file.write(textutils.serialize(config))
        file.close()
        return true
    end
    return false
end

local function loadConfig()
    if fs.exists(CONFIG_FILE) then
        local file = fs.open(CONFIG_FILE, "r")
        if file then
            local content = file.readAll()
            file.close()
            return textutils.unserialize(content)
        end
    end
    return nil
end

local function isInventoryType(peripheral_type)
    return string.find(peripheral_type, "chest") or
           string.find(peripheral_type, "barrel") or
           string.find(peripheral_type, "shulker") or
           string.find(peripheral_type, "drawer") or
           string.find(peripheral_type, "crate") or
           string.find(peripheral_type, "storage") or
           string.find(peripheral_type, "tank") or
           string.find(peripheral_type, "bin")
end

local function getAvailableInventories()
    local inventories = {}

    local networkPeripherals = peripheral.getNames()

    for _, name in pairs(networkPeripherals) do
        local peripheral_type = peripheral.getType(name)
        if peripheral_type and isInventoryType(peripheral_type) then
            table.insert(inventories, {side = name, type = peripheral_type, location = "network"})
        end
    end

    return inventories
end

local function selectInventory(prompt, inventories)
    print(prompt)
    for i, inv in pairs(inventories) do
        print(i .. ". " .. inv.side .. " (" .. inv.type .. ") [network]")
    end
    print("Enter choice (1-" .. #inventories .. "):")
    
    local choice = tonumber(io.read())
    if choice and choice >= 1 and choice <= #inventories then
        return inventories[choice].side
    end
    
    return nil
end

local function setupConfiguration()
    print("=== First Time Setup ===")
    print("Scanning for peripherals...")
    print()
    
    local inventoryCount = 0
    
    print("=== NETWORK CONNECTIONS ===")
    local networkPeripherals = peripheral.getNames()
    
    for _, name in pairs(networkPeripherals) do
        local peripheral_type = peripheral.getType(name)
        if peripheral_type then
            local isInventory = isInventoryType(peripheral_type)
            
            if isInventory then
                print(name .. ": " .. peripheral_type .. " [INVENTORY]")
                inventoryCount = inventoryCount + 1
            else
                print(name .. ": " .. peripheral_type .. " [NOT INVENTORY]")
            end
        end
    end
    
    print()
    print("Total inventories found: " .. inventoryCount)
    print()

    if inventoryCount == 0 then
        print("No inventories found! Please connect inventories and restart.")
        print("Make sure your inventories support the .list() method.")
        return nil
    end

    local inventories = getAvailableInventories()
    print("Available inventories for selection:")

    local inputChest = selectInventory("Select INPUT inventory:", inventories)
    if not inputChest then
        print("Invalid selection for input inventory")
        return nil
    end

    local outputChest = selectInventory("Select OUTPUT inventory:", inventories)
    if not outputChest then
        print("Invalid selection for output inventory")
        return nil
    end

    print("Select REDSTONE output side:")
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    for i, side in pairs(sides) do
        print(i .. ". " .. side)
    end
    print("Enter choice (1-6):")

    local redstoneChoice = tonumber(io.read())
    if not redstoneChoice or redstoneChoice < 1 or redstoneChoice > 6 then
        print("Invalid selection for redstone side")
        return nil
    end

    local redstoneSide = sides[redstoneChoice]

    print("Select FLOW CONTROL redstone side (controls item output):")
    for i, side in pairs(sides) do
        print(i .. ". " .. side)
    end
    print("Enter choice (1-6):")

    local flowControlChoice = tonumber(io.read())
    if not flowControlChoice or flowControlChoice < 1 or flowControlChoice > 6 then
        print("Invalid selection for flow control side")
        return nil
    end

    local flowControlSide = sides[flowControlChoice]

    local config = {
        inputChest = inputChest,
        outputChest = outputChest,
        redstoneSide = redstoneSide,
        flowControlSide = flowControlSide
    }

    if saveConfig(config) then
        print("Configuration saved!")
        print("Input inventory: " .. inputChest)
        print("Output inventory: " .. outputChest)
        print("Redstone side: " .. redstoneSide)
        print("Flow control side: " .. flowControlSide)
        return config
    else
        print("Failed to save configuration")
        return nil
    end
end

local function countItemsInChest(chestSide)
    local chest = peripheral.wrap(chestSide)
    if not chest then
        return 0
    end

    local totalItems = 0
    local items = chest.list()

    for slot, item in pairs(items) do
        totalItems = totalItems + item.count
    end

    return totalItems
end

local function getItemTypeAndCount(inputChestSide)
    local inputChest = peripheral.wrap(inputChestSide)
    if not inputChest then
        return nil, 0
    end

    local items = inputChest.list()
    local itemTypes = {}

    for slot, item in pairs(items) do
        if itemTypes[item.name] then
            itemTypes[item.name] = itemTypes[item.name] + item.count
        else
            itemTypes[item.name] = item.count
        end
    end

    local maxCount = 0
    local selectedType = nil

    for itemType, count in pairs(itemTypes) do
        if count > maxCount then
            maxCount = count
            selectedType = itemType
        end
    end

    return selectedType, maxCount
end

local function transferFromInputChest(inputChestSide, maxItems)
    inputChestSide = inputChestSide or "left"
    maxItems = maxItems or 64

    local inputChest = peripheral.wrap(inputChestSide)

    if not inputChest then
        print("Warning: No input inventory found on " .. inputChestSide .. " side")
        return 0, nil
    end

    local selectedType, availableCount = getItemTypeAndCount(inputChestSide)

    if not selectedType or availableCount == 0 then
        print("No items found in input inventory")
        return 0, nil
    end

    local itemsToProcess = math.min(availableCount, maxItems)

    print("Input inventory contains: " .. availableCount .. " x " .. selectedType)
    print("Processing: " .. itemsToProcess .. " items (max " .. maxItems .. " per batch)")

    return itemsToProcess, selectedType
end

local function transferToOutputChest(outputChestSide)
    outputChestSide = outputChestSide or "right"

    local outputChest = peripheral.wrap(outputChestSide)

    if not outputChest then
        print("Warning: No output inventory found on " .. outputChestSide .. " side")
        return false
    end

    print("Output inventory ready for items on " .. outputChestSide .. " side")
    return true
end

local function waitForOutputItems(outputChestSide, expectedItems, batchId, inputChestSide)
    local outputChest = peripheral.wrap(outputChestSide)
    if not outputChest then
        print("[Batch " .. batchId .. "] Error: Cannot access output chest")
        return false
    end

    local startTime = os.clock()
    local maxWaitTime = 30

    print("[Batch " .. batchId .. "] Waiting for " .. expectedItems .. " items to appear in output...")

    while true do
        local currentItems = countItemsInChest(outputChestSide)
        local elapsedTime = os.clock() - startTime
        local inputCount = countItemsInChest(inputChestSide)

        updateMonitorDisplay(batchId, "Waiting for Items", currentItems, expectedItems, inputCount, currentItems, quantity)

        if currentItems >= expectedItems then
            print("[Batch " .. batchId .. "] Found " .. currentItems .. " items in output chest!")
            updateMonitorDisplay(batchId, "Complete", expectedItems, expectedItems, inputCount, currentItems, quantity)
            return true
        end

        if elapsedTime > maxWaitTime then
            print("[Batch " .. batchId .. "] Timeout waiting for items (waited " .. maxWaitTime .. "s)")
            updateMonitorDisplay(batchId, "Timeout", currentItems, expectedItems, inputCount, currentItems, quantity)
            return false
        end

        if math.floor(elapsedTime) % 2 == 0 then
            print("[Batch " .. batchId .. "] Waiting... (" .. currentItems .. "/" .. expectedItems .. " items, " .. math.floor(elapsedTime) .. "s elapsed)")
        end

        sleep(0.5)
    end
end

local function markOutputItems(outputChestSide, itemsToMark, batchId)
    local outputChest = peripheral.wrap(outputChestSide)
    if not outputChest then
        print("[Batch " .. batchId .. "] Error: Cannot access output chest for marking")
        return false
    end

    print("[Batch " .. batchId .. "] Marking " .. itemsToMark .. " items as processed")

    local markerFile = "processed_items.txt"
    local processedCount = 0

    if fs.exists(markerFile) then
        local file = fs.open(markerFile, "r")
        if file then
            processedCount = tonumber(file.readAll()) or 0
            file.close()
        end
    end

    processedCount = processedCount + itemsToMark

    local file = fs.open(markerFile, "w")
    if file then
        file.write(tostring(processedCount))
        file.close()
        print("[Batch " .. batchId .. "] Total processed items: " .. processedCount)
        return true
    else
        print("[Batch " .. batchId .. "] Error: Could not update processed items count")
        return false
    end
end

local function getUnprocessedItemCount(outputChestSide)
    local totalItems = countItemsInChest(outputChestSide)
    local processedCount = 0

    local markerFile = "processed_items.txt"
    if fs.exists(markerFile) then
        local file = fs.open(markerFile, "r")
        if file then
            processedCount = tonumber(file.readAll()) or 0
            file.close()
        end
    end

    return math.max(0, totalItems - processedCount)
end

local function processBatch(batchId, quantity, inputChestSide, outputChestSide, redstoneSide, flowControlSide)
    print("[Batch " .. batchId .. "] Starting - " .. quantity .. " items")

    local initialUnprocessed = getUnprocessedItemCount(outputChestSide)
    print("[Batch " .. batchId .. "] Initial unprocessed items in output: " .. initialUnprocessed)

    local inputCount = countItemsInChest(inputChestSide)
    local outputCount = countItemsInChest(outputChestSide)

    updateMonitorDisplay(batchId, "Starting", 0, 100, inputCount, outputCount, quantity)

    if flowControlSide then
        sendRedstonePulse(flowControlSide, 7)
        print("[Batch " .. batchId .. "] Flow control pulse sent - allowing items out")
    end

    print("[Batch " .. batchId .. "] Waiting 30s for processing...")
    for i = 1, 60 do
        local progress = math.floor((i / 60) * 100)
        updateMonitorDisplay(batchId, "Processing", progress, 100, countItemsInChest(inputChestSide), countItemsInChest(outputChestSide), quantity)
        sleep(0.5)
    end

    if redstoneSide then
        redstone.setOutput(redstoneSide, true)
        print("[Batch " .. batchId .. "] Back signal turned OFF - waiting for items...")
    end

    local expectedTotal = initialUnprocessed + quantity
    local success = waitForOutputItems(outputChestSide, expectedTotal, batchId, inputChestSide)

    if success then
        markOutputItems(outputChestSide, quantity, batchId)

        print("[Batch " .. batchId .. "] Complete! Sending completion pulse...")

        sendRedstonePulse(redstoneSide, 10)

        print("[Batch " .. batchId .. "] Finished successfully")
        return true
    else
        print("[Batch " .. batchId .. "] Failed - items did not appear in time")
        return false
    end
end

local function blast(inputChestSide, outputChestSide, redstoneSide, flowControlSide)
    inputChestSide = inputChestSide or "left"
    outputChestSide = outputChestSide or "right"
    redstoneSide = redstoneSide or "back"

    local quantity, itemType = transferFromInputChest(inputChestSide, 64)

    if quantity == 0 then
        print("No items to process in input inventory")
        return false
    end

    transferToOutputChest(outputChestSide)

    return processBatch(1, quantity, inputChestSide, outputChestSide, redstoneSide, flowControlSide)
end

local function blastContinuous(inputChestSide, outputChestSide, redstoneSide, flowControlSide)
    inputChestSide = inputChestSide or "left"
    outputChestSide = outputChestSide or "right"
    redstoneSide = redstoneSide or "back"

    print("Starting continuous blasting mode...")
    print("Press Ctrl+C to stop")
    print("Processing batches linearly (one at a time)")

    local batchCounter = 0
    local processingBatch = false

    while true do
        local totalItems = countItemsInChest(inputChestSide)

        if not processingBatch and totalItems > 0 then
            batchCounter = batchCounter + 1
            local quantity, itemType = transferFromInputChest(inputChestSide, 64)

            if quantity > 0 then
                processingBatch = true
                print("\n--- Starting Batch " .. batchCounter .. " (" .. quantity .. " x " .. (itemType or "unknown") .. ") ---")

                processBatch(batchCounter, quantity, inputChestSide, outputChestSide, redstoneSide, flowControlSide)

                processingBatch = false
                print("Batch " .. batchCounter .. " completed. Ready for next batch.")
            end
        end

        if processingBatch then
            print("Processing batch " .. batchCounter .. " | Items remaining: " .. countItemsInChest(inputChestSide))
        elseif totalItems > 0 then
            print("Items ready for processing: " .. totalItems .. " (will process up to 64)")
        elseif totalItems == 0 then
            print("Waiting for items in input inventory...")
        end

        sleep(1)
    end
end

local function autoBlaster(config)
    print("=== Auto Blaster Started (Async Mode) ===")
    print("Input inventory: " .. config.inputChest)
    print("Output inventory: " .. config.outputChest)
    print("Redstone side: " .. config.redstoneSide)
    print("Flow control side: " .. (config.flowControlSide or "none"))
    print("Processing batches asynchronously - multiple batches can run at once")
    print("Monitoring for items... Press Ctrl+C to stop")
    
    local batchCounter = 0
    local lastProcessedItemCount = 0
    
    while true do
        local currentItemCount = countItemsInChest(config.inputChest)
        
        local activeBatchCount = 0
        for _ in pairs(activeBatches) do
            activeBatchCount = activeBatchCount + 1
        end
        
        if currentItemCount > 64 and activeBatchCount == 0 and currentItemCount ~= lastProcessedItemCount then
            print("\nLarge batch detected! Starting async processing...")
            
            batchCounter = batchCounter + 1
            local itemType, totalItems = getItemTypeAndCount(config.inputChest)
            
            if totalItems > 0 then
                print("Starting Batch " .. batchCounter .. " (" .. totalItems .. " x " .. (itemType or "unknown") .. ")")
                
                processAsyncBatch(batchCounter, totalItems, config.inputChest, config.outputChest, config.redstoneSide, config.flowControlSide)
                
                lastProcessedItemCount = totalItems
                print("Batch " .. batchCounter .. " started asynchronously!")
            end
        elseif currentItemCount > 0 and currentItemCount <= 64 and activeBatchCount == 0 then
            batchCounter = batchCounter + 1
            local quantity, itemType = transferFromInputChest(config.inputChest, 64)
            
            if quantity > 0 then
                print("Starting small Batch " .. batchCounter .. " (" .. quantity .. " x " .. (itemType or "unknown") .. ")")
                processAsyncBatch(batchCounter, quantity, config.inputChest, config.outputChest, config.redstoneSide, config.flowControlSide)
                lastProcessedItemCount = quantity
            end
        end
        
        updateAsyncBatches()
        
        if activeBatchCount > 0 then
            print("Active batches: " .. activeBatchCount .. " | Items in inventory: " .. currentItemCount)
        elseif currentItemCount > 0 then
            if activeBatchCount > 0 then
                print("Items ready (" .. currentItemCount .. ") - waiting for active batches to complete...")
            else
                print("Items ready for processing: " .. currentItemCount)
            end
        elseif currentItemCount == 0 then
            print("Waiting for items in input inventory...")
            local outputCount = countItemsInChest(config.outputChest)
            showWaitingScreen(outputCount)
        end
        
        sleep(1)
    end
end

local function main()
    print("=== Create Blasting Control System (Async Version) ===")
    print("Auto-detects items and processes them asynchronously")
    print("Large batches (>64 items): Dumps all items slowly, then 30s timer")
    print("Small batches (<=64 items): Processed when no other batches active")
    print()

    local config = loadConfig()

    if not config then
        print("No configuration found. Running first-time setup...")
        config = setupConfiguration()

        if not config then
            print("Setup failed. Exiting.")
            return
        end
    else
        print("Configuration loaded:")
        print("  Input inventory: " .. config.inputChest)
        print("  Output inventory: " .. config.outputChest)
        print("  Redstone side: " .. config.redstoneSide)
        print("  Flow control side: " .. (config.flowControlSide or "none"))
        print()
        print("To reconfigure, delete 'blaster_config.txt' and restart")
    end

    print()
    print("Async processing modes:")
    print("  Large batches: Slow dump + 30s processing timer")
    print("  Small batches: Traditional 30s processing")
    print()

    if initMonitor() then
        print("Monitor connected and initialized!")
    else
        print("No monitor found - running without visual display")
    end

    autoBlaster(config)
end

local activeBatches = {}

local function dumpAllItemsSlowly(inputChestSide, flowControlSide, itemCount, batchId)
    print("[Batch " .. batchId .. "] Starting stack-by-stack dump of " .. itemCount .. " items")
    
    local initialItems = countItemsInChest(inputChestSide)
    local stackCount = math.ceil(initialItems / 64)
    local stacksDumped = 0
    
    print("[Batch " .. batchId .. "] Estimated " .. stackCount .. " stacks to dump")
    
    local function dumpItems()
        while true do
            local currentItems = countItemsInChest(inputChestSide)
            
            if currentItems == 0 then
                print("[Batch " .. batchId .. "] All items dumped!")
                break
            end
            
            local itemsDumped = initialItems - currentItems
            local progress = math.floor((itemsDumped / initialItems) * 100)
            
            updateMonitorDisplay(batchId, "Dumping Items", itemsDumped, initialItems, currentItems, countItemsInChest(activeBatches[batchId].outputChestSide), initialItems)
            
            if flowControlSide then
                redstone.setOutput(flowControlSide, true)
                print("[Batch " .. batchId .. "] Flow ON - dumping stack " .. (stacksDumped + 1))
            end
            
            sleep(7 / 20)
            
            if flowControlSide then
                redstone.setOutput(flowControlSide, false)
            end
            
            stacksDumped = stacksDumped + 1
            
            local newItemCount = countItemsInChest(inputChestSide)
            local itemsThisStack = currentItems - newItemCount
            
            print("[Batch " .. batchId .. "] Stack " .. stacksDumped .. " dumped (" .. itemsThisStack .. " items) - " .. newItemCount .. " remaining")
            
            sleep(0.05)
        end
        
        print("[Batch " .. batchId .. "] All " .. stacksDumped .. " stacks dumped! Starting 30s processing timer...")
        activeBatches[batchId].dumpComplete = true
        activeBatches[batchId].timerStart = os.clock()
        
        return true
    end
    
    return dumpItems()
end

local function processAsyncBatch(batchId, totalItems, inputChestSide, outputChestSide, redstoneSide, flowControlSide)
    print("[Batch " .. batchId .. "] Starting async batch - " .. totalItems .. " items")
    
    activeBatches[batchId] = {
        totalItems = totalItems,
        inputChestSide = inputChestSide,
        outputChestSide = outputChestSide,
        redstoneSide = redstoneSide,
        flowControlSide = flowControlSide,
        dumpComplete = false,
        timerStart = nil,
        timerDuration = 30,
        processed = false
    }
    
    local inputCount = countItemsInChest(inputChestSide)
    local outputCount = countItemsInChest(outputChestSide)
    
    updateMonitorDisplay(batchId, "Starting", 0, 100, inputCount, outputCount, totalItems)
    
    return dumpAllItemsSlowly(inputChestSide, flowControlSide, totalItems, batchId)
end

local function updateAsyncBatches()
    for batchId, batch in pairs(activeBatches) do
        if batch.dumpComplete and not batch.processed then
            local elapsedTime = os.clock() - batch.timerStart
            local progress = math.min((elapsedTime / batch.timerDuration) * 100, 100)
            
            updateMonitorDisplay(batchId, "Processing", progress, 100, 
                countItemsInChest(batch.inputChestSide), 
                countItemsInChest(batch.outputChestSide), 
                batch.totalItems)
            
            if elapsedTime >= batch.timerDuration then
                print("[Batch " .. batchId .. "] Processing timer complete! Turning redstone ON")
                
                if batch.redstoneSide then
                    redstone.setOutput(batch.redstoneSide, true)
                end
                
                batch.processed = true
                
                local expectedTotal = getUnprocessedItemCount(batch.outputChestSide) + batch.totalItems
                
                local function waitForCompletion()
                    local startWait = os.clock()
                    local maxWaitTime = 30
                    
                    while true do
                        local currentItems = countItemsInChest(batch.outputChestSide)
                        local waitTime = os.clock() - startWait
                        
                        updateMonitorDisplay(batchId, "Waiting for Items", currentItems, expectedTotal, 
                            countItemsInChest(batch.inputChestSide), currentItems, batch.totalItems)
                        
                        if currentItems >= expectedTotal then
                            print("[Batch " .. batchId .. "] Complete! Found " .. currentItems .. " items in output")
                            updateMonitorDisplay(batchId, "Complete", expectedTotal, expectedTotal, 
                                countItemsInChest(batch.inputChestSide), currentItems, batch.totalItems)
                            
                            markOutputItems(batch.outputChestSide, batch.totalItems, batchId)
                            
                            if batch.redstoneSide then
                                sendRedstonePulse(batch.redstoneSide, 10)
                            end
                            
                            activeBatches[batchId] = nil
                            break
                        end
                        
                        if waitTime > maxWaitTime then
                            print("[Batch " .. batchId .. "] Timeout waiting for items")
                            updateMonitorDisplay(batchId, "Timeout", currentItems, expectedTotal, 
                                countItemsInChest(batch.inputChestSide), currentItems, batch.totalItems)
                            activeBatches[batchId] = nil
                            break
                        end
                        
                        sleep(0.5)
                    end
                end
                
                waitForCompletion()
            end
        end
    end
end

_G.blast = blast
_G.blastContinuous = blastContinuous
_G.autoBlaster = autoBlaster
_G.processBatch = processBatch
_G.processAsyncBatch = processAsyncBatch
_G.dumpAllItemsSlowly = dumpAllItemsSlowly
_G.updateAsyncBatches = updateAsyncBatches
_G.getBlastTime = getBlastTime
_G.sendRedstonePulse = sendRedstonePulse
_G.transferFromInputChest = transferFromInputChest
_G.transferToOutputChest = transferToOutputChest
_G.countItemsInChest = countItemsInChest
_G.setupConfiguration = setupConfiguration
_G.loadConfig = loadConfig
_G.saveConfig = saveConfig

if not _G.BLASTER_LOADED then
    _G.BLASTER_LOADED = true
    main()
end