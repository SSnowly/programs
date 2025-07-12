-- Create Blasting Control Program
-- Handles blasting times based on quantity and sends redstone pulses
-- Auto-detects items and saves configuration

local CONFIG_FILE = "blaster_config.txt"

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
    sleep(ticks / 20) -- Convert ticks to seconds (20 ticks = 1 second)
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
    -- Check if peripheral type is an inventory
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
    
    -- Check directly connected peripherals
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    
    for _, side in pairs(sides) do
        if peripheral.isPresent(side) then
            local peripheral_name = peripheral.getType(side)
            if peripheral_name and isInventoryType(peripheral_name) then
                table.insert(inventories, {side = side, type = peripheral_name, location = "direct"})
            end
        end
    end
    
    -- Check network connected peripherals
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
        local locationText = inv.location == "direct" and "direct" or "network"
        print(i .. ". " .. inv.side .. " (" .. inv.type .. ") [" .. locationText .. "]")
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
    
    -- Show all connected peripherals and check if they're inventories
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    local inventoryCount = 0
    
    print("=== DIRECT CONNECTIONS ===")
    for _, side in pairs(sides) do
        if peripheral.isPresent(side) then
            local peripheral_name = peripheral.getType(side)
            if peripheral_name then
                -- Check if it's an inventory using getType
                local isInventory = isInventoryType(peripheral_name)
                
                if isInventory then
                    print(side .. ": " .. peripheral_name .. " [INVENTORY]")
                    inventoryCount = inventoryCount + 1
                else
                    print(side .. ": " .. peripheral_name .. " [NOT INVENTORY]")
                end
            else
                print(side .. ": Error getting peripheral type")
            end
        else
            print(side .. ": No peripheral connected")
        end
    end
    
    print()
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

local function transferFromInputChest(inputChestSide, maxItems)
    inputChestSide = inputChestSide or "left"
    maxItems = maxItems or 16
    
    local inputChest = peripheral.wrap(inputChestSide)
    
    if not inputChest then
        print("Warning: No input inventory found on " .. inputChestSide .. " side")
        return 0
    end
    
    local totalItems = countItemsInChest(inputChestSide)
    local itemsToProcess = math.min(totalItems, maxItems)
    
    print("Input inventory contains: " .. totalItems .. " items")
    print("Processing: " .. itemsToProcess .. " items (max " .. maxItems .. " per batch)")
    
    return itemsToProcess
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

local function waitForOutputItems(outputChestSide, expectedItems, batchId)
    local outputChest = peripheral.wrap(outputChestSide)
    if not outputChest then
        print("[Batch " .. batchId .. "] Error: Cannot access output chest")
        return false
    end
    
    local startTime = os.clock()
    local maxWaitTime = 30 -- Maximum 30 seconds to wait
    
    print("[Batch " .. batchId .. "] Waiting for " .. expectedItems .. " items to appear in output...")
    
    while true do
        local currentItems = countItemsInChest(outputChestSide)
        local elapsedTime = os.clock() - startTime
        
        if currentItems >= expectedItems then
            print("[Batch " .. batchId .. "] Found " .. currentItems .. " items in output chest!")
            return true
        end
        
        if elapsedTime > maxWaitTime then
            print("[Batch " .. batchId .. "] Timeout waiting for items (waited " .. maxWaitTime .. "s)")
            return false
        end
        
        -- Show progress every 2 seconds
        if math.floor(elapsedTime) % 2 == 0 then
            print("[Batch " .. batchId .. "] Waiting... (" .. currentItems .. "/" .. expectedItems .. " items, " .. math.floor(elapsedTime) .. "s elapsed)")
        end
        
        sleep(0.5) -- Check every 0.5 seconds
    end
end

