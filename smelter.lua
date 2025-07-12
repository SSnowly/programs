-- Smelter Control Program
-- Handles smelting times based on quantity and sends redstone pulses

local function getSmeltTime(quantity)
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

local function smelt(quantity, redstoneSide)
    redstoneSide = redstoneSide or "back"
    
    if quantity < 1 or quantity > 64 then
        print("Error: Quantity must be between 1 and 64")
        return false
    end
    
    local smeltTime = getSmeltTime(quantity)
    
    print("Starting smelting process...")
    print("Quantity: " .. quantity .. " items")
    print("Smelt time: " .. smeltTime .. " seconds")
    
    -- Wait for smelting to complete
    sleep(smeltTime)
    
    print("Smelting complete! Sending redstone pulse...")
    
    -- Send 10-tick redstone pulse
    sendRedstonePulse(redstoneSide, 10)
    
    print("Redstone pulse sent (10 ticks)")
    return true
end

-- Main program
local function main()
    print("=== Smelter Control System ===")
    print("Usage: smelt(quantity, [redstoneSide])")
    print("Quantity ranges:")
    print("  1-16 items: 7.5s")
    print("  17-32 items: 15s")
    print("  33-48 items: 22.5s")
    print("  49-64 items: 30s")
    print("Default redstone side: back")
    print()
    
    -- Example usage
    if arg and arg[1] then
        local quantity = tonumber(arg[1])
        local side = arg[2] or "back"
        
        if quantity then
            smelt(quantity, side)
        else
            print("Error: Invalid quantity argument")
        end
    else
        print("Enter quantity to smelt (1-64):")
        local input = io.read()
        local quantity = tonumber(input)
        
        if quantity then
            smelt(quantity)
        else
            print("Error: Invalid quantity entered")
        end
    end
end

-- Export functions for use in other programs
_G.smelt = smelt
_G.getSmeltTime = getSmeltTime
_G.sendRedstonePulse = sendRedstonePulse

-- Run main program if executed directly
if not _G.SMELTER_LOADED then
    _G.SMELTER_LOADED = true
    main()
end 