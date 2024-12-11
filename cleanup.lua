local Services = require("services")
local Errors = require("errors")
local state = require("state")

local function destroyPlatform()
    if State.invis.platform then
        State.invis.platform:Destroy()
        State.invis.platform = nil
    end
end

local function cleanup()
    -- Disable all features
    State.ff.enabled = false
    State.kill.enabled = false
    State.aura.enabled = false
    
    -- Cancel all loops
    if State.kill.mainLoop then
        task.cancel(State.kill.mainLoop)
        State.kill.mainLoop = nil
    end
    if State.aura.mainLoop then
        task.cancel(State.aura.mainLoop)
        State.aura.mainLoop = nil
    end
    
    -- Cleanup instances
    destroyPlatform()
    
    -- Reset view
    if State.view.enabled then
        if State.view.originalSubject then
            workspace.CurrentCamera.CameraSubject = State.view.originalSubject
        end
        State.view.enabled = false
        State.view.target = nil
        State.view.originalSubject = nil
    end
    
    Errors.debugLog("Cleanup", "Script shutdown complete")
end

-- Connect cleanup to character respawn
Services.Players.LocalPlayer.CharacterAdded:Connect(function()
    if State.invis and not State.invis.enabled then
        destroyPlatform()
        State.invis.savedPosition = nil
    end
end)

return {
    cleanup = cleanup,
    destroyPlatform = destroyPlatform
}