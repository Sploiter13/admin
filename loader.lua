local function loadModule(url)
    return loadstring(game:HttpGet(url))()
end

-- Replace these with your actual GitHub raw URLs
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

local function initializeScript()
    -- Load core modules
    local Services = loadModule(BASE_URL .. "services.lua")
    local Config = loadModule(BASE_URL .. "config.lua")
    local State = loadModule(BASE_URL .. "state.lua")
    local Errors = loadModule(BASE_URL .. "errors.lua")
    local Utils = loadModule(BASE_URL .. "utils.lua")
    
    -- Load feature modules
    local Features = {
        Forcefield = loadModule(BASE_URL .. "features/forcefield.lua"),
        Kill = loadModule(BASE_URL .. "features/kill.lua"),
        KillAura = loadModule(BASE_URL .. "features/killaura.lua"),
        Invisibility = loadModule(BASE_URL .. "features/invisibility.lua"),
        View = loadModule(BASE_URL .. "features/view.lua"),
        Goto = loadModule(BASE_URL .. "features/goto.lua")
    }
    
    -- Initialize global state
    _G.State = State
    
    -- Load command handler
    local Commands = loadModule(BASE_URL .. "commands.lua")
    local Cleanup = loadModule(BASE_URL .. "cleanup.lua")
    
    -- Set up command listener
    Services.Players.LocalPlayer.Chatted:Connect(Commands.handle)
    
    -- Connect cleanup
    game:BindToClose(function()
        Cleanup.cleanup()
    end)
    
    Errors.notify("Script", "Initialized successfully")
end

-- Execute
<<<<<<< HEAD
initializeScript()
=======
initializeScript()
>>>>>>> 034caf7470466784342b93125f41ad2e72c01e2a
