-- features/invisibility.lua

local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local workspace = game:GetService("Workspace")

-- Load core modules with verification
local function loadModuleSafe(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path))()
    end)
    if not success then
        warn("Failed to load: " .. path)
        return nil
    end
    task.wait(0.1) -- Small delay to ensure module stability
    return result
end

-- Load dependencies
local Services = assert(loadModuleSafe("services.lua"), "Failed to load Services")
local Config = assert(loadModuleSafe("config.lua"), "Failed to load Config")
local Errors = assert(loadModuleSafe("errors.lua"), "Failed to load Errors")
local State = loadModuleSafe("state.lua") or {}

-- Initialize State.invis if not present
State.invis = State.invis or {
    enabled = false,
    platform = nil,
    savedCFrame = nil,
    updateConnection = nil,
    characterConnection = nil
}

-- Function to clean up invisibility state
local function cleanup()
    if State.invis.updateConnection then
        State.invis.updateConnection:Disconnect()
        State.invis.updateConnection = nil
    end

    if State.invis.characterConnection then
        State.invis.characterConnection:Disconnect()
        State.invis.characterConnection = nil
    end

    if State.invis.platform then
        State.invis.platform:Destroy()
        State.invis.platform = nil
    end

    State.invis.enabled = false
end

local function toggleInvisibility(enable: boolean)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = Services.Players.LocalPlayer.Character
            if not character then
                return Errors.handleError(Errors.Types.CHARACTER, "Character not found")
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            if not hrp then
                return Errors.handleError(Errors.Types.CHARACTER, "HumanoidRootPart not found")
            end

            -- Save current CFrame
            State.invis.savedCFrame = hrp.CFrame

            -- Create and position the platform at the character's current position
            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Vector3.new(1, 1, 1)
            State.invis.platform.Transparency = 1
            State.invis.platform.CanCollide = false
            State.invis.platform.Anchored = true
            State.invis.platform.CFrame = hrp.CFrame -- Position platform at character's location
            State.invis.platform.Parent = workspace

            -- Teleport character slightly upwards to avoid physics glitches
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 1, 0)
            
            -- Start position tracking
            State.invis.updateConnection = RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild("HumanoidRootPart") then
                    State.invis.savedCFrame = hrp.CFrame
                end
            end)

            -- Handle character death or respawn
            State.invis.characterConnection = Services.Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
                if State.invis.enabled then
                    cleanup()
                    task.wait(0.1)
                    toggleInvisibility(false)
                end
            end)

            State.invis.enabled = true
            Errors.notify("Invisibility", "Enabled - Position tracking started")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            -- Cleanup tracking connections
            cleanup()

            local character = Services.Players.LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp and State.invis.savedCFrame then
                    -- Restore the last saved position
                    hrp.CFrame = State.invis.savedCFrame + Vector3.new(0, 1, 0) -- Ensure slight offset to prevent glitches
                end
            end

            Errors.notify("Invisibility", "Disabled - Position restored")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    end
end

return {
    toggle = toggleInvisibility
}