local Services = require("services")
local Config = require("config")
local Errors = require("errors")
local Utils = require("utils")

-- Feature modules
local Forcefield = require("features/forcefield")
local Kill = require("features/kill")
local KillAura = require("features/killaura")
local Invisibility = require("features/invisibility")
local View = require("features/view")
local Goto = require("features/goto")

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
            Forcefield.toggle(true)
        elseif cmd == "/unff" then
            Forcefield.toggle(false)
        elseif cmd:sub(1, 6) == "/kill " then
            Kill.killTargets(cmd:sub(7), false)
        elseif cmd:sub(1, 4) == "/lk " then
            Kill.killTargets(cmd:sub(5), true)
        elseif cmd == "/unlk" or cmd == "/nolk" then
            State.kill.enabled = false
            if State.kill.mainLoop then
                task.cancel(State.kill.mainLoop)
                State.kill.mainLoop = nil
            end
            Errors.notify("Kill Loop", "Disabled")
        elseif cmd == "/aura" then
            KillAura.toggle(true)
        elseif cmd == "/noaura" or cmd == "/unaura" then
            KillAura.toggle(false)
        elseif cmd == "/invis" then
            Invisibility.toggle(true)
        elseif cmd == "/visible" or cmd == "/vis" then
            Invisibility.toggle(false)
        elseif cmd:sub(1, 6) == "/view " then
            local target = Utils.findPlayer(cmd:sub(7))
            if target then
                View.set(target)
            else
                Errors.notify("Error", "Player not found")
            end
        elseif cmd == "/unview" then
            View.set(nil)
        elseif cmd:sub(1, 6) == "/goto " then
            local target = Utils.findPlayer(cmd:sub(7))
            if target then
                Goto.goto(target)
            else
                Errors.notify("Error", "Player not found")
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