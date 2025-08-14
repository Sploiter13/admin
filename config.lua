-- UI Library Core
local Library = {}
local UI_ELEMENTS = {}
local DRAGGING_UI = nil
local DRAG_OFFSET_X = 0
local DRAG_OFFSET_Y = 0
local UI_ZINDEX_BASE = 1000 -- Base ZIndex for UI elements to appear on top

-- Helper function to check if a point is inside a rectangle
local function is_point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Helper function to get text dimensions (approximation, as TextBounds is readonly)
-- This is a very rough approximation. A real UI would need a more sophisticated text measurement.
local function get_text_dimensions(text_str, font_size)
    -- These are arbitrary values for demonstration.
    -- In a real scenario, you'd need to pre-calculate or have a way to query actual text bounds.
    local char_width = font_size * 0.6
    local char_height = font_size * 1.2
    return #text_str * char_width, char_height
end

-- Base UI Element Class
local UIElement = {}
UIElement.__index = UIElement

function UIElement:new(props)
    local o = {
        Name = props.Name or "Unnamed Element",
        Visible = true,
        ZIndex = UI_ZINDEX_BASE,
        Position = props.Position or {0, 0},
        Size = props.Size or {100, 20},
        Color = props.Color or {50, 50, 50},
        Opacity = props.Opacity or 1,
        Parent = props.Parent,
        Children = {},
        DrawingObjects = {}, -- Store Drawing library objects
        Type = "UIElement"
    }
    setmetatable(o, self)
    table.insert(UI_ELEMENTS, o)
    return o
end

function UIElement:SetVisible(state)
    self.Visible = state
    for _, obj in pairs(self.DrawingObjects) do
        obj.Visible = state
    end
    for _, child in pairs(self.Children) do
        child:SetVisible(state)
    end
end

function UIElement:SetPosition(x, y)
    local dx = x - self.Position[1]
    local dy = y - self.Position[2]
    self.Position = {x, y}
    -- Update positions of drawing objects
    for _, obj in pairs(self.DrawingObjects) do
        if obj.Position then
            obj.Position = {obj.Position[1] + dx, obj.Position[2] + dy}
        elseif obj.From and obj.To then
            obj.From = {obj.From[1] + dx, obj.From[2] + dy}
            obj.To = {obj.To[1] + dx, obj.To[2] + dy}
        elseif obj.PointA then -- For Quad/Triangle
            obj.PointA = {obj.PointA[1] + dx, obj.PointA[2] + dy}
            obj.PointB = {obj.PointB[1] + dx, obj.PointB[2] + dy}
            obj.PointC = {obj.PointC[1] + dx, obj.PointC[2] + dy}
            if obj.PointD then
                obj.PointD = {obj.PointD[1] + dx, obj.PointD[2] + dy}
            end
        end
    end
    -- Recursively update children
    for _, child in pairs(self.Children) do
        child:SetPosition(child.Position[1] + dx, child.Position[2] + dy)
    end
end

function UIElement:Remove()
    for _, obj in pairs(self.DrawingObjects) do
        obj:Remove()
    end
    for _, child in pairs(self.Children) do
        child:Remove()
    end
    -- Remove from global UI_ELEMENTS table
    for i, v in ipairs(UI_ELEMENTS) do
        if v == self then
            table.remove(UI_ELEMENTS, i)
            break
        end
    end
end

-- Library Class
local UILibrary = UIElement:new({
    Name = "Severe UI",
    Position = {100, 100},
    Size = {600, 400},
    Color = {30, 30, 30},
    Opacity = 0.9,
    Type = "Library"
})

