local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local Utils = loadstring(game:HttpGet(BASE_URL .. "utils.lua"))()

local function toggleKillAura(enable: boolean)
    State.aura.enabled = enable
    if enable then
        State.aura.mainLoop = task.spawn(function()
            while State.aura.enabled do
                local success, err = Utils.pcallWithRetry(function()
                    local localPlayer = Services.Players.LocalPlayer
                    if localPlayer and localPlayer.Character then
                        local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local meleeEvent = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
                            if meleeEvent then
                                for _, player in ipairs(Services.Players:GetPlayers()) do
                                    if player ~= localPlayer and player.Character then
                                        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                                        if targetRoot 
                                        and player.Character:FindFirstChild("Humanoid") 
                                        and player.Character.Humanoid.Health > 0 
                                        and not player.Character:FindFirstChildOfClass("ForceField") then
                                            local distance = (targetRoot.Position - root.Position).Magnitude
                                            if distance <= Config.AURA.RADIUS then
                                                meleeEvent:FireServer(player)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end, 3)
                
                if not success then
                    Errors.debugLog("Kill Aura", "Error: " .. tostring(err))
                end
                
                task.wait(Config.AURA.CHECK_INTERVAL)
            end
        end)
        Errors.notify("Kill Aura", "Enabled")
    else
        if State.aura.mainLoop then
            task.cancel(State.aura.mainLoop)
            State.aura.mainLoop = nil
        end
        Errors.notify("Kill Aura", "Disabled")
    end
end

return {
    toggle = toggleKillAura
}