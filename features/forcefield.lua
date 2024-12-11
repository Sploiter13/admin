local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function toggleForcefield(enable: boolean)
    -- Validation
    local localPlayer = Services.Players.LocalPlayer
    if not localPlayer then return Errors.notify("Error", "Player not found") end
    
    local function updatePosition(root)
        if not root then return end
        return {
            pos = root.Position,
            ori = root.CFrame - root.Position,
            cframe = root.CFrame
        }
    end
    
    local function restorePosition(root, posData, retries)
        if not (root and posData) then return false end
        for i = 1, retries or 5 do
            local success = pcall(function()
                root.CFrame = CFrame.new(posData.pos) * posData.ori
                localPlayer.Character:MoveTo(posData.pos)
            end)
            if success then return true end
            task.wait(0.05)
        end
        return false
    end

    local function switchTeams(teamEvent, posData)
        if not teamEvent then return false end
        
        -- Store position right before switch
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local currentPos = updatePosition(root)
        posData = currentPos or posData -- Use most recent position

        -- Execute team switch
        teamEvent:FireServer(Config.FF.TEAMS.ORANGE)
        task.wait(0.25)
        teamEvent:FireServer(Config.FF.TEAMS.BLUE)
        task.wait(0.25)

        -- Restore position with validation
        root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        return restorePosition(root, posData, 3)
    end

    State.ff.enabled = enable
    if enable then
        task.spawn(function()
            local lastSwitch = 0
            local switchCooldown = 0.5

            while State.ff.enabled do
                local character = localPlayer.Character
                if not character then task.wait(0.1) continue end

                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then task.wait(0.1) continue end

                -- Track position continuously
                local posData = updatePosition(root)
                
                -- FF detection and management
                local forceField = character:FindFirstChildOfClass("ForceField")
                if forceField then
                    local ffStartTime = tick()
                    
                    -- Wait while FF is active
                    while forceField and State.ff.enabled do
                        posData = updatePosition(root)
                        local elapsed = tick() - ffStartTime
                        
                        -- Pre-emptive switch before FF expires
                        if elapsed > 2.7 then
                            break
                        end
                        
                        task.wait(0.05)
                        forceField = character:FindFirstChildOfClass("ForceField")
                    end
                end

                -- Handle team switching with cooldown
                if not State.ff.changingTeam and tick() - lastSwitch >= switchCooldown then
                    State.ff.changingTeam = true
                    
                    local teamEvent = workspace:FindFirstChild("Remote"):FindFirstChild("TeamEvent")
                    if switchTeams(teamEvent, posData) then
                        lastSwitch = tick()
                    end
                    
                    State.ff.changingTeam = false
                end

                task.wait(0.1)
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