function UILibrary:Create(props)
    local lib = UILibrary:new(props)
    lib.Name = props.Name or "Severe UI"
    lib.Position = {100, 100}
    lib.Size = {600, 400}
    lib.Color = {30, 30, 30}
    lib.Opacity = 0.9

    -- Draw the main window background
    lib.DrawingObjects.background = Drawing.new("Square")
    lib.DrawingObjects.background.Position = lib.Position
    lib.DrawingObjects.background.Size = lib.Size
    lib.DrawingObjects.background.Color = lib.Color
    lib.DrawingObjects.background.Opacity = lib.Opacity
    lib.DrawingObjects.background.Filled = true
    lib.DrawingObjects.background.ZIndex = lib.ZIndex

    -- Draw the title bar
    lib.DrawingObjects.title_bar = Drawing.new("Square")
    lib.DrawingObjects.title_bar.Position = lib.Position
    lib.DrawingObjects.title_bar.Size = {lib.Size[1], 25}
    lib.DrawingObjects.title_bar.Color = {40, 40, 40}
    lib.DrawingObjects.title_bar.Opacity = 1
    lib.DrawingObjects.title_bar.Filled = true
    lib.DrawingObjects.title_bar.ZIndex = lib.ZIndex + 1

    -- Draw the title text
    lib.DrawingObjects.title_text = Drawing.new("Text")
    lib.DrawingObjects.title_text.Text = lib.Name
    lib.DrawingObjects.title_text.Position = {lib.Position[1] + 5, lib.Position[2] + 5}
    lib.DrawingObjects.title_text.Color = {255, 255, 255}
    lib.DrawingObjects.title_text.Size = 16
    lib.DrawingObjects.title_text.ZIndex = lib.ZIndex + 2

    lib.CurrentTab = nil
    lib.TabOffset = 0
    lib.SectionOffset = 0

    -- Draggable logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local title_bar_x, title_bar_y = lib.DrawingObjects.title_bar.Position[1], lib.DrawingObjects.title_bar.Position[2]
            local title_bar_w, title_bar_h = lib.DrawingObjects.title_bar.Size[1], lib.DrawingObjects.title_bar.Size[2]

            if is_point_in_rect(mouse_x, mouse_y, title_bar_x, title_bar_y, title_bar_w, title_bar_h) and isleftpressed() then
                if not DRAGGING_UI then
                    DRAGGING_UI = lib
                    DRAG_OFFSET_X = mouse_x - lib.Position[1]
                    DRAG_OFFSET_Y = mouse_y - lib.Position[2]
                end
            elseif not isleftpressed() then
                DRAGGING_UI = nil
            end

            if DRAGGING_UI == lib then
                lib:SetPosition(mouse_x - DRAG_OFFSET_X, mouse_y - DRAG_OFFSET_Y)
            end
            wait()
        end
    end)

    return lib
end

-- Tab Class
local Tab = UIElement:new({Type = "Tab"})
function UILibrary:Tab(props)
    local tab = Tab:new(props)
    tab.Parent = self
    tab.Position = {self.Position[1] + 5, self.Position[2] + 25 + self.TabOffset + 5} -- Position below title bar
    tab.Size = {100, 20}
    tab.Color = {50, 50, 50}
    tab.Opacity = 1
    tab.ZIndex = self.ZIndex + 3

    self.TabOffset = self.TabOffset + tab.Size[2] + 5 -- Increment offset for next tab

    -- Draw tab button
    tab.DrawingObjects.button = Drawing.new("Square")
    tab.DrawingObjects.button.Position = tab.Position
    tab.DrawingObjects.button.Size = tab.Size
    tab.DrawingObjects.button.Color = tab.Color
    tab.DrawingObjects.button.Opacity = tab.Opacity
    tab.DrawingObjects.button.Filled = true
    tab.DrawingObjects.button.ZIndex = tab.ZIndex

    tab.DrawingObjects.text = Drawing.new("Text")
    tab.DrawingObjects.text.Text = tab.Name
    tab.DrawingObjects.text.Position = {tab.Position[1] + 5, tab.Position[2] + 3}
    tab.DrawingObjects.text.Color = {200, 200, 200}
    tab.DrawingObjects.text.Size = 14
    tab.DrawingObjects.text.ZIndex = tab.ZIndex + 1

    table.insert(self.Children, tab)

    -- Tab click logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = tab.DrawingObjects.button.Position[1], tab.DrawingObjects.button.Position[2]
            local btn_w, btn_h = tab.DrawingObjects.button.Size[1], tab.DrawingObjects.button.Size[2]

            if is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                tab.DrawingObjects.button.Color = {70, 70, 70} -- Hover color
                if isleftclicked() then
                    if self.CurrentTab then
                        self.CurrentTab:SetVisible(false)
                        self.CurrentTab.DrawingObjects.button.Color = {50, 50, 50} -- Reset previous tab color
                    end
                    self.CurrentTab = tab
                    self.CurrentTab:SetVisible(true)
                    self.CurrentTab.DrawingObjects.button.Color = {90, 90, 90} -- Active color
                    self.SectionOffset = 0 -- Reset section offset for new tab
                end
            else
                if self.CurrentTab ~= tab then
                    tab.DrawingObjects.button.Color = {50, 50, 50} -- Default color
                end
            end
            wait()
        end
    end)

    tab:SetVisible(false) -- Tabs are initially hidden

    return tab
end

