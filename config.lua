-- Severe UI Library
-- Built for Severe External with Luau support
-- Uses Severe's Drawing API for rendering

local Library = {}
Library.__index = Library

-- Constants
local COLORS = {
    Background = {25, 25, 25},
    Secondary = {35, 35, 35},
    Border = {55, 55, 55},
    Text = {255, 255, 255},
    TextDark = {180, 180, 180},
    Accent = {0, 162, 255},
    Success = {76, 175, 80},
    Warning = {255, 193, 7},
    Error = {244, 67, 54}
}

local FONTS = {
    Regular = 2,
    Bold = 3,
    Light = 1
}

local KEYCODES = {
    [8] = "Backspace", [9] = "Tab", [13] = "Enter", [16] = "Shift", [17] = "Ctrl",
    [18] = "Alt", [19] = "Pause", [20] = "CapsLock", [27] = "Escape", [32] = "Space",
    [33] = "PageUp", [34] = "PageDown", [35] = "End", [36] = "Home", [37] = "Left",
    [38] = "Up", [39] = "Right", [40] = "Down", [45] = "Insert", [46] = "Delete",
    [48] = "Zero", [49] = "One", [50] = "Two", [51] = "Three", [52] = "Four",
    [53] = "Five", [54] = "Six", [55] = "Seven", [56] = "Eight", [57] = "Nine",
    [65] = "A", [66] = "B", [67] = "C", [68] = "D", [69] = "E", [70] = "F",
    [71] = "G", [72] = "H", [73] = "I", [74] = "J", [75] = "K", [76] = "L",
    [77] = "M", [78] = "N", [79] = "O", [80] = "P", [81] = "Q", [82] = "R",
    [83] = "S", [84] = "T", [85] = "U", [86] = "V", [87] = "W", [88] = "X",
    [89] = "Y", [90] = "Z", [112] = "F1", [113] = "F2", [114] = "F3", [115] = "F4",
    [116] = "F5", [117] = "F6", [118] = "F7", [119] = "F8", [120] = "F9", [121] = "F10",
    [122] = "F11", [123] = "F12"
}

-- Utility Functions
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function splitText(text, maxWidth, font, size)
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end
    
    local lines = {}
    local currentLine = ""
    
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        -- Approximate text width calculation
        local textWidth = #testLine * (size * 0.6)
        
        if textWidth <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
                currentLine = word
            else
                table.insert(lines, word)
            end
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end

-- Animation System
local Animations = {}
Animations.__index = Animations

function Animations.new()
    return setmetatable({
        tweens = {},
        lastTime = tick()
    }, Animations)
end

function Animations:add(target, property, endValue, duration, easing)
    local tween = {
        target = target,
        property = property,
        startValue = target[property] or 0,
        endValue = endValue,
        duration = duration or 0.3,
        startTime = tick(),
        easing = easing or "linear"
    }
    
    table.insert(self.tweens, tween)
    return tween
end

function Animations:update()
    local currentTime = tick()
    
    for i = #self.tweens, 1, -1 do
        local tween = self.tweens[i]
        local elapsed = currentTime - tween.startTime
        local progress = math.min(elapsed / tween.duration, 1)
        
        -- Apply easing
        local easedProgress = progress
        if tween.easing == "ease-out" then
            easedProgress = 1 - (1 - progress) ^ 2
        elseif tween.easing == "ease-in" then
            easedProgress = progress ^ 2
        end
        
        tween.target[tween.property] = lerp(tween.startValue, tween.endValue, easedProgress)
        
        if progress >= 1 then
            table.remove(self.tweens, i)
        end
    end
end

-- Global animation manager
local animationManager = Animations.new()

-- Notification System
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new()
    return setmetatable({
        notifications = {},
        yOffset = 50
    }, NotificationSystem)
end

