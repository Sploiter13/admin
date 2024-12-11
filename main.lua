local function loadModuleWithRetry(url, maxAttempts)
    maxAttempts = maxAttempts or 3
    local attempts = 0
    local lastError
    
    while attempts < maxAttempts do
        local success, result = pcall(function()
            local content = game:HttpGet(url)
            if not content then return nil, "No content received" end
            return loadstring(content)()
        end)
        
        if success and result then
            return result
        end
        
        attempts += 1
        lastError = result
        if attempts < maxAttempts then
            warn(string.format("[Attempt %d/%d] Failed to load %s: %s", 
                attempts, maxAttempts, url, tostring(lastError)))
            task.wait(1) -- Delay between retries
        end
    end
    
    return nil, lastError
end

local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"


local function initializeScript()
    -- Initialize global Features first
    _G.Features = {}
    
    -- Core modules loading
    local coreModules = {
        Services = "services.lua",
        Config = "config.lua",
        State = "state.lua",
        Errors = "errors.lua",
        Utils = "utils.lua"
    }
    
    local modules = {}
    
    -- Load core modules
    for name, path in pairs(coreModules) do
        local result, err = loadModuleWithRetry(BASE_URL .. path)
        if not result then
            error(string.format("Failed to load core module %s: %s", name, err))
        end
        modules[name] = result
        _G[name] = result -- Add to global scope
        print(string.format("Loaded %s successfully", name))
    end
    
    -- Initialize global state
    _G.State = modules.State
    
    -- Feature modules
    local featureModules = {
        Forcefield = "forcefield.lua",
        Kill = "kill.lua",
        KillAura = "killaura.lua",
        Invisibility = "invisibility.lua",
        View = "view.lua",
        Goto = "goto.lua"
    }
    
    -- Load features directly into _G.Features
    local loadedFeatures = {}
    for name, path in pairs(featureModules) do
        local result, err = loadModuleWithRetry(BASE_URL .. "features/" .. path)
        if result then
            _G.Features[name] = result
            table.insert(loadedFeatures, name)
            print(string.format("Loaded feature %s successfully", name))
        else
            warn(string.format("Failed to load feature %s: %s", name, err))
        end
    end
    
    -- Load command handler and cleanup last
    local Commands = loadModuleWithRetry(BASE_URL .. "commands.lua")
    if not Commands then
        error("Failed to load commands module")
    end
    
    local Cleanup = loadModuleWithRetry(BASE_URL .. "cleanup.lua")
    if not Cleanup then
        warn("Failed to load cleanup module")
    end
    
    -- Debug verification
    if not _G.Features then
        error("Features table not initialized")
    end
    
    -- Set up handlers with debug logging
    modules.Services.Players.LocalPlayer.Chatted:Connect(function(message)
        if _G.Features then
            Commands.handle(message)
        else
            warn("Features table not available during command execution")
        end
    end)
    
    print("Script initialized successfully")
    print("Loaded features: " .. table.concat(loadedFeatures, ", "))
    return modules
end

-- Execute with error handling
local success, result = pcall(initializeScript)
if not success then
    warn("Initialization failed: " .. tostring(result))
end