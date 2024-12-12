-- forcefield.lua

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
local State = loadModuleSafe("state.lua") or {}

local RunService = game:GetService("RunService")

-- Toggle Forcefield feature
local function toggleForcefield(enable: boolean)
    local localPlayer = Services.Players.LocalPlayer
    if not localPlayer then 
        Errors.notify("Error", "Player not found")
        return 
    end
    
    State.ff.enabled = enable

    if enable then
        -- Ultra-frequent position tracking
        State.ff.positionConnection = RunService.Heartbeat:Connect(function()
            if State.ff.enabled and localPlayer.Character then
                local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    State.ff.lastPosition = root.Position
                    State.ff.lastCFrame = root.CFrame
                    State.ff.lastVelocity = root.Velocity
                end
            else
                if State.ff.positionConnection then
                    State.ff.positionConnection:Disconnect()
                    State.ff.positionConnection = nil
                end
            end
        end)

        -- Main FF loop
        State.ff.mainLoop = task.spawn(function()
            while State.ff.enabled do
                local character = localPlayer.Character
                if not character then 
                    task.wait(0.1) 
                    continue 
                end

                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then 
                    task.wait(0.1) 
                    continue 
                end

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
                    
                    local teamEvent = workspace:FindFirstChild("Remote") and workspace.Remote:FindFirstChild("TeamEvent")
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
        -- Disable Forcefield feature
        if State.ff.mainLoop then
            task.cancel(State.ff.mainLoop)
            State.ff.mainLoop = nil
        end
        if State.ff.positionConnection then
            State.ff.positionConnection:Disconnect()
            State.ff.positionConnection = nil
        end
        Errors.notify("Forcefield", "Disabled")
    end
end

return {
    toggle = toggleForcefield
}