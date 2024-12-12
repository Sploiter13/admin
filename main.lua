-- init.lua

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Constants
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5 -- Seconds between retries

-- Module Cache
local moduleCache = {}

-- Utility function to delay execution without blocking
local function delayedWait(seconds)
    local startTime = tick()
    while tick() - startTime < seconds do
        task.wait(0.1)
    end
end

-- Module Loader with Retry Logic
local function loadModule(path)
    if moduleCache[path] then
        return moduleCache[path]
    end

    local url = BASE_URL .. path
    print(string.format("[Init] Attempting to load module: %s", url))

    for attempt = 1, MAX_RETRIES do
        local success, contentOrError = pcall(function()
            return game:HttpGet(url, true) -- 'true' to bypass any caching
        end)

        if success and contentOrError then
            if #contentOrError < 10 then
                warn(string.format("[Init] Module content too small for %s. Attempt %d/%d", path, attempt, MAX_RETRIES))
            else
                local loadSuccess, result = pcall(function()
                    return loadstring(contentOrError)()
                end)

                if loadSuccess and result then
                    moduleCache[path] = result
                    print(string.format("[Init] Successfully loaded module: %s", path))
                    return result
                else
                    warn(string.format("[Init] Error executing module %s: %s. Attempt %d/%d", path, tostring(result), attempt, MAX_RETRIES))
                end
            end
        else
            warn(string.format("[Init] Failed to download module %s: %s. Attempt %d/%d", path, tostring(contentOrError), attempt, MAX_RETRIES))
        end

        if attempt < MAX_RETRIES then
            print(string.format("[Init] Retrying to load module: %s after %0.1f seconds...", path, RETRY_DELAY))
            delayedWait(RETRY_DELAY)
        end
    end

    error(string.format("[Init] All attempts failed to load module: %s", path))
end

-- Initialize Global Tables
_G.Features = {}
_G.State = {}

-- Core Modules Loading
local function loadCoreModules()
    print("[Init] Loading core modules...")
    local coreModules = {
        Services = "services.lua",
        Config = "config.lua",
        State = "state.lua",
        Errors = "errors.lua",
        Utils = "utils.lua"
    }

    local modules = {}
    for name, path in pairs(coreModules) do
        modules[name] = loadModule(path)
        _G[name] = modules[name]
    end

    -- Initialize global State
    _G.State = modules.State
    print("[Init] Core modules loaded successfully.")
    return modules
end

-- Feature Modules Loading
local function loadFeatureModules()
    print("[Init] Loading feature modules...")
    local featureModules = {
        Forcefield = "forcefield.lua",
        Kill = "kill.lua",
        KillAura = "killaura.lua",
        Invisibility = "invisibility.lua",
        View = "view.lua",
        Goto = "goto.lua"
    }

    local loadedFeatures = {}
    for name, path in pairs(featureModules) do
        local status, result = pcall(function()
            return loadModule("features/" .. path)
        end)

        if status and result then
            _G.Features[name] = result
            table.insert(loadedFeatures, name)
            print(string.format("[Init] Feature loaded: %s", name))
        else
            warn(string.format("[Init] Failed to load feature: %s - %s", name, tostring(result)))
        end
    end

    print(string.format("[Init] Feature modules loading complete. Loaded features: %s", table.concat(loadedFeatures, ", ")))
end

-- Load Commands Module
local function loadCommandsModule()
    print("[Init] Loading commands module...")
    local Commands = loadModule("commands.lua")
    if not Commands then
        error("[Init] Commands module failed to load.")
    end
    print("[Init] Commands module loaded successfully.")
    return Commands
end

-- Setup Chat Command Handler
local function setupChatHandler(Commands)
    print("[Init] Setting up chat command handler...")
    local LocalPlayer = Players.LocalPlayer

    if not LocalPlayer then
        error("[Init] LocalPlayer not found.")
    end

    LocalPlayer.Chatted:Connect(function(message)
        if _G.Features and Commands and Commands.handle then
            Commands.handle(message)
        else
            warn("[Init] Unable to handle command - Features or Commands not available.")
        end
    end)

    print("[Init] Chat command handler set up successfully.")
end

-- Initialize Script
local function initializeScript()
    print("[Init] Starting initialization...")

    -- Load Core Modules
    loadCoreModules()

    -- Load Feature Modules
    loadFeatureModules()

    -- Load Commands Module
    local Commands = loadCommandsModule()

    -- Setup Chat Handler
    setupChatHandler(Commands)

    print("[Init] Initialization complete. All modules loaded.")
end

-- Execute Initialization with Error Handling
local success, err = pcall(initializeScript)
if not success then
    warn(string.format("[Init] CRITICAL ERROR during initialization: %s", tostring(err)))
    -- Optional: Implement fallback or cleanup here
end