function NotificationSystem:show(text, type, duration)
    local screenX, screenY = getscreendimensions()
    local notification = {
        text = text,
        type = type or "info",
        duration = duration or 3,
        startTime = tick(),
        x = screenX - 320,
        y = self.yOffset,
        alpha = 0,
        elements = {}
    }
    
    -- Create visual elements
    local bg = Drawing.new("Square")
    bg.Size = {300, 60}
    bg.Position = {notification.x, notification.y}
    bg.Color = type == "error" and COLORS.Error or type == "success" and COLORS.Success or COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 1000
    
    local border = Drawing.new("Square")
    border.Size = {300, 60}
    border.Position = {notification.x, notification.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 1001
    
    local textObj = Drawing.new("Text")
    textObj.Text = text
    textObj.Font = FONTS.Regular
    textObj.Size = 14
    textObj.Position = {notification.x + 10, notification.y + 20}
    textObj.Color = COLORS.Text
    textObj.Visible = true
    textObj.ZIndex = 1002
    
    notification.elements = {bg, border, textObj}
    
    -- Animate in
    animationManager:add(notification, "alpha", 1, 0.3, "ease-out")
    
    table.insert(self.notifications, notification)
    self.yOffset = self.yOffset + 70
    
    return notification
end

function NotificationSystem:update()
    local currentTime = tick()
    
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]
        
        if currentTime - notif.startTime > notif.duration then
            -- Animate out
            animationManager:add(notif, "alpha", 0, 0.3, "ease-in")
            
            -- Remove after animation
            spawn(function()
                wait(0.3)
                for _, element in pairs(notif.elements) do
                    if element and element.Remove then
                        element:Remove()
                    end
                end
            end)
            
            table.remove(self.notifications, i)
            self.yOffset = self.yOffset - 70
        else
            -- Update opacity
            for _, element in pairs(notif.elements) do
                if element then
                    element.Opacity = notif.alpha
                end
            end
        end
    end
end

-- Global notification system
local notifications = NotificationSystem.new()

-- Input Manager
local InputManager = {}
InputManager.__index = InputManager

function InputManager.new()
    return setmetatable({
        callbacks = {},
        mousePosition = {x = 0, y = 0},
        keybindListeners = {},
        dragData = nil
    }, InputManager)
end

function InputManager:addCallback(event, callback)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    table.insert(self.callbacks[event], callback)
end

function InputManager:trigger(event, ...)
    if self.callbacks[event] then
        for _, callback in pairs(self.callbacks[event]) do
            callback(...)
        end
    end
end

function InputManager:addKeybindListener(keybind, callback)
    self.keybindListeners[keybind] = callback
end

function InputManager:removeKeybindListener(keybind)
    self.keybindListeners[keybind] = nil
end

function InputManager:update()
    -- Update mouse position
    self.mousePosition.x, self.mousePosition.y = getmouseposition()
    
    -- Check for keybind presses
    local pressedKeys = getpressedkeys()
    for keybind, callback in pairs(self.keybindListeners) do
        local keys = string.split(keybind, "+")
        local allPressed = true
        
        for _, key in pairs(keys) do
            local found = false
            for _, pressedKey in pairs(pressedKeys) do
                if pressedKey:lower() == key:lower() then
                    found = true
                    break
                end
            end
            if not found then
                allPressed = false
                break
            end
        end
        
        if allPressed and #keys > 0 then
            callback()
        end
    end
    
    -- Handle mouse events
    if isleftclicked() then
        self:trigger("mouseClick", self.mousePosition.x, self.mousePosition.y, 1)
    end
    
    if isrightclicked() then
        self:trigger("mouseClick", self.mousePosition.x, self.mousePosition.y, 2)
    end
    
    -- Handle dragging
    if self.dragData then
        if isleftpressed() then
            local newX = self.mousePosition.x - self.dragData.offsetX
            local newY = self.mousePosition.y - self.dragData.offsetY
            
            if self.dragData.callback then
                self.dragData.callback(newX, newY)
            end
        else
            self.dragData = nil
        end
    end
end

function InputManager:startDrag(offsetX, offsetY, callback)
    self.dragData = {
        offsetX = offsetX,
        offsetY = offsetY,
        callback = callback
    }
end

-- Global input manager
local inputManager = InputManager.new()

-- UI Elements
local Element = {}
Element.__index = Element

function Element.new(type, parent)
    local element = setmetatable({
        type = type,
        parent = parent,
        children = {},
        visible = true,
        position = {x = 0, y = 0},
        size = {w = 100, h = 20},
        drawObjects = {},
        properties = {}
    }, Element)
    
    if parent then
        table.insert(parent.children, element)
    end
    
    return element
end

function Element:destroy()
    for _, obj in pairs(self.drawObjects) do
        if obj and obj.Remove then
            obj:Remove()
        end
    end
    
    for _, child in pairs(self.children) do
        child:destroy()
    end
    
    if self.parent then
        for i, child in pairs(self.parent.children) do
            if child == self then
                table.remove(self.parent.children, i)
                break
            end
        end
    end
