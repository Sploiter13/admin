local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

-- Load module with verification
local function loadModuleSafe(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path))()
    end)
    if not success then
        warn("Failed to load: " .. path)
        return nil
    end
    task.wait(0.1) -- Add delay between loads
    return result
end

-- Load core modules
local Services = assert(loadModuleSafe("services.lua"), "Failed to load Services")
local Config = assert(loadModuleSafe("config.lua"), "Failed to load Config")
local Errors = assert(loadModuleSafe("errors.lua"), "Failed to load Errors")
local Utils = assert(loadModuleSafe("utils.lua"), "Failed to load Utils")

-- Load features with verification
local Features = {
    Forcefield = loadModuleSafe("features/forcefield.lua"),
    Kill = loadModuleSafe("features/kill.lua"),
    KillAura = loadModuleSafe("features/killaura.lua"),
    Invisibility = loadModuleSafe("features/invisibility.lua"),
    View = loadModuleSafe("features/view.lua"),
    Goto = loadModuleSafe("features/goto.lua")
}

local function handleCommand(message: string)
    local cmd = message:lower()
    
    if cmd == "/cmds" then
        task.spawn(function()
            for _, command in ipairs(Config.COMMANDS) do
                Errors.notify("Commands", command)
                task.wait(0.6)
            end
        end)
        return
    end

    local success, err = pcall(function()
        if cmd == "/ff" then
            if Features.Forcefield then
                Features.Forcefield.toggle(true)
            end
        elseif cmd == "/unff" then
            if Features.Forcefield then
                Features.Forcefield.toggle(false)
            end
        elseif cmd:sub(1, 6) == "/kill " then
            if Features.Kill then
                Features.Kill.killTargets(cmd:sub(7), false)
            end
        elseif cmd == "/aura" then
            if Features.KillAura then
                Features.KillAura.toggle(true)
            end
        elseif cmd == "/noaura" then
            if Features.KillAura then
                Features.KillAura.toggle(false)
            end
        elseif cmd == "/invis" then
            if Features.Invisibility then
                Features.Invisibility.toggle(true)
            end
        elseif cmd == "/visible" then
            if Features.Invisibility then
                Features.Invisibility.toggle(false)
            end
        elseif cmd:sub(1, 6) == "/view " then
            if Features.View then
                local target = Utils.findPlayer(cmd:sub(7))
                if target then
                    Features.View.set(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            end
        elseif cmd == "/unview" then
            if Features.View then
                Features.View.set(nil)
            end
        elseif cmd:sub(1, 6) == "/goto " then
            if Features.Goto then
                local target = Utils.findPlayer(cmd:sub(7))
                if target then
                    Features.Goto.goto(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            end
        else
            Errors.notify("Error", "Invalid command. Use /cmds for help")
        end
    end)
    
    if not success then
        Errors.handleError(Errors.Types.COMMAND, "Command execution failed", err)
    end
end

return {
    handle = handleCommand
}