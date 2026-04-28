ZT_Tasks = {}

local DEBUG_SANDBOX = true
local loggedSandboxValues = {}

local notebookTypes = {
    ["Base.Notebook"] = true,
    ["Base.Journal"] = true,
    ["Base.Diary"] = true,
    ["Base.Notepad"] = true,
    ["Base.Note"] = true,
    ["Base.SheetPaper2"] = true,
}

local writingTools = {
    ["Base.Pen"] = true,
    ["Base.Pencil"] = true,
    ["Base.RedPen"] = true,
    ["Base.BluePen"] = true,
}

local eraserTypes = {
    ["Base.Eraser"] = true,
}

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

local function debugSandbox(...)
    if DEBUG_SANDBOX and print then
        print("[ZomboidTodo.Sandbox]", ...)
    end
end

local function getSandboxValue(name, default)
    if SandboxVars and SandboxVars.ZomboidTodo and SandboxVars.ZomboidTodo[name] ~= nil then
        if not loggedSandboxValues[name] then
            debugSandbox(name, "=", tostring(SandboxVars.ZomboidTodo[name]))
            loggedSandboxValues[name] = true
        end
        return SandboxVars.ZomboidTodo[name]
    end
    if not loggedSandboxValues[name] then
        debugSandbox(name, "missing; using default", tostring(default))
        loggedSandboxValues[name] = true
    end
    return default
end

function ZT_Tasks.getSupplySpawnRate()
    return tonumber(getSandboxValue("SupplySpawnRate", 4)) or 4
end

function ZT_Tasks.requireWritingTool()
    return getSandboxValue("RequireWritingTool", true) == true
end

function ZT_Tasks.requireEraser()
    return getSandboxValue("RequireEraser", false) == true
end

local function dumpSandboxOptions()
    if SandboxVars and SandboxVars.ZomboidTodo then
        debugSandbox(
            "loaded",
            "SupplySpawnRate=" .. tostring(SandboxVars.ZomboidTodo.SupplySpawnRate),
            "RequireWritingTool=" .. tostring(SandboxVars.ZomboidTodo.RequireWritingTool),
            "RequireEraser=" .. tostring(SandboxVars.ZomboidTodo.RequireEraser)
        )
    else
        debugSandbox("SandboxVars.ZomboidTodo missing on client")
    end
    if getText then
        debugSandbox("translation Sandbox_ZomboidTodo =", tostring(getText("Sandbox_ZomboidTodo")))
        debugSandbox("translation Sandbox_ZomboidTodo_SupplySpawnRate =", tostring(getText("Sandbox_ZomboidTodo_SupplySpawnRate")))
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(dumpSandboxOptions)
end

function ZT_Tasks.canModifyTasks(player)
    if not ZT_Tasks.requireWritingTool() then
        return true
    end
    return ZT_Tasks.hasWritingTool(player)
end

function ZT_Tasks.canDeleteTasks(player)
    if not ZT_Tasks.requireEraser() then
        return true
    end
    return ZT_Tasks.hasEraser(player)
end

local function saveItemData(item)
    if not item then return end
    if item.saveData then
        pcall(function() item:saveData() end)
    end
end

local function getItemModData(item)
    if not item then
        return { label = "", tasks = {}, nextTaskId = 1 }
    end

    local data = item:getModData()
    if not data.immersiveTodo then
        data.immersiveTodo = { label = "", tasks = {}, nextTaskId = 1 }
    end
    if type(data.immersiveTodo.label) ~= "string" then
        data.immersiveTodo.label = ""
    end
    if type(data.immersiveTodo.tasks) ~= "table" then
        data.immersiveTodo.tasks = {}
    end
    if type(data.immersiveTodo.nextTaskId) ~= "number" then
        data.immersiveTodo.nextTaskId = 1
    end
    return data.immersiveTodo
end

local function createTaskId()
    return tostring(getTimestampMs()) .. "_" .. tostring(ZombRand(1000000))
end

function ZT_Tasks.getData(item)
    return getItemModData(item)
end

function ZT_Tasks.getLabel(item)
    if not item then return nil end
    local data = getItemModData(item)
    return data and data.label or nil
end

function ZT_Tasks.setLabel(item, label)
    if not item or not label then return false end
    local labelText = trim(label)
    if labelText == "" then return false end

    local data = getItemModData(item)
    data.label = labelText
    -- TODO: future: optionally create/replace a custom named paper item so inventory shows the label
    if item.setCustomName then
        item:setCustomName(true)
    end
    if item.setName then
        item:setName(labelText)
    end
    saveItemData(item)
    return true
end

function ZT_Tasks.isNotebookItem(item)
    return item and notebookTypes[item:getFullType()]
end

function ZT_Tasks.hasWritingTool(player)
    if not player then return false end
    local inventory = player:getInventory()
    if not inventory then return false end
    for _, item in ipairs(collectionToTable(inventory:getItems())) do
        if item and writingTools[item:getFullType()] then
            return true
        end
    end
    return false
end

function ZT_Tasks.hasNotebook(player)
    if not player then return false end
    local inventory = player:getInventory()
    if not inventory then return false end
    for _, item in ipairs(collectionToTable(inventory:getItems())) do
        if item and ZT_Tasks.isNotebookItem(item) then
            return true
        end
    end
    return false
end

function ZT_Tasks.hasEraser(player)
    if not player then return false end
    local inventory = player:getInventory()
    if not inventory then return false end
    for _, item in ipairs(collectionToTable(inventory:getItems())) do
        if item and eraserTypes[item:getFullType()] then
            return true
        end
    end
    return false
end

function ZT_Tasks.getTasks(item)
    local data = getItemModData(item)
    data.tasks = data.tasks or {}
    return data.tasks
end

function ZT_Tasks.getTask(item, id)
    local tasks = ZT_Tasks.getTasks(item)
    local lookupId = tostring(id)
    for index, task in ipairs(tasks) do
        if tostring(task.id) == lookupId then
            return task, index
        end
    end
    return nil, nil
end

function ZT_Tasks.updateTask(item, taskId, newText)
    local taskText = trim(newText)
    if taskText == "" then
        return false
    end

    local tasks = ZT_Tasks.getTasks(item)
    local lookupId = tostring(taskId)
    for _, task in ipairs(tasks) do
        if tostring(task.id) == lookupId then
            task.text = taskText
            saveItemData(item)
            return true
        end
    end
    return false
end

function ZT_Tasks.addTask(item, text)
    local taskText = trim(text)
    if taskText == "" then
        return false
    end

    local data = getItemModData(item)
    data.tasks = data.tasks or {}
    local task = {
        id = createTaskId(),
        text = taskText,
        done = false,
        createdAt = os.time(),
    }
    table.insert(data.tasks, task)
    saveItemData(item)
    return true
end

local function findTaskIndex(tasks, id)
    local lookupId = tostring(id)
    for index, task in ipairs(tasks) do
        if tostring(task.id) == lookupId then
            return index
        end
    end
    return nil
end

function ZT_Tasks.toggleTask(item, id)
    local tasks = ZT_Tasks.getTasks(item)
    local index = findTaskIndex(tasks, id)
    if index then
        tasks[index].done = not tasks[index].done
        saveItemData(item)
        return true
    end
    return false
end

function ZT_Tasks.removeTask(item, id)
    local tasks = ZT_Tasks.getTasks(item)
    local index = findTaskIndex(tasks, id)
    if index then
        table.remove(tasks, index)
        saveItemData(item)
        return true
    end
    return false
end

function ZT_Tasks.deleteTask(item, id)
    return ZT_Tasks.removeTask(item, id)
end