-- Section Class
local Section = UIElement:new({Type = "Section"})
function Tab:Section(props)
    local section = Section:new(props)
    section.Parent = self
    section.Side = props.Side or "Left"
    section.Position = {self.Parent.Position[1] + (section.Side == "Left" and 110 or 350), self.Parent.Position[2] + 30 + self.Parent.SectionOffset}
    section.Size = {240, 150} -- Default section size
    section.Color = {40, 40, 40}
    section.Opacity = 0.95
    section.ZIndex = self.ZIndex + 2

    self.Parent.SectionOffset = self.Parent.SectionOffset + section.Size[2] + 10 -- Increment offset for next section

    -- Draw section background
    section.DrawingObjects.background = Drawing.new("Square")
    section.DrawingObjects.background.Position = section.Position
    section.DrawingObjects.background.Size = section.Size
    section.DrawingObjects.background.Color = section.Color
    section.DrawingObjects.background.Opacity = section.Opacity
    section.DrawingObjects.background.Filled = true
    section.DrawingObjects.background.ZIndex = section.ZIndex

    -- Draw section title
    section.DrawingObjects.title_text = Drawing.new("Text")
    section.DrawingObjects.title_text.Text = section.Name
    section.DrawingObjects.title_text.Position = {section.Position[1] + 5, section.Position[2] + 3}
    section.DrawingObjects.title_text.Color = {255, 255, 255}
    section.DrawingObjects.title_text.Size = 14
    section.DrawingObjects.title_text.ZIndex = section.ZIndex + 1

    section.ContentOffset = 25 -- Offset for content within the section

    table.insert(self.Children, section)
    section:SetVisible(self.Visible) -- Inherit visibility from parent tab

    return section
end

-- Button Class
local Button = UIElement:new({Type = "Button"})
function Section:Button(props)
    local button = Button:new(props)
    button.Parent = self
    button.Position = {self.Position[1] + 5, self.Position[2] + self.ContentOffset}
    button.Size = {self.Size[1] - 10, 25}
    button.Color = {60, 60, 60}
    button.Opacity = 1
    button.ZIndex = self.ZIndex + 1
    button.Callback = props.Callback or function() warn("Button '" .. button.Name .. "' clicked!") end
    button.Tooltip = props.Tooltip or ""

    self.ContentOffset = self.ContentOffset + button.Size[2] + 5

    -- Draw button background
    button.DrawingObjects.background = Drawing.new("Square")
    button.DrawingObjects.background.Position = button.Position
    button.DrawingObjects.background.Size = button.Size
    button.DrawingObjects.background.Color = button.Color
    button.DrawingObjects.background.Opacity = button.Opacity
    button.DrawingObjects.background.Filled = true
    button.DrawingObjects.background.ZIndex = button.ZIndex

    -- Draw button text
    button.DrawingObjects.text = Drawing.new("Text")
    button.DrawingObjects.text.Text = button.Name
    button.DrawingObjects.text.Position = {button.Position[1] + 5, button.Position[2] + 5}
    button.DrawingObjects.text.Color = {255, 255, 255}
    button.DrawingObjects.text.Size = 14
    button.DrawingObjects.text.ZIndex = button.ZIndex + 1

    table.insert(self.Children, button)
    button:SetVisible(self.Visible)

    -- Button click logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = button.DrawingObjects.background.Position[1], button.DrawingObjects.background.Position[2]
            local btn_w, btn_h = button.DrawingObjects.background.Size[1], button.DrawingObjects.background.Size[2]

            if button.Visible and is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                button.DrawingObjects.background.Color = {80, 80, 80} -- Hover color
                if isleftclicked() then
                    button.Callback()
                end
            else
                button.DrawingObjects.background.Color = {60, 60, 60} -- Default color
            end
            wait()
        end
    end)

    return button
end

