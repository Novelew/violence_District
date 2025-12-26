--!optimize 2
-- Arcane UI Library for V-Severe
-- Converted to use v-severe APIs: Drawing, task, getpressedkeys, isleftpressed, getmouseposition

local Players = game:GetService("Players")

Arcane = {}
local drawings = {}
local tabs = {}
ActiveKeybinds = {}
local ActiveNotifications = {}
local OpenDropdown = nil

local themes = {
    Default = {
        Background = Color3.fromRGB(15, 15, 15),
        Section = Color3.fromRGB(22, 22, 22),
        Accent = Color3.fromRGB(210, 140, 160),
        Outline = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(230, 230, 230),
        TextDark = Color3.fromRGB(140, 140, 140),
        Button = Color3.fromRGB(28, 28, 28)
    },
    Dracula = {
        Background = Color3.fromRGB(40, 42, 54),
        Section = Color3.fromRGB(52, 55, 70),
        Accent = Color3.fromRGB(189, 147, 249),
        Outline = Color3.fromRGB(68, 71, 90),
        Text = Color3.fromRGB(248, 248, 242),
        TextDark = Color3.fromRGB(98, 114, 164),
        Button = Color3.fromRGB(68, 71, 90)
    },
    Catppuccin = {
        Background = Color3.fromRGB(30, 30, 46),
        Section = Color3.fromRGB(49, 50, 68),
        Accent = Color3.fromRGB(203, 166, 247),
        Outline = Color3.fromRGB(88, 91, 112),
        Text = Color3.fromRGB(205, 214, 244),
        TextDark = Color3.fromRGB(166, 173, 200),
        Button = Color3.fromRGB(69, 71, 90)
    },
    Gruvbox = {
        Background = Color3.fromRGB(40, 40, 40),
        Section = Color3.fromRGB(50, 48, 47),
        Accent = Color3.fromRGB(214, 93, 14),
        Outline = Color3.fromRGB(60, 56, 54),
        Text = Color3.fromRGB(235, 219, 178),
        TextDark = Color3.fromRGB(146, 131, 116),
        Button = Color3.fromRGB(80, 73, 69)
    },
    Nord = {
        Background = Color3.fromRGB(46, 52, 64),
        Section = Color3.fromRGB(59, 66, 82),
        Accent = Color3.fromRGB(136, 192, 208),
        Outline = Color3.fromRGB(76, 86, 106),
        Text = Color3.fromRGB(236, 239, 244),
        TextDark = Color3.fromRGB(216, 222, 233),
        Button = Color3.fromRGB(67, 76, 94)
    },
    TokyoNight = {
        Background = Color3.fromRGB(26, 27, 38),
        Section = Color3.fromRGB(36, 40, 59),
        Accent = Color3.fromRGB(122, 162, 247),
        Outline = Color3.fromRGB(65, 72, 104),
        Text = Color3.fromRGB(192, 202, 245),
        TextDark = Color3.fromRGB(86, 95, 137),
        Button = Color3.fromRGB(59, 66, 97)
    }
}

local LocalPlayer = Players.LocalPlayer

-- V-Severe: Use math.lerp or custom lerp
local function lerp(a, b, t)
    if not a or not b or not t then return 0 end
    return a + (b - a) * t
end

local function clamp(x, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, x))
end

local function lerpColor(c1, c2, t)
    return Color3.new(
        lerp(c1.R, c2.R, t),
        lerp(c1.G, c2.G, t),
        lerp(c1.B, c2.B, t)
    )
end

function Arcane:AddTheme(name, config)
    themes[name] = config
end

-- V-Severe: Drawing.new returns drawing objects
local function Draw(t, props)
    local o = Drawing.new(t)
    for k, v in pairs(props) do
        o[k] = v
    end
    table.insert(drawings, o)
    return o
end

-- V-Severe: Use getmouseposition() instead of Mouse.X/Y
local function getMousePos()
    local pos = getmouseposition()
    return Vector2.new(pos.X or pos.x, pos.Y or pos.y)
end

local function isMouseOver(pos, size)
    local m = getMousePos()
    return m.X >= pos.X and m.X <= pos.X + size.X
       and m.Y >= pos.Y and m.Y <= pos.Y + size.Y
end

-- V-Severe key names (getpressedkeys returns string names)
local KeyNames = {
    "None", "Enter", "Space", "Backspace",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "Insert", "Delete", "Home", "End", "PageUp", "PageDown",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt"
}

-- V-Severe: Check if key is pressed using getpressedkeys()
local function isKeyPressed(keyName)
    local pressed = getpressedkeys()
    if not pressed then return false end
    for _, k in ipairs(pressed) do
        if k == keyName then return true end
    end
    return false
end

-- V-Severe: Check if mouse1 is pressed
local function isMousePressed()
    return isleftpressed()
end

