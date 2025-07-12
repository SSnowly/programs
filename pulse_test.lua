-- Simple redstone pulse test script
-- Use this to debug pulse issues

local function sendRedstonePulse(side, ticks)
    print("Sending " .. ticks .. "-tick pulse on " .. side .. " side")
    print("Setting redstone ON...")
    redstone.setOutput(side, true)
    
    local sleepTime = ticks / 20
    print("Sleeping for " .. sleepTime .. " seconds...")
    sleep(sleepTime)
    
    print("Setting redstone OFF...")
    redstone.setOutput(side, false)
    print("Pulse complete!")
end

print("=== Redstone Pulse Test ===")
print("Available sides: left, right, top, bottom, front, back")
print("Enter side to test:")
local side = io.read()

print("Enter pulse length in ticks (e.g., 10, 16, 20):")
local ticks = tonumber(io.read())

if not ticks then
    print("Invalid tick count")
    return
end

print("Testing pulse on " .. side .. " for " .. ticks .. " ticks...")
print()

-- Test the pulse
sendRedstonePulse(side, ticks)

print()
print("Test complete! Check if redstone device received the pulse.")
print("Current redstone state on " .. side .. ": " .. tostring(redstone.getOutput(side))) 