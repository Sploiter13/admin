-- forcefield.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Initialize protected state 
State.ff = State.ff or {
    enabled = false,
    mainLoop = nil,
    connections = {},
    hooks = {}
}

-- Create protected functions
local function protectCharacter(character)
    if not character then return end
    
    -- Find and hook damage handlers in GC
    for _, v in pairs(getgc()) do
        if type(v) == "function" and islclosure(v) then
            local constants = debug.getconstants(v)
            if table.find(constants, "TakeDamage") then
                State.ff.hooks["damage"] = hookfunction(v, newcclosure(function(...)
                    if State.ff.enabled and checkcaller() then
                        return -- Block damage
                    end
                    return State.ff.hooks["damage"](...)
                end))
            end
        end
    end

    -- Disable damage connections
    for _, desc in pairs(character:GetDescendants()) do
        for _, conn in pairs(getconnections(desc.Changed)) do
            conn:Disable()
            table.insert(State.ff.connections, conn)
        end
    end
end

local function toggleForcefield(enable)
    if enable and not State.ff.enabled then
        State.ff.enabled = true
        
        -- Protect current character
        protectCharacter(LocalPlayer.Character)
        
        -- Handle respawns
        local charConn = LocalPlayer.CharacterAdded:Connect(function(char)
            protectCharacter(char)
        end)
        table.insert(State.ff.connections, charConn)
        
        notify("Forcefield", "Enabled")
        
    else
        State.ff.enabled = false
        
        -- Restore connections
        for _, conn in pairs(State.ff.connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            else
                conn:Enable()
            end
        end
        State.ff.connections = {}
        
        -- Remove hooks
        for k,v in pairs(State.ff.hooks) do
            hookfunction(v, function(...) 
                return v(...)
            end)
        end
        State.ff.hooks = {}
        
        notify("Forcefield", "Disabled")
    end
end

return {
    toggle = toggleForcefield
}