-- Toggle Class
local Toggle = UIElement:new({Type = "Toggle"})
function Section:Toggle(props)
    local toggle = Toggle:new(props)
    toggle.Parent = self
    toggle.State = props.Default or false
    toggle.Position = {self.Position[1] + 5, self.Position[2] + self.ContentOffset}
    toggle.Size = {self.Size[1] - 10, 25}
    toggle.Color = {60, 60, 60}
    toggle.Opacity = 1
    toggle.ZIndex = self.ZIndex + 1
    toggle.Callback = props.Callback or function(state) warn("Toggle '" .. toggle.Name .. "' state: " .. tostring(state)) end
    toggle.Tooltip = props.Tooltip or ""

    self.ContentOffset = self.ContentOffset + toggle.Size[2] + 5

    -- Draw toggle background
    toggle.DrawingObjects.background = Drawing.new("Square")
    toggle.DrawingObjects.background.Position = toggle.Position
    toggle.DrawingObjects.background.Size = toggle.Size
    toggle.DrawingObjects.background.Color = toggle.Color
    toggle.DrawingObjects.background.Opacity = toggle.Opacity
    toggle.DrawingObjects.background.Filled = true
    toggle.DrawingObjects.background.ZIndex = toggle.ZIndex

    -- Draw toggle text
    toggle.DrawingObjects.text = Drawing.new("Text")
    toggle.DrawingObjects.text.Text = toggle.Name
    toggle.DrawingObjects.text.Position = {toggle.Position[1] + 5, toggle.Position[2] + 5}
    toggle.DrawingObjects.text.Color = {255, 255, 255}
    toggle.DrawingObjects.text.Size = 14
    toggle.DrawingObjects.text.ZIndex = toggle.ZIndex + 1

    -- Draw toggle indicator (square on the right)
    toggle.DrawingObjects.indicator = Drawing.new("Square")
    toggle.DrawingObjects.indicator.Position = {toggle.Position[1] + toggle.Size[1] - 20, toggle.Position[2] + 5}
    toggle.DrawingObjects.indicator.Size = {15, 15}
    toggle.DrawingObjects.indicator.Color = toggle.State and {0, 200, 0} or {100, 100, 100}
    toggle.DrawingObjects.indicator.Opacity = 1
    toggle.DrawingObjects.indicator.Filled = true
    toggle.DrawingObjects.indicator.ZIndex = toggle.ZIndex + 1

    table.insert(self.Children, toggle)
    toggle:SetVisible(self.Visible)

    -- Toggle click logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = toggle.DrawingObjects.background.Position[1], toggle.DrawingObjects.background.Position[2]
            local btn_w, btn_h = toggle.DrawingObjects.background.Size[1], toggle.DrawingObjects.background.Size[2]

            if toggle.Visible and is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                toggle.DrawingObjects.background.Color = {80, 80, 80} -- Hover color
                if isleftclicked() then
                    toggle.State = not toggle.State
                    toggle.DrawingObjects.indicator.Color = toggle.State and {0, 200, 0} or {100, 100, 100}
                    toggle.Callback(toggle.State)
                    wait(0.1) -- Debounce click
                end
            else
                toggle.DrawingObjects.background.Color = {60, 60, 60} -- Default color
            end
            wait()
        end
    end)

    return toggle
end

-- Keybind Class (attached to Toggle)
local Keybind = UIElement:new({Type = "Keybind"})
function Toggle:Keybind(props)
    local keybind = Keybind:new(props)
    keybind.Parent = self
    keybind.DefaultKey = props.Default or "None"
    keybind.CurrentKey = keybind.DefaultKey
    keybind.Callback = props.Callback or function(key) warn("Keybind for '" .. keybind.Parent.Name .. "' set to: " .. key) end
    keybind.Listening = false

    keybind.Position = {self.Position[1] + 5, self.Position[2] + self.Size[2] + 5} -- Below the parent toggle
    keybind.Size = {self.Size[1] - 10, 20}
    keybind.Color = {50, 50, 50}
    keybind.Opacity = 1
    keybind.ZIndex = self.ZIndex + 1

    -- Draw keybind background
    keybind.DrawingObjects.background = Drawing.new("Square")
    keybind.DrawingObjects.background.Position = keybind.Position
    keybind.DrawingObjects.background.Size = keybind.Size
    keybind.DrawingObjects.background.Color = keybind.Color
    keybind.DrawingObjects.background.Opacity = keybind.Opacity
    keybind.DrawingObjects.background.Filled = true
    keybind.DrawingObjects.background.ZIndex = keybind.ZIndex

    -- Draw keybind text
    keybind.DrawingObjects.text = Drawing.new("Text")
    keybind.DrawingObjects.text.Text = "Keybind: " .. keybind.CurrentKey
    keybind.DrawingObjects.text.Position = {keybind.Position[1] + 5, keybind.Position[2] + 3}
    keybind.DrawingObjects.text.Color = {255, 255, 255}
    keybind.DrawingObjects.text.Size = 12
    keybind.DrawingObjects.text.ZIndex = keybind.ZIndex + 1

    table.insert(self.Children, keybind)
    keybind:SetVisible(self.Visible)

    -- Keybind logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = keybind.DrawingObjects.background.Position[1], keybind.DrawingObjects.background.Position[2]
            local btn_w, btn_h = keybind.DrawingObjects.background.Size[1], keybind.DrawingObjects.background.Size[2]

            if keybind.Visible and is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                keybind.DrawingObjects.background.Color = {70, 70, 70} -- Hover color
                if isleftclicked() then
                    keybind.Listening = true
                    keybind.DrawingObjects.text.Text = "Press a key..."
                    keybind.DrawingObjects.background.Color = {100, 100, 0} -- Listening color
                    wait(0.1) -- Debounce click
                end
            else
                if not keybind.Listening then
                    keybind.DrawingObjects.background.Color = {50, 50, 50} -- Default color
                end
            end

            if keybind.Listening then
                local pressed_key = getpressedkey()
                if pressed_key and pressed_key ~= "" then
                    keybind.CurrentKey = pressed_key
                    keybind.Listening = false
                    keybind.DrawingObjects.text.Text = "Keybind: " .. keybind.CurrentKey
                    keybind.Callback(keybind.CurrentKey)
                    wait(0.1) -- Debounce key press
                end
            end
            wait()
        end
    end)

    return keybind
