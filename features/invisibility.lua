-- features/invisibility.lua

-- Dependencies (Assuming these are already loaded globally)
local Services = _G.Services
local Errors = _G.Errors
local State = _G.State
local Config = _G.Config

-- Check that core modules are loaded
if not Services or not Errors or not State or not Config then
    error("[Invisibility] Core modules not loaded.")
end

local Players = Services.Players or game:GetService("Players")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Initialize State.invis if not present
State.invis = State.invis or {
    enabled = false,
    platform = nil,
    savedPosition = nil
}

-- Default configuration values if not set in Config
Config.INVIS = Config.INVIS or {
    PLATFORM_SIZE = Vector3.new(5, 1, 5),
    PLATFORM_HEIGHT = 500,
    TELEPORT_DELAY = 0.1
}

-- Helper functions
local function notify(title, message)
    if Errors and Errors.notify then
        Errors.notify(title, message)
    else
        print(string.format("[%s] %s", title, message))
    end
end

local function handleError(errorType, message, err)
    if Errors and Errors.handleError then
        Errors.handleError(errorType, message, err)
    else
        warn(string.format("[Error] %s: %s", message, tostring(err)))
    end
end

-- The toggleInvisibility function as provided
local function toggleInvisibility(enable)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = LocalPlayer.Character
            if not character then
                return handleError(Errors.Types.CHARACTER, "Character not found")
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            State.invis.savedPosition = hrp.Position

            -- Create the platform at a high position
            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Config.INVIS.PLATFORM_SIZE
            State.invis.platform.Position = Vector3.new(0, Config.INVIS.PLATFORM_HEIGHT, 0)
            State.invis.platform.Anchored = true
            State.invis.platform.CanCollide = true
            State.invis.platform.Transparency = 1
            State.invis.platform.Parent = workspace

            local touched = false
            -- Connect to the platform's Touched event
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

                        notify("Invisibility", "Enabled")
                    end)
                end
            end)

            -- Move the character to the platform
            character:MoveTo(State.invis.platform.Position + Vector3.new(0, 3, 0))
        end)

        if not success then
            handleError(Errors.Types.CHARACTER, "Failed to enable invisibility", err)
        end
    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            local player = LocalPlayer
            local position = State.invis.savedPosition

            if position then
                -- Reset the character by setting health to zero
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

                    notify("Invisibility", "Disabled")
                end)
            end
        end)

        if not success then
            handleError(Errors.Types.CHARACTER, "Failed to disable invisibility", err)
        end
    end
end

return {
    toggle = toggleInvisibility
}