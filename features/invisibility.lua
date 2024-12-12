-- features/invisibility.lua

-- Dependencies (Assuming these are already loaded globally)
local Services = _G.Services
local Errors = _G.Errors
local State = _G.State

-- Check that core modules are loaded
if not Services or not Errors or not State then
    error("[Invisibility] Core modules not loaded.")
end

local RunService = game:GetService("RunService")
local Players = Services.Players or game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Initialize State.invis if not present
State.invis = State.invis or {
    enabled = false,
    connections = {},
    originalTransparency = {},
    originalCanCollide = {},
    originalEnabled = {}
}

-- Function to make character invisible
local function makeCharacterInvisible(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            State.invis.originalTransparency[part] = part.Transparency
            State.invis.originalCanCollide[part] = part.CanCollide
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            State.invis.originalTransparency[part] = part.Transparency
            part.Transparency = 1
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
            State.invis.originalEnabled = State.invis.originalEnabled or {}
            State.invis.originalEnabled[part] = part.Enabled
            part.Enabled = false
        end
    end
end

-- Function to restore character's original appearance
local function restoreCharacterAppearance(character)
    for part, transparency in pairs(State.invis.originalTransparency) do
        if part and part.Parent then
            part.Transparency = transparency
        end
    end
    for part, canCollide in pairs(State.invis.originalCanCollide) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
    if State.invis.originalEnabled then
        for part, enabled in pairs(State.invis.originalEnabled) do
            if part and part.Parent then
                part.Enabled = enabled
            end
        end
    end
    -- Clear stored properties
    State.invis.originalTransparency = {}
    State.invis.originalCanCollide = {}
    State.invis.originalEnabled = {}
end

-- Function to clean up invisibility state
local function cleanup()
    -- Disconnect any connections
    for _, connection in pairs(State.invis.connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    State.invis.connections = {}

    -- Restore character appearance
    local character = LocalPlayer.Character
    if character then
        restoreCharacterAppearance(character)
    end

    State.invis.enabled = false
end

local function toggleInvisibility(enable)
    if enable and not State.invis.enabled then
        local success, err = pcall(function()
            local character = LocalPlayer.Character
            if not character then
                error("Character not found")
            end

            -- Make character invisible
            makeCharacterInvisible(character)

            -- Listen for character added (in case of death or respawn)
            local characterAddedConn
            characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
                -- Cleanup and reapply invisibility to new character
                restoreCharacterAppearance(character)
                makeCharacterInvisible(newCharacter)
                character = newCharacter
            end)
            table.insert(State.invis.connections, characterAddedConn)

            -- Handle character's descendants added (for new parts)
            local descendantAddedConn
            descendantAddedConn = character.DescendantAdded:Connect(function(descendant)
                task.wait()
                if State.invis.enabled then
                    if descendant:IsA("BasePart") then
                        State.invis.originalTransparency[descendant] = descendant.Transparency
                        State.invis.originalCanCollide[descendant] = descendant.CanCollide
                        descendant.Transparency = 1
                        descendant.CanCollide = false
                    elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                        State.invis.originalTransparency[descendant] = descendant.Transparency
                        descendant.Transparency = 1
                    elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
                        State.invis.originalEnabled = State.invis.originalEnabled or {}
                        State.invis.originalEnabled[descendant] = descendant.Enabled
                        descendant.Enabled = false
                    end
                end
            end)
            table.insert(State.invis.connections, descendantAddedConn)

            State.invis.enabled = true
            Errors.notify("Invisibility", "Enabled - You are now invisible")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
            cleanup()
        end

    elseif not enable and State.invis.enabled then
        local success, err = pcall(function()
            -- Cleanup invisibility state
            cleanup()
            Errors.notify("Invisibility", "Disabled - You are now visible")
        end)

        if not success then
            Errors.handleError(Errors.Types.EXCEPTION, err)
        end
    end
end

return {
    toggle = toggleInvisibility
}