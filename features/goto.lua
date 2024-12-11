local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()

local function gotoPlayer(target: Player)
    local success, err = pcall(function()
        if not target then
            return Errors.handleError(Errors.Types.CHARACTER, "Target not found")
        end

        if not target.Character then
            return Errors.handleError(Errors.Types.CHARACTER, "Target character not found", target.Name)
        end

        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            return Errors.handleError(Errors.Types.CHARACTER, "Target HumanoidRootPart not found", target.Name)
        end

        local localPlayer = Services.Players.LocalPlayer
        if not localPlayer.Character then
            return Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
        end

        local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            return Errors.handleError(Errors.Types.CHARACTER, "Local HumanoidRootPart not found")
        end

        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Errors.notify("Goto", "Teleported to " .. target.Name)
    end)

    if not success then
        Errors.handleError(Errors.Types.TELEPORT, "Failed to teleport to player", err)
    end
end

return {
    goto = gotoPlayer
}