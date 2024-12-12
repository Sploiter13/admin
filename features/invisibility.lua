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
            if not character then return handleError(Errors.Types.CHARACTER, "Character not found") end
            
            local hrp = character:WaitForChild("HumanoidRootPart")
            State.invis.savedPosition = hrp.Position
            
            -- Clone primary parts
            local clone = hrp:Clone()
            clone.Parent = character
            
            -- Break physics replication
            hrp.AssemblyLinearVelocity = Vector3.new(math.huge, math.huge, math.huge)
            task.wait(0.1)
            hrp:Destroy()
            
            character:MoveTo(State.invis.savedPosition)
            State.invis.enabled = true
            notify("Invisibility", "Enabled")
        end)
        
        if not success then
            handleError(Errors.Types.CHARACTER, "Failed to enable invisibility", err)
        end
    end
end

return {
    toggleInvisibility = toggleInvisibility
}