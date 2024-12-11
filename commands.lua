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

-- Load core modules
local Services = assert(loadModuleSafe("services.lua"), "Failed to load Services")
local Config = assert(loadModuleSafe("config.lua"), "Failed to load Config")
local Errors = assert(loadModuleSafe("errors.lua"), "Failed to load Errors")
local Utils = assert(loadModuleSafe("utils.lua"), "Failed to load Utils")
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

-- Reference Features from _G (loaded by main script)
local Features = _G.Features

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
            if Features.Forcefield and Features.Forcefield.toggle then
                Features.Forcefield.toggle(true)
            else
                Errors.notify("Error", "Forcefield module not available")
            end
        elseif cmd == "/unff" then
            if Features.Forcefield and Features.Forcefield.toggle then
                Features.Forcefield.toggle(false)
            end
        elseif cmd:sub(1, 6) == "/kill " then
            if Features.Kill and Features.Kill.killTargets then
                Features.Kill.killTargets(cmd:sub(7), false)
            else
                Errors.notify("Error", "Kill module not available")
            end
        elseif cmd == "/aura" then
            if Features.KillAura and Features.KillAura.toggle then
                Features.KillAura.toggle(true)
            else
                Errors.notify("Error", "KillAura module not available")
            end
        elseif cmd == "/noaura" then
            if Features.KillAura and Features.KillAura.toggle then
                Features.KillAura.toggle(false)
            end
        elseif cmd == "/invis" then
            if Features.Invisibility and Features.Invisibility.toggle then
                Features.Invisibility.toggle(true)
            else
                Errors.notify("Error", "Invisibility module not available")
            end
        elseif cmd == "/visible" then
            if Features.Invisibility and Features.Invisibility.toggle then
                Features.Invisibility.toggle(false)
            end
        elseif cmd:sub(1, 6) == "/view " then
            if Features.View and Features.View.set then
                local target = Utils.findPlayer(cmd:sub(7))
                if target then
                    Features.View.set(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            else
                Errors.notify("Error", "View module not available")
            end
        elseif cmd == "/unview" then
            if Features.View and Features.View.set then
                Features.View.set(nil)
            end
        elseif cmd:sub(1, 6) == "/goto " then
            if Features.Goto and Features.Goto.goto then
                local target = Utils.findPlayer(cmd:sub(7))
                if target then
                    Features.Goto.goto(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            else
                Errors.notify("Error", "Goto module not available")
            end
        else
            Errors.notify("Error", "Invalid command. Use /cmds for help")
        end
    end)
    
    if not success then
        Errors.notify("Error", "Failed to execute command: " .. tostring(err))
        Errors.debugLog("Command", tostring(err))
    end
end

return {
    handle = handleCommand
}