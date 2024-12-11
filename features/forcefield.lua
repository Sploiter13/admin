local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function toggleForcefield(enable: boolean)
    State.ff.enabled = enable
    if enable then
        task.spawn(function()
            while State.ff.enabled do
                local localPlayer = Services.Players.LocalPlayer
                if localPlayer and localPlayer.Character then
                    local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        -- Update position every frame
                        if tick() - (State.ff.lastUpdate or 0) >= 0.03 then
                            State.ff.lastPosition = humanoidRootPart.Position
                            State.ff.lastOrientation = humanoidRootPart.CFrame - State.ff.lastPosition
                            State.ff.lastUpdate = tick()
                        end
                        
                        local forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                        if forceField then
                            while forceField and State.ff.enabled do
                                task.wait(0.03)
                                forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                            end
                        end
                        
                        if not State.ff.changingTeam and State.ff.lastPosition then
                            State.ff.changingTeam = true
                            
                            local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
                            if teamEvent then
                                -- Store current position
                                local savedPos = State.ff.lastPosition
                                local savedOri = State.ff.lastOrientation
                                
                                -- Rapid team switching
                                teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                                task.wait(0.1) -- Reduced delay
                                teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                                task.wait(0.1) -- Reduced delay
                                
                                -- Instant position restoration
                                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    localPlayer.Character:MoveTo(savedPos)
                                    localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savedPos) * savedOri
                                end
                            end
                            State.ff.changingTeam = false
                        end
                    end
                end
                task.wait(0.03) -- Reduced main loop interval
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