end

function Element:setVisible(visible)
    self.visible = visible
    for _, obj in pairs(self.drawObjects) do
        if obj then
            obj.Visible = visible
        end
    end
end

-- Button Element
local Button = setmetatable({}, {__index = Element})
Button.__index = Button

function Button.new(parent, config)
    local button = setmetatable(Element.new("Button", parent), Button)
    
    button.name = config.Name or "Button"
    button.tooltip = config.Tooltip
    button.callback = config.Callback or function() end
    
    button:createVisuals()
    button:setupEvents()
    
    return button
end

function Button:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 10
    
    local border = Drawing.new("Square")
    border.Size = {self.size.w, self.size.h}
    border.Position = {self.position.x, self.position.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 11
    
    local text = Drawing.new("Text")
    text.Text = self.name
    text.Font = FONTS.Regular
    text.Size = 12
    text.Position = {self.position.x + 10, self.position.y + 5}
    text.Color = COLORS.Text
    text.Visible = true
    text.ZIndex = 12
    
    self.drawObjects = {bg, border, text}
end

function Button:setupEvents()
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, self.position.x, self.position.y, self.size.w, self.size.h) then
            self:onClick()
        end
    end)
end

function Button:onClick()
    -- Visual feedback
    local bg = self.drawObjects[1]
    if bg then
        bg.Color = COLORS.Accent
        spawn(function()
            wait(0.1)
            bg.Color = COLORS.Secondary
        end)
    end
    
    self.callback()
end

-- Toggle Element
local Toggle = setmetatable({}, {__index = Element})
Toggle.__index = Toggle

function Toggle.new(parent, config)
    local toggle = setmetatable(Element.new("Toggle", parent), Toggle)
    
    toggle.name = config.Name or "Toggle"
    toggle.tooltip = config.Tooltip
    toggle.default = config.Default or false
    toggle.callback = config.Callback or function() end
    toggle.state = toggle.default
    toggle.keybind = nil
    
    toggle:createVisuals()
    toggle:setupEvents()
    
    return toggle
end

function Toggle:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 10
    
    local border = Drawing.new("Square")
    border.Size = {self.size.w, self.size.h}
    border.Position = {self.position.x, self.position.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    bg.ZIndex = 11
    
    local checkbox = Drawing.new("Square")
    checkbox.Size = {12, 12}
    checkbox.Position = {self.position.x + self.size.w - 20, self.position.y + 4}
    checkbox.Color = self.state and COLORS.Accent or COLORS.Border
    checkbox.Filled = self.state
    checkbox.Visible = true
    checkbox.ZIndex = 12
    
    local text = Drawing.new("Text")
    text.Text = self.name
    text.Font = FONTS.Regular
    text.Size = 12
    text.Position = {self.position.x + 10, self.position.y + 5}
    text.Color = COLORS.Text
    text.Visible = true
    text.ZIndex = 12
    
    self.drawObjects = {bg, border, checkbox, text}
end

function Toggle:setupEvents()
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, self.position.x, self.position.y, self.size.w, self.size.h) then
            self:toggle()
        end
    end)
end

function Toggle:toggle()
    self.state = not self.state
    
    local checkbox = self.drawObjects[3]
    if checkbox then
        checkbox.Color = self.state and COLORS.Accent or COLORS.Border
        checkbox.Filled = self.state
    end
    
    self.callback(self.state)
end

function Toggle:Keybind(config)
    local keybind = {
        default = config.Default or "None",
        callback = config.Callback or function() end,
        current = config.Default or "None",
        listening = false
    }
    
    self.keybind = keybind
    
    if keybind.current ~= "None" then
        inputManager:addKeybindListener(keybind.current, function()
            self:toggle()
            keybind.callback(self.state)
        end)
    end
    
    return keybind
end

-- Dropdown Element
local Dropdown = setmetatable({}, {__index = Element})
Dropdown.__index = Dropdown

function Dropdown.new(parent, config)
    local dropdown = setmetatable(Element.new("Dropdown", parent), Dropdown)
    
    dropdown.name = config.Name or "Dropdown"
    dropdown.tooltip = config.Tooltip
    dropdown.default = config.Default or "None"
    dropdown.options = config.Options or {}
    dropdown.callback = config.Callback or function() end
    dropdown.selected = dropdown.default
    dropdown.opened = false
    
    dropdown:createVisuals()
    dropdown:setupEvents()
    
    return dropdown
