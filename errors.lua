local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()

-- Rest of errors.lua code...

-- Error type definitions
local ErrorTypes = {
    TEAM_CHANGE = "TeamChangeError",
    POSITION = "PositionError", 
    CHARACTER = "CharacterError",
    EVENT = "EventError",
    TELEPORT = "TeleportError",
    PLATFORM = "PlatformError",
    VIEW = "ViewError",
    COMMAND = "CommandError"
}

-- Notification helper
local function notify(title: string, message: string)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 3
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
    
    pcall(function()
        notify("Error", message)
    end)
    
    return false, errorData
end

return {
    Types = ErrorTypes,
    notify = notify,
    debugLog = debugLog,
    handleError = handleError
}