local Services = require("services")
local Config = require("config")
local Errors = require("errors")

local function toggleInvisibility(enable: boolean)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = Services.Players.LocalPlayer.Character
            if not character then
                return Errors.handleError(Errors.Types.CHARACTER, "Character not found")
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            State.invis.savedPosition = hrp.Position
            
            -- Create invisible platform
            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Config.INVIS.PLATFORM_SIZE
            State.invis.platform.Position = Vector3.new(0, Config.INVIS.PLATFORM_HEIGHT, 0)
            State.invis.platform.Anchored = true
            State.invis.platform.CanCollide = true
            State.invis.platform.Transparency = 1
            State.invis.platform.Parent = workspace
            
            -- Handle character touching platform
            local touched = false
            State.invis.platform.Touched:Connect(function(hit)
                if not touched and hit.Parent == character then
                    touched = true
                    
                    task.spawn(function()
                        local clone = hrp:Clone()
                        task.wait(Config.INVIS.TELEPORT_DELAY)
                        hrp:Destroy()
                        clone.Parent = character
                        character:MoveTo(State.invis.savedPosition)
                        
                        State.invis.enabled = true
                        if State.invis.platform then
                            State.invis.platform:Destroy()
                            State.invis.platform = nil
                        end
                        
                        Errors.notify("Invisibility", "Enabled")
                    end)
                end
            end)
            
            character:MoveTo(State.invis.platform.Position + Vector3.new(0, 3, 0))
        end)
        
        if not success then
            Errors.handleError(Errors.Types.CHARACTER, "Failed to enable invisibility", err)
        end
    elseif not enable and State.invis.enabled then
        -- Disable invisibility
        local success, err = pcall(function()
            local player = Services.Players.LocalPlayer
            local position = State.invis.savedPosition
            
            if position then
                if player.Character then
                    player.Character.Humanoid.Health = 0
                end
                
                local connection
                connection = player.CharacterAdded:Connect(function(newCharacter)
                    connection:Disconnect()
                    task.wait(0.1)
                    
                    newCharacter:WaitForChild("HumanoidRootPart")
                    newCharacter:MoveTo(position)
                    
                    State.invis.enabled = false
                    State.invis.savedPosition = nil
                    
                    Errors.notify("Invisibility", "Disabled")
                end)
            end
        end)
        
        if not success then
            Errors.handleError(Errors.Types.CHARACTER, "Failed to disable invisibility", err)
        end
    end
end

return {
    toggle = toggleInvisibility
}