-- errors.lua
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

-- Load core modules with verification
local function loadModuleSafe(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path))()
    end)
    if not success then
        warn("Failed to load module: " .. path)
        return nil
    end
    task.wait(0.1)
    return result
end

-- Load dependencies
local Services = loadModuleSafe("services.lua")
if not Services then error("Services module failed to load") end

local Config = loadModuleSafe("config.lua")
if not Config then error("Config module failed to load") end

local State = loadModuleSafe("state.lua") or {}

-- Error type definitions
local ErrorTypes = {
    TEAM_CHANGE = "TeamChangeError",
    POSITION = "PositionError",
    CHARACTER = "CharacterError",
    EVENT = "EventError",
    TELEPORT = "TeleportError",
    PLATFORM = "PlatformError",
    VIEW = "ViewError",
    COMMAND = "CommandError",
    EXCEPTION = "ExceptionError" -- Added missing exception type
}

-- Notification helper
local function notify(title: string, message: string, duration: number?)
    duration = duration or 3
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration
        })
    end)
end

-- Debug logging
local function debugLog(feature: string, message: string)
    if Config.DEBUG then
        warn(string.format("[%s] %s", feature, message))
    end
end

-- Main error handler
local function handleError(errorType: string, message: string, context: any?)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local errorData = {
        timestamp = timestamp,
        type = errorType,
        message = message,
        context = context
    }
    
    debugLog("ErrorHandler", string.format("Type: %s | Message: %s | Context: %s", errorType, message, tostring(context)))
    
    notify("Error", message)
    
    -- Optionally log to a remote server or save to State
    -- Example:
    -- table.insert(State.errorLog, errorData)
    
    return false, errorData
end

return {
    Types = ErrorTypes,
    notify = notify,
    debugLog = debugLog,
    handleError = handleError
}