end

-- Dropdown Class
local Dropdown = UIElement:new({Type = "Dropdown"})
function Section:Dropdown(props)
    local dropdown = Dropdown:new(props)
    dropdown.Parent = self
    dropdown.Selected = props.Default or "None"
    dropdown.Options = props.Options or {}
    dropdown.Callback = props.Callback or function(selected) warn("Dropdown '" .. dropdown.Name .. "' selected: " .. selected) end
    dropdown.Expanded = false

    dropdown.Position = {self.Position[1] + 5, self.Position[2] + self.ContentOffset}
    dropdown.Size = {self.Size[1] - 10, 25}
    dropdown.Color = {60, 60, 60}
    dropdown.Opacity = 1
    dropdown.ZIndex = self.ZIndex + 1

    self.ContentOffset = self.ContentOffset + dropdown.Size[2] + 5

    -- Draw dropdown main button
    dropdown.DrawingObjects.button = Drawing.new("Square")
    dropdown.DrawingObjects.button.Position = dropdown.Position
    dropdown.DrawingObjects.button.Size = dropdown.Size
    dropdown.DrawingObjects.button.Color = dropdown.Color
    dropdown.DrawingObjects.button.Opacity = dropdown.Opacity
    dropdown.DrawingObjects.button.Filled = true
    dropdown.DrawingObjects.button.ZIndex = dropdown.ZIndex

    -- Draw dropdown text
    dropdown.DrawingObjects.text = Drawing.new("Text")
    dropdown.DrawingObjects.text.Text = dropdown.Name .. ": " .. dropdown.Selected
    dropdown.DrawingObjects.text.Position = {dropdown.Position[1] + 5, dropdown.Position[2] + 5}
    dropdown.DrawingObjects.text.Color = {255, 255, 255}
    dropdown.DrawingObjects.text.Size = 14
    dropdown.DrawingObjects.text.ZIndex = dropdown.ZIndex + 1

    dropdown.OptionElements = {}
    for i, option_text in ipairs(dropdown.Options) do
        local option_pos_y = dropdown.Position[2] + dropdown.Size[2] + (i - 1) * 20
        local option_element = {
            text = option_text,
            position = {dropdown.Position[1], option_pos_y},
            size = {dropdown.Size[1], 20},
            drawing_bg = Drawing.new("Square"),
            drawing_text = Drawing.new("Text")
        }
        option_element.drawing_bg.Position = option_element.position
        option_element.drawing_bg.Size = option_element.size
        option_element.drawing_bg.Color = {70, 70, 70}
        option_element.drawing_bg.Opacity = 1
        option_element.drawing_bg.Filled = true
        option_element.drawing_bg.ZIndex = dropdown.ZIndex + 2
        option_element.drawing_bg.Visible = false

        option_element.drawing_text.Text = option_text
        option_element.drawing_text.Position = {option_element.position[1] + 5, option_element.position[2] + 3}
        option_element.drawing_text.Color = {255, 255, 255}
        option_element.drawing_text.Size = 12
        option_element.drawing_text.ZIndex = dropdown.ZIndex + 3
        option_element.drawing_text.Visible = false

        table.insert(dropdown.OptionElements, option_element)
        table.insert(dropdown.DrawingObjects, option_element.drawing_bg)
        table.insert(dropdown.DrawingObjects, option_element.drawing_text)
    end

    table.insert(self.Children, dropdown)
    dropdown:SetVisible(self.Visible)

    -- Dropdown logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = dropdown.DrawingObjects.button.Position[1], dropdown.DrawingObjects.button.Position[2]
            local btn_w, btn_h = dropdown.DrawingObjects.button.Size[1], dropdown.DrawingObjects.button.Size[2]

            if dropdown.Visible then
                if is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                    dropdown.DrawingObjects.button.Color = {80, 80, 80} -- Hover color
                    if isleftclicked() then
                        dropdown.Expanded = not dropdown.Expanded
                        for _, opt_elem in ipairs(dropdown.OptionElements) do
                            opt_elem.drawing_bg.Visible = dropdown.Expanded
                            opt_elem.drawing_text.Visible = dropdown.Expanded
                        end
                        wait(0.1)
                    end
                else
                    dropdown.DrawingObjects.button.Color = {60, 60, 60} -- Default color
                    if isleftclicked() and dropdown.Expanded then -- Click outside to close
                        dropdown.Expanded = false
                        for _, opt_elem in ipairs(dropdown.OptionElements) do
                            opt_elem.drawing_bg.Visible = false
                            opt_elem.drawing_text.Visible = false
                        end
                        wait(0.1)
                    end
                end

                if dropdown.Expanded then
                    for _, opt_elem in ipairs(dropdown.OptionElements) do
                        local opt_x, opt_y = opt_elem.drawing_bg.Position[1], opt_elem.drawing_bg.Position[2]
                        local opt_w, opt_h = opt_elem.drawing_bg.Size[1], opt_elem.drawing_bg.Size[2]
                        if is_point_in_rect(mouse_x, mouse_y, opt_x, opt_y, opt_w, opt_h) then
                            opt_elem.drawing_bg.Color = {90, 90, 90} -- Option hover color
                            if isleftclicked() then
                                dropdown.Selected = opt_elem.text
                                dropdown.DrawingObjects.text.Text = dropdown.Name .. ": " .. dropdown.Selected
                                dropdown.Callback(dropdown.Selected)
                                dropdown.Expanded = false
                                for _, oe in ipairs(dropdown.OptionElements) do
                                    oe.drawing_bg.Visible = false
                                    oe.drawing_text.Visible = false
                                end
                                wait(0.1)
                            end
                        else
                            opt_elem.drawing_bg.Color = {70, 70, 70} -- Option default color
                        end
                    end
                end
            end
            wait()
        end
    end)

    return dropdown