function Arcane:Notify(title, text, duration)
    task.spawn(function()
        local theme = themes.Default
        duration = duration or 5
        local id = {}
        
        local function wrapText(str, limit)
            local res = ""
            for i = 1, #str do
                res = res .. str:sub(i, i)
                if i > 0 and i % limit == 0 then res = res .. "\n" end
            end
            return res
        end

        local processedText = wrapText(text, 35)
        
        local elements = {
            Outline = Draw("Square", {Size = Vector2.new(208, 64), Color = theme.Accent, Filled = true, ZIndex = 2000, Visible = true}),
            Background = Draw("Square", {Size = Vector2.new(204, 60), Color = theme.Background, Filled = true, ZIndex = 2001, Visible = true}),
            Title = Draw("Text", {Text = title, Size = 16, Color = theme.Accent, Font = 2, ZIndex = 2002, Visible = true}),
            Text = Draw("Text", {Text = processedText, Size = 14, Color = theme.Text, Font = 2, ZIndex = 2002, Visible = true}),
            BarBG = Draw("Square", {Size = Vector2.new(190, 2), Color = theme.Accent, Transparency = 0.3, Filled = true, ZIndex = 2002, Visible = true}),
            Bar = Draw("Square", {Size = Vector2.new(190, 2), Color = theme.Accent, Filled = true, ZIndex = 2003, Visible = true})
        }

        local data = {ID = id, Elements = elements}
        table.insert(ActiveNotifications, data)

        local elapsed = 0
        while elapsed < duration do
            local waitTime = task.wait(0.03)
            elapsed = elapsed + waitTime
            
            local percent = clamp(1 - (elapsed / duration), 0, 1)
            
            local index = 0
            for i, v in ipairs(ActiveNotifications) do
                if v.ID == id then index = i break end
            end

            if index > 0 then
                local screenWidth = 1920
                local screenHeight = 1080

                local targetY = screenHeight - 80 - ((index - 1) * 75)
                local targetPos = Vector2.new(screenWidth - 220, targetY)

                elements.Outline.Position = targetPos - Vector2.new(2, 2)
                elements.Background.Position = targetPos
                elements.Title.Position = targetPos + Vector2.new(8, 5)
                elements.Text.Position = targetPos + Vector2.new(8, 25)
                elements.BarBG.Position = targetPos + Vector2.new(8, 52)
                elements.Bar.Position = targetPos + Vector2.new(8, 52)
                elements.Bar.Size = Vector2.new(190 * percent, 2)
            end
        end
        
        for i, v in ipairs(ActiveNotifications) do
            if v.ID == id then table.remove(ActiveNotifications, i) break end
        end
        for _, el in pairs(elements) do el:Remove() end
    end)
end

local KeybindList = {
    CurrentTransparency = 0,
    TargetHeight = 25,
    CurrentHeight = 25,
    Entries = {},
    MainFrame = Draw("Square", {
        Filled = true,
        Color = themes.Default.Background,
        Size = Vector2.new(150, 25),
        Position = Vector2.new(20, 300),
        Visible = false,
        Transparency = 0,
        ZIndex = 100
    }),
    Title = Draw("Text", {
        Text = "Keybinds",
        Size = 14,
        Color = themes.Default.Accent,
        Position = Vector2.new(25, 305),
        Font = 2,
        Visible = false,
        Transparency = 0,
        ZIndex = 101
    })
}

function Arcane:UpdateKeybindList()
    local activeData = {}
    for name, mode in pairs(ActiveKeybinds) do
        table.insert(activeData, {Name = name, Mode = mode})
    end
    
    local activeCount = #activeData
    KeybindList.TargetHeight = 25 + (activeCount * 18) + (activeCount > 0 and 5 or 0)
    
    local alpha = KeybindList.CurrentTransparency
    local shouldShow = alpha > 0.05

    KeybindList.MainFrame.Visible = shouldShow
    KeybindList.Title.Visible = shouldShow
    KeybindList.MainFrame.Transparency = alpha
    KeybindList.Title.Transparency = alpha
    
    KeybindList.CurrentHeight = lerp(KeybindList.CurrentHeight, KeybindList.TargetHeight, 0.15)
    KeybindList.MainFrame.Size = Vector2.new(150, KeybindList.CurrentHeight)

    for i, entry in ipairs(KeybindList.Entries) do
        local isEntryActive = i <= activeCount
        entry.Text.Visible = shouldShow and isEntryActive
        entry.Mode.Visible = shouldShow and isEntryActive
        
        if isEntryActive then
            entry.CurrentAlpha = lerp(entry.CurrentAlpha, 1, 0.1)
        else
            entry.CurrentAlpha = lerp(entry.CurrentAlpha, 0, 0.1)
        end
        
        entry.Text.Transparency = alpha * entry.CurrentAlpha
        entry.Mode.Transparency = alpha * entry.CurrentAlpha
    end

    if not shouldShow then return end

    local yOffset = 25
    for i, data in ipairs(activeData) do
        local entry = KeybindList.Entries[i]
        if not entry then
            entry = {
                Text = Draw("Text", { Size = 13, Color = themes.Default.Text, Font = 2, Visible = false, ZIndex = 102 }),
                Mode = Draw("Text", { Size = 13, Color = themes.Default.TextDark, Font = 2, Visible = false, ZIndex = 102 }),
                CurrentAlpha = 0
            }
            KeybindList.Entries[i] = entry
        end

        entry.Text.Text = data.Name
        entry.Mode.Text = "[" .. data.Mode .. "]"
        
        entry.Text.Position = KeybindList.MainFrame.Position + Vector2.new(10, yOffset)
        entry.Mode.Position = KeybindList.MainFrame.Position + Vector2.new(140 - entry.Mode.TextBounds.X, yOffset)
        
        yOffset = yOffset + 18
    end
end

-- V-Severe: Use task.spawn instead of spawn
task.spawn(function()
    while true do
        local activeCount = 0
        for _ in pairs(ActiveKeybinds) do activeCount = activeCount + 1 end
        local target = (activeCount > 0 or Arcane.IsOpen) and 1 or 0
        
        KeybindList.CurrentTransparency = lerp(KeybindList.CurrentTransparency, target, 0.1)
        Arcane:UpdateKeybindList()
        task.wait(0.01)
    end
end)

