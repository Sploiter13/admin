local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function toggleForcefield(enable: boolean)
    State.ff.enabled = enable
    if enable then
        local localPlayer = Services.Players.LocalPlayer
        
        -- Position tracking loop
        task.spawn(function()
            while State.ff.enabled do
                if localPlayer and localPlayer.Character then
                    local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        State.ff.lastCFrame = root.CFrame
                    end
                end
                task.wait(0.01)
            end
        end)

        -- Initial team switch
        local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
        if teamEvent then
            teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
            task.wait(0.3)
            teamEvent:FireServer(Config.FF.TEAMS.BLUE)
        end

        -- FF monitoring and position restore loop
        task.spawn(function()
            while State.ff.enabled do
                if localPlayer and localPlayer.Character then
                    local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                        local ffStartTime = tick()
                        local hasFF = false

                        if forceField then
                            hasFF = true
                            -- Track FF duration
                            while forceField and State.ff.enabled do
                                if (tick() - ffStartTime) > 2.8 then
                                    break
                                end
                                task.wait(0.03)
                                forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                            end
                        end

                        -- Team switch and position restore when FF expires
                        if hasFF and not State.ff.changingTeam and State.ff.lastCFrame then
                            State.ff.changingTeam = true
                            
                            local savedCFrame = State.ff.lastCFrame
                            
                            if teamEvent then
                                teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                                task.wait(0.3)
                                teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                                task.wait(0.3)
                                
                                -- Restore position with validation
                                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    pcall(function()
                                        localPlayer.Character.HumanoidRootPart.CFrame = savedCFrame
                                        localPlayer.Character:MoveTo(savedCFrame.Position)
                                    end)
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