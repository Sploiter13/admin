local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function toggleForcefield(enable: boolean)
    State.ff.enabled = enable
    if enable then
        -- Initial team switch to get FF
        local localPlayer = Services.Players.LocalPlayer
        local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
        if teamEvent then
            teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
            task.wait(0.3)
            teamEvent:FireServer(Config.FF.TEAMS.BLUE)
        end

        -- Position tracking loop
        task.spawn(function()
            while State.ff.enabled do
                if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    State.ff.lastPosition = localPlayer.Character.HumanoidRootPart.Position
                    State.ff.lastOrientation = localPlayer.Character.HumanoidRootPart.CFrame - State.ff.lastPosition
                end
                task.wait(0.01)
            end
        end)

        -- Main FF loop
        task.spawn(function()
            while State.ff.enabled do
                if localPlayer and localPlayer.Character then
                    local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                        local ffStartTime = tick()
                        local hasFF = false

                        if forceField then
                            hasFF = true
                            while forceField and State.ff.enabled do
                                if (tick() - ffStartTime) > 2.8 then
                                    break
                                end
                                task.wait(0.03)
                                forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                            end
                        end

                        if hasFF and not State.ff.changingTeam and State.ff.lastPosition then
                            State.ff.changingTeam = true
                            
                            if teamEvent then
                                local savedPos = State.ff.lastPosition
                                local savedOri = State.ff.lastOrientation
                                
                                teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                                task.wait(0.3)
                                teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                                task.wait(0.3)
                                
                                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    localPlayer.Character:MoveTo(savedPos)
                                    localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savedPos) * savedOri
                                end
                            end
                            State.ff.changingTeam = false
                        end
                    end
                end
                task.wait(0.03)
            end
        end)
        Errors.notify("Forcefield", "Enabled")
    else
        Errors.notify("Forcefield", "Disabled")
    end
end

return {
    toggle = toggleForcefield
}