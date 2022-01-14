local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local GUI = {}

local Button = {}

function Button.__init__(baseClass, id, text, x, y, width, height, text_color, back_color, active_color, type, active)
    self = {}
    self.id = id
    self.text = text
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.text_color = text_color
    self.back_color = back_color
    self.active_color = active_color
    self.type = type or "switch"
    self.func = nil
    self.obj = nil
    self.parameters = {}
    self.active = active
    setmetatable(self, { __index = Button })
    return self
end

function Button:get_name()
    local text_len = string.len(self.text)
    if text_len > self.width then
        return string.sub(self.text, 1, self.width)
    else
        return self.text
    end
end

function Button:add_event(func, parameters)
    if self.obj then
        self.obj = nil
    end
    self.func = func
    self.parameters = parameters
end

function Button:add_obj(obj, parameters)
    if self.func then
        self.func = nil
    end
    self.obj = obj
    self.parameters = parameters
end

function Button:call()
    if self.func then
        self.func(self.parameters)
    elseif self.obj then
        self.obj:call(self.parameters)
    end
end

function Button:click()
    self.active = not self.active
    self:call()
end

setmetatable(Button, { __call = Button.__init__ })

function GUI.__init__(baseClass, monitor)
    self = {}
    self.monitor = monitor
    self.active_layout = ""
    self.layouts = {}
    self.buttons = {}
    self.charts = {}
    self.labels = {}
    setmetatable(self, { __index = GUI })
    return self
end

setmetatable(GUI, { __call = GUI.__init__ })

function GUI:create_button(id, text, x, y, width, height, text_color, back_color, active_color, type, active)
    local button = Button(id, text, x, y, width, height, text_color, back_color, active_color, type, active)
    return button
end

function GUI:add_button(layout, button)
    if not has_value(self.layouts, layout) then
        table.insert(self.layouts, layout)
        self.buttons[layout] = {}
    end
    self.buttons[layout][button.id] = button
end

function GUI:_draw_button(button)
    local old_back_color = self.monitor.getBackgroundColor()
    local old_text_color = self.monitor.getTextColor()

    local text_x = button.x + (button.width / 2) - (string.len(button:get_name()) / 2)
    local text_y = button.y
    if button.height >= 3 then
        text_y =button.y + (button.height / 2)
    end

    if button.active then
        self.monitor.setBackgroundColor(button.active_color)
    else
        self.monitor.setBackgroundColor(button.back_color)
    end
    self.monitor.setTextColor(button.text_color)

    for x = button.x, button.x + button.width - 1 do
        for y = button.y, button.y + button.height - 1 do
            self.monitor.setCursorPos(x, y)
            self.monitor.write(" ")
        end
    end
    self.monitor.setCursorPos(text_x, text_y)
    self.monitor.write(button:get_name())

    self.monitor.setBackgroundColor(old_back_color)
    self.monitor.setTextColor(old_text_color)
end

function GUI:draw_layout(layout)
    layout = layout or self.active_layout
    if layout ~= self.active_layout then
        self.active_layout = layout
    end
    self.monitor.clear()
    if has_value(self.layouts, layout) then
        for id, button in pairs(self.buttons[layout]) do
            self:_draw_button(button)
        end
    end
end

function GUI:click(x,y)
    for id, button in pairs(self.buttons[self.active_layout]) do
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            button:click()
            if button.type == "button" then
                self:draw_layout()
                sleep(0.15)
                button.active = false
            end
            self:draw_layout()
        end
    end
end

function GUI:clear()
    self.active_layout = ""
    self.layouts = {}
    self.buttons = {}
    self.monitor.clear()
end

return GUI