end

function Dropdown:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 10
    
    local border = Drawing.new("Square")
    border.Size = {self.size.w, self.size.h}
    border.Position = {self.position.x, self.position.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 11
    
    local label = Drawing.new("Text")
    label.Text = self.name
    label.Font = FONTS.Regular
    label.Size = 12
    label.Position = {self.position.x + 10, self.position.y + 5}
    label.Color = COLORS.Text
    label.Visible = true
    label.ZIndex = 12
    
    local value = Drawing.new("Text")
    value.Text = self.selected
    value.Font = FONTS.Regular
    value.Size = 12
    value.Position = {self.position.x + self.size.w - 100, self.position.y + 5}
    value.Color = COLORS.TextDark
    value.Visible = true
    value.ZIndex = 12
    
    local arrow = Drawing.new("Text")
    arrow.Text = "v"
    arrow.Font = FONTS.Regular
    arrow.Size = 12
    arrow.Position = {self.position.x + self.size.w - 20, self.position.y + 5}
    arrow.Color = COLORS.TextDark
    arrow.Visible = true
    arrow.ZIndex = 12
    
    self.drawObjects = {bg, border, label, value, arrow}
end

function Dropdown:setupEvents()
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, self.position.x, self.position.y, self.size.w, self.size.h) then
            self:toggleDropdown()
        end
    end)
end

function Dropdown:toggleDropdown()
    self.opened = not self.opened
    -- Implementation for dropdown menu would go here
    -- For brevity, this is simplified
end

-- Multi Dropdown Element
local MultiDropdown = setmetatable({}, {__index = Element})
MultiDropdown.__index = MultiDropdown

function MultiDropdown.new(parent, config)
    local dropdown = setmetatable(Element.new("MultiDropdown", parent), MultiDropdown)
    
    dropdown.name = config.Name or "Multi Dropdown"
    dropdown.tooltip = config.Tooltip
    dropdown.default = config.Default or {"None"}
    dropdown.options = config.Options or {}
    dropdown.callback = config.Callback or function() end
    dropdown.selected = dropdown.default
    dropdown.opened = false
    
    dropdown:createVisuals()
    dropdown:setupEvents()
    
    return dropdown
end

function MultiDropdown:createVisuals()
    -- Similar to Dropdown but with multi-select capability
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 10
    
    self.drawObjects = {bg}
end

function MultiDropdown:setupEvents()
    -- Multi-select logic would go here
end

-- Slider Element
local Slider = setmetatable({}, {__index = Element})
Slider.__index = Slider

function Slider.new(parent, config)
    local slider = setmetatable(Element.new("Slider", parent), Slider)
    
    slider.name = config.Name or "Slider"
    slider.tooltip = config.Tooltip
    slider.min = config.Min or 0
    slider.max = config.Max or 100
    slider.default = config.Default or 50
    slider.units = config.Units or ""
    slider.increment = config.Increment or 1
    slider.callback = config.Callback or function() end
    slider.value = slider.default
    slider.dragging = false
    
    slider:createVisuals()
    slider:setupEvents()
    
    return slider
end

function Slider:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Secondary
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 10
    
    local border = Drawing.new("Square")
    border.Size = {self.size.w, self.size.h}
    border.Position = {self.position.x, self.position.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 11
    
    local label = Drawing.new("Text")
    label.Text = self.name
    label.Font = FONTS.Regular
    label.Size = 12
    label.Position = {self.position.x + 10, self.position.y + 5}
    label.Color = COLORS.Text
    label.Visible = true
    label.ZIndex = 12
    
    local valueText = Drawing.new("Text")
    valueText.Text = tostring(self.value) .. self.units
    valueText.Font = FONTS.Regular
    valueText.Size = 12
    valueText.Position = {self.position.x + self.size.w - 60, self.position.y + 5}
    valueText.Color = COLORS.TextDark
    valueText.Visible = true
    valueText.ZIndex = 12
    
    self.drawObjects = {bg, border, label, valueText}
end

function Slider:setupEvents()
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, self.position.x, self.position.y, self.size.w, self.size.h) then
            self.dragging = true
            self:updateValue(x)
        end
    end)
end

