require "ZomboidTodo/ZT_Tasks"

ZomboidTodoWindow = ISCollapsableWindow:derive("ZomboidTodoWindow")

local function collectionToTable(collection)
    if not collection then return {} end
    if type(collection) == "table" then
        return collection
    end

    local list = {}
    for i = 0, collection:size() - 1 do
        table.insert(list, collection:get(i))
    end
    return list
end

function ZomboidTodoWindow:createChildren()
    local margin = 10
    local inputHeight = 24
    local buttonWidth = 70

    self.taskTextEntry = ISTextEntryBox:new("", margin, 30, self.width - margin * 2 - buttonWidth - 4, inputHeight)
    self.taskTextEntry:initialise()
    self.taskTextEntry:instantiate()
    self.taskTextEntry:setText("")
    self:addChild(self.taskTextEntry)

    self.addButton = ISButton:new(self.width - margin - buttonWidth, 30, buttonWidth, inputHeight, "Add", self, ZomboidTodoWindow.onAddTask)
    self.addButton:initialise()
    self.addButton:instantiate()
    self:addChild(self.addButton)

    self.taskListPanel = ISPanel:new(margin, 60, self.width - margin * 2, self.height - 90)
    self.taskListPanel:initialise()
    self.taskListPanel:instantiate()
    self.taskListPanel:setScrollChildren(true)
    self.taskListPanel:setScrollHeight(0)
    self:addChild(self.taskListPanel)

    self.statusLabel = ISLabel:new(margin, self.height - 25, 20, "", 1, 1, 1, 1, UIFont.Small)
    self.statusLabel:initialise()
    self.statusLabel:instantiate()
    self:addChild(self.statusLabel)

    self:refresh()
end

function ZomboidTodoWindow:onAddTask(button)
    if not self.player or not ZT_Tasks.hasWritingTool(self.player) then
        return
    end

    local text = self.taskTextEntry:getInternalText()
    if text and ZT_Tasks.addTask(self.player, text) then
        self.taskTextEntry:setText("")
        self:refresh()
    end
end

function ZomboidTodoWindow:onToggleTask(button)
    if not self.player or not ZT_Tasks.hasWritingTool(self.player) then
        return
    end
    if button.taskId and ZT_Tasks.toggleTask(self.player, button.taskId) then
        self:refresh()
    end
end

function ZomboidTodoWindow:onDeleteTask(button)
    if not self.player or not ZT_Tasks.hasWritingTool(self.player) then
        return
    end
    if button.taskId and ZT_Tasks.removeTask(self.player, button.taskId) then
        self:refresh()
    end
end

function ZomboidTodoWindow:createTaskRows()
    local panel = self.taskListPanel
    if not panel then return end

    local children = {}
    for _, child in ipairs(collectionToTable(panel:getChildren())) do
        table.insert(children, child)
    end
    for _, child in ipairs(children) do
        panel:removeChild(child)
    end

    local tasks = ZT_Tasks.getTasks(self.player) or {}
    local rowHeight = 28
    local width = panel:getWidth()
    local buttonWidth = 50

    for index, task in ipairs(tasks) do
        local y = (index - 1) * (rowHeight + 4)
        local labelText = (task.done and "☑ " or "☐ ") .. task.text
        local toggleButton = ISButton:new(0, y, width - buttonWidth - 4, rowHeight, labelText, self, ZomboidTodoWindow.onToggleTask)
        toggleButton.taskId = task.id
        toggleButton:initialise()
        toggleButton:instantiate()
        toggleButton:setEnable(ZT_Tasks.hasWritingTool(self.player))
        panel:addChild(toggleButton)

        local deleteButton = ISButton:new(width - buttonWidth, y, buttonWidth, rowHeight, "Delete", self, ZomboidTodoWindow.onDeleteTask)
        deleteButton.taskId = task.id
        deleteButton:initialise()
        deleteButton:instantiate()
        deleteButton:setEnable(ZT_Tasks.hasWritingTool(self.player))
        panel:addChild(deleteButton)
    end

    panel:setScrollHeight(#tasks * (rowHeight + 4))
end

function ZomboidTodoWindow:refresh()
    if not self.player or not self.taskTextEntry or not self.addButton or not self.statusLabel then
        return
    end

    local canModify = ZT_Tasks.hasWritingTool(self.player) == true

    self.taskTextEntry:setEditable(canModify)
    self.addButton:setEnable(canModify)

    local statusText = ""
    if not canModify then
        statusText = "You need a pen or pencil to modify tasks."
    end

    if self.statusLabel.setName then
        self.statusLabel:setName(statusText)
    elseif self.statusLabel.name ~= nil then
        self.statusLabel.name = statusText
    end

    self:createTaskRows()
end

function ZomboidTodoWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height, "Survivor Tasks", true)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.9 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    return o
end

function ZomboidTodoWindow:close()
    if self and self.setVisible then
        self:setVisible(false)
    end
    if self and self.removeFromUIManager then
        self:removeFromUIManager()
    end
end