function Arcane:CreateWindow(Title, Size, ThemeName)
    local theme = themes[ThemeName] or themes.Default
    local windowSize = Size or Vector2.new(650, 450)
    local screenPos = Vector2.new(200, 200)

    local main = Draw("Square", { Filled = true, Color = theme.Background, Size = windowSize, Position = screenPos, Visible = true, ZIndex = 1 })
    local sidebar = Draw("Square", { Filled = true, Color = Color3.fromRGB(12, 12, 12), Size = Vector2.new(150, windowSize.Y), Position = screenPos, Visible = true, ZIndex = 2 })
    local logo = Draw("Text", { Text = Title or "Arcane", Size = 24, Color = theme.Accent, Position = screenPos + Vector2.new(25, 20), Font = 2, Visible = true, ZIndex = 3 })
    local globalSelector = Draw("Square", { Filled = true, Color = theme.Accent, Size = Vector2.new(3, 18), Position = screenPos + Vector2.new(0, 70), Visible = true, ZIndex = 5 })

    local window = {
        Main = main, Sidebar = sidebar, Logo = logo, GlobalSelector = globalSelector,
        Pos = screenPos, Size = windowSize, Theme = theme, Sections = {}, CurrentTab = "",
        SidebarItems = {}, SidebarLayoutY = 70, SidebarPadding = 6, TargetSelectorY = 70, CurrentSelectorY = 70,
        TabSections = {}
    }
    
    Arcane.IsOpen = true

    function window:SetVisible(state)
        Arcane.IsOpen = state
        self.Main.Visible = state
        self.Sidebar.Visible = state
        self.Logo.Visible = state
        self.GlobalSelector.Visible = state
        for _, item in ipairs(self.SidebarItems) do if item.Text then item.Text.Visible = state end end
        self:UpdateVisibility()
    end

    function window:Move(delta)
        self.Pos = self.Pos + delta
        self.Main.Position = self.Main.Position + delta
        self.Sidebar.Position = self.Sidebar.Position + delta
        self.Logo.Position = self.Logo.Position + delta
        self.GlobalSelector.Position = self.GlobalSelector.Position + delta
        for _, item in ipairs(self.SidebarItems) do item:_Move(delta) end
        self:RelayoutTab(self.CurrentTab)
    end

    function window:CreateTabSection(text)
        local y = self.SidebarLayoutY
        self.SidebarLayoutY = self.SidebarLayoutY + 24
        local label = Draw("Text", { Text = text, Size = 13, Color = Color3.fromRGB(255, 255, 255), Position = self.Pos + Vector2.new(25, y), Font = 2, Visible = true, ZIndex = 4 })
        local tabSection = { Text = label, _Move = function(_, d) label.Position = label.Position + d end }
        table.insert(self.SidebarItems, tabSection)
        self.TabSections[text] = tabSection
        return tabSection
    end

    function window:CreateTab(Name)
        local height = 30
        local y = self.SidebarLayoutY
        self.SidebarLayoutY = self.SidebarLayoutY + height + self.SidebarPadding
        local pos = self.Pos + Vector2.new(0, y)
        local text = Draw("Text", { Text = Name, Size = 14, Color = theme.TextDark, Position = pos + Vector2.new(35, 6), Font = 2, Visible = true, ZIndex = 4 })
        local tab = { Name = Name, Position = pos, Size = Vector2.new(150, height), Text = text, RelativeY = y + 6 }
        function tab:_Move(d) self.Position = self.Position + d; self.Text.Position = self.Text.Position + d end
        table.insert(self.SidebarItems, tab)
        table.insert(tabs, tab)
        if self.CurrentTab == "" then self.CurrentTab = Name; text.Color = theme.Text; self.TargetSelectorY = tab.RelativeY; self.CurrentSelectorY = tab.RelativeY end
        return tab
    end

    function window:UpdateVisibility()
        for _, s in ipairs(self.Sections) do
            local isVisible = (s.Tab == self.CurrentTab) and Arcane.IsOpen
            s.Frame.Visible = isVisible
            s.Title.Visible = isVisible
            for _, item in ipairs(s.ContentDrawings) do 
                if item.Type == "PickerPart" or item.Type == "DropdownPart" then
                    item.Obj.Visible = false
                else
                    item.Obj.Visible = isVisible
                end
            end
        end
        OpenDropdown = nil
        self:RelayoutTab(self.CurrentTab)
    end

    function window:CreateSection(Name, TabName)
        local section = { Frame = nil, Title = nil, Tab = TabName, Name = Name, ContentDrawings = {}, InternalY = 5, Width = 220 }
        section.Frame = Draw("Square", { Filled = true, Color = theme.Section, Size = Vector2.new(220, 25), Visible = (TabName == self.CurrentTab), ZIndex = 10 })
        section.Title = Draw("Text", { Text = Name, Size = 14, Color = theme.TextDark, Font = 2, Visible = (TabName == self.CurrentTab), ZIndex = 11 })

        function section:AddLabel(text)
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            table.insert(self.ContentDrawings, {Obj = label, Type = "Label", Height = 18})
            self.InternalY = self.InternalY + 18
            window:RelayoutTab(self.Tab)
            return label
        end

        function section:AddToggle(text, default, callback)
            local toggle = {Value = default or false, Callback = callback}
            local boxFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(22, 22), Visible = self.Frame.Visible, ZIndex = 12 })
            local check = Draw("Square", { Filled = true, Color = theme.Accent, Size = Vector2.new(12, 12), Visible = false, ZIndex = 13 })
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            table.insert(self.ContentDrawings, {Obj = label, Type = "Label", Height = 24})
            table.insert(self.ContentDrawings, {Obj = boxFrame, Type = "ToggleFrame", Height = 0})
            table.insert(self.ContentDrawings, {Obj = check, Type = "Ignore"})
            
            function toggle:SetValue(val)
                self.Value = val
                check.Visible = self.Value and section.Frame.Visible and Arcane.IsOpen
                check.Position = boxFrame.Position + Vector2.new(5, 5)
                self.Callback(self.Value)
            end
            function toggle:GetValue() return self.Value end

            task.spawn(function()
                local wasDown = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local over = isMouseOver(boxFrame.Position, boxFrame.Size)
                        local down = isMousePressed()
                        if not OpenDropdown and over and down and not wasDown then
                            toggle:SetValue(not toggle.Value)
                            task.wait(0.1)
                        end
                        wasDown = down
                        check.Visible = toggle.Value and section.Frame.Visible and Arcane.IsOpen
                        check.Position = boxFrame.Position + Vector2.new(5, 5)
                    else
                        check.Visible = false
                    end
                    task.wait()
                end
            end)
            toggle:SetValue(toggle.Value)
            section.InternalY = section.InternalY + 24
            window:RelayoutTab(section.Tab)
            return toggle
        end

        function section:AddTextBox(text, default, callback)
            local box = {Value = default or "", Callback = callback}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local boxFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(section.Width - 20, 22), Visible = self.Frame.Visible, ZIndex = 12 })
            local boxText = Draw("Text", { Text = box.Value, Size = 14, Color = theme.TextDark, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 13 })
            local active = false
            table.insert(self.ContentDrawings, {Obj = label, Type = "Label", Height = 18})
            table.insert(self.ContentDrawings, {Obj = boxFrame, Type = "ButtonFrame", Height = 26})
            table.insert(self.ContentDrawings, {Obj = boxText, Type = "ButtonText", Center = true})
            
            function box:SetValue(val)
                self.Value = val
                boxText.Text = self.Value
                self.Callback(self.Value)
            end
            function box:GetValue() return self.Value end

            task.spawn(function()
                local wasM1 = false
                local wasPressed = {}
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local m1 = isMousePressed()
                        if not OpenDropdown and m1 and not wasM1 then
                            active = isMouseOver(boxFrame.Position, boxFrame.Size)
                            boxFrame.Color = active and theme.Section or theme.Button
                            boxText.Color = active and theme.Text or theme.TextDark
                        end
                        wasM1 = m1
                        if active then
                            for _, name in ipairs(KeyNames) do
                                local down = isKeyPressed(name)
                                if down and not wasPressed[name] then
                                    if name == "Backspace" then 
                                        box.Value = box.Value:sub(1, #box.Value - 1)
                                    elseif name == "Enter" then
                                        active = false
                                        boxFrame.Color = theme.Button
                                        boxText.Color = theme.TextDark
                                        box.Callback(box.Value)
                                    elseif #name == 1 or name == "Space" then
                                        local char = (name == "Space" and " " or name)
                                        if isKeyPressed("LeftShift") or isKeyPressed("RightShift") then 
                                            char = char:upper() 
                                        else 
                                            char = char:lower() 
                                        end
                                        box.Value = box.Value .. char
                                    end
                                    boxText.Text = box.Value
                                end
                                wasPressed[name] = down
                            end
                        end
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 44
            window:RelayoutTab(section.Tab)
            return box
        end

        function section:AddButton(text, callback)
            local btnFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(self.Width - 20, 22), Visible = self.Frame.Visible, ZIndex = 12 })
            local btnText = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 13 })
            table.insert(self.ContentDrawings, {Obj = btnFrame, Type = "ButtonFrame", Height = 26})
            table.insert(self.ContentDrawings, {Obj = btnText, Type = "ButtonText", Center = true})
            
            task.spawn(function()
                local wasDown = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local over = isMouseOver(btnFrame.Position, btnFrame.Size)
                        local down = isMousePressed()
                        if not OpenDropdown and over then
                            btnFrame.Color = lerpColor(theme.Button, theme.Accent, 0.2)
                            if down and not wasDown then 
                                callback()
                                btnFrame.Color = theme.Accent
                                task.wait(0.1) 
                            end
                        else 
                            btnFrame.Color = theme.Button 
                        end
                        wasDown = down
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 26
            window:RelayoutTab(section.Tab)
            return {Frame = btnFrame, Text = btnText}
        end

        function section:AddSlider(text, options)
            local slider = {Value = options.Default or 0, Min = options.Min or 0, Max = options.Max or 100, Callback = options.Callback}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local backFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(section.Width - 20, 16), Visible = self.Frame.Visible, ZIndex = 12 })
            local fillFrame = Draw("Square", { Filled = true, Color = theme.Accent, Size = Vector2.new(0, 16), Visible = self.Frame.Visible, ZIndex = 13 })
            local valueText = Draw("Text", { Text = tostring(slider.Value), Size = 14, Color = theme.Text, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 14 })
            table.insert(self.ContentDrawings, {Obj = label, Type = "Label", Height = 18})
            table.insert(self.ContentDrawings, {Obj = backFrame, Type = "SliderFrame", Height = 20})
            table.insert(self.ContentDrawings, {Obj = fillFrame, Type = "Ignore"})
            table.insert(self.ContentDrawings, {Obj = valueText, Type = "Ignore"})
            
            function slider:SetValue(val)
                self.Value = clamp(val, self.Min, self.Max)
                local percent = (self.Value - self.Min) / (self.Max - self.Min)
                fillFrame.Size = Vector2.new(backFrame.Size.X * percent, backFrame.Size.Y)
                valueText.Text = tostring(self.Value)
                self.Callback(self.Value)
            end
            function slider:GetValue() return self.Value end

            task.spawn(function()
                local dragging = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local down = isMousePressed()
                        if not OpenDropdown and isMouseOver(backFrame.Position, backFrame.Size) and down then 
                            dragging = true 
                        end
                        if not down then dragging = false end
                        if dragging then
                            local percent = clamp((getMousePos().X - backFrame.Position.X) / backFrame.Size.X, 0, 1)
                            slider:SetValue(math.floor(slider.Min + (slider.Max - slider.Min) * percent))
                        end
                        fillFrame.Position = backFrame.Position
                        fillFrame.Visible = section.Frame.Visible and Arcane.IsOpen
                        valueText.Position = backFrame.Position + Vector2.new(backFrame.Size.X/2, backFrame.Size.Y/2)
                        valueText.Visible = section.Frame.Visible and Arcane.IsOpen
                    else
                        fillFrame.Visible = false
                        valueText.Visible = false
                    end
                    task.wait()
                end
            end)
            slider:SetValue(slider.Value)
            section.InternalY = section.InternalY + 38
            window:RelayoutTab(section.Tab)
            return slider
        end

        function section:AddKeybind(text, defaultKeyName, callback, isMenuKey)
            local kb = {Key = defaultKeyName or "Insert", Mode = "Hold", Binding = false, Active = false, MenuOpen = false, Callback = callback}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local btnFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(60, 18), Visible = self.Frame.Visible, ZIndex = 12 })
            local btnText = Draw("Text", { Text = "[" .. kb.Key .. "]", Size = 13, Color = theme.Text, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 13 })
            local dropFrame = Draw("Square", { Filled = true, Color = theme.Section, Size = Vector2.new(60, 54), Visible = false, ZIndex = 20 })
            local optHold = Draw("Text", { Text = "Hold", Size = 12, Color = theme.Accent, Center = true, Font = 2, Visible = false, ZIndex = 21 })
            local optToggle = Draw("Text", { Text = "Toggle", Size = 12, Color = theme.Text, Center = true, Font = 2, Visible = false, ZIndex = 21 })
            local optAlways = Draw("Text", { Text = "Always", Size = 12, Color = theme.Text, Center = true, Font = 2, Visible = false, ZIndex = 21 })
            
            table.insert(self.ContentDrawings, {Obj = label, Type = "Label", Height = 22})
            table.insert(self.ContentDrawings, {Obj = btnFrame, Type = "KeybindFrame", Height = 0})
            table.insert(self.ContentDrawings, {Obj = btnText, Type = "KeybindText", Center = true})
            table.insert(self.ContentDrawings, {Obj = dropFrame, Type = "Ignore"})
            table.insert(self.ContentDrawings, {Obj = optHold, Type = "Ignore"})
            table.insert(self.ContentDrawings, {Obj = optToggle, Type = "Ignore"})
            table.insert(self.ContentDrawings, {Obj = optAlways, Type = "Ignore"})

            function kb:SetValue(k) 
                self.Key = k
                btnText.Text = "[" .. self.Key .. "]" 
            end
            function kb:GetValue() return self.Key end

            local function updateActive()
                if isMenuKey then return end
                local isA = (kb.Mode == "Always") or kb.Active
                ActiveKeybinds[text] = isA and kb.Mode or nil
                kb.Callback(isA)
            end

            task.spawn(function()
                local wasPressed = {}
                while true do
                    for _, name in ipairs(KeyNames) do
                        local down = isKeyPressed(name)
                        if down and not wasPressed[name] then
                            if kb.Binding then
                                kb:SetValue(name)
                                kb.Binding = false
                                btnFrame.Color = theme.Button
                            elseif name == kb.Key then
                                if isMenuKey then 
                                    kb.Callback() 
                                else
                                    if kb.Mode == "Hold" then 
                                        kb.Active = true
                                        updateActive() 
                                    elseif kb.Mode == "Toggle" then 
                                        kb.Active = not kb.Active
                                        updateActive() 
                                    end
                                end
                            end
                        elseif not down and wasPressed[name] then
                            if not isMenuKey and name == kb.Key and kb.Mode == "Hold" then 
                                kb.Active = false
                                updateActive() 
                            end
                        end
                        wasPressed[name] = down
                    end
                    task.wait()
                end
            end)

            task.spawn(function()
                local wasM1, wasM2 = false, false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local m1 = isMousePressed()
                        local m2 = isrightpressed and isrightpressed() or false
                        local overBtn = isMouseOver(btnFrame.Position, btnFrame.Size)
                        
                        if not OpenDropdown and overBtn and m1 and not wasM1 then 
                            kb.Binding = true
                            btnText.Text = "[ ... ]"
                            btnFrame.Color = theme.Accent 
                        end
                        if not OpenDropdown and not isMenuKey and overBtn and m2 and not wasM2 then 
                            kb.MenuOpen = not kb.MenuOpen 
                        end
                        
                        if kb.MenuOpen then
                            dropFrame.Position = btnFrame.Position + Vector2.new(0, 20)
                            dropFrame.Visible = true
                            optHold.Visible = true
                            optToggle.Visible = true
                            optAlways.Visible = true
                            optHold.Position = dropFrame.Position + Vector2.new(30, 5)
                            optToggle.Position = dropFrame.Position + Vector2.new(30, 21)
                            optAlways.Position = dropFrame.Position + Vector2.new(30, 37)
                            
                            if m1 and not wasM1 then
                                if isMouseOver(optHold.Position - Vector2.new(30,5), Vector2.new(60,16)) then 
                                    kb.Mode = "Hold"
                                    kb.MenuOpen = false 
                                elseif isMouseOver(optToggle.Position - Vector2.new(30,5), Vector2.new(60,16)) then 
                                    kb.Mode = "Toggle"
                                    kb.MenuOpen = false 
                                elseif isMouseOver(optAlways.Position - Vector2.new(30,5), Vector2.new(60,16)) then 
                                    kb.Mode = "Always"
                                    kb.MenuOpen = false 
                                end
                                optHold.Color = kb.Mode == "Hold" and theme.Accent or theme.Text
                                optToggle.Color = kb.Mode == "Toggle" and theme.Accent or theme.Text
                                optAlways.Color = kb.Mode == "Always" and theme.Accent or theme.Text
                                updateActive()
                            end
                        else 
                            dropFrame.Visible = false
                            optHold.Visible = false
                            optToggle.Visible = false
                            optAlways.Visible = false
                        end
                        wasM1, wasM2 = m1, m2
                    else
                        kb.MenuOpen = false
                        dropFrame.Visible = false
                        optHold.Visible = false
                        optToggle.Visible = false
                        optAlways.Visible = false
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 22
            window:RelayoutTab(section.Tab)
            return kb
        end

        function section:AddColorPicker(text, default, callback)
            local cp = {Value = default or Color3.new(1,0,0), Callback = callback, H = 0, S = 1, V = 1, Open = false}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local preview = Draw("Square", { Filled = true, Color = cp.Value, Size = Vector2.new(24, 12), Visible = self.Frame.Visible, ZIndex = 12 })
            local pickerFrame = Draw("Square", { Filled = true, Color = theme.Section, Size = Vector2.new(135, 115), Visible = false, ZIndex = 60 })
            local pickerOutline = Draw("Square", { Filled = false, Color = theme.Outline, Size = Vector2.new(135, 115), Visible = false, ZIndex = 61, Thickness = 1 })
            
            local gridParts = {}
            local hueParts = {}
            
            for x = 0, 9 do
                for y = 0, 8 do
                    local p = Draw("Square", { Filled = true, Size = Vector2.new(10, 10), Visible = false, ZIndex = 62 })
                    table.insert(gridParts, {Obj = p, sat = x/9, val = 1-(y/8)})
                    table.insert(section.ContentDrawings, {Obj = p, Type = "PickerPart"})
                end
            end

            for y = 0, 8 do
                local p = Draw("Square", { Filled = true, Size = Vector2.new(12, 10), Visible = false, ZIndex = 62 })
                table.insert(hueParts, {Obj = p, hue = y/8})
                table.insert(section.ContentDrawings, {Obj = p, Type = "PickerPart"})
            end

            table.insert(section.ContentDrawings, {Obj = label, Type = "Label", Height = 22})
            table.insert(section.ContentDrawings, {Obj = preview, Type = "ToggleFrame", Height = 0})
            table.insert(section.ContentDrawings, {Obj = pickerFrame, Type = "PickerPart"})
            table.insert(section.ContentDrawings, {Obj = pickerOutline, Type = "PickerPart"})

            function cp:SetValue(col)
                self.Value = col
                preview.Color = col
                self.Callback(col)
            end
            function cp:GetValue() return self.Value end

            task.spawn(function()
                local wasM1 = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local m1 = isMousePressed()
                        local mp = getMousePos()
                        
                        if not OpenDropdown and isMouseOver(preview.Position, preview.Size) and m1 and not wasM1 then 
                            cp.Open = not cp.Open 
                        end
                        
                        pickerFrame.Visible = cp.Open
                        pickerOutline.Visible = cp.Open
                        pickerFrame.Position = preview.Position + Vector2.new(30, 0)
                        pickerOutline.Position = pickerFrame.Position
                        
                        for i, p in ipairs(gridParts) do
                            p.Obj.Visible = cp.Open
                            p.Obj.Position = pickerFrame.Position + Vector2.new(10 + (math.floor((i-1)/9) * 10), 10 + (((i-1)%9) * 10))
                            p.Obj.Color = Color3.fromHSV(cp.H, p.sat, p.val)
                            if cp.Open and m1 and isMouseOver(p.Obj.Position, p.Obj.Size) then 
                                cp.S, cp.V = p.sat, p.val 
                                cp:SetValue(Color3.fromHSV(cp.H, cp.S, cp.V))
                            end
                        end

                        for i, p in ipairs(hueParts) do
                            p.Obj.Visible = cp.Open
                            p.Obj.Position = pickerFrame.Position + Vector2.new(112, 10 + ((i-1) * 10))
                            p.Obj.Color = Color3.fromHSV(p.hue, 1, 1)
                            if cp.Open and m1 and isMouseOver(p.Obj.Position, p.Obj.Size) then 
                                cp.H = p.hue 
                                cp:SetValue(Color3.fromHSV(cp.H, cp.S, cp.V))
                            end
                        end
                        wasM1 = m1
                    else
                        cp.Open = false
                        pickerFrame.Visible = false
                        pickerOutline.Visible = false
                        for _, p in ipairs(gridParts) do p.Obj.Visible = false end
                        for _, p in ipairs(hueParts) do p.Obj.Visible = false end
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 22
            window:RelayoutTab(section.Tab)
            return cp
        end

        function section:AddDropdown(text, list, default, callback)
            local dp = {Value = default or list[1], List = list, Callback = callback, Open = false}
            local self_id = {}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local dropFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(section.Width - 20, 22), Visible = self.Frame.Visible, ZIndex = 12 })
            local dropText = Draw("Text", { Text = dp.Value, Size = 14, Color = theme.TextDark, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 13 })
            local container = Draw("Square", { Filled = true, Color = theme.Section, Size = Vector2.new(section.Width - 20, #list * 20 + 10), Visible = false, ZIndex = 50 })
            local items = {}

            local function clearItems()
                for _, it in ipairs(items) do it.Obj:Remove() end
                items = {}
            end

            local function createItems()
                clearItems()
                for i, val in ipairs(dp.List) do
                    local itemText = Draw("Text", { Text = val, Size = 13, Color = (val == dp.Value and theme.Accent or theme.Text), Center = true, Font = 2, Visible = false, ZIndex = 51 })
                    table.insert(items, {Obj = itemText, Value = val})
                    table.insert(section.ContentDrawings, {Obj = itemText, Type = "DropdownPart"})
                end
                container.Size = Vector2.new(section.Width - 20, #dp.List * 20 + 10)
            end

            function dp:SetValue(val)
                self.Value = val
                dropText.Text = self.Value
                for _, it in ipairs(items) do 
                    it.Obj.Color = (it.Value == self.Value and theme.Accent or theme.Text) 
                end
                self.Callback(self.Value)
            end
            function dp:GetValue() return self.Value end
            function dp:Refresh(newList) self.List = newList; createItems() end

            createItems()
            table.insert(section.ContentDrawings, {Obj = label, Type = "Label", Height = 18})
            table.insert(section.ContentDrawings, {Obj = dropFrame, Type = "ButtonFrame", Height = 26})
            table.insert(section.ContentDrawings, {Obj = dropText, Type = "ButtonText", Center = true})
            table.insert(section.ContentDrawings, {Obj = container, Type = "DropdownPart"})

            task.spawn(function()
                local wasM1 = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local m1 = isMousePressed()
                        local over = isMouseOver(dropFrame.Position, dropFrame.Size)
                        
                        if m1 and not wasM1 then
                            if over then
                                if OpenDropdown == self_id then 
                                    dp.Open = false
                                    OpenDropdown = nil
                                elseif OpenDropdown == nil then
                                    dp.Open = true
                                    OpenDropdown = self_id
                                end
                            elseif dp.Open and not isMouseOver(container.Position, container.Size) then
                                dp.Open = false
                                if OpenDropdown == self_id then OpenDropdown = nil end
                            end
                        end
                        
                        container.Visible = dp.Open
                        container.Position = dropFrame.Position + Vector2.new(0, 25)
                        
                        for i, item in ipairs(items) do
                            item.Obj.Visible = dp.Open
                            item.Obj.Position = container.Position + Vector2.new(container.Size.X/2, 10 + (i-1)*20)
                            if dp.Open and m1 and not wasM1 and isMouseOver(item.Obj.Position - Vector2.new(container.Size.X/2, 8), Vector2.new(container.Size.X, 18)) then
                                dp:SetValue(item.Value)
                                dp.Open = false
                                OpenDropdown = nil
                            end
                        end
                        wasM1 = m1
                    else 
                        dp.Open = false
                        if OpenDropdown == self_id then OpenDropdown = nil end
                        container.Visible = false 
                        for _, it in ipairs(items) do it.Obj.Visible = false end 
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 44
            window:RelayoutTab(section.Tab)
            return dp
        end

        function section:AddMultipleDropdown(text, list, default, callback)
            local mdp = {Value = default or {}, List = list, Callback = callback, Open = false}
            local self_id = {}
            local label = Draw("Text", { Text = text, Size = 14, Color = theme.Text, Font = 2, Visible = self.Frame.Visible, ZIndex = 12 })
            local dropFrame = Draw("Square", { Filled = true, Color = theme.Button, Size = Vector2.new(section.Width - 20, 22), Visible = self.Frame.Visible, ZIndex = 12 })
            local dropText = Draw("Text", { Text = "...", Size = 14, Color = theme.TextDark, Center = true, Font = 2, Visible = self.Frame.Visible, ZIndex = 13 })
            local container = Draw("Square", { Filled = true, Color = theme.Section, Size = Vector2.new(section.Width - 20, #list * 20 + 10), Visible = false, ZIndex = 50 })
            local items = {}

            local function updateText()
                local str = ""
                for i, v in ipairs(mdp.Value) do 
                    str = str .. v .. (i == #mdp.Value and "" or ", ") 
                end
                if str == "" then str = "None" end
                if #str > 20 then str = str:sub(1, 17) .. "..." end
                dropText.Text = str
            end

            local function createItems()
                for _, it in ipairs(items) do it.Obj:Remove() end
                items = {}
                for i, val in ipairs(mdp.List) do
                    local isS = false
                    for _, s in pairs(mdp.Value) do 
                        if s == val then isS = true break end 
                    end
                    local itemText = Draw("Text", { Text = val, Size = 13, Color = (isS and theme.Accent or theme.Text), Center = true, Font = 2, Visible = false, ZIndex = 51 })
                    table.insert(items, {Obj = itemText, Value = val})
                    table.insert(section.ContentDrawings, {Obj = itemText, Type = "DropdownPart"})
                end
                container.Size = Vector2.new(section.Width - 20, #mdp.List * 20 + 10)
            end

            function mdp:SetValue(val)
                self.Value = val
                for _, it in ipairs(items) do
                    local s = false
                    for _, v in pairs(self.Value) do 
                        if v == it.Value then s = true break end 
                    end
                    it.Obj.Color = s and theme.Accent or theme.Text
                end
                updateText()
                self.Callback(self.Value)
            end
            function mdp:GetValue() return self.Value end
            function mdp:Refresh(newList) self.List = newList; createItems() end

            createItems()
            updateText()
            table.insert(section.ContentDrawings, {Obj = label, Type = "Label", Height = 18})
            table.insert(section.ContentDrawings, {Obj = dropFrame, Type = "ButtonFrame", Height = 26})
            table.insert(section.ContentDrawings, {Obj = dropText, Type = "ButtonText", Center = true})
            table.insert(section.ContentDrawings, {Obj = container, Type = "DropdownPart"})

            task.spawn(function()
                local wasM1 = false
                while true do
                    if section.Frame.Visible and window.CurrentTab == section.Tab and Arcane.IsOpen then
                        local m1 = isMousePressed()
                        local over = isMouseOver(dropFrame.Position, dropFrame.Size)
                        
                        if m1 and not wasM1 then
                            if over then
                                if OpenDropdown == self_id then 
                                    mdp.Open = false
                                    OpenDropdown = nil
                                elseif OpenDropdown == nil then
                                    mdp.Open = true
                                    OpenDropdown = self_id
                                end
                            elseif mdp.Open and not isMouseOver(container.Position, container.Size) then
                                mdp.Open = false
                                if OpenDropdown == self_id then OpenDropdown = nil end
                            end
                        end
                        
                        container.Visible = mdp.Open
                        container.Position = dropFrame.Position + Vector2.new(0, 25)
                        
                        for i, item in ipairs(items) do
                            item.Obj.Visible = mdp.Open
                            item.Obj.Position = container.Position + Vector2.new(container.Size.X/2, 10 + (i-1)*20)
                            if mdp.Open and m1 and not wasM1 and isMouseOver(item.Obj.Position - Vector2.new(container.Size.X/2, 8), Vector2.new(container.Size.X, 18)) then
                                local found = false
                                for idx, v in ipairs(mdp.Value) do
                                    if v == item.Value then
                                        table.remove(mdp.Value, idx)
                                        found = true
                                        break
                                    end
                                end
                                if not found then table.insert(mdp.Value, item.Value) end
                                item.Obj.Color = (not found and theme.Accent or theme.Text)
                                updateText()
                                mdp.Callback(mdp.Value)
                            end
                        end
                        wasM1 = m1
                    else 
                        mdp.Open = false
                        if OpenDropdown == self_id then OpenDropdown = nil end
                        container.Visible = false 
                        for _, it in ipairs(items) do it.Obj.Visible = false end 
                    end
                    task.wait()
                end
            end)
            section.InternalY = section.InternalY + 44
            window:RelayoutTab(section.Tab)
            return mdp
        end

        table.insert(self.Sections, section)
        return section
    end

    function window:RelayoutTab(TabName)
        local startX, startY, padding = 170, 30, 15
        local curX, curY, maxH = startX, startY, 0

        for _, s in ipairs(self.Sections) do
            if s.Tab == TabName then
                if curX + s.Width > self.Size.X - 20 then 
                    curX = startX
                    curY = curY + maxH + 30
                    maxH = 0
                end
                
                s.Frame.Position = self.Pos + Vector2.new(curX, curY)
                s.Title.Position = s.Frame.Position + Vector2.new(5, -18)
                
                local lY = 5
                local lastLabelPos = nil
                local lastSquarePos = nil
                local lastSquareSize = nil

                for _, item in ipairs(s.ContentDrawings) do
                    local d = item.Obj
                    if item.Type == "ButtonFrame" or item.Type == "SliderFrame" then
                        d.Position = s.Frame.Position + Vector2.new(10, lY)
                        lastSquarePos = d.Position
                        lastSquareSize = d.Size
                        lY = lY + (item.Height or 26)
                    elseif item.Type == "Label" then
                        d.Position = s.Frame.Position + Vector2.new(10, lY)
                        lastLabelPos = d.Position
                        lY = lY + (item.Height or 18)
                    elseif item.Type == "ToggleFrame" then
                        if lastLabelPos then
                            d.Position = Vector2.new(s.Frame.Position.X + s.Width - d.Size.X - 10, lastLabelPos.Y)
                        end
                    elseif item.Type == "ButtonText" or item.Type == "KeybindText" then
                        if item.Center and lastSquarePos then
                            d.Position = Vector2.new(lastSquarePos.X + (lastSquareSize.X / 2), lastSquarePos.Y + (lastSquareSize.Y / 2))
                        end
                    elseif item.Type == "KeybindFrame" then
                        if lastLabelPos then
                            d.Position = Vector2.new(s.Frame.Position.X + s.Width - d.Size.X - 10, lastLabelPos.Y)
                            lastSquarePos = d.Position
                            lastSquareSize = d.Size
                        end
                    end
                end
                
                s.Frame.Size = Vector2.new(s.Width, lY + 5)
                if s.Frame.Size.Y > maxH then maxH = s.Frame.Size.Y end
                curX = curX + s.Width + padding
            end
        end
    end

    -- Main input loop
    task.spawn(function()
        local wasD = false
        local drag = false
        local dsm, dsp = nil, nil
        local dragK = false
        local dsmK, dspK = nil, nil
        
        while true do
            local d = isMousePressed()
            local mp = getMousePos()
            
            if Arcane.IsOpen then
                -- Window dragging
                if d and not wasD and isMouseOver(window.Pos, Vector2.new(window.Size.X, 50)) then 
                    drag = true
                    dsm = mp
                    dsp = window.Pos 
                end
                if not d then drag = false end
                if drag then 
                    window:Move((dsp + (mp - dsm)) - window.Pos) 
                end
                
                -- Keybind list dragging
                if d and not wasD and isMouseOver(KeybindList.MainFrame.Position, Vector2.new(KeybindList.MainFrame.Size.X, 25)) then 
                    dragK = true
                    dsmK = mp
                    dspK = KeybindList.MainFrame.Position 
                end
                if not d then dragK = false end
                if dragK then 
                    local delta = (dspK + (mp - dsmK)) - KeybindList.MainFrame.Position
                    KeybindList.MainFrame.Position = KeybindList.MainFrame.Position + delta
                    KeybindList.Title.Position = KeybindList.Title.Position + delta
                end
                
                -- Tab switching
                for _, tab in ipairs(tabs) do
                    if isMouseOver(tab.Position, tab.Size) then
                        if window.CurrentTab ~= tab.Name then 
                            tab.Text.Color = Color3.fromRGB(200, 200, 200) 
                        end
                        if d and not wasD then 
                            for _, t in ipairs(tabs) do 
                                t.Text.Color = theme.TextDark 
                            end
                            tab.Text.Color = theme.Text
                            window.CurrentTab = tab.Name
                            window.TargetSelectorY = tab.RelativeY
                            window:UpdateVisibility() 
                        end
                    elseif window.CurrentTab ~= tab.Name then 
                        tab.Text.Color = theme.TextDark 
                    end
                end
            end
            
            -- Animate selector
            window.CurrentSelectorY = lerp(window.CurrentSelectorY, window.TargetSelectorY, 0.15)
            window.GlobalSelector.Position = Vector2.new(window.Pos.X, window.Pos.Y + window.CurrentSelectorY)
            
            wasD = d
            task.wait(0.01)
        end
    end)

    function window:Finalize()
        self:CreateTabSection("System")
        self:CreateTab("Settings")
        local s = self:CreateSection("Menu", "Settings")
        s:AddLabel("v1.0.0")
        s:AddKeybind("Menu Keybind", "F1", function() 
            window:SetVisible(not Arcane.IsOpen) 
        end, true)
        s:AddButton("Unload UI", function() 
            for _, v in ipairs(drawings) do 
                v:Remove() 
            end 
        end)
        self:UpdateVisibility()
    end
    
    return window
end

return Arcane
