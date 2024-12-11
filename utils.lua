-- utils.lua
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

local Errors = loadModuleSafe("errors.lua")
if not Errors or not Errors.handleError or not Errors.debugLog then
    error("Errors module is missing required functions")
end

local State = loadModuleSafe("state.lua") or {}

-- Retry mechanism for pcall
local function pcallWithRetry(callback: () -> any, retries: number): (boolean, any)
    for attempt = 1, retries do
        local success, result = pcall(callback)
        if success then
            return true, result
        end
        Errors.debugLog("Error", string.format("Attempt %d failed: %s", attempt, tostring(result)))
        task.wait(0.1)
    end
    return false, "Max retries reached"
end

-- Find a player by name (case-insensitive, partial match)
local function findPlayer(name: string): Player?
    local lowerName = name:lower()
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Name:lower():find(lowerName, 1, true) then
            return player
        end
    end
    return nil
end

-- Get target players based on targetType
local function getTargets(targetType: string): {Player}
    local targets = {}
    local localPlayer = Services.Players.LocalPlayer
    local lowerType = targetType:lower()

    if lowerType == "others" then
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(targets, player)
            end
        end
        return targets
    end

    if lowerType:sub(1, 5) == "team " then
        local teamName = targetType:sub(6):lower()
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and player.Team.Name:lower():find(teamName, 1, true) then
                table.insert(targets, player)
            end
        end
        if #targets > 0 then
            return targets
        end
    end

    local target = findPlayer(targetType)
    if target then
        table.insert(targets, target)
    end

    return targets
end

return {
    pcallWithRetry = pcallWithRetry,
    findPlayer = findPlayer,
    getTargets = getTargets
}