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

-- Initialize State
State.kill = State.kill or {
    enabled = false,
    mainLoop = nil
}

-- Get melee event reference
local meleeEvent = Services.ReplicatedStorage:FindFirstChild("meleeEvent")
if not meleeEvent then
    Errors.handleError(Errors.Types.EVENT, "meleeEvent not found in ReplicatedStorage")
end

-- kill.lua

-- Add default config values if not present
Config.KILL = Config.KILL or {
    MAX_ATTEMPTS = 10,
    FF_WAIT = 3,
    RETRY_DELAY = 0.1,
    INTERVAL = 1,
    TIMEOUT = 3,
    OFFSET = Vector3.new(0, 0, 3)
}

local function killTargets(targetType: string, loop: boolean)
    local success, err = pcall(function()
        -- Validate config values
        if not Config.KILL.TIMEOUT then
            Config.KILL.TIMEOUT = 3
        end
        if not Config.KILL.MAX_ATTEMPTS then
            Config.KILL.MAX_ATTEMPTS = 10
        end

        local targets = Utils.getTargets(targetType)
        if #targets == 0 then
            return Errors.handleError(Errors.Types.COMMAND, "No valid targets found", targetType)
        end

        local localPlayer = Services.Players.LocalPlayer
        if not localPlayer or not localPlayer.Character then
            return Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
        end

        local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            return Errors.handleError(Errors.Types.CHARACTER, "Local HumanoidRootPart not found")
        end

        -- Store original position
        local originalCFrame = localRoot.CFrame

        if loop then
            State.kill.enabled = true
            State.kill.mainLoop = task.spawn(function()
                while State.kill.enabled do
                    for _, target in ipairs(targets) do
                        if not target or not target.Character then continue end

                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        
                        if targetRoot and humanoid and humanoid.Health > 0 then
                            local attempts = 0
                            local startTime = tick()
                            
                            while humanoid.Health > 0 and attempts < Config.KILL.MAX_ATTEMPTS do
                                if not target or not target.Character then break end
                                
                                if target.Character:FindFirstChildOfClass("ForceField") then
                                    local ffWaitStart = tick()
                                    while target.Character:FindFirstChildOfClass("ForceField") and 
                                          (tick() - ffWaitStart) < (Config.KILL.FF_WAIT or 3) do
                                        task.wait(0.1)
                                    end
                                end
                                
                                if not target.Character:FindFirstChildOfClass("ForceField") then
                                    localRoot.CFrame = targetRoot.CFrame * CFrame.new(Config.KILL.OFFSET or Vector3.new(0, 0, 3))
                                    meleeEvent:FireServer(target)
                                    attempts += 1
                                end
                                
                                task.wait(Config.KILL.RETRY_DELAY or 0.1)
                            end
                            
                            if humanoid and humanoid.Health <= 0 then
                                Errors.notify("Kill", "Successfully killed " .. target.Name)
                            end
                        end
                    end
                    task.wait(Config.KILL.INTERVAL or 1)
                end
            end)
            Errors.notify("Kill", "Started loop targeting " .. targetType)
        else
            for _, target in ipairs(targets) do
                if target and target.Character then
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    local humanoid = target.Character:FindFirstChild("Humanoid")
                    
                    if targetRoot and humanoid and humanoid.Health > 0 then
                        local startTime = tick()
                        
                        while humanoid and humanoid.Health > 0 and (tick() - startTime) < (Config.KILL.TIMEOUT or 3) do
                            if not target or not target.Character then break end
                            
                            if not target.Character:FindFirstChildOfClass("ForceField") then
                                localRoot.CFrame = targetRoot.CFrame * CFrame.new(Config.KILL.OFFSET or Vector3.new(0, 0, 3))
                                meleeEvent:FireServer(target)
                            end
                            task.wait(0.1)
                        end
                        
                        -- Return to original position
                        if localRoot then
                            localRoot.CFrame = originalCFrame
                        end
                        
                        if humanoid and humanoid.Health <= 0 then
                            Errors.notify("Kill", "Successfully killed " .. target.Name)
                        else
                            Errors.notify("Kill", "Failed to kill " .. target.Name)
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