local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

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

local Services = assert(loadModuleSafe("services.lua"), "Failed to load Services")
local Config = assert(loadModuleSafe("config.lua"), "Failed to load Config")
local State = loadModuleSafe("state.lua") or {}

local ErrorTypes = {
	TEAM_CHANGE = "TeamChangeError",
	POSITION = "PositionError",
	CHARACTER = "CharacterError",
	EVENT = "EventError",
	TELEPORT = "TeleportError",
	PLATFORM = "PlatformError",
	VIEW = "ViewError",
	COMMAND = "CommandError",
	EXCEPTION = "ExceptionError"
}

local function notify(title, message, duration)
	duration = duration or 3
	pcall(function()
		Services.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = message,
			Duration = duration
		})
	end)
end

local function debugLog(feature, message)
	if Config.DEBUG then
		warn(string.format("[%s] %s", feature, message))
	end
end

local function handleError(errorType, message, context)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local errorData = {
		timestamp = timestamp,
		type = errorType,
		message = message,
		context = context
	}
	debugLog("ErrorHandler", string.format("Type: %s | Message: %s | Context: %s", errorType, message, tostring(context)))
	task.spawn(function() notify("Error", message) end)
	if State.errorLog then
		table.insert(State.errorLog, errorData)
	end
	return false, errorData
end

return {
	Types = ErrorTypes,
	notify = notify,
	debugLog = debugLog,
	handleError = handleError
}
