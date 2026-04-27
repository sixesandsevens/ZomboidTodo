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

local function trim(text)
    if not text then return "" end
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function setButtonText(button, text)
    if not button then return end
    if button.setTitle then
        button:setTitle(text)
    elseif button.setText then
        button:setText(text)
    else
        button.title = text
    end
end

local function setLabelText(label, text)
    if not label then return end
    if label.setText then
        label:setText(text)
    elseif label.setName then
        label:setName(text)
    else
        label.name = text
    end
end

function ZomboidTodoWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local margin = 10
    local inputHeight = 24
    local buttonWidth = 70
    local labelWidth = 80
    local renameWidth = buttonWidth

    self.listNameEntry = ISTextEntryBox:new("", margin, 30, self.width - margin * 2 - renameWidth - 8, inputHeight)
    self.listNameEntry:initialise()
    self.listNameEntry:instantiate()
    self.listNameEntry:setText("")
    self:addChild(self.listNameEntry)

    self.renameButton = ISButton:new(self.width - margin - renameWidth, 30, renameWidth, inputHeight, "Rename", self, ZomboidTodoWindow.onRenameList)
    self.renameButton:initialise()
    self.renameButton:instantiate()
    self:addChild(self.renameButton)

    self.taskTextEntry = ISTextEntryBox:new("", margin, 64, self.width - margin * 2 - buttonWidth - 8, inputHeight)
    self.taskTextEntry:initialise()
    self.taskTextEntry:instantiate()
    self.taskTextEntry:setText("")
    self:addChild(self.taskTextEntry)

    self.addButton = ISButton:new(self.width - margin - buttonWidth, 64, buttonWidth, inputHeight, "Add", self, ZomboidTodoWindow.onAddTask)
    self.addButton:initialise()
    self.addButton:instantiate()
    self:addChild(self.addButton)

    self.taskListPanel = ISPanel:new(margin, 100, self.width - margin * 2, self.height - 110)
    self.taskListPanel:initialise()
    self.taskListPanel:instantiate()
    self.taskListPanel:setScrollChildren(true)
    self.taskListPanel:setScrollHeight(0)
    self:addChild(self.taskListPanel)

    self.toolStatusLabel = ISLabel:new(margin, self.height - 52, self.width - margin * 2, "", 1, 1, 1, 1, UIFont.Small)
    self.toolStatusLabel:initialise()
    self.toolStatusLabel:instantiate()
    self:addChild(self.toolStatusLabel)

    self.statusLabel = ISLabel:new(margin, self.height - 30, self.width - margin * 2, "", 1, 1, 1, 1, UIFont.Small)
    self.statusLabel:initialise()
    self.statusLabel:instantiate()
    self:addChild(self.statusLabel)

    self:updateListNameEntry()
    self:refresh()
end

function ZomboidTodoWindow:setStatus(text)
    setLabelText(self.statusLabel, text)
end

function ZomboidTodoWindow:getItemDisplayName()
    if not self.item then
        return "Paper"
    end
    if self.item.getDisplayName then
        return self.item:getDisplayName()
    end
    if self.item.getName then
        return self.item:getName()
    end
    return tostring(self.item:getFullType() or "Paper")
end

function ZomboidTodoWindow:updateWindowTitle()
    if not self.item then return end
    local windowTitle = "To-Do List"
    local label = ZT_Tasks.getLabel(self.item)
    if label and label ~= "" then
        windowTitle = windowTitle .. ": " .. label
    else
        windowTitle = windowTitle .. ": " .. self:getItemDisplayName()
    end
    if self.setTitle then
        self:setTitle(windowTitle)
    else
        self.title = windowTitle
    end
end

function ZomboidTodoWindow:updateListNameEntry()
    if not self.listNameEntry then return end
    local label = ZT_Tasks.getLabel(self.item)
    self.listNameEntry:setText(label or "")
end

function ZomboidTodoWindow:updateAddButtonLabel()
    local label = "Add"
    if self.editingTaskId then
        label = "Save"
    end
    setButtonText(self.addButton, label)
end

function ZomboidTodoWindow:onRenameList(button)
    if not self.player or not self.item then return end
    if not ZT_Tasks.hasWritingTool(self.player) then
        self:setStatus("You need a pen or pencil to rename this list.")
        return
    end

    local labelText = trim(self.listNameEntry:getText() or self.listNameEntry:getInternalText())
    if labelText == "" then
        self:setStatus("List name cannot be empty.")
        return
    end

    if ZT_Tasks.setLabel(self.item, labelText) then
        self:updateListNameEntry()
        self:updateWindowTitle()
        self:setStatus("List renamed.")
        self:refresh()
    end
end

function ZomboidTodoWindow:onAddTask(button)
    if not self.player or not self.item then return end

    local text = trim(self.taskTextEntry:getText() or self.taskTextEntry:getInternalText())
    if text == "" then
        return
    end

    if not ZT_Tasks.hasWritingTool(self.player) then
        self:setStatus("You need a pen or pencil to edit tasks.")
        return
    end

    if self.editingTaskId then
        if ZT_Tasks.updateTask(self.item, self.editingTaskId, text) then
            self:setStatus("Task saved.")
        end
        self.editingTaskId = nil
    else
        if ZT_Tasks.addTask(self.item, text) then
            self:setStatus("")
        end
    end

    self.taskTextEntry:setText("")
    self:updateAddButtonLabel()
    self:refresh()
end

