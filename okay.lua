-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "مغير التيم",
    SubTitle = "هاشم :)",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Add Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "التيمات", Icon = "" }),
    Settings = Window:AddTab({ Title = "الاعدادات", Icon = "settings" })
}

-- Get Teams
local Teams = game:GetService("Teams"):GetTeams()
local TeamNames = {}
for _, Team in pairs(Teams) do
    table.insert(TeamNames, Team.Name)
end

-- Add Dropdown for Teams
local TeamDropdown = Tabs.Main:AddDropdown("TeamDropdown", {
    Title = "اختار التيم",
    Values = TeamNames,
    Multi = false,
    Default = 1,
})

-- Add Button to Change Team
Tabs.Main:AddButton({
    Title = "غير التيم",
    Description = "غير التيم الى التيم الذي اخترته ^^",
    Callback = function()
        local SelectedTeam = TeamDropdown.Value
        local TeamService = game:GetService("Teams")
        local LocalPlayer = game:GetService("Players").LocalPlayer

        -- Find the selected team
        for _, Team in pairs(TeamService:GetTeams()) do
            if Team.Name == SelectedTeam then
                -- Change team client-side
                LocalPlayer.Team = Team
                Fluent:Notify({
                    Title = "تم تغيير التيم",
                    Content = "انت الان في تيم: " .. Team.Name,
                    Duration = 5
                })
                break
            end
        end
    end
})

-- Addons
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("TeamChanger")
SaveManager:SetFolder("TeamChanger/config")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Select First Tab
Window:SelectTab(1)

-- Notify User
Fluent:Notify({
    Title = "مغير التيم",
    Content = "تحمل.",
    Duration = 8
})

-- Load Autoload Config
SaveManager:LoadAutoloadConfig()
