-- features/invisibility.lua

-- Dependencies (Assuming these are already loaded globally)
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local Utils = loadstring(game:HttpGet(BASE_URL .. "utils.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

-- Check that core modules are loaded
if not Services or not Errors or not State or not Config then
    error("[Invisibility] Core modules not loaded.")
end

local Players = Services.Players or game:GetService("Players")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

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
                handleError(Errors.Types.CHARACTER, "Character not found")
                return
            end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                handleError(Errors.Types.CHARACTER, "HumanoidRootPart not found")
                return
            end

            State.invis.savedPosition = hrp.Position

            -- Create the platform near the character to prevent being thrown into the air
            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Config.INVIS.PLATFORM_SIZE
            -- Position the platform slightly above the character to facilitate smooth teleportation
            State.invis.platform.Position = hrp.Position + Vector3.new(0, Config.INVIS.PLATFORM_HEIGHT, 0)
            State.invis.platform.Anchored = true
            State.invis.platform.CanCollide = false -- Prevent any collision-related physics issues
            State.invis.platform.Transparency = 1 -- Make the platform invisible
            State.invis.platform.Parent = workspace

            local touched = false

            -- Define the touch handler function
            local function onTouched(hit)
                if not touched and hit.Parent == character then
                    touched = true

                    -- Disconnect the Touched event to prevent multiple triggers
                    if State.invis.platform and State.invis.platform:FindFirstChildOfClass("Touched") then
                        State.invis.platform.Touched:Disconnect()
                    end

                    task.spawn(function()
                        local clone = hrp:Clone()
                        task.wait(Config.INVIS.TELEPORT_DELAY)
                        hrp:Destroy()
                        clone.Parent = character
                        clone.Name = "HumanoidRootPart" -- Ensure the clone has the correct name
                        character:SetPrimaryPartCFrame(CFrame.new(State.invis.savedPosition))

                        State.invis.enabled = true

                        if State.invis.platform then
                            State.invis.platform:Destroy()
                            State.invis.platform = nil
                        end

                        notify("Invisibility", "Enabled")
                    end)
                end
            end

            -- Connect the Touched event and store the connection for later disconnection
            local touchedConn = State.invis.platform.Touched:Connect(onTouched)
            table.insert(State.invis.connections, touchedConn)

            -- Move the character slightly to trigger the Touched event
            character:SetPrimaryPartCFrame(CFrame.new(State.invis.platform.Position + Vector3.new(0, -3, 0)))
        end)

        if not success then
            handleError(Errors.Types.CHARACTER, "Failed to enable invisibility", err)
        end
    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            local player = LocalPlayer
            local position = State.invis.savedPosition

            if position then
                -- Reset the character by setting health to zero to trigger respawn
                if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                    player.Character.Humanoid.Health = 0
                else
                    handleError(Errors.Types.CHARACTER, "Humanoid not found on character")
                    return
                end

                -- Connect to CharacterAdded to restore position after respawn
                local connection
                connection = player.CharacterAdded:Connect(function(newCharacter)
                    connection:Disconnect() -- Disconnect after first trigger
                    task.wait(0.5) -- Wait to ensure the new character is fully loaded

                    local newHRP = newCharacter:WaitForChild("HumanoidRootPart")
                    newCharacter:SetPrimaryPartCFrame(CFrame.new(position))

                    State.invis.enabled = false
                    State.invis.savedPosition = nil

                    notify("Invisibility", "Disabled")
                end)

                table.insert(State.invis.connections, connection)
            else
                handleError(Errors.Types.CHARACTER, "Saved position not found")
            end
        end)

        if not success then
            handleError(Errors.Types.CHARACTER, "Failed to disable invisibility", err)
        end
    end
end
return {
    toggleInvisibility = toggleInvisibility
}