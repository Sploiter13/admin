local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local Utils = loadstring(game:HttpGet(BASE_URL .. "utils.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function killTargets(targetType: string, loop: boolean)
    local success, err = pcall(function()
        local targets = Utils.getTargets(targetType)
        if #targets == 0 then return Errors.handleError(Errors.Types.COMMAND, "No valid targets found", targetType) end

        local meleeEvent = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
        if not meleeEvent then return Errors.handleError(Errors.Types.EVENT, "MeleeEvent not found") end

        State.kill.enabled = loop
        if loop then
            State.kill.mainLoop = task.spawn(function()
                while State.kill.enabled do
                    for _, target in ipairs(targets) do
                        if not target.Character then continue end
                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        
                        if targetRoot and humanoid and humanoid.Health > 0 then
                            local localPlayer = Services.Players.LocalPlayer
                            if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                -- Continuous kill attempts with instant teleports
                                local startTime = tick()
                                while humanoid.Health > 0 and (tick() - startTime) < Config.KILL.FF_WAIT do
                                    if not target.Character:FindFirstChildOfClass("ForceField") then
                                        -- Predict target movement and teleport
                                        local targetVelocity = targetRoot.Velocity
                                        local predictedCFrame = targetRoot.CFrame + targetVelocity * 0.1
                                        localPlayer.Character.HumanoidRootPart.CFrame = predictedCFrame * CFrame.new(0, 0, 2)
                                        meleeEvent:FireServer(target)
                                    end
                                    task.wait(0.03) -- Reduced wait time for faster updates
                                end
                            end
                        end
                    end
                    task.wait(0.1) -- Reduced interval
                end
            end)
        else
            -- Single kill with aggressive tracking
            for _, target in ipairs(targets) do
                if not target.Character then continue end
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = target.Character:FindFirstChild("Humanoid")
                
                if targetRoot and humanoid and humanoid.Health > 0 then
                    local localPlayer = Services.Players.LocalPlayer
                    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local startTime = tick()
                        -- Rapid kill attempts
                        while humanoid.Health > 0 and (tick() - startTime) < Config.KILL.FF_WAIT do
                            if not target.Character:FindFirstChildOfClass("ForceField") then
                                localPlayer.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                                meleeEvent:FireServer(target)
                            end
                            task.wait(0.03)
                        end
                    end
                end
            end
        end
    end)

    if not success then
        Errors.handleError(Errors.Types.COMMAND, "Failed to execute kill command", err)
    end
end

return {
    killTargets = killTargets
}