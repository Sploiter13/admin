-- features/invisibility.lua

-- Dependencies (Assuming these are already loaded globally)
local Services = _G.Services
local Errors = _G.Errors

-- Initialize State if not present
local State = _G.State or {}
_G.State = State

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
            State.invis.originalEnabled[part] = part.Enabled
            part.Enabled = false
        end
    end
end

-- Rest of the script...