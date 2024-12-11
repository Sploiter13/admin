local StateType = require("types")

-- Initial state
local State: StateType = {
    ff = {
        enabled = false,
        changingTeam = false,
        lastPosition = nil,
        lastOrientation = nil,
        lastUpdate = 0
    },
    kill = {
        enabled = false,
        mainLoop = nil
    },
    aura = {
        enabled = false,
        mainLoop = nil
    },
    invis = {
        enabled = false,
        platform = nil,
        savedPosition = nil
    },
    view = {
        enabled = false,
        target = nil,
        originalSubject = nil
    }
}

-- Create read-only proxy of state
local ReadOnlyState = setmetatable({}, {
    __index = State,
    __newindex = function()
        error("Attempt to modify read-only state")
    end,
    __metatable = false
})

return ReadOnlyState