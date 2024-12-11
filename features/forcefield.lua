local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()
local RunService = game:GetService("RunService")

local function toggleForcefield(enable: boolean)
    local localPlayer = Services.Players.LocalPlayer
    if not localPlayer then return Errors.notify("Error", "Player not found") end
    
    State.ff.enabled = enable
    if enable then
        -- Ultra-frequent position tracking
        local positionConnection
        positionConnection = RunService.Heartbeat:Connect(function()
            if State.ff.enabled and localPlayer.Character then
                local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    State.ff.lastPosition = root.Position
                    State.ff.lastCFrame = root.CFrame
                    State.ff.lastVelocity = root.Velocity
                end
            else
                positionConnection:Disconnect()
            end
        end)

        -- Main FF loop
        task.spawn(function()
            while State.ff.enabled do
                local character = localPlayer.Character
                if not character then task.wait(0.1) continue end

                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then task.wait(0.1) continue end

                local forceField = character:FindFirstChildOfClass("ForceField")
                if forceField then
                    local ffStartTime = tick()
                    
                    while forceField and State.ff.enabled do
                        if (tick() - ffStartTime) > 2.7 then
                            break
                        end
                        task.wait(0.03)
                        forceField = character:FindFirstChildOfClass("ForceField")
                    end
                end

                if not State.ff.changingTeam then
                    State.ff.changingTeam = true
                    
                    local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
                    if teamEvent and State.ff.lastCFrame then
                        local savedCFrame = State.ff.lastCFrame
                        local savedVelocity = State.ff.lastVelocity
                        
                        teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
                        task.wait(0.3)
                        teamEvent:FireServer(Config.FF.TEAMS.BLUE)
                        task.wait(0.3)

                        -- Precise position restoration with velocity
                        if character and root then
                            pcall(function()
                                root.CFrame = savedCFrame
                                root.Velocity = savedVelocity
                                character:MoveTo(savedCFrame.Position)
                            end)
                        end
                    end
                    State.ff.changingTeam = false
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