local function markOutputItems(outputChestSide, itemsToMark, batchId)
    local outputChest = peripheral.wrap(outputChestSide)
    if not outputChest then
        print("[Batch " .. batchId .. "] Error: Cannot access output chest for marking")
        return false
    end
    
    print("[Batch " .. batchId .. "] Marking " .. itemsToMark .. " items as processed")
    
    -- Create a marker file to track processed items
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
    
    -- Record initial unprocessed item count in output
    local initialUnprocessed = getUnprocessedItemCount(outputChestSide)
    print("[Batch " .. batchId .. "] Initial unprocessed items in output: " .. initialUnprocessed)
    
    -- Send flow control pulse to allow items out
    if flowControlSide then
        sendRedstonePulse(flowControlSide, 4)
        print("[Batch " .. batchId .. "] Flow control pulse sent - allowing items out")
    end
    
    -- Wait 7.5 seconds for processing to start
    print("[Batch " .. batchId .. "] Waiting 7.5s for processing...")
    sleep(7.5)
    
    -- Wait for the expected number of items to appear in output
    local expectedTotal = initialUnprocessed + quantity
    local success = waitForOutputItems(outputChestSide, expectedTotal, batchId)
    
    if success then
        -- Mark the new items as processed
        markOutputItems(outputChestSide, quantity, batchId)
        
        print("[Batch " .. batchId .. "] Complete! Sending completion pulse...")
        
        -- Send 10-tick redstone pulse for completion
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
    
    -- Check input inventory and get items to process (max 16)
    local quantity = transferFromInputChest(inputChestSide, 16)
    
    if quantity == 0 then
        print("No items to process in input inventory")
        return false
    end
    
    -- Check output inventory availability
    transferToOutputChest(outputChestSide)
    
    -- Process single batch
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
        
        -- Only start new batch if not currently processing
        if not processingBatch and totalItems >= 16 then
            -- Start new batch if we have enough items
            batchCounter = batchCounter + 1
            local quantity = transferFromInputChest(inputChestSide, 16)
            
            if quantity > 0 then
                processingBatch = true
                print("\n--- Starting Batch " .. batchCounter .. " ---")
                
                -- Process batch linearly (wait for completion)
                processBatch(batchCounter, quantity, inputChestSide, outputChestSide, redstoneSide, flowControlSide)
                
                processingBatch = false
                print("Batch " .. batchCounter .. " completed. Ready for next batch.")
            end
        elseif not processingBatch and totalItems > 0 and totalItems < 16 then
            -- Process remaining items if less than 16
            batchCounter = batchCounter + 1
            local quantity = transferFromInputChest(inputChestSide, totalItems)
            
            if quantity > 0 then
                processingBatch = true
                print("\n--- Starting Final Batch " .. batchCounter .. " (" .. quantity .. " items) ---")
                
                -- Process batch linearly (wait for completion)
                processBatch(batchCounter, quantity, inputChestSide, outputChestSide, redstoneSide, flowControlSide)
                
                processingBatch = false
                print("Final batch " .. batchCounter .. " completed.")
            end
        end
        
        -- Show status
        if processingBatch then
            print("Processing batch " .. batchCounter .. " | Items remaining: " .. countItemsInChest(inputChestSide))
        elseif totalItems > 0 and totalItems < 16 then
            print("Waiting for more items (" .. totalItems .. "/16) | Need " .. (16 - totalItems) .. " more")
        elseif totalItems == 0 then
            print("Waiting for items in input inventory...")
        end
        
        sleep(1) -- Check every second
    end
end

local function autoBlaster(config)
    print("=== Auto Blaster Started ===")
    print("Input inventory: " .. config.inputChest)
    print("Output inventory: " .. config.outputChest)
    print("Redstone side: " .. config.redstoneSide)
    print("Flow control side: " .. (config.flowControlSide or "none"))
    print("Processing batches linearly (one at a time)")
    print("Monitoring for items... Press Ctrl+C to stop")
    
    local lastItemCount = 0
    local batchCounter = 0
    local processingBatch = false
    
    while true do
        local currentItemCount = countItemsInChest(config.inputChest)
        
        -- Only start new batch if not currently processing and items are available
        if not processingBatch and currentItemCount >= 16 then
            print("\nItems detected! Starting batch processing...")
            
            batchCounter = batchCounter + 1
            local quantity = transferFromInputChest(config.inputChest, 16)
            
            if quantity > 0 then
                processingBatch = true
                print("Starting Batch " .. batchCounter .. " (" .. quantity .. " items)")
                
                -- Process batch linearly (wait for completion)
                processBatch(batchCounter, quantity, config.inputChest, config.outputChest, config.redstoneSide, config.flowControlSide)
                
                processingBatch = false
                print("Batch " .. batchCounter .. " completed. Ready for next batch.")
            end
        end
        
        lastItemCount = currentItemCount
        
        -- Show status
        if processingBatch then
            print("Processing batch " .. batchCounter .. " | Items in inventory: " .. currentItemCount)
        elseif currentItemCount > 0 and currentItemCount < 16 then
            print("Waiting for more items (" .. currentItemCount .. "/16) | Need " .. (16 - currentItemCount) .. " more")
        elseif currentItemCount == 0 then
            print("Waiting for items in input inventory...")
        end
        
        sleep(2) -- Check every 2 seconds
    end
end

-- Main program
local function main()
    print("=== Create Blasting Control System ===")
    print("Auto-detects items and processes in 16-item batches")
    print("Multiple batches can run simultaneously")
    print()
    
    -- Load or create configuration
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
    print("Blast times per batch (max 16 items):")
    print("  1-16 items: 7.5s")
    print()
    
    -- Start auto blaster
    autoBlaster(config)
end

-- Export functions for use in other programs
_G.blast = blast
_G.blastContinuous = blastContinuous
_G.autoBlaster = autoBlaster
_G.processBatch = processBatch
_G.getBlastTime = getBlastTime
_G.sendRedstonePulse = sendRedstonePulse
_G.transferFromInputChest = transferFromInputChest
_G.transferToOutputChest = transferToOutputChest
_G.countItemsInChest = countItemsInChest
_G.setupConfiguration = setupConfiguration
_G.loadConfig = loadConfig
_G.saveConfig = saveConfig

-- Run main program if executed directly
if not _G.BLASTER_LOADED then
    _G.BLASTER_LOADED = true
    main()
end 