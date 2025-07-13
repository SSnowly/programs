-- SnowyOS Web Installer
-- Downloads and installs SnowyOS from the internet
-- Usage: wget run https://raw.githubusercontent.com/your-repo/snowyos/main/installer.lua

print("SnowyOS Web Installer")
print("=====================")
print()
print("Downloading SnowyOS files...")

-- Base URL for the files (you'll need to host these on GitHub or similar)
local baseUrl = "https://raw.githubusercontent.com/SSnowly/programs/refs/heads/main/snowyos"

-- Files to download
local files = {
    {url = "startup.lua", path = "startup.lua"},
    {url = "snowyos/boot.lua", path = "snowyos/boot.lua"},
    {url = "snowyos/install.lua", path = "snowyos/install.lua"},
    {url = "snowyos/login.lua", path = "snowyos/login.lua"}
}

-- Create directories if they don't exist
local function createDir(path)
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

-- Download a file
local function downloadFile(url, path)
    print("Downloading " .. path .. "...")
    
    createDir(path)
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        
        print("✓ " .. path .. " downloaded successfully")
        return true
    else
        print("✗ Failed to download " .. path)
        return false
    end
end

-- Main installation process
local function install()
    local success = true
    
    for _, file in ipairs(files) do
        if not downloadFile(baseUrl .. file.url, file.path) then
            success = false
        end
    end
    
    if success then
        print()
        print("✓ All files downloaded successfully!")
        print()
        print("SnowyOS is now ready to install.")
        print("The system will restart and begin installation...")
        sleep(2)
        
        -- Start the installation
        os.reboot()
    else
        print()
        print("✗ Installation failed!")
        print("Some files could not be downloaded.")
        print("Please check your internet connection and try again.")
    end
end

-- Check if HTTP is enabled
if not http then
    print("✗ HTTP is not enabled!")
    print("Please enable HTTP in your ComputerCraft config:")
    print("1. Go to config/computercraft-common.toml")
    print("2. Set http_enable = true")
    print("3. Restart your world")
    return
end

-- Start installation
install() 