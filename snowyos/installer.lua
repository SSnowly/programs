-- SnowyOS Web Installer
-- Downloads and installs SnowyOS from the internet

print("SnowyOS Web Installer")
print("=====================")
print()
print("Downloading SnowyOS files...")

-- Base URL for the files
local baseUrl = "https://raw.githubusercontent.com/SSnowly/programs/refs/heads/main/snowyos/"

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
    print("  URL: " .. url)
    
    createDir(path)
    
    local response, error = http.get(url)
    if response then
        local content = response.readAll()
        local responseCode = response.getResponseCode()
        response.close()
        
        if responseCode == 200 then
            local file = fs.open(path, "w")
            file.write(content)
            file.close()
            
            print("✓ " .. path .. " downloaded successfully (" .. #content .. " bytes)")
            return true
        else
            print("✗ HTTP Error " .. responseCode .. " for " .. path)
            if responseCode == 404 then
                print("  File not found on server")
            elseif responseCode == 403 then
                print("  Access forbidden - check if repository is public")
            elseif responseCode == 500 then
                print("  Server error")
            end
            return false
        end
    else
        print("✗ Failed to download " .. path)
        if error then
            print("  Error: " .. error)
        else
            print("  Possible causes:")
            print("  - Network connectivity issues")
            print("  - HTTP not enabled in CC config")
            print("  - URL is incorrect")
            print("  - Server is down")
        end
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

-- Test connectivity and setup
local function testSetup()
    print("Testing system setup...")
    
    -- Check if HTTP is enabled
    if not http then
        print("✗ HTTP is not enabled!")
        print("Please enable HTTP in your ComputerCraft config:")
        print("1. Go to config/computercraft-common.toml")
        print("2. Set http_enable = true")
        print("3. Restart your world")
        return false
    end
    print("✓ HTTP is enabled")
    
    -- Test basic connectivity
    print("Testing connectivity to GitHub...")
    local testResponse, testError = http.get("https://api.github.com")
    if testResponse then
        local code = testResponse.getResponseCode()
        testResponse.close()
        if code == 200 then
            print("✓ GitHub is reachable")
        else
            print("✗ GitHub returned HTTP " .. code)
            return false
        end
    else
        print("✗ Cannot reach GitHub")
        if testError then
            print("  Error: " .. testError)
        end
        return false
    end
    
    -- Test if we can reach the specific repository
    print("Testing repository access...")
    local repoTest = http.get(baseUrl .. "startup.lua")
    if repoTest then
        local code = repoTest.getResponseCode()
        repoTest.close()
        if code == 200 then
            print("✓ Repository is accessible")
            return true
        else
            print("✗ Repository returned HTTP " .. code)
            if code == 404 then
                print("  Repository or files not found")
            elseif code == 403 then
                print("  Repository might be private")
            end
            return false
        end
    else
        print("✗ Cannot access repository")
        return false
    end
end

-- Run tests first
if not testSetup() then
    print()
    print("Setup test failed. Cannot proceed with installation.")
    print("Please check the issues above and try again.")
    return
end

print()
print("All tests passed! Starting installation...")
print()

-- Start installation
install() 