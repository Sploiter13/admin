-- kill.lua

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

-- Initialize State.kill if not present
State.kill = State.kill or {
    enabled = false,
    mainLoop = nil
}

-- Reference ReplicatedStorage meleeEvent
local meleeEvent = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
if not meleeEvent then
    Errors.handleError(Errors.Types.EVENT, "meleeEvent not found in ReplicatedStorage")
end

-- Toggle Kill feature
local function toggleKill(enable: boolean, loop: boolean)
    State.kill.enabled = enable

    if enable then
        Errors.notify("Kill", "Kill feature enabled.")
        
        if loop then
            -- Start continuous kill attempts with looping
            State.kill.mainLoop = task.spawn(function()
                while State.kill.enabled do
                    local targets = Utils.getTargets("others") -- Assuming getTargets can fetch all other players
                    for _, target in ipairs(targets) do
                        if not target.Character then
                            Errors.debugLog("Kill", "Target character not found for " .. target.Name)
                            continue
                        end

                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = target.Character:FindFirstChild("Humanoid")

                        if targetRoot and humanoid and humanoid.Health > 0 then
                            local localPlayer = Services.Players.LocalPlayer
                            local localCharacter = localPlayer.Character
                            
                            if not localCharacter then
                                Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
                                continue
                            end

                            local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
                            if not localRoot then
                                Errors.handleError(Errors.Types.POSITION, "Local HumanoidRootPart not found")
                                continue
                            end

                            -- Continuous kill attempts with instant teleports
                            local startTime = tick()
                            while humanoid.Health > 0 and (tick() - startTime) < Config.KILL.FF_WAIT do
                                if not target.Character:FindFirstChildOfClass("ForceField") then
                                    -- Predict target movement and teleport
                                    local targetVelocity = targetRoot.Velocity
                                    local predictedCFrame = targetRoot.CFrame + targetVelocity * 0.1
                                    local teleportCFrame = predictedCFrame * CFrame.new(0, 0, 2)
                                    
                                    -- Teleport local player to the predicted position
                                    localRoot.CFrame = teleportCFrame
                                    
                                    -- Fire the melee event to attack the target
                                    meleeEvent:FireServer(target)

                                    Errors.debugLog("Kill", "Attacked player: " .. target.Name)
                                end
                                task.wait(0.03) -- Reduced wait time for faster updates
                            end
                        end
                    end
                    task.wait(Config.KILL.INTERVAL) -- Configurable interval between kill cycles
                end
            end)
        else
            -- Single kill with aggressive tracking
            local targets = Utils.getTargets("others")
            for _, target in ipairs(targets) do
                if not target.Character then
                    Errors.debugLog("Kill", "Target character not found for " .. target.Name)
                    continue
                end

                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = target.Character:FindFirstChild("Humanoid")

                if targetRoot and humanoid and humanoid.Health > 0 then
                    local localPlayer = Services.Players.LocalPlayer
                    local localCharacter = localPlayer.Character
                            
                    if not localCharacter then
                        Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
                        continue
                    end

                    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
                    if not localRoot then
                        Errors.handleError(Errors.Types.POSITION, "Local HumanoidRootPart not found")
                        continue
                    end

                    -- Aggressive kill attempt with instant teleport
                    if not target.Character:FindFirstChildOfClass("ForceField") then
                        -- Predict target movement and teleport
                        local targetVelocity = targetRoot.Velocity
                        local predictedCFrame = targetRoot.CFrame + targetVelocity * 0.1
                        local teleportCFrame = predictedCFrame * CFrame.new(0, 0, 2)
                        
                        -- Teleport local player to the predicted position
                        localRoot.CFrame = teleportCFrame
                        
                        -- Fire the melee event to attack the target
                        meleeEvent:FireServer(target)

                        Errors.debugLog("Kill", "Attacked player: " .. target.Name)
                        task.wait(0.03) -- Short wait before next kill attempt
                    end
                end
            end
        end
    else
        -- Disable Kill feature
        if State.kill.mainLoop then
            task.cancel(State.kill.mainLoop)
            State.kill.mainLoop = nil
            Errors.notify("Kill", "Kill feature disabled.")
        end
    end
end

return {
    toggle = toggleKill
}