end

-- MultiDropdown Class (Simplified, similar to Dropdown but with multiple selections)
local MultiDropdown = UIElement:new({Type = "MultiDropdown"})
function Section:MultiDropdown(props)
    local multidropdown = MultiDropdown:new(props)
    multidropdown.Parent = self
    multidropdown.Selected = props.Default or {}
    multidropdown.Options = props.Options or {}
    multidropdown.Callback = props.Callback or function(selected) warn("MultiDropdown '" .. multidropdown.Name .. "' selected: " .. table.concat(selected, ", ")) end
    multidropdown.Expanded = false

    multidropdown.Position = {self.Position[1] + 5, self.Position[2] + self.ContentOffset}
    multidropdown.Size = {self.Size[1] - 10, 25}
    multidropdown.Color = {60, 60, 60}
    multidropdown.Opacity = 1
    multidropdown.ZIndex = self.ZIndex + 1

    self.ContentOffset = self.ContentOffset + multidropdown.Size[2] + 5

    -- Draw multidropdown main button
    multidropdown.DrawingObjects.button = Drawing.new("Square")
    multidropdown.DrawingObjects.button.Position = multidropdown.Position
    multidropdown.DrawingObjects.button.Size = multidropdown.Size
    multidropdown.DrawingObjects.button.Color = multidropdown.Color
    multidropdown.DrawingObjects.button.Opacity = multidropdown.Opacity
    multidropdown.DrawingObjects.button.Filled = true
    multidropdown.DrawingObjects.button.ZIndex = multidropdown.ZIndex

    -- Draw multidropdown text
    multidropdown.DrawingObjects.text = Drawing.new("Text")
    multidropdown.DrawingObjects.text.Text = multidropdown.Name .. ": " .. (table.concat(multidropdown.Selected, ", ") or "None")
    multidropdown.DrawingObjects.text.Position = {multidropdown.Position[1] + 5, multidropdown.Position[2] + 5}
    multidropdown.DrawingObjects.text.Color = {255, 255, 255}
    multidropdown.DrawingObjects.text.Size = 14
    multidropdown.DrawingObjects.text.ZIndex = multidropdown.ZIndex + 1

    multidropdown.OptionElements = {}
    for i, option_text in ipairs(multidropdown.Options) do
        local option_pos_y = multidropdown.Position[2] + multidropdown.Size[2] + (i - 1) * 20
        local option_element = {
            text = option_text,
            position = {multidropdown.Position[1], option_pos_y},
            size = {multidropdown.Size[1], 20},
            drawing_bg = Drawing.new("Square"),
            drawing_text = Drawing.new("Text"),
            is_selected = false
        }
        -- Check if default includes this option
        for _, v in ipairs(multidropdown.Selected) do
            if v == option_text then
                option_element.is_selected = true
                break
            end
        end

        option_element.drawing_bg.Position = option_element.position
        option_element.drawing_bg.Size = option_element.size
        option_element.drawing_bg.Color = option_element.is_selected and {0, 150, 0} or {70, 70, 70}
        option_element.drawing_bg.Opacity = 1
        option_element.drawing_bg.Filled = true
        option_element.drawing_bg.ZIndex = multidropdown.ZIndex + 2
        option_element.drawing_bg.Visible = false

        option_element.drawing_text.Text = option_text
        option_element.drawing_text.Position = {option_element.position[1] + 5, option_element.position[2] + 3}
        option_element.drawing_text.Color = {255, 255, 255}
        option_element.drawing_text.Size = 12
        option_element.drawing_text.ZIndex = multidropdown.ZIndex + 3
        option_element.drawing_text.Visible = false

        table.insert(multidropdown.OptionElements, option_element)
        table.insert(multidropdown.DrawingObjects, option_element.drawing_bg)
        table.insert(multidropdown.DrawingObjects, option_element.drawing_text)
    end

    table.insert(self.Children, multidropdown)
    multidropdown:SetVisible(self.Visible)

    -- MultiDropdown logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local btn_x, btn_y = multidropdown.DrawingObjects.button.Position[1], multidropdown.DrawingObjects.button.Position[2]
            local btn_w, btn_h = multidropdown.DrawingObjects.button.Size[1], multidropdown.DrawingObjects.button.Size[2]

            if multidropdown.Visible then
                if is_point_in_rect(mouse_x, mouse_y, btn_x, btn_y, btn_w, btn_h) then
                    multidropdown.DrawingObjects.button.Color = {80, 80, 80} -- Hover color
                    if isleftclicked() then
                        multidropdown.Expanded = not multidropdown.Expanded
                        for _, opt_elem in ipairs(multidropdown.OptionElements) do
                            opt_elem.drawing_bg.Visible = multidropdown.Expanded
                            opt_elem.drawing_text.Visible = multidropdown.Expanded
                        end
                        wait(0.1)
                    end
                else
                    multidropdown.DrawingObjects.button.Color = {60, 60, 60} -- Default color
                    -- No auto-close on click outside for multi-dropdown, user must click main button again
                end

                if multidropdown.Expanded then
                    for _, opt_elem in ipairs(multidropdown.OptionElements) do
                        local opt_x, opt_y = opt_elem.drawing_bg.Position[1], opt_elem.drawing_bg.Position[2]
                        local opt_w, opt_h = opt_elem.drawing_bg.Size[1], opt_elem.drawing_bg.Size[2]
                        if is_point_in_rect(mouse_x, mouse_y, opt_x, opt_y, opt_w, opt_h) then
                            opt_elem.drawing_bg.Color = {90, 90, 90} -- Option hover color
                            if isleftclicked() then
                                opt_elem.is_selected = not opt_elem.is_selected
                                opt_elem.drawing_bg.Color = opt_elem.is_selected and {0, 150, 0} or {70, 70, 70}

                                -- Update selected list
                                multidropdown.Selected = {}
                                for _, oe in ipairs(multidropdown.OptionElements) do
                                    if oe.is_selected then
                                        table.insert(multidropdown.Selected, oe.text)
                                    end
                                end
                                multidropdown.DrawingObjects.text.Text = multidropdown.Name .. ": " .. (table.concat(multidropdown.Selected, ", ") or "None")
                                multidropdown.Callback(multidropdown.Selected)
                                wait(0.1)
                            end
                        else
                            opt_elem.drawing_bg.Color = opt_elem.is_selected and {0, 150, 0} or {70, 70, 70} -- Option default color
                        end
                    end
                end
            end
            wait()
        end
    end)

    return multidropdown