function Slider:updateValue(mouseX)
    local relativeX = mouseX - self.position.x
    local percentage = math.max(0, math.min(1, relativeX / self.size.w))
    self.value = self.min + (self.max - self.min) * percentage
    self.value = math.floor(self.value / self.increment + 0.5) * self.increment
    
    local valueText = self.drawObjects[4]
    if valueText then
        valueText.Text = tostring(self.value) .. self.units
    end
    
    self.callback(self.value)
end

-- Section Element
local Section = setmetatable({}, {__index = Element})
Section.__index = Section

function Section.new(parent, config)
    local section = setmetatable(Element.new("Section", parent), Section)
    
    section.name = config.Name or "Section"
    section.side = config.Side or "Left"
    section.elements = {}
    section.yOffset = 30
    
    section:createVisuals()
    
    return section
end

function Section:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {280, 400}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Background
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 5
    
    local border = Drawing.new("Square")
    border.Size = {280, 400}
    border.Position = {self.position.x, self.position.y}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 6
    
    local title = Drawing.new("Text")
    title.Text = self.name
    title.Font = FONTS.Bold
    title.Size = 14
    title.Position = {self.position.x + 10, self.position.y + 8}
    title.Color = COLORS.Text
    title.Visible = true
    title.ZIndex = 7
    
    self.drawObjects = {bg, border, title}
end

function Section:Button(config)
    local button = Button.new(self, config)
    button.position = {x = self.position.x + 10, y = self.position.y + self.yOffset}
    button.size = {w = 260, h = 25}
    button:createVisuals()
    
    self.yOffset = self.yOffset + 30
    table.insert(self.elements, button)
    return button
end

function Section:Toggle(config)
    local toggle = Toggle.new(self, config)
    toggle.position = {x = self.position.x + 10, y = self.position.y + self.yOffset}
    toggle.size = {w = 260, h = 25}
    toggle:createVisuals()
    
    self.yOffset = self.yOffset + 30
    table.insert(self.elements, toggle)
    return toggle
end

function Section:Dropdown(config)
    local dropdown = Dropdown.new(self, config)
    dropdown.position = {x = self.position.x + 10, y = self.position.y + self.yOffset}
    dropdown.size = {w = 260, h = 25}
    dropdown:createVisuals()
    
    self.yOffset = self.yOffset + 30
    table.insert(self.elements, dropdown)
    return dropdown
end

function Section:MultiDropdown(config)
    local dropdown = MultiDropdown.new(self, config)
    dropdown.position = {x = self.position.x + 10, y = self.position.y + self.yOffset}
    dropdown.size = {w = 260, h = 25}
    dropdown:createVisuals()
    
    self.yOffset = self.yOffset + 30
    table.insert(self.elements, dropdown)
    return dropdown
end

function Section:Slider(config)
    local slider = Slider.new(self, config)
    slider.position = {x = self.position.x + 10, y = self.position.y + self.yOffset}
    slider.size = {w = 260, h = 25}
    slider:createVisuals()
    
    self.yOffset = self.yOffset + 30
    table.insert(self.elements, slider)
    return slider
end

-- Tab Element
local Tab = setmetatable({}, {__index = Element})
Tab.__index = Tab

function Tab.new(parent, config)
    local tab = setmetatable(Element.new("Tab", parent), Tab)
    
    tab.name = config.Name or "Tab"
    tab.sections = {}
    tab.leftSections = {}
    tab.rightSections = {}
    
    return tab
end

