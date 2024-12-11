local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local RunService = game:GetService("RunService")

-- Load core modules with verification
local function loadModuleSafe(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path))()
    end)
    if not success then
        warn("Failed to load: " .. path)
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

-- Initialize State.invis if not present
State.invis = State.invis or {
    enabled = false,
    platform = nil,
    savedPosition = nil,
    savedCFrame = nil,
    updateConnection = nil
}

local function toggleInvisibility(enable: boolean)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = Services.Players.LocalPlayer.Character
            if not character then
                return Errors.handleError(Errors.Types.CHARACTER, "Character not found")
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            
            -- Start position tracking
            State.invis.updateConnection = RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild("HumanoidRootPart") then
                    State.invis.savedPosition = hrp.Position
                    State.invis.savedCFrame = hrp.CFrame
                end
            end)
            
            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Vector3.new(1, 1, 1)
            State.invis.platform.Transparency = 1
            State.invis.platform.CanCollide = false
            State.invis.platform.Anchored = true
            State.invis.platform.Parent = workspace
            
            hrp.CFrame = State.invis.platform.CFrame
            State.invis.enabled = true
            
            Errors.notify("Invisibility", "Enabled - Position tracking started")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            -- Cleanup tracking connection
            if State.invis.updateConnection then
                State.invis.updateConnection:Disconnect()
                State.invis.updateConnection = nil
            end

            local character = Services.Players.LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp and State.invis.savedCFrame then
                    -- Restore last saved position
                    hrp.CFrame = State.invis.savedCFrame
                end
            end

            if State.invis.platform then
                State.invis.platform:Destroy()
                State.invis.platform = nil
            end

            State.invis.enabled = false
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