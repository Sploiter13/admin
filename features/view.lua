local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function setCameraSubject(character: Character)
    if character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = character.Humanoid
    elseif character:FindFirstChild("Head") then
        workspace.CurrentCamera.CameraSubject = character.Head
    else
        Errors.handleError(Errors.Types.VIEW, "No valid camera subject found", character.Name)
    end
end

local function setView(targetPlayer: Player?)
    local success, err = pcall(function()
        if targetPlayer then
            if not targetPlayer.Character then
                Errors.handleError(Errors.Types.CHARACTER, "Target character not found", targetPlayer.Name)
                return
            end

            State.view.enabled = true
            State.view.target = targetPlayer
            State.view.originalSubject = workspace.CurrentCamera.CameraSubject

            setCameraSubject(targetPlayer.Character)
            Errors.notify("View", "Now viewing: " .. targetPlayer.Name)
        else
            if State.view.enabled then
                local localPlayer = Services.Players.LocalPlayer
                if not localPlayer.Character then
                    Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
                    return
                end

                setCameraSubject(localPlayer.Character)
                State.view.enabled = false
                Errors.notify("View", "Returned to original view.")
            end
        end
    end)

    if not success then
        Errors.handleError(Errors.Types.EXCEPTION, err)
    end
end

return {
    set = setView
}