function Tab:Section(config)
    local section = Section.new(self, config)
    
    if config.Side == "Right" then
        section.position = {x = 320, y = 80 + #self.rightSections * 420}
        table.insert(self.rightSections, section)
    else
        section.position = {x = 20, y = 80 + #self.leftSections * 420}
        table.insert(self.leftSections, section)
    end
    
    section:createVisuals()
    table.insert(self.sections, section)
    return section
end

-- Main UI Element
local UI = setmetatable({}, {__index = Element})
UI.__index = UI

function UI.new(config)
    local ui = setmetatable(Element.new("UI", nil), UI)
    
    ui.name = config.Name or "Severe UI"
    ui.tabs = {}
    ui.currentTab = nil
    ui.visible = true
    ui.position = {x = 100, y = 100}
    ui.size = {w = 620, h = 500}
    ui.dragging = false
    ui.keybindViewer = {
        enabled = false,
        keybinds = {},
        elements = {}
    }
    
    ui:createVisuals()
    ui:setupEvents()
    ui:startUpdateLoop()
    
    return ui
end

function UI:createVisuals()
    local bg = Drawing.new("Square")
    bg.Size = {self.size.w, self.size.h}
    bg.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Background
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 1
    
    local border = Drawing.new("Square")
    border.Size = {self.size.w, self.size.h}
    border.Position = {self.position.x, self.position.y}
    bg.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 2
    
    local titleBar = Drawing.new("Square")
    titleBar.Size = {self.size.w, 40}
    titleBar.Position = {self.position.x, self.position.y}
    titleBar.Color = COLORS.Secondary
    titleBar.Filled = true
    titleBar.Visible = true
    titleBar.ZIndex = 3
    
    local titleBorder = Drawing.new("Square")
    titleBorder.Size = {self.size.w, 40}
    titleBorder.Position = {self.position.x, self.position.y}
    titleBorder.Color = COLORS.Border
    titleBorder.Thickness = 1
    titleBorder.Filled = false
    titleBorder.Visible = true
    titleBorder.ZIndex = 4
    
    local title = Drawing.new("Text")
    title.Text = self.name
    title.Font = FONTS.Bold
    title.Size = 16
    title.Position = {self.position.x + 15, self.position.y + 12}
    title.Color = COLORS.Text
    title.Visible = true
    title.ZIndex = 5
    
    self.drawObjects = {bg, border, titleBar, titleBorder, title}
end

function UI:setupEvents()
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, self.position.x, self.position.y, self.size.w, 40) then
            -- Start dragging
            inputManager:startDrag(
                x - self.position.x,
                y - self.position.y,
                function(newX, newY)
                    self:setPosition(newX, newY)
                end
            )
        end
    end)
end

function UI:setPosition(x, y)
    local deltaX = x - self.position.x
    local deltaY = y - self.position.y
    
    self.position.x = x
    self.position.y = y
    
    -- Update main UI elements
    for _, obj in pairs(self.drawObjects) do
        if obj then
            obj.Position = {obj.Position[1] + deltaX, obj.Position[2] + deltaY}
        end
    end
    
    -- Update tab buttons
    for i, tab in pairs(self.tabs) do
        local tabButton = tab.button
        if tabButton then
            tabButton.Position = {tabButton.Position[1] + deltaX, tabButton.Position[2] + deltaY}
        end
    end
    
    -- Update sections and their elements
    for _, tab in pairs(self.tabs) do
        for _, section in pairs(tab.sections) do
            section.position.x = section.position.x + deltaX
            section.position.y = section.position.y + deltaY
            
            for _, obj in pairs(section.drawObjects) do
                if obj then
                    obj.Position = {obj.Position[1] + deltaX, obj.Position[2] + deltaY}
                end
            end
            
            -- Update section elements
            for _, element in pairs(section.elements) do
                element.position.x = element.position.x + deltaX
                element.position.y = element.position.y + deltaY
                
                for _, obj in pairs(element.drawObjects) do
                    if obj then
                        obj.Position = {obj.Position[1] + deltaX, obj.Position[2] + deltaY}
                    end
                end
            end
        end
    end
end

function UI:Tab(config)
    local tab = Tab.new(self, config)
    local tabIndex = #self.tabs + 1
    
    -- Create tab button
    local tabButton = Drawing.new("Square")
    tabButton.Size = {100, 25}
    tabButton.Position = {self.position.x + 15 + (tabIndex - 1) * 105, self.position.y + 50}
    tabButton.Color = tabIndex == 1 and COLORS.Accent or COLORS.Secondary
    tabButton.Filled = true
    tabButton.Visible = true
    tabButton.ZIndex = 8
    
    local tabButtonBorder = Drawing.new("Square")
    tabButtonBorder.Size = {100, 25}
    tabButtonBorder.Position = {self.position.x + 15 + (tabIndex - 1) * 105, self.position.y + 50}
    tabButtonBorder.Color = COLORS.Border
    tabButtonBorder.Thickness = 1
    tabButtonBorder.Filled = false
    tabButtonBorder.Visible = true
    tabButtonBorder.ZIndex = 9
    
    local tabText = Drawing.new("Text")
    tabText.Text = tab.name
    tabText.Font = FONTS.Regular
    tabText.Size = 12
    tabText.Position = {self.position.x + 25 + (tabIndex - 1) * 105, self.position.y + 56}
    tabText.Color = COLORS.Text
    tabText.Visible = true
    tabText.ZIndex = 10
    
    tab.button = tabButton
    tab.buttonBorder = tabButtonBorder
    tab.buttonText = tabText
    tab.index = tabIndex
    
    -- Setup tab click event
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, tabButton.Position[1], tabButton.Position[2], 100, 25) then
            self:switchTab(tabIndex)
        end
    end)
    
    table.insert(self.tabs, tab)
    
    if tabIndex == 1 then
        self.currentTab = tab
    else
        self:hideTab(tab)
    end
    
    return tab
