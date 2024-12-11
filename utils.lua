local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()

local function pcallWithRetry(callback: () -> any, retries: number): (boolean, any)
    local attempts = 0
    while attempts < retries do
        local success, result = pcall(callback)
        if success then
            return true, result
        end
        attempts += 1
        Errors.debugLog("Error", string.format("Attempt %d failed: %s", attempts, tostring(result)))
        task.wait(0.1)
    end
    return false, "Max retries reached"
end

local function findPlayer(name: string): Player?
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player.Name:lower():find(name:lower(), 1, true) then
            return player
        end
    end
    return nil
end

local function getTargets(targetType: string): {Player}
    local targets = {}
    local localPlayer = Services.Players.LocalPlayer

    if targetType:lower() == "others" then
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(targets, player)
            end
        end
        return targets
    end

    if targetType:sub(1, 5):lower() == "team " then
        local teamName = targetType:sub(6)
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= localPlayer and player.Team and 
               player.Team.Name:lower():find(teamName:lower(), 1, true) then
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