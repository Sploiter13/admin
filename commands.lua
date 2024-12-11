-- commands.lua
local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"

-- Load core modules with verification
local function loadModuleSafe(path)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path))()
    end)
    if not success then
        warn("Failed to load module: " .. path)
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
local State = assert(loadModuleSafe("state.lua"), "Failed to load State")

-- Reference Features from _G (loaded by main script)
local Features = _G.Features
if not Features then
    error("Features table not found in _G")
end

-- Define available commands
local Commands = {
    cmds = {
        description = "List all available commands.",
        execute = function()
            task.spawn(function()
                for _, command in ipairs(Config.COMMANDS) do
                    Errors.notify("Commands", command)
                    task.wait(0.6)
                end
            end)
        end,
    },
    ff = {
        description = "Enable Forcefield.",
        execute = function()
            if Features.Forcefield and Features.Forcefield.toggle then
                Features.Forcefield.toggle(true)
            else
                Errors.notify("Error", "Forcefield module not available")
            end
        end,
    },
    unff = {
        description = "Disable Forcefield.",
        execute = function()
            if Features.Forcefield and Features.Forcefield.toggle then
                Features.Forcefield.toggle(false)
            end
        end,
    },
    kill = {
        description = "Kill a target player. Usage: /kill [playerName]",
        execute = function(args)
            if Features.Kill and Features.Kill.killTargets then
                Features.Kill.killTargets(args, false)
            else
                Errors.notify("Error", "Kill module not available")
            end
        end,
    },
    aura = {
        description = "Enable KillAura.",
        execute = function()
            if Features.KillAura and Features.KillAura.toggle then
                Features.KillAura.toggle(true)
            else
                Errors.notify("Error", "KillAura module not available")
            end
        end,
    },
    noaura = {
        description = "Disable KillAura.",
        execute = function()
            if Features.KillAura and Features.KillAura.toggle then
                Features.KillAura.toggle(false)
            end
        end,
    },
    invis = {
        description = "Enable Invisibility.",
        execute = function()
            if Features.Invisibility and Features.Invisibility.toggle then
                Features.Invisibility.toggle(true)
            else
                Errors.notify("Error", "Invisibility module not available")
            end
        end,
    },
    visible = {
        description = "Disable Invisibility.",
        execute = function()
            if Features.Invisibility and Features.Invisibility.toggle then
                Features.Invisibility.toggle(false)
            end
        end,
    },
    view = {
        description = "View a player. Usage: /view [playerName]",
        execute = function(args)
            if Features.View and Features.View.set then
                local target = Utils.findPlayer(args)
                if target then
                    Features.View.set(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            else
                Errors.notify("Error", "View module not available")
            end
        end,
    },
    unview = {
        description = "Stop viewing a player.",
        execute = function()
            if Features.View and Features.View.set then
                Features.View.set(nil)
            end
        end,
    },
    goto = {
        description = "Goto a player. Usage: /goto [playerName]",
        execute = function(args)
            if Features.Goto and Features.Goto.goto then
                local target = Utils.findPlayer(args)
                if target then
                    Features.Goto.goto(target)
                else
                    Errors.notify("Error", "Player not found")
                end
            else
                Errors.notify("Error", "Goto module not available")
            end
        end,
    },
}

-- Handle incoming commands
local function handleCommand(message: string)
    local cmd, args = message:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:sub(2):lower() -- Remove leading '/' and convert to lowercase
    args = args or ""

    if not cmd then
        Errors.notify("Error", "No command entered. Use /cmds for a list of commands.")
        return
    end

    local command = Commands[cmd]
    if command then
        local success, err = pcall(function()
            command.execute(args)
        end)
        if not success then
            Errors.notify("Error", "Failed to execute command: " .. tostring(err))
            Errors.debugLog("Command", tostring(err))
        end
    else
        Errors.notify("Error", "Invalid command. Use /cmds for help.")
    end
end

return {
    handle = handleCommand
}