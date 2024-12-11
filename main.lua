-- Import modules
local Services = require("services")
local Config = require("config")
local State = require("state")
local Commands = require("commands")
local Cleanup = require("cleanup")

-- Initialize State
_G.State = State

-- Set up command listener
local function initializeScript()
    -- Connect chat command handler
    Services.Players.LocalPlayer.Chatted:Connect(Commands.handle)
    
    -- Connect cleanup to player leaving
    game:BindToClose(function()
        Cleanup.cleanup()
    end)
    
    -- Notify successful initialization
    Errors.notify("Script", "Initialized successfully")
end

-- Start the script
initializeScript()