end

function UI:switchTab(tabIndex)
    if self.currentTab then
        self:hideTab(self.currentTab)
        self.currentTab.button.Color = COLORS.Secondary
    end
    
    local newTab = self.tabs[tabIndex]
    if newTab then
        self.currentTab = newTab
        self:showTab(newTab)
        newTab.button.Color = COLORS.Accent
    end
end

function UI:hideTab(tab)
    for _, section in pairs(tab.sections) do
        section:setVisible(false)
        for _, element in pairs(section.elements) do
            element:setVisible(false)
        end
    end
end

function UI:showTab(tab)
    for _, section in pairs(tab.sections) do
        section:setVisible(true)
        for _, element in pairs(section.elements) do
            element:setVisible(true)
        end
    end
end

function UI:setVisible(visible)
    self.visible = visible
    
    -- Update main UI elements
    for _, obj in pairs(self.drawObjects) do
        if obj then
            obj.Visible = visible
        end
    end
    
    -- Update tabs
    for _, tab in pairs(self.tabs) do
        if tab.button then tab.button.Visible = visible end
        if tab.buttonBorder then tab.buttonBorder.Visible = visible end
        if tab.buttonText then tab.buttonText.Visible = visible end
        
        if visible and tab == self.currentTab then
            self:showTab(tab)
        else
            self:hideTab(tab)
        end
    end
end

