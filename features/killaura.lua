-- killaura.lua

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
local Services = assert(loadModuleSafe("services.lua"), "Failed to load Services")
local Config = assert(loadModuleSafe("config.lua"), "Failed to load Config")
local Errors = assert(loadModuleSafe("errors.lua"), "Failed to load Errors")
local Utils = assert(loadModuleSafe("utils.lua"), "Failed to load Utils")
local State = loadModuleSafe("state.lua") or {}

-- Initialize State.aura if not present
State.aura = State.aura or {
    enabled = false,
    mainLoop = nil
}

-- Toggle KillAura feature
local function toggleKillAura(enable: boolean)
    State.aura.enabled = enable

    if enable then
        Errors.notify("KillAura", "KillAura enabled.")
        State.aura.mainLoop = task.spawn(function()
            while State.aura.enabled do
                local success, err = Utils.pcallWithRetry(function()
                    local localPlayer = Services.Players.LocalPlayer
                    if not (localPlayer and localPlayer.Character) then
                        Errors.handleError(Errors.Types.CHARACTER, "LocalPlayer or Character not found")
                        return
                    end

                    local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not root then
                        Errors.handleError(Errors.Types.POSITION, "HumanoidRootPart not found")
                        return
                    end

                    local meleeEvent = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
                    if not meleeEvent then
                        Errors.handleError(Errors.Types.EVENT, "meleeEvent not found in ReplicatedStorage")
                        return
                    end

                    for _, player in ipairs(Services.Players:GetPlayers()) do
                        if player ~= localPlayer and player.Character then
                            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                            local humanoid = player.Character:FindFirstChild("Humanoid")
                            local forceField = player.Character:FindFirstChildOfClass("ForceField")

                            if targetRoot and humanoid and humanoid.Health > 0 and not forceField then
                                local distance = (targetRoot.Position - root.Position).Magnitude
                                if distance <= Config.AURA.RADIUS then
                                    meleeEvent:FireServer(player)
                                end
                            end
                        end
                    end
                end, 3) -- Retry up to 3 times

                if not success then
                    Errors.handleError(Errors.Types.EXCEPTION, err)
                end

                task.wait(Config.AURA.INTERVAL)
            end
        end)
    else
        if State.aura.mainLoop then
            task.cancel(State.aura.mainLoop)
            State.aura.mainLoop = nil
            Errors.notify("KillAura", "KillAura disabled.")
        end
    end
end

return {
    toggle = toggleKillAura
}