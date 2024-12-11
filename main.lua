-- Base URL for GitHub raw content
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

-- Import modules using loadstring
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Config = loadstring(game:HttpGet(BASE_URL .. "config.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local Commands = loadstring(game:HttpGet(BASE_URL .. "commands.lua"))()
local Cleanup = loadstring(game:HttpGet(BASE_URL .. "cleanup.lua"))()

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

-- Start the script with error handling
pcall(initializeScript)