function UI:updateKeybindViewer()
    if not self.keybindViewer.enabled then
        -- Hide all keybind viewer elements
        for _, element in pairs(self.keybindViewer.elements) do
            if element and element.Remove then
                element:Remove()
            end
        end
        self.keybindViewer.elements = {}
        return
    end
    
    -- Clear existing elements
    for _, element in pairs(self.keybindViewer.elements) do
        if element and element.Remove then
            element:Remove()
        end
    end
    self.keybindViewer.elements = {}
    
    local screenX, screenY = getscreendimensions()
    local viewerX = screenX - 220
    local viewerY = 50
    local yOffset = 0
    
    -- Create background
    local bg = Drawing.new("Square")
    bg.Size = {200, 30 + #self.keybindViewer.keybinds * 25}
    bg.Position = {viewerX, viewerY}
    bg.Color = COLORS.Background
    bg.Filled = true
    bg.Visible = true
    bg.ZIndex = 500
    
    local border = Drawing.new("Square")
    border.Size = {200, 30 + #self.keybindViewer.keybinds * 25}
    border.Position = {viewerX, viewerY}
    border.Color = COLORS.Border
    border.Thickness = 1
    border.Filled = false
    border.Visible = true
    border.ZIndex = 501
    
    local title = Drawing.new("Text")
    title.Text = "Keybinds"
    title.Font = FONTS.Bold
    title.Size = 14
    title.Position = {viewerX + 10, viewerY + 8}
    title.Color = COLORS.Text
    title.Visible = true
    title.ZIndex = 502
    
    table.insert(self.keybindViewer.elements, bg)
    table.insert(self.keybindViewer.elements, border)
    table.insert(self.keybindViewer.elements, title)
    
    yOffset = 30
    
    for _, keybind in pairs(self.keybindViewer.keybinds) do
        if keybind.key ~= "None" then
            local nameText = Drawing.new("Text")
            nameText.Text = keybind.name
            nameText.Font = FONTS.Regular
            nameText.Size = 12
            nameText.Position = {viewerX + 10, viewerY + yOffset}
            nameText.Color = COLORS.Text
            nameText.Visible = true
            nameText.ZIndex = 502
            
            local keyText = Drawing.new("Text")
            keyText.Text = "[" .. keybind.key .. "]"
            keyText.Font = FONTS.Regular
            keyText.Size = 12
            keyText.Position = {viewerX + 140, viewerY + yOffset}
            keyText.Color = COLORS.Accent
            keyText.Visible = true
            keyText.ZIndex = 502
            
            table.insert(self.keybindViewer.elements, nameText)
            table.insert(self.keybindViewer.elements, keyText)
            
            yOffset = yOffset + 20
        end
    end
end

function UI:addKeybind(name, key)
    table.insert(self.keybindViewer.keybinds, {name = name, key = key})
    self:updateKeybindViewer()
end

function UI:startUpdateLoop()
    thread.create("SevereUI_MainLoop", function()
        while true do
            inputManager:update()
            animationManager:update()
            notifications:update()
            wait(1/60) -- 60 FPS update loop
        end
    end)
end

-- Library Constructor
function Library:Create(config)
    return UI.new(config)
end

-- Extended Keybind functionality for Toggle
function Toggle:Keybind(config)
    local keybind = {
        default = config.Default or "None",
        callback = config.Callback or function() end,
        current = config.Default or "None",
        listening = false,
        toggle = self
    }
    
    self.keybind = keybind
    
    -- Create keybind button
    local keybindButton = Drawing.new("Square")
    keybindButton.Size = {50, 15}
    keybindButton.Position = {self.position.x + self.size.w - 70, self.position.y + 5}
    keybindButton.Color = COLORS.Border
    keybindButton.Filled = false
    keybindButton.Visible = true
    keybindButton.ZIndex = 13
    
    local keybindText = Drawing.new("Text")
    keybindText.Text = keybind.current
    keybindText.Font = FONTS.Regular
    keybindText.Size = 10
    keybindText.Position = {self.position.x + self.size.w - 65, self.position.y + 7}
    keybindText.Color = COLORS.TextDark
    keybindText.Visible = true
    keybindText.ZIndex = 14
    
    table.insert(self.drawObjects, keybindButton)
    table.insert(self.drawObjects, keybindText)
    
    -- Setup keybind click event
    inputManager:addCallback("mouseClick", function(x, y, button)
        if button == 1 and pointInRect(x, y, keybindButton.Position[1], keybindButton.Position[2], 50, 15) then
            keybind.listening = true
            keybindText.Text = "..."
            keybindButton.Color = COLORS.Accent
            
            -- Listen for key press
            thread.create("KeybindListener_" .. self.name, function()
                while keybind.listening do
                    local pressedKey = getpressedkey()
                    if pressedKey and pressedKey ~= "" then
                        keybind.listening = false
                        
                        if pressedKey == "Escape" then
                            keybind.current = "None"
                            if keybind.current ~= "None" then
                                inputManager:removeKeybindListener(keybind.current)
                            end
                        else
                            if keybind.current ~= "None" then
                                inputManager:removeKeybindListener(keybind.current)
                            end
                            keybind.current = pressedKey
                            inputManager:addKeybindListener(pressedKey, function()
                                self:toggle()
                                keybind.callback(self.state)
                            end)
                        end
                        
                        keybindText.Text = keybind.current
                        keybindButton.Color = COLORS.Border
                        
                        -- Update keybind viewer
                        local ui = self.parent.parent.parent -- Navigate up to UI
                        if ui and ui.addKeybind then
                            ui:addKeybind(self.name, keybind.current)
                        end
                        
                        break
                    end
                    wait(0.1)
                end
            end)
        end
    end)
    
    if keybind.current ~= "None" then
        inputManager:addKeybindListener(keybind.current, function()
            self:toggle()
            keybind.callback(self.state)
        end)
        
        -- Add to keybind viewer
        local ui = self.parent.parent.parent -- Navigate up to UI
        if ui and ui.addKeybind then
            ui:addKeybind(self.name, keybind.current)
        end
    end
    
    return keybind
end

-- Notification wrapper
function Library:Notify(text, type, duration)
    return notifications:show(text, type, duration)
end

-- Utility functions for users
function Library:GetMousePosition()
    return getmouseposition()
end

function Library:IsKeyPressed(key)
    local pressedKeys = getpressedkeys()
    for _, pressedKey in pairs(pressedKeys) do
        if pressedKey:lower() == key:lower() then
            return true
        end
    end
    return false
end

function Library:DestroyUI()
    Drawing.clear()
    thread.clear()
end

-- Return the library
return Library
