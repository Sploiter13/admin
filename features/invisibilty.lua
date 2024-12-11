local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

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

local function toggleInvisibility(enable: boolean)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = Services.Players.LocalPlayer.Character
            if not character then
                Errors.handleError(Errors.Types.CHARACTER, "Character not found")
                return
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            State.invis.savedPosition = hrp.Position

            State.invis.platform = Instance.new("Part")
            State.invis.platform.Size = Vector3.new(1, 1, 1)
            State.invis.platform.Transparency = 1
            State.invis.platform.CanCollide = false
            State.invis.platform.Anchored = true
            State.invis.platform.Parent = workspace
            hrp.CFrame = State.invis.platform.CFrame

            State.invis.enabled = true
            Errors.notify("Invisibility", "Invisibility enabled.")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            local character = Services.Players.LocalPlayer.Character
            if not character then
                Errors.handleError(Errors.Types.CHARACTER, "Character not found")
                return
            end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp and State.invis.savedPosition then
                hrp.Position = State.invis.savedPosition
            end

            if State.invis.platform then
                State.invis.platform:Destroy()
                State.invis.platform = nil
            end

            State.invis.enabled = false
            Errors.notify("Invisibility", "Invisibility disabled.")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    end
end

return {
    toggleInvisibility = toggleInvisibility
}