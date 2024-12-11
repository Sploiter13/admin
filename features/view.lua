local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function setView(targetPlayer: Player?)
    local success, err = pcall(function()
        if targetPlayer then
            if not targetPlayer.Character then
                return Errors.handleError(Errors.Types.CHARACTER, "Target character not found", targetPlayer.Name)
            end

            State.view.enabled = true
            State.view.target = targetPlayer
            State.view.originalSubject = workspace.CurrentCamera.CameraSubject
            
            if targetPlayer.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
            elseif targetPlayer.Character:FindFirstChild("Head") then
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Head
            else
                return Errors.handleError(Errors.Types.VIEW, "No valid camera subject found", targetPlayer.Name)
            end
            
            Errors.notify("View", "Now viewing: " .. targetPlayer.Name)
        else
            if State.view.enabled then
                local localPlayer = Services.Players.LocalPlayer
                if not localPlayer.Character then
                    return Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
                end

                if localPlayer.Character:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = localPlayer.Character.Humanoid
                elseif localPlayer.Character:FindFirstChild("Head") then
                    workspace.CurrentCamera.CameraSubject = localPlayer.Character.Head
                else
                    return Errors.handleError(Errors.Types.VIEW, "No valid camera subject found for local player")
                end

                State.view.enabled = false
                State.view.target = nil
                Errors.notify("View", "Returned to own view")
            end
        end
    end)
    
    if not success then
        Errors.handleError(Errors.Types.VIEW, "Failed to set view", err)
    end
end

return {
    set = setView
}