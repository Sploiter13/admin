local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create the main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.8, 0, 0.6, 0) -- 80% width, 60% height of the screen
frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centered on the screen
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
frame.Visible = false -- Initially hidden
frame.Parent = screenGui

-- Create the drag handle
local dragHandle = Instance.new("TextButton")
dragHandle.Text = "Teams"
dragHandle.Size = UDim2.new(1, 0, 0, 40) -- Height of 40 pixels
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
dragHandle.TextColor3 = Color3.new(1, 1, 1)
dragHandle.TextScaled = true -- Ensure text scales on mobile
dragHandle.Parent = frame

-- Dragging functionality
local userInputService = game:GetService("UserInputService")
local dragging = false
local dragStartPos
local frameStartPos

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local inputPos = input.Position
        if inputPos.X >= dragHandle.AbsolutePosition.X and inputPos.X <= dragHandle.AbsolutePosition.X + dragHandle.AbsoluteSize.X and
           inputPos.Y >= dragHandle.AbsolutePosition.Y and inputPos.Y <= dragHandle.AbsolutePosition.Y + dragHandle.AbsoluteSize.Y then
            dragging = true
            dragStartPos = inputPos
            frameStartPos = frame.Position
        end
    end
end

local function onInputChanged(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local inputPos = input.Position
        local dragDelta = inputPos - dragStartPos
        frame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + dragDelta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + dragDelta.Y)
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end

userInputService.InputBegan:Connect(onInputBegan)
userInputService.InputChanged:Connect(onInputChanged)
userInputService.InputEnded:Connect(onInputEnded)

-- Create the scrollable area for team buttons
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -45) -- Adjusted for drag handle
scrollFrame.Position = UDim2.new(0, 0, 0, 45) -- Positioned below the drag handle
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 5
scrollFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = scrollFrame

-- Add team buttons
local teams = game:GetService("Teams"):GetTeams()

for _, team in pairs(teams) do
    local button = Instance.new("TextButton")
    button.Text = team.Name
    button.Size = UDim2.new(1, -10, 0, 40) -- Height of 40 pixels
    button.Position = UDim2.new(0, 5, 0, 0)
    button.BackgroundColor3 = team.TeamColor.Color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true -- Ensure text scales on mobile
    button.Parent = scrollFrame

    button.MouseButton1Click:Connect(function()
        game.Players.LocalPlayer.Team = team
    end)
end

-- Update scroll frame canvas size when content changes
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end)

-- Create the toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Text = "Toggle UI"
toggleButton.Size = UDim2.new(0.2, 0, 0.1, 0) -- 20% width, 10% height of the screen
toggleButton.Position = UDim2.new(0.5, 0, 0.9, 0) -- Bottom center of the screen
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true -- Ensure text scales on mobile
toggleButton.Parent = screenGui

-- Toggle the visibility of the frame when the button is activated
toggleButton.Activated:Connect(function()
    frame.Visible = not frame.Visible
end)
