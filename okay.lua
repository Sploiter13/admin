local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 200) 
frame.Position = UDim2.new(0.5, -75, 0.5, -100) 
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
frame.Parent = screenGui

local dragHandle = Instance.new("TextButton")
dragHandle.Text = "Teams"
dragHandle.Size = UDim2.new(1, 0, 0, 20)
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
dragHandle.TextColor3 = Color3.new(1, 1, 1)
dragHandle.Parent = frame

local userInputService = game:GetService("UserInputService")
local dragging = false
local dragStartPos
local frameStartPos

dragHandle.MouseButton1Down:Connect(function()
    dragging = true
    dragStartPos = userInputService:GetMouseLocation()
    frameStartPos = frame.Position
end)

userInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local dragDelta = userInputService:GetMouseLocation() - dragStartPos
        frame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + dragDelta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + dragDelta.Y)
    end
end)

dragHandle.MouseButton1Up:Connect(function()
    dragging = false
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -25)
scrollFrame.Position = UDim2.new(0, 0, 0, 25)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 5
scrollFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = scrollFrame

local teams = game:GetService("Teams"):GetTeams()

for _, team in pairs(teams) do
    local button = Instance.new("TextButton")
    button.Text = team.Name
    button.Size = UDim2.new(1, -10, 0, 25) 
    button.Position = UDim2.new(0, 5, 0, 0)
    button.BackgroundColor3 = team.TeamColor.Color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = scrollFrame

    button.MouseButton1Click:Connect(function()
        game.Players.LocalPlayer.Team = team
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end)