end

-- Slider Class
local Slider = UIElement:new({Type = "Slider"})
function Section:Slider(props)
    local slider = Slider:new(props)
    slider.Parent = self
    slider.Min = props.Min or 0
    slider.Max = props.Max or 100
    slider.Default = props.Default or slider.Min
    slider.Value = slider.Default
    slider.Units = props.Units or ""
    slider.Increment = props.Increment or 1
    slider.Callback = props.Callback or function(value) warn("Slider '" .. slider.Name .. "' value: " .. value) end
    slider.Dragging = false

    slider.Position = {self.Position[1] + 5, self.Position[2] + self.ContentOffset}
    slider.Size = {self.Size[1] - 10, 30} -- Slightly taller for slider bar
    slider.Color = {60, 60, 60}
    slider.Opacity = 1
    slider.ZIndex = self.ZIndex + 1

    self.ContentOffset = self.ContentOffset + slider.Size[2] + 5

    -- Draw slider background
    slider.DrawingObjects.background = Drawing.new("Square")
    slider.DrawingObjects.background.Position = slider.Position
    slider.DrawingObjects.background.Size = slider.Size
    slider.DrawingObjects.background.Color = slider.Color
    slider.DrawingObjects.background.Opacity = slider.Opacity
    slider.DrawingObjects.background.Filled = true
    slider.DrawingObjects.background.ZIndex = slider.ZIndex

    -- Draw slider text
    slider.DrawingObjects.text = Drawing.new("Text")
    slider.DrawingObjects.text.Text = slider.Name .. ": " .. tostring(slider.Value) .. slider.Units
    slider.DrawingObjects.text.Position = {slider.Position[1] + 5, slider.Position[2] + 3}
    slider.DrawingObjects.text.Color = {255, 255, 255}
    slider.DrawingObjects.text.Size = 14
    slider.DrawingObjects.text.ZIndex = slider.ZIndex + 1

    -- Draw slider bar
    slider.DrawingObjects.bar = Drawing.new("Square")
    slider.DrawingObjects.bar.Position = {slider.Position[1] + 5, slider.Position[2] + slider.Size[2] - 10}
    slider.DrawingObjects.bar.Size = {slider.Size[1] - 10, 5}
    slider.DrawingObjects.bar.Color = {40, 40, 40}
    slider.DrawingObjects.bar.Opacity = 1
    slider.DrawingObjects.bar.Filled = true
    slider.DrawingObjects.bar.ZIndex = slider.ZIndex + 1

    -- Draw slider thumb
    slider.DrawingObjects.thumb = Drawing.new("Square")
    slider.DrawingObjects.thumb.Position = {slider.Position[1] + 5 + (slider.Value - slider.Min) / (slider.Max - slider.Min) * (slider.Size[1] - 10 - 10), slider.Position[2] + slider.Size[2] - 13} -- -10 for thumb width
    slider.DrawingObjects.thumb.Size = {10, 10}
    slider.DrawingObjects.thumb.Color = {0, 150, 255}
    slider.DrawingObjects.thumb.Opacity = 1
    slider.DrawingObjects.thumb.Filled = true
    slider.DrawingObjects.thumb.ZIndex = slider.ZIndex + 2

    table.insert(self.Children, slider)
    slider:SetVisible(self.Visible)

    -- Slider logic
    spawn(function()
        while true do
            local mouse_x, mouse_y = getmouseposition()
            local bar_x, bar_y = slider.DrawingObjects.bar.Position[1], slider.DrawingObjects.bar.Position[2]
            local bar_w, bar_h = slider.DrawingObjects.bar.Size[1], slider.DrawingObjects.bar.Size[2]

            if slider.Visible then
                if is_point_in_rect(mouse_x, mouse_y, bar_x, bar_y, bar_w, bar_h) and isleftpressed() then
                    slider.Dragging = true
                elseif not isleftpressed() then
                    slider.Dragging = false
                end

                if slider.Dragging then
                    local relative_x = mouse_x - bar_x
                    local percentage = math.max(0, math.min(1, relative_x / bar_w))
                    local new_value = slider.Min + percentage * (slider.Max - slider.Min)
                    new_value = math.floor(new_value / slider.Increment) * slider.Increment -- Snap to increment
                    new_value = math.max(slider.Min, math.min(slider.Max, new_value)) -- Clamp to min/max

                    if new_value ~= slider.Value then
                        slider.Value = new_value
                        slider.DrawingObjects.text.Text = slider.Name .. ": " .. tostring(slider.Value) .. slider.Units
                        slider.Callback(slider.Value)
                        -- Update thumb position
                        local thumb_x_pos = bar_x + percentage * (bar_w - slider.DrawingObjects.thumb.Size[1])
                        slider.DrawingObjects.thumb.Position = {thumb_x_pos, slider.DrawingObjects.thumb.Position[2]}
                    end
                end
            end
            wait()
        end
    end)

    return slider
end

-- Global UI rendering and input loop (main loop)
spawn(function()
    while true do
        -- This loop is primarily for handling global UI state like dragging
        -- Individual element logic is handled in their own spawns
        wait()
    end
end)

return Library