function ZomboidTodoWindow:onToggleTask(button)
    if not self.player or not self.item then
        return
    end
    if not ZT_Tasks.hasWritingTool(self.player) then
        self:setStatus("You need a pen or pencil to toggle tasks.")
        return
    end
    if button and button.taskId and ZT_Tasks.toggleTask(self.item, button.taskId) then
        self:refresh()
    end
end

function ZomboidTodoWindow:onEditTask(button, taskId)
    if not self.player or not self.item then return end
    if not ZT_Tasks.hasWritingTool(self.player) then
        self:setStatus("You need a pen or pencil to edit tasks.")
        return
    end

    local task = ZT_Tasks.getTask(self.item, taskId)
    if not task then return end

    self.taskTextEntry:setText(task.text or "")
    self.editingTaskId = taskId
    self:updateAddButtonLabel()
    self:setStatus("Editing task")
end

function ZomboidTodoWindow:deleteTaskById(taskId)
    return self:onDeleteTaskFromMenu(nil, taskId)
end

function ZomboidTodoWindow:onDeleteTaskFromMenu(button, taskId)
    if not self.player or not self.item then return end
    if not ZT_Tasks.hasEraser(self.player) then
        self:setStatus("You need an eraser to delete tasks.")
        return
    end

    if ZT_Tasks.removeTask(self.item, taskId) then
        self.editingTaskId = nil
        self.taskTextEntry:setText("")
        self:setStatus("Task deleted.")
        self:updateAddButtonLabel()
        self:refresh()
    end
end

function ZomboidTodoWindow:showTaskContextMenu(taskId)
    if not self.player or not self.item or not taskId then return end

    local playerNum = 0
    if self.player.getPlayerNum then
        playerNum = self.player:getPlayerNum()
    end

    local menu = ISContextMenu.get(playerNum, getMouseX(), getMouseY())
    if not menu then return end

    local window = self
    local selectedTaskId = taskId

    menu:addOption("Edit Task", nil, function()
        window:onEditTask(nil, selectedTaskId)
    end)

    local deleteOption = menu:addOption("Delete Task", nil, function()
        window:deleteTaskById(selectedTaskId)
    end)
end

function ZomboidTodoWindow:createTaskRows()
    if self.taskListPanel then
        self:removeChild(self.taskListPanel)
        if self.taskListPanel.removeFromUIManager then
            self.taskListPanel:removeFromUIManager()
        end
        self.taskListPanel = nil
    end

    local margin = 10
    self.taskListPanel = ISPanel:new(margin, 100, self.width - margin * 2, self.height - 110)
    self.taskListPanel:initialise()
    self.taskListPanel:instantiate()
    self.taskListPanel:setScrollChildren(true)
    self.taskListPanel:setScrollHeight(0)
    self:addChild(self.taskListPanel)

    local tasks = ZT_Tasks.getTasks(self.item) or {}
    local rowHeight = 44
    local width = self.taskListPanel:getWidth()

    for index, task in ipairs(tasks) do
        local y = (index - 1) * (rowHeight + 6)
        local labelText = (task.done and "[x] " or "[ ] ") .. task.text
        local toggleButton = ISButton:new(0, y, width, rowHeight, labelText, self, ZomboidTodoWindow.onToggleTask)
        toggleButton.taskId = task.id
        toggleButton:initialise()
        toggleButton:instantiate()
        toggleButton.titleLeft = true
        if task.done then
            toggleButton.backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
        end
        toggleButton.onRightMouseUp = function(btn, mx, my)
            if btn and btn.target then
                btn.target:showTaskContextMenu(btn.taskId, mx, my)
            end
        end
        self.taskListPanel:addChild(toggleButton)
    end

    self.taskListPanel:setScrollHeight(#tasks * (rowHeight + 6))
end

function ZomboidTodoWindow:refresh()
    if not self.player or not self.item or not self.taskTextEntry or not self.addButton or not self.renameButton or not self.statusLabel then
        return
    end

    local hasWriting = ZT_Tasks.hasWritingTool(self.player) == true
    local hasEraser = ZT_Tasks.hasEraser(self.player) == true

    self:updateAddButtonLabel()
    self:updateWindowTitle()

    local toolStatus
    if not hasWriting and not hasEraser then
        toolStatus = "Need a pencil/pen to write. Need an eraser to delete."
    elseif not hasWriting then
        toolStatus = "Need a pencil/pen to write. Eraser: " .. (hasEraser and "Present" or "Missing")
    elseif not hasEraser then
        toolStatus = "Writing Tool: Present. Need an eraser to delete."
    else
        toolStatus = "Writing Tool: Present    Eraser: Present"
    end
    setLabelText(self.toolStatusLabel, toolStatus)

    local statusText = ""
    if not hasWriting then
        statusText = "You need a pen or pencil to modify tasks."
    else
        local displayName = self:getItemDisplayName()
        local label = ZT_Tasks.getLabel(self.item)
        if label and label ~= "" then
            statusText = "Stored on: " .. displayName .. " — " .. label
        else
            statusText = "Stored on: " .. displayName
        end
        if self.item.getCount and self.item:getCount() > 1 then
            statusText = statusText .. "  Tip: separate stacked paper items before making separate lists."
        end
    end

    self:setStatus(statusText)
    self:createTaskRows()
end

function ZomboidTodoWindow:new(x, y, width, height, player, item)
    local o = ISCollapsableWindow:new(x, y, width, height, "To-Do List", true)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.item = item
    o.editingTaskId = nil
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
    if ISCollapsableWindow.close then
        ISCollapsableWindow.close(self)
    end
end
