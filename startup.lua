-- Startup script to download and run the latest smelter from GitHub
-- This ensures you always have the most up-to-date version

local GITHUB_URL = "https://raw.githubusercontent.com/SSnowly/programs/refs/heads/main/smelter.lua"
local LOCAL_FILE = "smelter.lua"

print("=== Smelter Auto-Updater ===")
print("Downloading latest version from GitHub...")

-- Download the latest version
local response = http.get(GITHUB_URL)

if response then
    print("Download successful!")
    
    -- Save to local file
    local file = fs.open(LOCAL_FILE, "w")
    if file then
        file.write(response.readAll())
        file.close()
        response.close()
        
        print("Smelter updated successfully!")
        print("Starting smelter...")
        print()
        
        -- Run the downloaded script
        dofile(LOCAL_FILE)
    else
        print("Error: Could not save file")
        response.close()
    end
else
    print("Error: Could not download from GitHub")
    print("Check your internet connection or modem setup")
    
    -- Try to run existing local version if download fails
    if fs.exists(LOCAL_FILE) then
        print("Using existing local version...")
        dofile(LOCAL_FILE)
    else
        print("No local version found. Cannot start smelter.")
    end
end 