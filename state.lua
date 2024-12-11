local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local StateType = loadstring(game:HttpGet(BASE_URL .. "types.lua"))()

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

return State