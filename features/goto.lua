local BASE_URL = "https://raw.githubusercontent.com/Sploiter13/admin/main/"
local Services = loadstring(game:HttpGet(BASE_URL .. "services.lua"))()
local Errors = loadstring(game:HttpGet(BASE_URL .. "errors.lua"))()
local State = loadstring(game:HttpGet(BASE_URL .. "state.lua"))()

local function gotoPlayer(target: Player)
    local success, err = pcall(function()
        if not target then
            Errors.handleError(Errors.Types.CHARACTER, "Target not found")
            return
        end

        local targetCharacter = target.Character
        if not targetCharacter then
            Errors.handleError(Errors.Types.CHARACTER, "Target character not found", target.Name)
            return
        end

        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            Errors.handleError(Errors.Types.CHARACTER, "Target HumanoidRootPart not found", target.Name)
            return
        end

        local localPlayer = Services.Players.LocalPlayer
        local localCharacter = localPlayer.Character
        if not localCharacter then
            Errors.handleError(Errors.Types.CHARACTER, "Local character not found")
            return
        end

        local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            Errors.handleError(Errors.Types.CHARACTER, "Local HumanoidRootPart not found")
            return
        end

        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Errors.notify("Goto", "Teleported to " .. target.Name)
    end)

    if not success then
        Errors.handleError(Errors.Types.EXCEPTION, err)
    end
end