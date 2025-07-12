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

local function getAvailableInventories()
    local inventories = {}
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    
    for _, side in pairs(sides) do
        local peripheral_name = peripheral.getType(side)
        if peripheral_name and string.find(peripheral_name, "chest") then
            table.insert(inventories, {side = side, type = peripheral_name})
        end
    end
    
    return inventories
end

local function selectInventory(prompt, inventories)
    print(prompt)
    for i, inv in pairs(inventories) do
        print(i .. ". " .. inv.side .. " (" .. inv.type .. ")")
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
    print("Scanning for available inventories...")
    
    local inventories = getAvailableInventories()
    
    if #inventories == 0 then
        print("No chests found! Please connect chests and restart.")
        return nil
    end
    
    print("Found " .. #inventories .. " inventories:")
    
    local inputChest = selectInventory("Select INPUT chest:", inventories)
    if not inputChest then
        print("Invalid selection for input chest")
        return nil
    end
    
    local outputChest = selectInventory("Select OUTPUT chest:", inventories)
    if not outputChest then
        print("Invalid selection for output chest")
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
    
    local config = {
        inputChest = inputChest,
        outputChest = outputChest,
        redstoneSide = redstoneSide
    }
    
    if saveConfig(config) then
        print("Configuration saved!")
        print("Input chest: " .. inputChest)
        print("Output chest: " .. outputChest)
        print("Redstone side: " .. redstoneSide)
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
        print("Warning: No input chest found on " .. inputChestSide .. " side")
        return 0
    end
    
    local totalItems = countItemsInChest(inputChestSide)
    local itemsToProcess = math.min(totalItems, maxItems)
    
    print("Input chest contains: " .. totalItems .. " items")
    print("Processing: " .. itemsToProcess .. " items (max " .. maxItems .. " per batch)")
    
    return itemsToProcess
end

local function transferToOutputChest(outputChestSide)
    outputChestSide = outputChestSide or "right"
    
    local outputChest = peripheral.wrap(outputChestSide)
    
    if not outputChest then
        print("Warning: No output chest found on " .. outputChestSide .. " side")
        return false
    end
    
    print("Output chest ready for items on " .. outputChestSide .. " side")
    return true
end

local function processBatch(batchId, quantity, inputChestSide, outputChestSide, redstoneSide)
    local blastTime = getBlastTime(quantity)
    
    print("[Batch " .. batchId .. "] Starting - " .. quantity .. " items (" .. blastTime .. "s)")
    
    -- Wait for blasting to complete
    sleep(blastTime)
    
    print("[Batch " .. batchId .. "] Complete! Sending redstone pulse...")
    
    -- Send 10-tick redstone pulse
    sendRedstonePulse(redstoneSide, 10)
    
    print("[Batch " .. batchId .. "] Finished")
    return true
end

local function blast(inputChestSide, outputChestSide, redstoneSide)
    inputChestSide = inputChestSide or "left"
    outputChestSide = outputChestSide or "right"
    redstoneSide = redstoneSide or "back"
    
    -- Check input chest and get items to process (max 16)
    local quantity = transferFromInputChest(inputChestSide, 16)
    
    if quantity == 0 then
        print("No items to process in input chest")
        return false
    end
    
    -- Check output chest availability
    transferToOutputChest(outputChestSide)
    
    -- Process single batch
    return processBatch(1, quantity, inputChestSide, outputChestSide, redstoneSide)
end

local function blastContinuous(inputChestSide, outputChestSide, redstoneSide)
    inputChestSide = inputChestSide or "left"
    outputChestSide = outputChestSide or "right"
    redstoneSide = redstoneSide or "back"
    
    print("Starting continuous blasting mode...")
    print("Press Ctrl+C to stop")
    print("Multiple batches can run simultaneously")
    
    local batchCounter = 0
    local activeBatches = {}
    
    while true do
        local totalItems = countItemsInChest(inputChestSide)
        
        if totalItems >= 16 then
            -- Start new batch if we have enough items
            batchCounter = batchCounter + 1
            local quantity = transferFromInputChest(inputChestSide, 16)
            
            if quantity > 0 then
                print("\n--- Starting Batch " .. batchCounter .. " ---")
                
                -- Start batch processing in parallel
                local co = coroutine.create(function()
                    processBatch(batchCounter, quantity, inputChestSide, outputChestSide, redstoneSide)
                end)
                
                table.insert(activeBatches, co)
                coroutine.resume(co)
            end
        elseif totalItems > 0 and totalItems < 16 then
            -- Process remaining items if less than 16
            batchCounter = batchCounter + 1
            local quantity = transferFromInputChest(inputChestSide, totalItems)
            
            if quantity > 0 then
                print("\n--- Starting Final Batch " .. batchCounter .. " (" .. quantity .. " items) ---")
                
                local co = coroutine.create(function()
                    processBatch(batchCounter, quantity, inputChestSide, outputChestSide, redstoneSide)
                end)
                
                table.insert(activeBatches, co)
                coroutine.resume(co)
            end
        end
        
        -- Resume all active batches
        for i = #activeBatches, 1, -1 do
            local co = activeBatches[i]
            if coroutine.status(co) == "suspended" then
                coroutine.resume(co)
            elseif coroutine.status(co) == "dead" then
                table.remove(activeBatches, i)
            end
        end
        
        -- Show status
        if #activeBatches > 0 then
            print("Active batches: " .. #activeBatches)
        elseif totalItems == 0 then
            print("Waiting for items in input chest...")
        end
        
        sleep(1) -- Check every second
    end
end

local function autoBlaster(config)
    print("=== Auto Blaster Started ===")
    print("Input chest: " .. config.inputChest)
    print("Output chest: " .. config.outputChest)
    print("Redstone side: " .. config.redstoneSide)
    print("Monitoring for items... Press Ctrl+C to stop")
    
    local lastItemCount = 0
    local batchCounter = 0
    local activeBatches = {}
    
    while true do
        local currentItemCount = countItemsInChest(config.inputChest)
        
        -- Detect when items are added
        if currentItemCount > lastItemCount and currentItemCount >= 16 then
            print("\nItems detected! Starting batch processing...")
            
            -- Process all available items in 16-item batches
            while countItemsInChest(config.inputChest) >= 16 do
                batchCounter = batchCounter + 1
                local quantity = transferFromInputChest(config.inputChest, 16)
                
                if quantity > 0 then
                    print("Starting Batch " .. batchCounter .. " (" .. quantity .. " items)")
                    
                    -- Start batch processing in parallel
                    local co = coroutine.create(function()
                        processBatch(batchCounter, quantity, config.inputChest, config.outputChest, config.redstoneSide)
                    end)
                    
                    table.insert(activeBatches, co)
                    coroutine.resume(co)
                end
                
                sleep(0.1) -- Small delay between batch starts
            end
        end
        
        -- Resume all active batches
        for i = #activeBatches, 1, -1 do
            local co = activeBatches[i]
            if coroutine.status(co) == "suspended" then
                coroutine.resume(co)
            elseif coroutine.status(co) == "dead" then
                table.remove(activeBatches, i)
            end
        end
        
        lastItemCount = currentItemCount
        
        -- Show status occasionally
        if #activeBatches > 0 then
            print("Active batches: " .. #activeBatches .. " | Items in chest: " .. currentItemCount)
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
        print("  Input chest: " .. config.inputChest)
        print("  Output chest: " .. config.outputChest)
        print("  Redstone side: " .. config.redstoneSide)
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