local Services = require("services")
local Config = require("config")
local Errors = require("errors")

local function toggleForcefield(enable: boolean)
    State.ff.enabled = enable
    if enable then
        task.spawn(function()
            while State.ff.enabled do
                local localPlayer = Services.Players.LocalPlayer
                if localPlayer and localPlayer.Character then
                    local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local pos = humanoidRootPart.Position
                        local ori = humanoidRootPart.CFrame - pos
                        
                        local forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                        if forceField then
                            while forceField and State.ff.enabled do
                                task.wait(0.1)
                                forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                                pos = humanoidRootPart.Position
                                ori = humanoidRootPart.CFrame - pos
                            end
                        end
                        
                        if not State.ff.changingTeam then
                            State.ff.changingTeam = true
                            
                            local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
                            if teamEvent then
                                pos = humanoidRootPart.Position
                                ori = humanoidRootPart.CFrame - pos
                                
                                teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                                task.wait(0.3)
                                teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                                task.wait(0.3)
                                
                                for i = 1, 5 do
                                    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        localPlayer.Character:MoveTo(pos)
                                        localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos) * ori
                                        break
                                    end
                                    task.wait(0.1)
                                end
                            end
                            State.ff.changingTeam = false
                        end
                    end
                end
                task.wait(0.5)
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