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
                        -- Update last valid position
                        if tick() - (State.ff.lastUpdate or 0) >= Config.FF.POSITION_UPDATE_INTERVAL then
                            State.ff.lastPosition = humanoidRootPart.Position
                            State.ff.lastOrientation = humanoidRootPart.CFrame - State.ff.lastPosition
                            State.ff.lastUpdate = tick()
                        end
                        
                        local forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                        if forceField then
                            while forceField and State.ff.enabled do
                                task.wait(0.1)
                                forceField = localPlayer.Character:FindFirstChildOfClass("ForceField")
                            end
                        end
                        
                        if not State.ff.changingTeam and State.ff.lastPosition then
                            State.ff.changingTeam = true
                            
                            local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
                            if teamEvent then
                                -- Store current position before team change
                                local savedPos = State.ff.lastPosition
                                local savedOri = State.ff.lastOrientation
                                
                                teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                                task.wait(Config.FF.TEAM_SWITCH_DELAY)
                                teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                                task.wait(Config.FF.TEAM_SWITCH_DELAY)
                                
                                -- Restore position with retries
                                local attempts = 0
                                while attempts < Config.FF.MAX_ATTEMPTS do
                                    if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        local success = pcall(function()
                                            localPlayer.Character:MoveTo(savedPos)
                                            localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savedPos) * savedOri
                                        end)
                                        if success then break end
                                    end
                                    attempts += 1
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